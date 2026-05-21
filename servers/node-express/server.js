const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const express = require('express');
const multer = require('multer');

const runtime = 'node';
const port = Number(process.env.LAB_PORT || process.env.PORT || 8080);
const serverDir = __dirname;
const rootDir = path.resolve(serverDir, '..', '..');
const uploadDir = path.join(serverDir, 'uploads');
const logDir = path.join(serverDir, 'logs');
const commonDir = path.join(rootDir, 'common');

fs.mkdirSync(uploadDir, { recursive: true });
fs.mkdirSync(logDir, { recursive: true });

function cleanFilename(filename) {
  const base = path.basename(filename || 'upload.bin');
  return base.replace(/[\x00-\x1f]/g, '_') || 'upload.bin';
}
function sha256(filePath) { return crypto.createHash('sha256').update(fs.readFileSync(filePath)).digest('hex'); }
function appendUploadLog(event) { fs.appendFileSync(path.join(logDir, 'upload-events.jsonl'), `${JSON.stringify(event)}\n`); }

const storage = multer.diskStorage({ destination: (_req, _file, cb) => cb(null, uploadDir), filename: (_req, file, cb) => cb(null, cleanFilename(file.originalname)) });
const app = express();
const upload = multer({ storage });

app.use('/static', express.static(path.join(commonDir, 'public')));
app.use('/uploads', express.static(uploadDir, { dotfiles: 'allow', index: false }));
app.get('/', (_req, res) => res.sendFile(path.join(commonDir, 'templates', 'index.html')));
app.get('/health', (_req, res) => res.json({ ok: true, runtime, uploadPath: uploadDir }));
app.post('/upload', upload.single('file'), (req, res) => {
  if (!req.file) return res.status(400).json({ success: false, message: 'file field is required' });
  const event = { runtime, originalName: req.file.originalname, storedName: req.file.filename, storedPath: req.file.path, size: req.file.size, mimeType: req.file.mimetype, sha256: sha256(req.file.path), uploadedAt: new Date().toISOString(), remoteAddress: req.ip };
  appendUploadLog(event);
  return res.json({ success: true, file: event });
});
app.get('/files', (_req, res) => {
  const files = fs.readdirSync(uploadDir, { withFileTypes: true }).filter((entry) => entry.isFile()).map((entry) => {
    const filePath = path.join(uploadDir, entry.name);
    const stat = fs.statSync(filePath);
    return { name: entry.name, size: stat.size, modifiedAt: stat.mtime.toISOString(), url: `/uploads/${encodeURIComponent(entry.name)}` };
  });
  res.json({ runtime, files });
});
app.listen(port, '127.0.0.1', () => console.log(`Node lab server listening on http://127.0.0.1:${port}`));

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const express = require('express');
const multer = require('multer');

const runtime = 'node';
const port = Number(process.env.LAB_PORT || process.env.PORT || 8080);
const host = process.env.LAB_HOST || '0.0.0.0';
const serverDir = __dirname;
const rootDir = path.resolve(serverDir, '..', '..');
const uploadDir = path.join(serverDir, 'uploads');
const logDir = path.join(serverDir, 'logs');
const commonDir = path.join(rootDir, 'common');
const uploadExecutable = /^(1|true|yes|on)$/i.test(process.env.LAB_UPLOAD_EXECUTABLE || '');

fs.mkdirSync(uploadDir, { recursive: true });
fs.mkdirSync(logDir, { recursive: true });
if (uploadExecutable) fs.chmodSync(uploadDir, 0o775);

function cleanFilename(filename) {
  const base = path.basename(filename || 'upload.bin');
  return base.replace(/[\x00-\x1f]/g, '_') || 'upload.bin';
}

function sha256(filePath) {
  return crypto.createHash('sha256').update(fs.readFileSync(filePath)).digest('hex');
}

function applyExecutableUploadPermissions(filePath) {
  if (uploadExecutable) fs.chmodSync(filePath, 0o775);
}

function appendUploadLog(event) {
  fs.appendFileSync(path.join(logDir, 'upload-events.jsonl'), `${JSON.stringify(event)}\n`);
}

function tokenFor(username) {
  return Buffer.from(JSON.stringify({ username, issuedAt: Date.now() })).toString('base64url');
}

function usernameFromToken(authHeader) {
  const token = (authHeader || '').replace(/^Bearer\s+/i, '');
  if (!token) return null;
  try {
    return JSON.parse(Buffer.from(token, 'base64url').toString('utf8')).username;
  } catch (_error) {
    return null;
  }
}

function sendPage(res, name) {
  res.sendFile(path.join(commonDir, 'templates', name));
}

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, uploadDir),
  filename: (_req, file, cb) => cb(null, cleanFilename(file.originalname)),
});

const app = express();
const upload = multer({ storage });

app.use(express.json());
app.use(express.static(path.join(commonDir, 'public')));
app.use('/uploads', express.static(uploadDir, { dotfiles: 'allow', index: false }));

app.get('/', (_req, res) => sendPage(res, 'index.html'));
app.get('/index.html', (_req, res) => sendPage(res, 'index.html'));
app.get('/login.html', (_req, res) => sendPage(res, 'login.html'));
app.get('/signup.html', (_req, res) => sendPage(res, 'signup.html'));
app.get('/dashboard.html', (_req, res) => sendPage(res, 'dashboard.html'));
app.get('/upload.html', (_req, res) => sendPage(res, 'upload.html'));
app.get('/upload', (_req, res) => sendPage(res, 'upload.html'));

app.get('/health', (_req, res) => res.json({ ok: true, runtime, uploadPath: uploadDir, uploadExecutable }));

app.post('/api/signup', (req, res) => {
  const username = String(req.body?.username || '').trim();
  if (!username || !req.body?.password) {
    return res.status(400).json({ success: false, message: 'Username and password are required.' });
  }
  return res.json({ success: true, message: 'Signup complete' });
});

app.post('/api/login', (req, res) => {
  const username = String(req.body?.username || '').trim();
  if (!username || !req.body?.password) {
    return res.status(400).json({ success: false, message: 'Username and password are required.' });
  }
  return res.json({ success: true, token: tokenFor(username) });
});

app.get('/api/dashboard', (req, res) => {
  const username = usernameFromToken(req.headers.authorization);
  if (!username) return res.status(401).json({ success: false, message: 'Authentication required' });
  return res.json({ success: true, username });
});

app.post('/upload', upload.single('file'), (req, res) => {
  if (!req.file) return res.status(400).json({ success: false, message: 'file field is required' });
  applyExecutableUploadPermissions(req.file.path);
  const event = {
    runtime,
    originalName: req.file.originalname,
    storedName: req.file.filename,
    storedPath: req.file.path,
    size: req.file.size,
    mimeType: req.file.mimetype,
    sha256: sha256(req.file.path),
    uploadedAt: new Date().toISOString(),
    remoteAddress: req.ip,
  };
  appendUploadLog(event);
  return res.json({ success: true, file: event });
});

app.get('/files', (_req, res) => {
  const files = fs.readdirSync(uploadDir, { withFileTypes: true })
    .filter((entry) => entry.isFile())
    .map((entry) => {
      const filePath = path.join(uploadDir, entry.name);
      const stat = fs.statSync(filePath);
      return {
        name: entry.name,
        size: stat.size,
        modifiedAt: stat.mtime.toISOString(),
        url: `/uploads/${encodeURIComponent(entry.name)}`,
      };
    });
  res.json({ runtime, files });
});

app.listen(port, host, () => {
  console.log(`Node lab server listening on http://${host}:${port}`);
});

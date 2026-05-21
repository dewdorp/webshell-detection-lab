<?php
$runtime = 'php';
$serverDir = __DIR__;
$rootDir = dirname(__DIR__, 2);
$uploadDir = $serverDir . DIRECTORY_SEPARATOR . 'uploads';
$logDir = $serverDir . DIRECTORY_SEPARATOR . 'logs';
@mkdir($uploadDir, 0775, true);
@mkdir($logDir, 0775, true);

function json_response($payload, $status = 200) {
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode($payload, JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT);
}
function clean_filename($name) { $base = basename($name ?: 'upload.bin'); $base = preg_replace('/[\x00-\x1f]/', '_', $base); return $base ?: 'upload.bin'; }
function serve_file($path, $contentType) { if (!is_file($path)) { http_response_code(404); echo 'Not found'; return; } header('Content-Type: ' . $contentType); readfile($path); }

$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$method = $_SERVER['REQUEST_METHOD'];

if ($path === '/') { serve_file($rootDir . '/common/templates/index.html', 'text/html; charset=utf-8'); return; }
if (str_starts_with($path, '/static/')) { $name = basename(substr($path, strlen('/static/'))); $target = $rootDir . '/common/public/' . $name; $type = str_ends_with($name, '.css') ? 'text/css; charset=utf-8' : 'application/javascript; charset=utf-8'; serve_file($target, $type); return; }
if (str_starts_with($path, '/uploads/')) { $name = basename(urldecode(substr($path, strlen('/uploads/')))); serve_file($uploadDir . DIRECTORY_SEPARATOR . $name, 'application/octet-stream'); return; }
if ($path === '/health') { json_response(['ok' => true, 'runtime' => $runtime, 'uploadPath' => $uploadDir]); return; }
if ($path === '/upload' && $method === 'POST') {
    if (!isset($_FILES['file'])) { json_response(['success' => false, 'message' => 'file field is required'], 400); return; }
    $file = $_FILES['file'];
    $storedName = clean_filename($file['name']);
    $storedPath = $uploadDir . DIRECTORY_SEPARATOR . $storedName;
    if (!move_uploaded_file($file['tmp_name'], $storedPath)) { json_response(['success' => false, 'message' => 'failed to store upload'], 500); return; }
    $event = ['runtime' => $runtime, 'originalName' => $file['name'], 'storedName' => $storedName, 'storedPath' => $storedPath, 'size' => filesize($storedPath), 'mimeType' => $file['type'] ?? 'application/octet-stream', 'sha256' => hash_file('sha256', $storedPath), 'uploadedAt' => gmdate('c'), 'remoteAddress' => $_SERVER['REMOTE_ADDR'] ?? ''];
    file_put_contents($logDir . '/upload-events.jsonl', json_encode($event, JSON_UNESCAPED_SLASHES) . PHP_EOL, FILE_APPEND);
    json_response(['success' => true, 'file' => $event]); return;
}
if ($path === '/files') {
    $files = [];
    foreach (scandir($uploadDir) ?: [] as $name) { $fullPath = $uploadDir . DIRECTORY_SEPARATOR . $name; if ($name === '.' || $name === '..' || !is_file($fullPath)) continue; $files[] = ['name' => $name, 'size' => filesize($fullPath), 'modifiedAt' => gmdate('c', filemtime($fullPath)), 'url' => '/uploads/' . rawurlencode($name)]; }
    json_response(['runtime' => $runtime, 'files' => $files]); return;
}
json_response(['success' => false, 'message' => 'not found'], 404);

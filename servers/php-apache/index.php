<?php
$runtime = 'php';
$serverDir = __DIR__;
$rootDir = dirname(__DIR__, 2);
$uploadDir = $serverDir . DIRECTORY_SEPARATOR . 'uploads';
$logDir = $serverDir . DIRECTORY_SEPARATOR . 'logs';

function upload_exec_enabled() {
    $value = strtolower((string) (getenv('LAB_UPLOAD_EXECUTABLE') ?: '0'));
    return in_array($value, ['1', 'true', 'yes', 'on'], true);
}

function apply_executable_upload_permissions($path) {
    if (upload_exec_enabled()) @chmod($path, 0775);
}

@mkdir($uploadDir, 0775, true);
@mkdir($logDir, 0775, true);
apply_executable_upload_permissions($uploadDir);

function json_response($payload, $status = 200) {
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode($payload, JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT);
}

function clean_filename($name) {
    $base = basename($name ?: 'upload.bin');
    $base = preg_replace('/[\x00-\x1f]/', '_', $base);
    return $base ?: 'upload.bin';
}

function serve_file($path, $contentType) {
    if (!is_file($path)) {
        http_response_code(404);
        echo 'Not found';
        return;
    }
    header('Content-Type: ' . $contentType);
    readfile($path);
}

function token_for($username) {
    return base64_encode(json_encode(['username' => $username, 'issuedAt' => time()], JSON_UNESCAPED_SLASHES));
}

function username_from_token() {
    $header = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    $token = trim(preg_replace('/^Bearer\s+/i', '', $header));
    if ($token === '') return null;
    $decoded = json_decode(base64_decode($token), true);
    return $decoded['username'] ?? null;
}

function request_json() {
    return json_decode(file_get_contents('php://input'), true) ?: [];
}

$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$method = $_SERVER['REQUEST_METHOD'];

if ($path === '/' || $path === '/index.html') {
    serve_file($rootDir . '/common/templates/index.html', 'text/html; charset=utf-8');
    return;
}

if (in_array($path, ['/login.html', '/signup.html', '/dashboard.html', '/upload.html'], true)) {
    serve_file($rootDir . '/common/templates/' . basename($path), 'text/html; charset=utf-8');
    return;
}

if ($path === '/upload' && $method === 'GET') {
    serve_file($rootDir . '/common/templates/upload.html', 'text/html; charset=utf-8');
    return;
}

if ($path === '/secutrace.png') {
    serve_file($rootDir . '/common/public/secutrace.png', 'image/png');
    return;
}

if (preg_match('/^\/(styles\.css|login\.js|signup\.js|dashboard\.js|upload\.js)$/', $path)) {
    $name = basename($path);
    $target = $rootDir . '/common/public/' . $name;
    $type = str_ends_with($name, '.css') ? 'text/css; charset=utf-8' : 'application/javascript; charset=utf-8';
    serve_file($target, $type);
    return;
}

if (str_starts_with($path, '/uploads/')) {
    $name = basename(urldecode(substr($path, strlen('/uploads/'))));
    serve_file($uploadDir . DIRECTORY_SEPARATOR . $name, 'application/octet-stream');
    return;
}

if ($path === '/health') {
    json_response(['ok' => true, 'runtime' => $runtime, 'uploadPath' => $uploadDir, 'uploadExecutable' => upload_exec_enabled()]);
    return;
}

if ($path === '/api/signup' && $method === 'POST') {
    $body = request_json();
    $username = trim($body['username'] ?? '');
    if ($username === '' || empty($body['password'])) {
        json_response(['success' => false, 'message' => 'Username and password are required.'], 400);
        return;
    }
    json_response(['success' => true, 'message' => 'Signup complete']);
    return;
}

if ($path === '/api/login' && $method === 'POST') {
    $body = request_json();
    $username = trim($body['username'] ?? '');
    if ($username === '' || empty($body['password'])) {
        json_response(['success' => false, 'message' => 'Username and password are required.'], 400);
        return;
    }
    json_response(['success' => true, 'token' => token_for($username)]);
    return;
}

if ($path === '/api/dashboard') {
    $username = username_from_token();
    if (!$username) {
        json_response(['success' => false, 'message' => 'Authentication required'], 401);
        return;
    }
    json_response(['success' => true, 'username' => $username]);
    return;
}

if ($path === '/upload' && $method === 'POST') {
    if (!isset($_FILES['file'])) {
        json_response(['success' => false, 'message' => 'file field is required'], 400);
        return;
    }

    $file = $_FILES['file'];
    $storedName = clean_filename($file['name']);
    $storedPath = $uploadDir . DIRECTORY_SEPARATOR . $storedName;

    if (!move_uploaded_file($file['tmp_name'], $storedPath)) {
        json_response(['success' => false, 'message' => 'failed to store upload'], 500);
        return;
    }
    apply_executable_upload_permissions($storedPath);

    $event = [
        'runtime' => $runtime,
        'originalName' => $file['name'],
        'storedName' => $storedName,
        'storedPath' => $storedPath,
        'size' => filesize($storedPath),
        'mimeType' => $file['type'] ?? 'application/octet-stream',
        'sha256' => hash_file('sha256', $storedPath),
        'uploadedAt' => gmdate('c'),
        'remoteAddress' => $_SERVER['REMOTE_ADDR'] ?? '',
    ];

    file_put_contents($logDir . '/upload-events.jsonl', json_encode($event, JSON_UNESCAPED_SLASHES) . PHP_EOL, FILE_APPEND);
    json_response(['success' => true, 'file' => $event]);
    return;
}

if ($path === '/files') {
    $files = [];
    foreach (scandir($uploadDir) ?: [] as $name) {
        $fullPath = $uploadDir . DIRECTORY_SEPARATOR . $name;
        if ($name === '.' || $name === '..' || !is_file($fullPath)) continue;
        $files[] = [
            'name' => $name,
            'size' => filesize($fullPath),
            'modifiedAt' => gmdate('c', filemtime($fullPath)),
            'url' => '/uploads/' . rawurlencode($name),
        ];
    }
    json_response(['runtime' => $runtime, 'files' => $files]);
    return;
}

json_response(['success' => false, 'message' => 'not found'], 404);

<?php
// Timezone
date_default_timezone_set('Asia/Jakarta');

// Start session SEBELUM headers
session_set_cookie_params([
    'lifetime' => 0,
    'path' => '/',
    'secure' => false,
    'httponly' => true,
    'samesite' => 'Lax'
]);
session_start();

// CORS Headers
$origin = $_SERVER['HTTP_ORIGIN'] ?? '';

if (preg_match('#^http://(localhost|127\.0\.0\.1)(:\d+)?$#', $origin)) {
    header("Access-Control-Allow-Origin: $origin");
}

header("Access-Control-Allow-Credentials: true");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json; charset=UTF-8");

// Handle preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Include database
require_once '../config/database.php';

// Helper functions
function sendResponse($status, $message, $data = null) {
    $response = ['status' => $status, 'message' => $message];
    if ($data !== null) $response['data'] = $data;
    echo json_encode($response);
    exit();
}

function sendError($message, $code = 400) {
    http_response_code($code);
    sendResponse('error', $message);
}

function sendSuccess($message, $data = null) {
    http_response_code(200);
    sendResponse('success', $message, $data);
}

function getAuthUserId() {
    $header = $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';

    // Aplikasi: membawa token
    if (preg_match('/Bearer\s+(\S+)/', $header, $m)) {
        $db = new Database();
        $conn = $db->getConnection();
        $stmt = $conn->prepare('SELECT user_id FROM api_tokens WHERE token = :token AND expires_at > NOW()');
        $stmt->bindParam(':token', $m[1]);
        $stmt->execute();
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        return $row ? (int) $row['user_id'] : null;
    }

    // Website lama: memakai session
    return isset($_SESSION['user_id']) ? (int) $_SESSION['user_id'] : null;
}

// Membuat token baru untuk pengguna (berlaku 7 hari)
function createApiToken($conn, $user_id) {
    $token = bin2hex(random_bytes(32));
    $stmt = $conn->prepare('INSERT INTO api_tokens (user_id, token, expires_at) VALUES (:user_id, :token, DATE_ADD(NOW(), INTERVAL 7 DAY))');
    $stmt->bindParam(':user_id', $user_id);
    $stmt->bindParam(':token', $token);
    $stmt->execute();
    return $token;
}

// Menghapus token yang sedang dipakai (untuk logout)
function revokeApiToken($conn) {
    $header = $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';
    if (preg_match('/Bearer\s+(\S+)/', $header, $m)) {
        $stmt = $conn->prepare('DELETE FROM api_tokens WHERE token = :token');
        $stmt->bindParam(':token', $m[1]);
        $stmt->execute();
    }
}

?>
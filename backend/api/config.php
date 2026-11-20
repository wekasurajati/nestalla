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
session_start(['read_and_close' => true]);

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

// Include environment reader
require_once '../config/env.php';

// Include database
require_once '../config/database.php';

// ========================================
// PENGATURAN PEMBAYARAN MIDTRANS
// ========================================
define('PAYMENT_EXPIRY_MINUTES', 60);
define('PAYMENT_FINISH_URL', 'https://nestalla.app/payment/finish');

function midtransBaseUrls() {
    $isProduction = (env('MIDTRANS_IS_PRODUCTION', 'false') === 'true');

    if ($isProduction) {
        return [
            'snap' => 'https://app.midtrans.com/snap/v1/transactions',
            'core' => 'https://api.midtrans.com',
        ];
    }

    return [
        'snap' => 'https://app.sandbox.midtrans.com/snap/v1/transactions',
        'core' => 'https://api.sandbox.midtrans.com',
    ];
}

function midtransRequest($method, $url, $body = null) {
    $serverKey = env('MIDTRANS_SERVER_KEY', '');
    $auth = base64_encode($serverKey . ':');

    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CONNECTTIMEOUT => 5,
        CURLOPT_TIMEOUT => 8,
        CURLOPT_CUSTOMREQUEST => $method,
        CURLOPT_HTTPHEADER => [
            'Authorization: Basic ' . $auth,
            'Content-Type: application/json',
            'Accept: application/json',
        ],
    ]);

    if ($body !== null) {
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($body));
    }

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlError = curl_error($ch);
    curl_close($ch);

    if ($response === false) {
        throw new Exception('Midtrans cURL error: ' . $curlError);
    }

    $decoded = json_decode($response, true);
    if ($decoded === null && json_last_error() !== JSON_ERROR_NONE) {
        $decoded = ['raw' => $response];
    }

    return [$httpCode, $decoded];
}

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

// GOOGLE SIGN-IN
// Web Client ID dari Google Cloud. Ganti dengan milikmu.
define('GOOGLE_WEB_CLIENT_ID', '347952003102-1i1unpugipp7pgjj4r0o3q81mu7arujg.apps.googleusercontent.com');

// Memeriksa ID Token ke Google. Mengembalikan data pengguna, atau null jika tidak valid.
// Melempar Exception jika Google tidak dapat dihubungi.
function verifyGoogleIdToken($idToken) {
    $ch = curl_init('https://oauth2.googleapis.com/tokeninfo?id_token=' . urlencode($idToken));
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 10,
    ]);
    $response = curl_exec($ch);
    $status = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlError = curl_error($ch);
    curl_close($ch);

    if ($response === false) {
        error_log('Google tokeninfo error: ' . $curlError);
        throw new Exception('Tidak dapat menghubungi Google');
    }
    if ($status !== 200) {
        return null;
    }

    $payload = json_decode($response, true);
    if (!is_array($payload)) {
        return null;
    }

    // Penerbit harus Google
    $iss = $payload['iss'] ?? '';
    if ($iss !== 'accounts.google.com' && $iss !== 'https://accounts.google.com') {
        return null;
    }
    // Token harus ditujukan untuk aplikasi KITA
    if (($payload['aud'] ?? '') !== GOOGLE_WEB_CLIENT_ID) {
        return null;
    }
    // Belum kedaluwarsa
    if ((int) ($payload['exp'] ?? 0) < time()) {
        return null;
    }
    // Email harus sudah diverifikasi Google
    $verified = $payload['email_verified'] ?? false;
    if ($verified !== true && $verified !== 'true') {
        return null;
    }
    if (empty($payload['sub']) || empty($payload['email'])) {
        return null;
    }

    return $payload;
}

// Membuat username unik dari email 
function generateUniqueUsername($conn, $email) {
    $base = strtolower(explode('@', $email)[0]);
    $base = preg_replace('/[^a-z0-9._]/', '', $base);
    if ($base === '') {
        $base = 'user';
    }
    $base = substr($base, 0, 40);

    $stmt = $conn->prepare('SELECT 1 FROM users WHERE username = :u');
    $username = $base;
    for ($i = 1; $i <= 1000; $i++) {
        $stmt->execute([':u' => $username]);
        if (!$stmt->fetch()) {
            return $username;
        }
        $username = $base . $i;
    }
    return $base . random_int(100000, 999999);
}

?>
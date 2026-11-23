<?php
// File: admin/includes/auth.php
// Proteksi halaman admin dan fungsi bantu yang dipakai semua halaman.

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

if (empty($_SESSION['admin_logged_in']) || $_SESSION['admin_logged_in'] !== true) {
    header('Location: login.php');
    exit;
}

date_default_timezone_set('Asia/Jakarta');

require_once '../config/database.php';

// ---------- Format ----------
function e($value)
{
    return htmlspecialchars((string) $value, ENT_QUOTES, 'UTF-8');
}

function formatRupiah($angka)
{
    return 'Rp' . number_format((float) $angka, 0, ',', '.');
}

function formatTanggal($tanggal)
{
    if (empty($tanggal)) {
        return '-';
    }
    static $bulan = [1 => 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    $t = strtotime($tanggal);
    return date('d', $t) . ' ' . $bulan[(int) date('n', $t)] . ' ' . date('Y, H:i', $t);
}

// Lencana status berwarna (tone: ok, warn, bad, info, muted)
function badge($tone, $text)
{
    return '<span class="nv-badge nv-badge--' . e($tone) . '">' . e($text) . '</span>';
}

// ---------- CSRF ----------
function csrf_token()
{
    if (empty($_SESSION['csrf'])) {
        $_SESSION['csrf'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf'];
}

function csrf_field()
{
    return '<input type="hidden" name="csrf" value="' . e(csrf_token()) . '">';
}

function csrf_valid()
{
    return isset($_POST['csrf'], $_SESSION['csrf']) && hash_equals($_SESSION['csrf'], (string) $_POST['csrf']);
}

// ---------- Pesan kilat (flash) ----------
function flash($type, $message)
{
    // Pesan "info" tidak boleh menimpa pesan sukses yang belum sempat dibaca
    if ($type === 'info' && !empty($_SESSION['flash']) && $_SESSION['flash']['type'] === 'success') {
        return;
    }
    $_SESSION['flash'] = ['type' => $type, 'message' => $message];
}

function flash_render()
{
    $out = '';
    if (!empty($_SESSION['flash'])) {
        $f = $_SESSION['flash'];
        $styles = [
            'success' => ['alert-success', 'fa-check-circle'],
            'info'    => ['alert-info', 'fa-info-circle'],
            'warning' => ['alert-warning', 'fa-exclamation-triangle'],
            'error'   => ['alert-danger', 'fa-exclamation-circle'],
        ];
        list($cls, $icon) = $styles[$f['type']] ?? $styles['error'];
        $out = '<div class="alert ' . $cls . ' alert-dismissible"><button type="button" class="close" data-dismiss="alert">&times;</button>'
             . '<i class="fas ' . $icon . ' mr-1"></i> ' . e($f['message']) . '</div>';
        unset($_SESSION['flash']);
    }
    // Pesan lama dari halaman yang belum diperbarui
    foreach (['success' => 'alert-success', 'error' => 'alert-danger'] as $key => $cls) {
        if (!empty($_SESSION[$key])) {
            $out .= '<div class="alert ' . $cls . ' alert-dismissible"><button type="button" class="close" data-dismiss="alert">&times;</button>'
                  . e($_SESSION[$key]) . '</div>';
            unset($_SESSION[$key]);
        }
    }
    return $out;
}

// ---------- Query aman ----------
function db_rows(PDO $conn, $sql, array $params = [])
{
    try {
        $st = $conn->prepare($sql);
        $st->execute($params);
        return $st->fetchAll(PDO::FETCH_ASSOC);
    } catch (Throwable $ex) {
        error_log('[admin] ' . $ex->getMessage());
        return [];
    }
}

function db_scalar(PDO $conn, $sql, array $params = [], $default = 0)
{
    try {
        $st = $conn->prepare($sql);
        $st->execute($params);
        $v = $st->fetchColumn();
        return ($v === false || $v === null) ? $default : $v;
    } catch (Throwable $ex) {
        error_log('[admin] ' . $ex->getMessage());
        return $default;
    }
}

// Alamat gambar sampul buku: nama file di image/covers, atau path lama (assets/uploads/...)
function cover_url($image)
{
    $image = trim((string) $image);
    if ($image === '') {
        return '';
    }
    if (strpos($image, '/') !== false) {
        return '../' . ltrim($image, '/');
    }
    return '../image/covers/' . rawurlencode($image);
}

<?php
// File: admin/includes/auth.php
// Proteksi halaman admin - harus login dulu

session_start();

// Cek apakah user sudah login
if(!isset($_SESSION['admin_logged_in']) || $_SESSION['admin_logged_in'] !== true) {
    // Belum login, redirect ke halaman login
    header("Location: login.php");
    exit;
}

// Set timezone
date_default_timezone_set('Asia/Jakarta');

// Include database connection
require_once '../config/database.php';

// Fungsi helper
function formatRupiah($angka) {
    return 'Rp' . number_format($angka, 0, ',', '.');
}

function formatTanggal($tanggal) {
    return date('d M Y, H:i', strtotime($tanggal));
}
?>
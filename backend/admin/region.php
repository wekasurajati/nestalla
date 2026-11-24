<?php
// File: admin/region.php
// Perantara data wilayah untuk halaman Pengiriman.
// Browser tidak boleh memanggil emsifa.github.io langsung (diblokir CORS), jadi server PHP
// yang mengambilnya, menyimpannya sebagai cache, lalu meneruskannya ke browser.
//   region.php?type=provinces
//   region.php?type=regencies&id=33
// Hanya untuk admin yang sudah login (auth.php mengalihkan ke login bila belum).

require_once 'includes/auth.php';
session_write_close(); // hanya membaca sesi; lepaskan kunci agar permintaan paralel tidak antre

const REGION_UPSTREAM = 'https://emsifa.github.io/api-wilayah-indonesia/api';
const REGION_CACHE_DAYS = 30;

function region_fail($code, $message)
{
    http_response_code($code);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode(['error' => $message]);
    exit;
}

// Ambil isi URL. Mengembalikan [isi|null, pesanError].
function region_fetch($url)
{
    if (function_exists('curl_init')) {
        $run = function ($verify) use ($url) {
            $ch = curl_init($url);
            curl_setopt_array($ch, [
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_FOLLOWLOCATION => true,
                CURLOPT_CONNECTTIMEOUT => 8,
                CURLOPT_TIMEOUT        => 15,
                CURLOPT_SSL_VERIFYPEER => $verify,
                CURLOPT_SSL_VERIFYHOST => $verify ? 2 : 0,
            ]);
            $body = curl_exec($ch);
            $errno = curl_errno($ch);
            $err = curl_error($ch);
            $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);
            return [$body, $errno, $err, $code];
        };
        list($body, $errno, $err, $code) = $run(true);
        // XAMPP di Windows sering tidak punya paket sertifikat (error 60 atau 77).
        // Data wilayah ini publik dan hanya dipakai untuk mengisi pilihan, jadi
        // boleh dicoba ulang tanpa verifikasi. Dicatat di log supaya terlihat.
        if ($body === false && in_array($errno, [60, 77], true)) {
            error_log('[admin] region: sertifikat SSL tidak terverifikasi, dicoba tanpa verifikasi (' . $err . ')');
            list($body, $errno, $err, $code) = $run(false);
        }
        if ($body !== false && $code === 200) {
            return [$body, ''];
        }
        return [null, $err !== '' ? $err : 'HTTP ' . $code];
    }

    $ctx = stream_context_create(['http' => ['timeout' => 15]]);
    $body = @file_get_contents($url, false, $ctx);
    return $body === false ? [null, 'file_get_contents gagal (periksa allow_url_fopen dan openssl di php.ini)'] : [$body, ''];
}

$type = (string) ($_GET['type'] ?? '');
if ($type === 'provinces') {
    $path = '/provinces.json';
    $key = 'provinces';
} elseif ($type === 'regencies') {
    $id = (string) ($_GET['id'] ?? '');
    if (!preg_match('/^[0-9]{1,4}$/', $id)) {
        region_fail(400, 'Kode provinsi tidak valid.');
    }
    $path = '/regencies/' . $id . '.json';
    $key = 'regencies_' . $id;
} else {
    region_fail(400, 'Jenis data tidak dikenal.');
}

$dir = rtrim(sys_get_temp_dir(), '/\\') . DIRECTORY_SEPARATOR . 'nestalla-wilayah';
if (!is_dir($dir)) {
    @mkdir($dir, 0775, true);
}
$file = $dir . DIRECTORY_SEPARATOR . $key . '.json';
$fresh = is_file($file) && filemtime($file) > time() - REGION_CACHE_DAYS * 86400;

$body = null;
if ($fresh) {
    $body = @file_get_contents($file);
}
if ($body === null || $body === false) {
    list($remote, $why) = region_fetch(REGION_UPSTREAM . $path);
    $data = $remote !== null ? json_decode($remote, true) : null;
    if (is_array($data) && $data && isset($data[0]['id'], $data[0]['name'])) {
        $body = $remote;
        @file_put_contents($file, $body, LOCK_EX);
    } else {
        // Sumber tidak terjangkau: pakai cache lama kalau ada
        $stale = is_file($file) ? @file_get_contents($file) : false;
        if ($stale !== false && $stale !== '') {
            $body = $stale;
        } else {
            error_log('[admin] region: gagal mengambil ' . $path . ' - ' . $why);
            region_fail(502, 'Server tidak bisa mengambil data wilayah: ' . $why);
        }
    }
}

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: private, max-age=86400');
echo $body;

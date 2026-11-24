<?php
// File: admin/includes/shipping_lib.php
// Fungsi bantu halaman Pengiriman (ekspedisi dan tarif per kota).
// Tabel: shipping_carriers (ekspedisi) dan shipping_rates (tarif per provinsi dan kota).

function ship_text($v)
{
    return trim(preg_replace('/\s+/u', ' ', (string) $v));
}

function ship_len($s)
{
    return function_exists('mb_strlen') ? mb_strlen($s, 'UTF-8') : strlen($s);
}

// Baca harga: hanya angka bulat. Mengembalikan [int|null, pesanError].
function ship_read_price($raw)
{
    $t = trim((string) $raw);
    if ($t === '') {
        return [null, 'Harga wajib diisi.'];
    }
    if (!ctype_digit($t)) {
        return [null, 'Harga hanya boleh angka bulat, tanpa titik, koma, atau "Rp".'];
    }
    if (strlen($t) > 9) {
        return [null, 'Harga terlalu besar.'];
    }
    return [(int) $t, ''];
}

// Baca isian ekspedisi. Mengembalikan [data, daftarError].
function ship_read_carrier(array $src)
{
    $errors = [];
    $d = [
        'name'   => ship_text($src['carrier_name'] ?? ''),
        'phone'  => ship_text($src['contact_phone'] ?? ''),
        'email'  => trim((string) ($src['contact_email'] ?? '')),
        'active' => isset($src['is_active']) ? 1 : 0,
    ];
    if ($d['name'] === '') {
        $errors[] = 'Nama ekspedisi wajib diisi.';
    } elseif (ship_len($d['name']) > 100) {
        $errors[] = 'Nama ekspedisi maksimal 100 karakter.';
    }
    if ($d['phone'] !== '' && (ship_len($d['phone']) > 20 || !preg_match('/^[0-9+\-\s()]+$/', $d['phone']))) {
        $errors[] = 'Telepon maksimal 20 karakter, hanya angka, spasi, +, -, dan tanda kurung.';
    }
    if ($d['email'] !== '' && (strlen($d['email']) > 100 || !filter_var($d['email'], FILTER_VALIDATE_EMAIL))) {
        $errors[] = 'Format email tidak valid (maksimal 100 karakter).';
    }
    $d['phone'] = $d['phone'] === '' ? null : $d['phone'];
    $d['email'] = $d['email'] === '' ? null : $d['email'];
    return [$d, $errors];
}

// Baca isian tarif. Mengembalikan [data, daftarError].
function ship_read_rate(array $src)
{
    $errors = [];
    $d = [
        'province' => ship_text($src['province'] ?? ''),
        'city'     => ship_text($src['city'] ?? ''),
        'active'   => isset($src['is_active']) ? 1 : 0,
    ];
    if ($d['province'] === '') {
        $errors[] = 'Provinsi wajib diisi.';
    } elseif (ship_len($d['province']) > 100) {
        $errors[] = 'Provinsi maksimal 100 karakter.';
    }
    if ($d['city'] === '') {
        $errors[] = 'Kota atau kabupaten wajib diisi.';
    } elseif (ship_len($d['city']) > 100) {
        $errors[] = 'Kota atau kabupaten maksimal 100 karakter.';
    }
    list($price, $perr) = ship_read_price($src['price'] ?? '');
    if ($perr !== '') {
        $errors[] = $perr;
    }
    $d['price'] = $price;
    return [$d, $errors];
}

// Nama ekspedisi sudah dipakai? (tanpa membedakan huruf besar kecil)
function ship_carrier_name_taken(PDO $conn, $name, $exceptId)
{
    $n = db_scalar(
        $conn,
        'SELECT COUNT(*) FROM shipping_carriers WHERE carrier_name = :n AND carrier_id <> :id',
        [':n' => $name, ':id' => (int) $exceptId],
        0
    );
    return ((int) $n) > 0;
}

// Tarif untuk ekspedisi, provinsi, dan kota yang sama sudah ada?
// Pencocokan sama dengan yang dipakai API saat checkout.
function ship_rate_duplicate(PDO $conn, $carrierId, $province, $city, $exceptRateId)
{
    $n = db_scalar(
        $conn,
        'SELECT COUNT(*) FROM shipping_rates WHERE carrier_id = :c AND province = :p AND city = :ct AND rate_id <> :id',
        [':c' => (int) $carrierId, ':p' => $province, ':ct' => $city, ':id' => (int) $exceptRateId],
        0
    );
    return ((int) $n) > 0;
}

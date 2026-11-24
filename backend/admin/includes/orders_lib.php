<?php
// File: admin/includes/orders_lib.php
// Fungsi bantu khusus pesanan (label, warna, ubah status, nomor resi).

function enum_values(PDO $conn, $table, $column)
{
    $type = db_scalar(
        $conn,
        'SELECT COLUMN_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = :t AND COLUMN_NAME = :c',
        [':t' => $table, ':c' => $column],
        ''
    );
    if ($type === '' || stripos($type, 'enum(') !== 0) {
        return [];
    }
    preg_match_all("/'((?:[^']|'')*)'/", $type, $m);
    return array_map(function ($v) { return str_replace("''", "'", $v); }, $m[1]);
}

function order_status_values(PDO $conn)
{
    $v = enum_values($conn, 'orders', 'status');
    return $v ?: ['pending', 'processing', 'shipped', 'completed', 'cancelled'];
}

function status_label($s)
{
    $map = ['pending' => 'Menunggu', 'processing' => 'Diproses', 'shipped' => 'Dikirim',
            'completed' => 'Selesai', 'cancelled' => 'Dibatalkan'];
    return $map[$s] ?? ucfirst((string) $s);
}

function status_tone($s)
{
    $map = ['pending' => 'warn', 'processing' => 'info', 'shipped' => 'info',
            'completed' => 'ok', 'cancelled' => 'bad'];
    return $map[$s] ?? 'muted';
}

function payment_status_label($s)
{
    $map = ['pending' => 'Belum dibayar', 'paid' => 'Lunas', 'failed' => 'Gagal',
            'expired' => 'Kedaluwarsa', 'cancelled' => 'Dibatalkan'];
    return $map[$s] ?? ucfirst((string) $s);
}

function payment_status_tone($s)
{
    $map = ['pending' => 'warn', 'paid' => 'ok', 'failed' => 'bad', 'expired' => 'muted', 'cancelled' => 'bad'];
    return $map[$s] ?? 'muted';
}

function payment_method_label($m)
{
    $map = ['bank' => 'Transfer bank', 'ewallet' => 'E-wallet', 'cod' => 'Bayar di tempat',
            'credit' => 'Kartu kredit', 'midtrans' => 'Midtrans'];
    return $map[$m] ?? ucfirst((string) $m);
}

// ---------- Nomor resi ----------

// Apakah kolom orders.tracking_number sudah ada (migrasi sudah diimpor)?
function orders_has_tracking(PDO $conn)
{
    static $has = null;
    if ($has === null) {
        $n = db_scalar(
            $conn,
            "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'orders' AND COLUMN_NAME = 'tracking_number'",
            [],
            0
        );
        $has = ((int) $n) > 0;
    }
    return $has;
}

// Validasi nomor resi di server. Mengembalikan [nilaiBersih, pesanError].
// Pesan error kosong berarti valid.
function clean_tracking($raw)
{
    $t = trim((string) $raw);
    if ($t === '') {
        return ['', 'Nomor resi wajib diisi.'];
    }
    if (strlen($t) > 100) {
        return ['', 'Nomor resi maksimal 100 karakter.'];
    }
    if (!preg_match('/^[A-Za-z0-9-]+$/', $t)) {
        return ['', 'Nomor resi hanya boleh berisi huruf, angka, dan tanda hubung (-), tanpa spasi.'];
    }
    return [$t, ''];
}

function tracking_missing_message()
{
    return 'Kolom tracking_number belum ada di database. Jalankan file migrasi 2026-11-24_orders_tracking_number.sql di phpMyAdmin dulu.';
}

// Ubah nomor resi saja (untuk pesanan yang sudah Dikirim atau Selesai).
// Mengembalikan [jenisPesan, pesan].
function admin_update_tracking(PDO $conn, $orderId, $trackingRaw)
{
    if (!orders_has_tracking($conn)) {
        return ['error', tracking_missing_message()];
    }
    list($tracking, $err) = clean_tracking($trackingRaw);
    if ($err !== '') {
        return ['error', 'Nomor resi tidak disimpan. ' . $err];
    }

    $rows = db_rows(
        $conn,
        'SELECT order_number, status, tracking_number FROM orders WHERE order_id = :id',
        [':id' => $orderId]
    );
    if (!$rows) {
        return ['error', 'Pesanan tidak ditemukan.'];
    }
    $o = $rows[0];
    $no = $o['order_number'];

    if (!in_array($o['status'], ['shipped', 'completed'], true)) {
        return ['error', 'Nomor resi hanya bisa diubah setelah pesanan ' . $no . ' berstatus Dikirim.'];
    }
    if ((string) $o['tracking_number'] === $tracking) {
        return ['info', 'Nomor resi pesanan ' . $no . ' tidak berubah.'];
    }

    try {
        $up = $conn->prepare(
            "UPDATE orders SET tracking_number = :t WHERE order_id = :id AND status IN ('shipped', 'completed')"
        );
        $ok = $up->execute([':t' => $tracking, ':id' => $orderId]);
    } catch (Throwable $ex) {
        error_log('[admin] gagal simpan resi ' . $no . ': ' . $ex->getMessage());
        return ['error', 'Nomor resi gagal disimpan. Coba lagi.'];
    }
    if ($ok === false || $up->rowCount() === 0) {
        return ['info', 'Pesanan ' . $no . ' baru saja berubah. Muat ulang halaman, lalu coba lagi.'];
    }
    return ['success', 'Nomor resi pesanan ' . $no . ' disimpan: ' . $tracking . '.'];
}

// ---------- Ubah status ----------

// Ubah status pesanan.
// Mengembalikan [jenisPesan, pesan, tugasSesudahRespons|null].
// jenisPesan: success | info | warning | error. Email dikirim SESUDAH halaman
// selesai dimuat (lihat admin_redirect_then), supaya admin tidak menunggu SMTP.
// Bila status baru 'shipped', nomor resi ($trackingRaw) wajib dan disimpan
// bersama status dalam satu UPDATE.
function admin_update_order_status(PDO $conn, $orderId, $newStatus, $sendEmail, $expectedStatus = '', $trackingRaw = '')
{
    if (!in_array($newStatus, order_status_values($conn), true)) {
        return ['error', 'Status tidak valid.', null];
    }

    $st = $conn->prepare(
        'SELECT o.order_id, o.order_number, o.status, u.email, u.full_name
         FROM orders o LEFT JOIN users u ON u.user_id = o.user_id
         WHERE o.order_id = :id'
    );
    $st->execute([':id' => $orderId]);
    $order = $st->fetch(PDO::FETCH_ASSOC);
    if (!$order) {
        return ['error', 'Pesanan tidak ditemukan.', null];
    }
    $no = $order['order_number'];
    $old = $order['status'];

    // Halaman yang dibuka sudah usang: status diubah pihak lain (aplikasi, pembayaran, admin lain)
    if ($expectedStatus !== '' && $old !== $expectedStatus && $old !== $newStatus) {
        return ['warning', 'Status pesanan ' . $no . ' sudah berubah menjadi "' . status_label($old)
            . '" sejak halaman ini dibuka (bisa dari aplikasi, pembayaran, atau admin lain). '
            . 'Tidak ada yang diubah. Periksa status terbaru, lalu coba lagi.', null];
    }
    if ($old === $newStatus) {
        return ['info', 'Pesanan ' . $no . ' sudah berstatus "' . status_label($old) . '", tidak ada perubahan.', null];
    }

    // Status Dikirim: nomor resi wajib dan divalidasi di server
    $isShip = ($newStatus === 'shipped');
    $tracking = '';
    if ($isShip) {
        if (!orders_has_tracking($conn)) {
            return ['error', tracking_missing_message(), null];
        }
        list($tracking, $trkErr) = clean_tracking($trackingRaw);
        if ($trkErr !== '') {
            return ['error', 'Status tidak diubah. ' . $trkErr, null];
        }
    }

    // Ubah hanya bila status masih sama dengan yang tadi dibaca (anti tabrakan)
    try {
        if ($isShip) {
            $up = $conn->prepare('UPDATE orders SET status = :s, tracking_number = :t WHERE order_id = :id AND status = :old');
            $ok = $up->execute([':s' => $newStatus, ':t' => $tracking, ':id' => $orderId, ':old' => $old]);
        } else {
            $up = $conn->prepare('UPDATE orders SET status = :s WHERE order_id = :id AND status = :old');
            $ok = $up->execute([':s' => $newStatus, ':id' => $orderId, ':old' => $old]);
        }
    } catch (Throwable $ex) {
        error_log('[admin] gagal ubah status ' . $no . ': ' . $ex->getMessage());
        return ['error', 'Status pesanan ' . $no . ' gagal disimpan. Coba lagi.', null];
    }
    if ($ok === false) {
        return ['error', 'Status pesanan ' . $no . ' gagal disimpan. Coba lagi.', null];
    }
    if ($up->rowCount() === 0) {
        return ['info', 'Status pesanan ' . $no . ' baru saja diubah oleh permintaan lain. Muat ulang halaman untuk melihat status terbaru.', null];
    }

    $msg = 'Status pesanan ' . $no . ' diubah dari "' . status_label($old) . '" menjadi "' . status_label($newStatus) . '".';
    if ($isShip) {
        $msg .= ' Nomor resi: ' . $tracking . '.';
    }

    $after = null;
    $file = __DIR__ . '/../../config/email.php';
    if ($sendEmail && !empty($order['email']) && is_file($file)) {
        $msg .= ' Email pemberitahuan dikirim di latar belakang.';
        $to = $order['email'];
        $name = $order['full_name'];
        $after = function () use ($file, $to, $name, $no, $newStatus) {
            try {
                require_once $file;
                $svc = new EmailService();
                $svc->sendOrderStatusUpdate($to, $name, $no, $newStatus);
            } catch (Throwable $ex) {
                error_log('[admin] gagal kirim email status ' . $no . ': ' . $ex->getMessage());
            }
        };
    }
    return ['success', $msg, $after];
}

// Alihkan ke halaman lain, lalu (opsional) jalankan tugas lambat setelah respons terkirim.
function admin_redirect_then($url, $after = null)
{
    header('Location: ' . $url);
    if ($after === null) {
        exit;
    }
    ignore_user_abort(true);
    @set_time_limit(120);
    if (session_status() === PHP_SESSION_ACTIVE) {
        session_write_close(); // lepaskan kunci sesi agar halaman berikutnya tidak menunggu
    }
    header('Connection: close');
    header('Content-Length: 0');
    while (ob_get_level() > 0) {
        @ob_end_flush();
    }
    flush();
    if (function_exists('fastcgi_finish_request')) {
        fastcgi_finish_request();
    }
    $after();
    exit;
}

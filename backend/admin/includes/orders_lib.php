<?php
// File: admin/includes/orders_lib.php
// Fungsi bantu khusus pesanan (label, warna, ubah status).

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

// Ubah status pesanan.
// Mengembalikan [jenisPesan, pesan, tugasSesudahRespons|null].
// jenisPesan: success | info | warning | error. Email dikirim SESUDAH halaman
// selesai dimuat (lihat admin_redirect_then), supaya admin tidak menunggu SMTP.
function admin_update_order_status(PDO $conn, $orderId, $newStatus, $sendEmail, $expectedStatus = '')
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

    // Ubah hanya bila status masih sama dengan yang tadi dibaca (anti tabrakan)
    $up = $conn->prepare('UPDATE orders SET status = :s WHERE order_id = :id AND status = :old');
    $up->execute([':s' => $newStatus, ':id' => $orderId, ':old' => $old]);
    if ($up->rowCount() === 0) {
        return ['info', 'Status pesanan ' . $no . ' baru saja diubah oleh permintaan lain. Muat ulang halaman untuk melihat status terbaru.', null];
    }

    $msg = 'Status pesanan ' . $no . ' diubah dari "' . status_label($old) . '" menjadi "' . status_label($newStatus) . '".';

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

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

// Ubah status pesanan. Mengembalikan [berhasil(bool), pesan(string)].
function admin_update_order_status(PDO $conn, $orderId, $newStatus, $sendEmail)
{
    if (!in_array($newStatus, order_status_values($conn), true)) {
        return [false, 'Status tidak valid.'];
    }

    $st = $conn->prepare(
        'SELECT o.order_id, o.order_number, o.status, u.email, u.full_name
         FROM orders o LEFT JOIN users u ON u.user_id = o.user_id
         WHERE o.order_id = :id'
    );
    $st->execute([':id' => $orderId]);
    $order = $st->fetch(PDO::FETCH_ASSOC);
    if (!$order) {
        return [false, 'Pesanan tidak ditemukan.'];
    }
    if ($order['status'] === $newStatus) {
        return [true, 'Status pesanan tidak berubah.'];
    }

    $up = $conn->prepare('UPDATE orders SET status = :s WHERE order_id = :id');
    $up->execute([':s' => $newStatus, ':id' => $orderId]);
    $msg = 'Status pesanan ' . $order['order_number'] . ' diubah menjadi ' . status_label($newStatus) . '.';

    if ($sendEmail && !empty($order['email'])) {
        $file = __DIR__ . '/../../config/email.php';
        if (is_file($file)) {
            try {
                require_once $file;
                $svc = new EmailService();
                $svc->sendOrderStatusUpdate($order['email'], $order['full_name'], $order['order_number'], $newStatus);
                $msg .= ' Email pemberitahuan terkirim.';
            } catch (Throwable $ex) {
                error_log('[admin] gagal kirim email status: ' . $ex->getMessage());
                $msg .= ' (Email pemberitahuan gagal dikirim.)';
            }
        }
    }
    return [true, $msg];
}

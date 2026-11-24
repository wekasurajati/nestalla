<?php
require_once 'includes/auth.php';
require_once 'includes/orders_lib.php';

$database = new Database();
$conn = $database->getConnection();

$orderId = (int) ($_GET['id'] ?? $_POST['order_id'] ?? 0);
if ($orderId <= 0) {
    header('Location: orders.php');
    exit;
}

// ---------- Ubah status ----------
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['update_status'])) {
    $after = null;
    if (!csrf_valid()) {
        flash('error', 'Sesi tidak valid. Muat ulang halaman lalu coba lagi.');
    } else {
        list($kind, $msg, $after) = admin_update_order_status(
            $conn,
            $orderId,
            (string) ($_POST['status'] ?? ''),
            !empty($_POST['send_email']),
            (string) ($_POST['expected_status'] ?? ''),
            (string) ($_POST['tracking_number'] ?? '')
        );
        flash($kind, $msg);
    }
    admin_redirect_then('orders-detail.php?id=' . $orderId, $after);
}

// ---------- Ubah nomor resi saja ----------
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['update_tracking'])) {
    if (!csrf_valid()) {
        flash('error', 'Sesi tidak valid. Muat ulang halaman lalu coba lagi.');
    } else {
        list($kind, $msg) = admin_update_tracking($conn, $orderId, (string) ($_POST['tracking_number'] ?? ''));
        flash($kind, $msg);
    }
    admin_redirect_then('orders-detail.php?id=' . $orderId);
}

// ---------- Data ----------
$rows = db_rows(
    $conn,
    'SELECT o.*, u.full_name, u.email, u.phone AS user_phone
     FROM orders o LEFT JOIN users u ON u.user_id = o.user_id
     WHERE o.order_id = :id',
    [':id' => $orderId]
);
if (!$rows) {
    flash('error', 'Pesanan tidak ditemukan.');
    header('Location: orders.php');
    exit;
}
$order = $rows[0];

$addr = null;
if (!empty($order['address_id'])) {
    $a = db_rows($conn, 'SELECT * FROM user_addresses WHERE address_id = :a', [':a' => $order['address_id']]);
    $addr = $a[0] ?? null;
}

$items = db_rows(
    $conn,
    'SELECT oi.*, b.title, b.author, b.image
     FROM order_items oi LEFT JOIN books b ON b.book_id = oi.book_id
     WHERE oi.order_id = :id',
    [':id' => $orderId]
);

$itemsTotal = 0;
foreach ($items as $k => $it) {
    $price = (float) ($it['price'] ?? $it['unit_price'] ?? $it['book_price'] ?? 0);
    $qty = (int) ($it['quantity'] ?? 1);
    $items[$k]['_price'] = $price;
    $items[$k]['_qty'] = $qty;
    $items[$k]['_subtotal'] = (float) ($it['subtotal'] ?? $price * $qty);
    $itemsTotal += $items[$k]['_subtotal'];
}

$statuses = order_status_values($conn);
$recipient = $addr['recipient_name'] ?? ($order['full_name'] ?? '-');
$phone = $addr['phone'] ?? ($order['user_phone'] ?? '');

// Nomor resi dan kurir
$hasTracking = array_key_exists('tracking_number', $order);
$trackingNo = (string) ($order['tracking_number'] ?? '');
$canEditTracking = $hasTracking && in_array($order['status'], ['shipped', 'completed'], true);
$carrierName = '';
if (!empty($order['shipping_carrier_id'])) {
    $c = db_rows($conn, 'SELECT carrier_name FROM shipping_carriers WHERE carrier_id = :c', [':c' => $order['shipping_carrier_id']]);
    $carrierName = (string) ($c[0]['carrier_name'] ?? '');
}

$page_title = 'Pesanan ' . $order['order_number'];
include 'includes/header.php';
include 'includes/sidebar.php';
?>

<div class="content-wrapper">
    <section class="content-header">
        <div class="container-fluid">
            <div class="nv-pagehead">
                <div>
                    <h1><i class="fas fa-receipt"></i><?php echo e($order['order_number']); ?></h1>
                    <p>Dibuat <?php echo e(formatTanggal($order['created_at'])); ?></p>
                </div>
                <div>
                    <?php echo badge(status_tone($order['status']), status_label($order['status'])); ?>
                    <?php echo badge(payment_status_tone($order['payment_status']), payment_status_label($order['payment_status'])); ?>
                    <a href="orders.php" class="btn btn-sm btn-light-nv ml-2"><i class="fas fa-arrow-left"></i> Kembali</a>
                </div>
            </div>
        </div>
    </section>

    <section class="content">
        <div class="container-fluid">
            <?php echo flash_render(); ?>

            <?php if (!$hasTracking): ?>
                <div class="alert alert-warning">
                    <i class="fas fa-exclamation-triangle mr-1"></i>
                    Kolom nomor resi belum ada di database, jadi status Dikirim belum bisa disimpan.
                    Jalankan file migrasi <code>2026-11-24_orders_tracking_number.sql</code> di phpMyAdmin.
                </div>
            <?php endif; ?>

            <div class="row">
                <div class="col-lg-8">
                    <div class="card">
                        <div class="card-header"><h3 class="card-title">Barang dipesan</h3></div>
                        <div class="card-body p-0">
                            <?php if (!$items): ?>
                                <div class="nv-empty"><i class="fas fa-box-open"></i>Tidak ada barang pada pesanan ini.</div>
                            <?php else: ?>
                                <div class="table-responsive">
                                    <table class="table mb-0">
                                        <thead><tr><th>Buku</th><th class="text-right">Harga</th><th class="text-center">Jumlah</th><th class="text-right">Subtotal</th></tr></thead>
                                        <tbody>
                                        <?php foreach ($items as $it): ?>
                                            <tr>
                                                <td>
                                                    <div class="d-flex align-items-center">
                                                        <?php $img = cover_url($it['image'] ?? ''); ?>
                                                        <?php if ($img !== ''): ?>
                                                            <img src="<?php echo e($img); ?>" alt="" class="nv-cover mr-3">
                                                        <?php else: ?>
                                                            <span class="nv-cover nv-cover--ph mr-3"><i class="fas fa-book"></i></span>
                                                        <?php endif; ?>
                                                        <div>
                                                            <strong><?php echo e($it['title'] ?? 'Buku dihapus'); ?></strong>
                                                            <br><small class="text-muted"><?php echo e($it['author'] ?? ''); ?></small>
                                                        </div>
                                                    </div>
                                                </td>
                                                <td class="text-right"><?php echo e(formatRupiah($it['_price'])); ?></td>
                                                <td class="text-center"><?php echo (int) $it['_qty']; ?></td>
                                                <td class="text-right"><strong><?php echo e(formatRupiah($it['_subtotal'])); ?></strong></td>
                                            </tr>
                                        <?php endforeach; ?>
                                        </tbody>
                                    </table>
                                </div>
                            <?php endif; ?>
                        </div>
                    </div>

                    <div class="card">
                        <div class="card-header"><h3 class="card-title">Ringkasan pembayaran</h3></div>
                        <div class="card-body">
                            <div class="nv-kv"><span>Subtotal barang</span><span><?php echo e(formatRupiah($itemsTotal)); ?></span></div>
                            <div class="nv-kv"><span>Ongkos kirim</span><span><?php echo e(formatRupiah($order['shipping_cost'] ?? 0)); ?></span></div>
                            <?php if ((float) ($order['tax'] ?? 0) > 0): ?>
                                <div class="nv-kv"><span>Pajak</span><span><?php echo e(formatRupiah($order['tax'])); ?></span></div>
                            <?php endif; ?>
                            <?php if ((float) ($order['discount_amount'] ?? 0) > 0): ?>
                                <div class="nv-kv"><span>Diskon</span><span class="text-success">-<?php echo e(formatRupiah($order['discount_amount'])); ?></span></div>
                            <?php endif; ?>
                            <div class="nv-kv"><span class="nv-total">Total</span><span class="nv-total"><?php echo e(formatRupiah($order['total_amount'])); ?></span></div>
                        </div>
                    </div>
                </div>

                <div class="col-lg-4">
                    <div class="card">
                        <div class="card-header"><h3 class="card-title">Ubah status</h3></div>
                        <div class="card-body">
                            <form method="post" id="statusForm" novalidate>
                                <?php echo csrf_field(); ?>
                                <input type="hidden" name="update_status" value="1">
                                <input type="hidden" name="expected_status" value="<?php echo e($order['status']); ?>">
                                <input type="hidden" name="order_id" value="<?php echo (int) $orderId; ?>">
                                <div class="form-group">
                                    <select name="status" id="d_status" class="custom-select">
                                        <?php foreach ($statuses as $s): ?>
                                            <option value="<?php echo e($s); ?>" <?php echo $s === $order['status'] ? 'selected' : ''; ?>><?php echo e(status_label($s)); ?></option>
                                        <?php endforeach; ?>
                                    </select>
                                </div>
                                <div class="form-group" id="d_tracking_group" style="display:none">
                                    <label for="d_tracking">Nomor resi <span class="text-danger">*</span></label>
                                    <input type="text" name="tracking_number" id="d_tracking" class="form-control" maxlength="100"
                                           autocomplete="off" placeholder="Contoh: JNE1234567890"
                                           value="<?php echo e($trackingNo); ?>" disabled>
                                    <small class="form-text text-muted">Wajib untuk status Dikirim. Huruf, angka, dan tanda hubung (-).</small>
                                    <div class="invalid-feedback" id="d_tracking_err"></div>
                                </div>
                                <div class="custom-control custom-checkbox mb-3">
                                    <input type="checkbox" class="custom-control-input" id="send_email" name="send_email" value="1" checked>
                                    <label class="custom-control-label" for="send_email">Kirim email pemberitahuan</label>
                                    <small class="form-text text-muted">Dikirim di latar belakang.</small>
                                </div>
                                <button type="submit" class="btn btn-primary btn-block" id="d_save" disabled>Simpan status</button>
                            </form>
                        </div>
                    </div>

                    <?php if ($hasTracking && ($canEditTracking || $trackingNo !== '')): ?>
                    <div class="card">
                        <div class="card-header"><h3 class="card-title">Pengiriman</h3></div>
                        <div class="card-body">
                            <div class="nv-kv"><span>Kurir</span><span><?php echo e($carrierName !== '' ? $carrierName : '-'); ?></span></div>
                            <?php if ($canEditTracking): ?>
                                <form method="post" id="trackingForm" class="mt-3" novalidate>
                                    <?php echo csrf_field(); ?>
                                    <input type="hidden" name="update_tracking" value="1">
                                    <input type="hidden" name="order_id" value="<?php echo (int) $orderId; ?>">
                                    <div class="form-group mb-2">
                                        <label for="t_tracking">Nomor resi</label>
                                        <input type="text" name="tracking_number" id="t_tracking" class="form-control" maxlength="100"
                                               autocomplete="off" value="<?php echo e($trackingNo); ?>">
                                        <div class="invalid-feedback" id="t_tracking_err"></div>
                                    </div>
                                    <button type="submit" class="btn btn-primary btn-block" id="t_save" disabled>Simpan resi</button>
                                </form>
                            <?php else: ?>
                                <div class="nv-kv"><span>Nomor resi</span><span><?php echo e($trackingNo); ?></span></div>
                            <?php endif; ?>
                        </div>
                    </div>
                    <?php endif; ?>

                    <div class="card">
                        <div class="card-header"><h3 class="card-title">Pelanggan</h3></div>
                        <div class="card-body">
                            <div class="nv-kv"><span>Nama</span><span><?php echo e($order['full_name'] ?? '-'); ?></span></div>
                            <div class="nv-kv"><span>Email</span><span><?php echo e($order['email'] ?? '-'); ?></span></div>
                        </div>
                    </div>

                    <div class="card">
                        <div class="card-header"><h3 class="card-title">Alamat pengiriman</h3></div>
                        <div class="card-body">
                            <?php if ($addr): ?>
                                <strong><?php echo e($recipient); ?></strong>
                                <?php if ($phone): ?><br><small class="text-muted"><i class="fas fa-phone mr-1"></i><?php echo e($phone); ?></small><?php endif; ?>
                                <p class="mt-2 mb-0">
                                    <?php echo e($addr['address'] ?? ''); ?><br>
                                    <?php echo e(trim(($addr['city'] ?? '') . ', ' . ($addr['province'] ?? ''), ', ')); ?>
                                    <?php echo e($addr['postal_code'] ?? ''); ?>
                                </p>
                            <?php else: ?>
                                <span class="text-muted">Alamat tidak tersedia.</span>
                            <?php endif; ?>
                        </div>
                    </div>

                    <div class="card">
                        <div class="card-header"><h3 class="card-title">Pembayaran</h3></div>
                        <div class="card-body">
                            <div class="nv-kv"><span>Metode</span><span><?php echo e(payment_method_label($order['payment_method'])); ?></span></div>
                            <div class="nv-kv"><span>Status</span><span><?php echo badge(payment_status_tone($order['payment_status']), payment_status_label($order['payment_status'])); ?></span></div>
                            <?php if (!empty($order['merchant_order_id'])): ?>
                                <div class="nv-kv"><span>ID transaksi</span><span class="small"><?php echo e($order['merchant_order_id']); ?></span></div>
                            <?php endif; ?>
                            <?php if (!empty($order['notes'])): ?>
                                <div class="nv-kv"><span>Catatan</span><span class="small text-right"><?php echo e($order['notes']); ?></span></div>
                            <?php endif; ?>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>
</div>

<?php
ob_start();
?>
<style>
    /* Tombol "Simpan resi" saat isinya sudah tersimpan: abu-abu, tidak bisa diklik */
    #t_save.is-saved, #t_save.is-saved:disabled, #t_save.is-saved:hover {
        background: #E6EBF3 !important;
        background-image: none !important;
        border-color: #E6EBF3 !important;
        color: #6B778C !important;
        box-shadow: none !important;
        opacity: 1 !important;
        cursor: not-allowed !important;
        pointer-events: none;
    }
</style>
<script>
$(function () {
    var current = <?php echo json_encode((string) $order['status']); ?>;
    var currentTracking = <?php echo json_encode($trackingNo); ?>;
    var trackingRe = /^[A-Za-z0-9-]{1,100}$/;
    var errText = function (v) {
        return v === '' ? 'Nomor resi wajib diisi.' : 'Hanya huruf, angka, dan tanda hubung (-), maksimal 100 karakter.';
    };

    // ----- Form ubah status -----
    var saveHtml = $('#d_save').html();
    function needTracking() { return $('#d_status').val() === 'shipped' && current !== 'shipped'; }
    function syncSave() { $('#d_save').prop('disabled', $('#d_status').val() === current); }
    function syncTracking() {
        var on = needTracking();
        $('#d_tracking_group').toggle(on);
        $('#d_tracking').prop('disabled', !on).removeClass('is-invalid');
    }
    syncSave();
    syncTracking();
    $('#d_status').on('change', function () { syncSave(); syncTracking(); });
    $('#d_tracking').on('input', function () { $(this).removeClass('is-invalid'); });
    $('#statusForm').on('submit', function (ev) {
        if (needTracking()) {
            var v = $.trim($('#d_tracking').val());
            if (!trackingRe.test(v)) {
                ev.preventDefault();
                $('#d_tracking_err').text(errText(v));
                $('#d_tracking').addClass('is-invalid').trigger('focus');
                return false;
            }
            $('#d_tracking').val(v);
        }
        $('#d_save').prop('disabled', true).html('<i class="fas fa-spinner fa-spin"></i> Menyimpan…');
    });

    // ----- Form ubah nomor resi -----
    var trackHtml = $('#t_save').html();
    function syncTrackSave() {
        var v = $.trim($('#t_tracking').val());
        var same = (v === currentTracking);
        var saved = same && currentTracking !== '';
        $('#t_save')
            .prop('disabled', same)
            .toggleClass('is-saved', saved)
            .html(saved ? 'Resi tersimpan' : trackHtml);
    }
    syncTrackSave();
    $('#t_tracking').on('input', function () { $(this).removeClass('is-invalid'); syncTrackSave(); });
    $('#trackingForm').on('submit', function (ev) {
        var v = $.trim($('#t_tracking').val());
        if (v === currentTracking) {
            // Tidak ada perubahan: jangan kirim apa pun
            ev.preventDefault();
            return false;
        }
        if (!trackingRe.test(v)) {
            ev.preventDefault();
            $('#t_tracking_err').text(errText(v));
            $('#t_tracking').addClass('is-invalid').trigger('focus');
            return false;
        }
        $('#t_tracking').val(v);
        $('#t_save').prop('disabled', true).html('<i class="fas fa-spinner fa-spin"></i> Menyimpan…');
    });

    $(window).on('pageshow', function (e) {
        if (e.originalEvent && e.originalEvent.persisted) {
            $('#d_save').html(saveHtml); syncSave();
            syncTrackSave();
        }
    });
});
</script>
<?php
$extra_js = ob_get_clean();
include 'includes/footer.php';

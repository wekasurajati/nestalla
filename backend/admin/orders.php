<?php
require_once 'includes/auth.php';
require_once 'includes/orders_lib.php';

$database = new Database();
$conn = $database->getConnection();

// ---------- Ubah status ----------
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['update_status'])) {
    if (!csrf_valid()) {
        flash('error', 'Sesi tidak valid. Muat ulang halaman lalu coba lagi.');
    } else {
        list($ok, $msg) = admin_update_order_status(
            $conn,
            (int) ($_POST['order_id'] ?? 0),
            (string) ($_POST['status'] ?? ''),
            !empty($_POST['send_email'])
        );
        flash($ok ? 'success' : 'error', $msg);
    }
    header('Location: orders.php');
    exit;
}

// ---------- Data ----------
$sql = 'SELECT o.order_id, o.order_number, o.total_amount, o.discount_amount, o.payment_method, o.status,
               o.payment_status, o.created_at, u.full_name, u.email, a.recipient_name, a.city
        FROM orders o
        LEFT JOIN users u ON u.user_id = o.user_id
        LEFT JOIN user_addresses a ON a.address_id = o.address_id
        ORDER BY o.created_at DESC';
$orders = db_rows($conn, $sql);
if (!$orders) {
    // cadangan tanpa alamat, bila nama kolom alamat berbeda
    $orders = db_rows(
        $conn,
        'SELECT o.order_id, o.order_number, o.total_amount, o.discount_amount, o.payment_method, o.status,
                o.payment_status, o.created_at, u.full_name, u.email
         FROM orders o LEFT JOIN users u ON u.user_id = o.user_id ORDER BY o.created_at DESC'
    );
}
$statuses = order_status_values($conn);

$page_title = 'Pesanan';
include 'includes/header.php';
include 'includes/sidebar.php';
?>

<div class="content-wrapper">
    <section class="content-header">
        <div class="container-fluid">
            <div class="nv-pagehead">
                <div>
                    <h1><i class="fas fa-receipt"></i>Pesanan</h1>
                    <p>Pantau dan ubah status pesanan pelanggan.</p>
                </div>
            </div>
        </div>
    </section>

    <section class="content">
        <div class="container-fluid">
            <?php echo flash_render(); ?>

            <div class="card">
                <div class="card-header d-flex flex-wrap align-items-center justify-content-between">
                    <h3 class="card-title mb-0"><?php echo count($orders); ?> pesanan</h3>
                    <div class="form-inline">
                        <label for="statusFilter" class="mr-2 small text-muted mb-0">Status</label>
                        <select id="statusFilter" class="custom-select custom-select-sm" style="width:auto">
                            <option value="">Semua</option>
                            <?php foreach ($statuses as $s): ?>
                                <option value="<?php echo e(status_label($s)); ?>"><?php echo e(status_label($s)); ?></option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                </div>
                <div class="card-body">
                    <table id="ordersTable" class="table table-hover" style="width:100%">
                        <thead>
                            <tr>
                                <th>Pesanan</th>
                                <th>Pelanggan</th>
                                <th>Total</th>
                                <th>Pembayaran</th>
                                <th>Status</th>
                                <th class="text-right">Aksi</th>
                            </tr>
                        </thead>
                        <tbody>
                        <?php foreach ($orders as $o): ?>
                            <tr>
                                <td data-order="<?php echo (int) strtotime($o['created_at']); ?>">
                                    <strong><?php echo e($o['order_number']); ?></strong>
                                    <br><small class="text-muted"><?php echo e(formatTanggal($o['created_at'])); ?></small>
                                </td>
                                <td>
                                    <strong><?php echo e($o['full_name'] ?? 'Pelanggan'); ?></strong>
                                    <br><small class="text-muted"><?php echo e($o['email'] ?? ''); ?></small>
                                    <?php if (!empty($o['recipient_name']) && $o['recipient_name'] !== ($o['full_name'] ?? '')): ?>
                                        <br><small class="text-muted">Penerima: <?php echo e($o['recipient_name']); ?></small>
                                    <?php endif; ?>
                                </td>
                                <td data-order="<?php echo (float) $o['total_amount']; ?>">
                                    <strong><?php echo e(formatRupiah($o['total_amount'])); ?></strong>
                                    <?php if ((float) $o['discount_amount'] > 0): ?>
                                        <br><small class="text-success">Diskon <?php echo e(formatRupiah($o['discount_amount'])); ?></small>
                                    <?php endif; ?>
                                </td>
                                <td>
                                    <?php echo e(payment_method_label($o['payment_method'])); ?><br>
                                    <?php echo badge(payment_status_tone($o['payment_status']), payment_status_label($o['payment_status'])); ?>
                                </td>
                                <td><?php echo badge(status_tone($o['status']), status_label($o['status'])); ?></td>
                                <td class="text-right text-nowrap">
                                    <a href="orders-detail.php?id=<?php echo (int) $o['order_id']; ?>" class="btn btn-sm btn-light-nv" title="Lihat detail"><i class="fas fa-eye"></i> Detail</a>
                                    <button type="button" class="btn btn-sm btn-primary" data-toggle="modal" data-target="#statusModal"
                                            data-id="<?php echo (int) $o['order_id']; ?>"
                                            data-number="<?php echo e($o['order_number']); ?>"
                                            data-status="<?php echo e($o['status']); ?>"><i class="fas fa-pen"></i> Status</button>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </section>
</div>

<div class="modal fade" id="statusModal" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <form method="post" class="modal-content" style="border:0;border-radius:16px">
            <div class="modal-header" style="border-bottom:1px solid #E6EBF3">
                <h5 class="modal-title font-weight-bold">Ubah status pesanan</h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Tutup">&times;</button>
            </div>
            <div class="modal-body">
                <?php echo csrf_field(); ?>
                <input type="hidden" name="update_status" value="1">
                <input type="hidden" name="order_id" id="m_order_id">
                <p class="mb-3">Pesanan <strong id="m_number"></strong></p>
                <div class="form-group">
                    <label for="m_status">Status baru</label>
                    <select name="status" id="m_status" class="custom-select">
                        <?php foreach ($statuses as $s): ?>
                            <option value="<?php echo e($s); ?>"><?php echo e(status_label($s)); ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="custom-control custom-checkbox">
                    <input type="checkbox" class="custom-control-input" id="m_email" name="send_email" value="1" checked>
                    <label class="custom-control-label" for="m_email">Kirim email pemberitahuan ke pelanggan</label>
                </div>
            </div>
            <div class="modal-footer" style="border-top:1px solid #E6EBF3">
                <button type="button" class="btn btn-light-nv" data-dismiss="modal">Batal</button>
                <button type="submit" class="btn btn-primary">Simpan</button>
            </div>
        </form>
    </div>
</div>

<?php
ob_start();
?>
<script>
$(function () {
    var table = $('#ordersTable').DataTable({
        paging: true, searching: true, ordering: true, info: true, autoWidth: false,
        order: [[0, 'desc']],
        columnDefs: [{ orderable: false, targets: 5 }]
    });
    var q = new URLSearchParams(window.location.search).get('q');
    if (q) { table.search(q).draw(); }
    $('#statusFilter').on('change', function () {
        table.column(4).search(this.value ? '^' + $.fn.dataTable.util.escapeRegex(this.value) + '$' : '', true, false).draw();
    });
    $('#statusModal').on('show.bs.modal', function (ev) {
        var b = $(ev.relatedTarget);
        $('#m_order_id').val(b.data('id'));
        $('#m_number').text(b.data('number'));
        $('#m_status').val(b.data('status'));
    });
});
</script>
<?php
$extra_js = ob_get_clean();
include 'includes/footer.php';

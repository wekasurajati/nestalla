<?php
require_once 'includes/auth.php';

$database = new Database();
$conn = $database->getConnection();

$users = db_rows(
    $conn,
    "SELECT u.user_id, u.username, u.full_name, u.email, u.phone, u.created_at,
            (SELECT COUNT(*) FROM orders o WHERE o.user_id = u.user_id) AS order_count
     FROM users u WHERE u.role = 'customer' ORDER BY u.created_at DESC"
);

$page_title = 'Pengguna';
include 'includes/header.php';
include 'includes/sidebar.php';
?>

<div class="content-wrapper">
    <section class="content-header">
        <div class="container-fluid">
            <div class="nv-pagehead">
                <div>
                    <h1><i class="fas fa-users"></i>Pengguna</h1>
                    <p>Daftar pelanggan yang terdaftar di aplikasi.</p>
                </div>
            </div>
        </div>
    </section>

    <section class="content">
        <div class="container-fluid">
            <?php echo flash_render(); ?>
            <div class="card">
                <div class="card-header"><h3 class="card-title"><?php echo count($users); ?> pelanggan</h3></div>
                <div class="card-body">
                    <table id="usersTable" class="table table-hover" style="width:100%">
                        <thead>
                            <tr>
                                <th>Pelanggan</th><th>Email</th><th>Telepon</th><th>Terdaftar</th><th>Pesanan</th>
                                <th class="text-right" data-orderable="false">Aksi</th>
                            </tr>
                        </thead>
                        <tbody>
                        <?php foreach ($users as $u):
                            $name = $u['full_name'] ?: $u['username'];
                            $initial = strtoupper(function_exists('mb_substr') ? mb_substr($name, 0, 1) : substr($name, 0, 1));
                            ?>
                            <tr>
                                <td>
                                    <div class="d-flex align-items-center">
                                        <span class="nv-avatar-sm mr-2"><?php echo e($initial); ?></span>
                                        <div><strong><?php echo e($name); ?></strong><br><small class="text-muted">@<?php echo e($u['username']); ?></small></div>
                                    </div>
                                </td>
                                <td><?php echo e($u['email']); ?></td>
                                <td><?php echo $u['phone'] ? e($u['phone']) : '<span class="text-muted">-</span>'; ?></td>
                                <td data-order="<?php echo (int) strtotime($u['created_at']); ?>"><?php echo e(formatTanggal($u['created_at'])); ?></td>
                                <td data-order="<?php echo (int) $u['order_count']; ?>">
                                    <?php echo (int) $u['order_count'] > 0 ? badge('info', $u['order_count'] . ' pesanan') : badge('muted', 'Belum ada'); ?>
                                </td>
                                <td class="text-right">
                                    <?php if ((int) $u['order_count'] > 0): ?>
                                        <a href="orders.php?q=<?php echo rawurlencode($u['email']); ?>" class="btn btn-sm btn-light-nv"><i class="fas fa-receipt"></i> Lihat pesanan</a>
                                    <?php endif; ?>
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

<?php
ob_start();
?>
<script>
$(function () {
    $('#usersTable').DataTable({ autoWidth: false, order: [[3, 'desc']] });
});
</script>
<?php
$extra_js = ob_get_clean();
include 'includes/footer.php';

<?php
require_once 'includes/auth.php';
require_once 'includes/promos_lib.php';

$database = new Database();
$conn = $database->getConnection();
$conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

// ---------- Aksi (POST + CSRF) ----------
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['promo_action'])) {
    if (!csrf_valid()) {
        flash('error', 'Sesi tidak valid. Muat ulang halaman lalu coba lagi.');
    } else {
        $id = (int) ($_POST['promo_id'] ?? 0);
        try {
            if ($_POST['promo_action'] === 'toggle') {
                $conn->prepare('UPDATE promo_codes SET is_active = 1 - is_active WHERE promo_id = :id')->execute([':id' => $id]);
                flash('success', 'Status promo diperbarui.');
            } elseif ($_POST['promo_action'] === 'delete') {
                $conn->prepare('DELETE FROM promo_codes WHERE promo_id = :id')->execute([':id' => $id]);
                flash('success', 'Kode promo dihapus.');
            }
        } catch (PDOException $ex) {
            error_log('[admin] promo: ' . $ex->getMessage());
            flash('error', 'Kode promo tidak bisa dihapus karena sudah dipakai pada pesanan. Nonaktifkan saja.');
        }
    }
    header('Location: promos.php');
    exit;
}

$promos = db_rows($conn, 'SELECT * FROM promo_codes ORDER BY created_at DESC, promo_id DESC');
$today = date('Y-m-d');

$page_title = 'Kode Promo';
include 'includes/header.php';
include 'includes/sidebar.php';
?>

<div class="content-wrapper">
    <section class="content-header">
        <div class="container-fluid">
            <div class="nv-pagehead">
                <div>
                    <h1><i class="fas fa-ticket-alt"></i>Kode Promo</h1>
                    <p>Atur diskon dan gratis ongkir untuk pelanggan.</p>
                </div>
                <a href="promos-add.php" class="btn btn-primary"><i class="fas fa-plus mr-1"></i> Tambah promo</a>
            </div>
        </div>
    </section>

    <section class="content">
        <div class="container-fluid">
            <?php echo flash_render(); ?>
            <div class="card">
                <div class="card-body">
                    <table id="promosTable" class="table table-hover" style="width:100%">
                        <thead>
                            <tr>
                                <th>Kode</th><th>Jenis</th><th>Nilai</th><th>Berlaku</th><th>Pemakaian</th><th>Status</th>
                                <th class="text-right" data-orderable="false">Aksi</th>
                            </tr>
                        </thead>
                        <tbody>
                        <?php foreach ($promos as $p):
                            $expired = $p['valid_until'] < $today;
                            ?>
                            <tr>
                                <td><strong><?php echo e($p['code']); ?></strong><?php if ($p['description']): ?><br><small class="text-muted"><?php echo e($p['description']); ?></small><?php endif; ?></td>
                                <td><?php echo badge($p['type'] === 'percentage' ? 'info' : 'ok', promo_types()[$p['type']] ?? $p['type']); ?></td>
                                <td><strong><?php echo $p['type'] === 'percentage' ? e(rtrim(rtrim(number_format((float) $p['value'], 2, ',', '.'), '0'), ',')) . '%' : e(formatRupiah($p['value'])); ?></strong></td>
                                <td data-order="<?php echo e($p['valid_until']); ?>"><small><?php echo e(date('d/m/Y', strtotime($p['valid_from']))); ?> – <?php echo e(date('d/m/Y', strtotime($p['valid_until']))); ?></small></td>
                                <td><?php echo (int) $p['used_count']; ?> / <?php echo (int) $p['usage_limit'] > 0 ? (int) $p['usage_limit'] : '∞'; ?></td>
                                <td>
                                    <?php
                                    if (!$p['is_active']) { echo badge('muted', 'Nonaktif'); }
                                    elseif ($expired) { echo badge('warn', 'Kedaluwarsa'); }
                                    else { echo badge('ok', 'Aktif'); }
                                    ?>
                                </td>
                                <td>
                                    <div class="nv-actions">
                                        <form method="post">
                                            <?php echo csrf_field(); ?>
                                            <input type="hidden" name="promo_action" value="toggle">
                                            <input type="hidden" name="promo_id" value="<?php echo (int) $p['promo_id']; ?>">
                                            <button type="submit" class="btn btn-sm btn-light-nv" title="<?php echo $p['is_active'] ? 'Nonaktifkan' : 'Aktifkan'; ?>"><i class="fas fa-<?php echo $p['is_active'] ? 'toggle-on' : 'toggle-off'; ?>"></i></button>
                                        </form>
                                        <a href="promos-edit.php?id=<?php echo (int) $p['promo_id']; ?>" class="btn btn-sm btn-light-nv" title="Ubah"><i class="fas fa-pen"></i></a>
                                        <form method="post" onsubmit="return confirm('Hapus kode promo ini?');">
                                            <?php echo csrf_field(); ?>
                                            <input type="hidden" name="promo_action" value="delete">
                                            <input type="hidden" name="promo_id" value="<?php echo (int) $p['promo_id']; ?>">
                                            <button type="submit" class="btn btn-sm btn-outline-danger" title="Hapus"><i class="fas fa-trash"></i></button>
                                        </form>
                                    </div>
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
    $('#promosTable').DataTable({ autoWidth: false, order: [[3, 'desc']] });
});
</script>
<?php
$extra_js = ob_get_clean();
include 'includes/footer.php';

<?php
require_once 'includes/auth.php';
require_once 'includes/promos_lib.php';

$database = new Database();
$conn = $database->getConnection();
$conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$id = (int) ($_GET['id'] ?? $_POST['promo_id'] ?? 0);
$rows = $id > 0 ? db_rows($conn, 'SELECT * FROM promo_codes WHERE promo_id = :id', [':id' => $id]) : [];
if (!$rows) {
    flash('error', 'Kode promo tidak ditemukan.');
    header('Location: promos.php');
    exit;
}
$promo = $rows[0];
$p = $promo;
$errors = [];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $p = $_POST;
    if (!csrf_valid()) {
        $errors[] = 'Sesi tidak valid. Muat ulang halaman lalu coba lagi.';
    } else {
        list($d, $errors) = promo_read_input($_POST, $conn, $id);
        if (!$errors) {
            try {
                $conn->prepare(
                    'UPDATE promo_codes SET code = :code, type = :type, value = :value, description = :description,
                            valid_from = :valid_from, valid_until = :valid_until, usage_limit = :usage_limit, is_active = :is_active
                     WHERE promo_id = :id'
                )->execute([
                    ':code' => $d['code'], ':type' => $d['type'], ':value' => $d['value'], ':description' => $d['description'],
                    ':valid_from' => $d['valid_from'], ':valid_until' => $d['valid_until'],
                    ':usage_limit' => $d['usage_limit'], ':is_active' => $d['is_active'], ':id' => $id,
                ]);
                flash('success', 'Kode promo ' . $d['code'] . ' berhasil diperbarui.');
                header('Location: promos.php');
                exit;
            } catch (PDOException $ex) {
                error_log('[admin] ubah promo: ' . $ex->getMessage());
                $errors[] = 'Perubahan gagal disimpan.';
            }
        }
    }
}

$page_title = 'Ubah promo';
include 'includes/header.php';
include 'includes/sidebar.php';
?>

<div class="content-wrapper">
    <section class="content-header">
        <div class="container-fluid">
            <div class="nv-pagehead">
                <div><h1><i class="fas fa-pen"></i>Ubah promo</h1><p><?php echo e($promo['code']); ?> &middot; dipakai <?php echo (int) $promo['used_count']; ?> kali</p></div>
                <a href="promos.php" class="btn btn-sm btn-light-nv"><i class="fas fa-arrow-left"></i> Kembali</a>
            </div>
        </div>
    </section>
    <section class="content">
        <div class="container-fluid">
            <?php if ($errors): ?>
                <div class="alert alert-danger"><ul class="mb-0 pl-3"><?php foreach ($errors as $m): ?><li><?php echo e($m); ?></li><?php endforeach; ?></ul></div>
            <?php endif; ?>
            <form method="post" novalidate>
                <?php echo csrf_field(); ?>
                <input type="hidden" name="promo_id" value="<?php echo (int) $id; ?>">
                <?php render_promo_form($p, 'Simpan perubahan'); ?>
            </form>
        </div>
    </section>
</div>

<?php
$extra_js = promo_form_js();
include 'includes/footer.php';

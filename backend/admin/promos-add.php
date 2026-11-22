<?php
require_once 'includes/auth.php';
require_once 'includes/promos_lib.php';

$database = new Database();
$conn = $database->getConnection();
$conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$errors = [];
$p = [];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $p = $_POST;
    if (!csrf_valid()) {
        $errors[] = 'Sesi tidak valid. Muat ulang halaman lalu coba lagi.';
    } else {
        list($d, $errors) = promo_read_input($_POST, $conn, 0);
        if (!$errors) {
            try {
                $conn->prepare(
                    'INSERT INTO promo_codes (code, type, value, description, valid_from, valid_until, usage_limit, is_active)
                     VALUES (:code, :type, :value, :description, :valid_from, :valid_until, :usage_limit, :is_active)'
                )->execute([
                    ':code' => $d['code'], ':type' => $d['type'], ':value' => $d['value'], ':description' => $d['description'],
                    ':valid_from' => $d['valid_from'], ':valid_until' => $d['valid_until'],
                    ':usage_limit' => $d['usage_limit'], ':is_active' => $d['is_active'],
                ]);
                flash('success', 'Kode promo ' . $d['code'] . ' berhasil dibuat.');
                header('Location: promos.php');
                exit;
            } catch (PDOException $ex) {
                error_log('[admin] tambah promo: ' . $ex->getMessage());
                $errors[] = 'Kode promo gagal disimpan.';
            }
        }
    }
}

$page_title = 'Tambah promo';
include 'includes/header.php';
include 'includes/sidebar.php';
?>

<div class="content-wrapper">
    <section class="content-header">
        <div class="container-fluid">
            <div class="nv-pagehead">
                <div><h1><i class="fas fa-plus"></i>Tambah promo</h1><p>Buat kode promo baru.</p></div>
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
                <?php render_promo_form($p, 'Buat promo'); ?>
            </form>
        </div>
    </section>
</div>

<?php
$extra_js = promo_form_js();
include 'includes/footer.php';

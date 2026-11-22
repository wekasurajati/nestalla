<?php
require_once 'includes/auth.php';

$database = new Database();
$conn = $database->getConnection();
$conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

// ---------- Hapus ulasan (POST + CSRF) ----------
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['delete_id'])) {
    if (!csrf_valid()) {
        flash('error', 'Sesi tidak valid. Muat ulang halaman lalu coba lagi.');
    } else {
        try {
            $conn->prepare('DELETE FROM testimonials WHERE testimonial_id = :id')->execute([':id' => (int) $_POST['delete_id']]);
            flash('success', 'Ulasan dihapus.');
        } catch (PDOException $ex) {
            error_log('[admin] hapus ulasan: ' . $ex->getMessage());
            flash('error', 'Ulasan gagal dihapus.');
        }
    }
    header('Location: testimonials.php');
    exit;
}

$items = db_rows(
    $conn,
    'SELECT t.testimonial_id, t.rating, t.message, t.is_anonymous, t.created_at,
            u.full_name, u.username, b.title AS book_title, o.order_id, o.order_number
     FROM testimonials t
     LEFT JOIN users u ON u.user_id = t.user_id
     LEFT JOIN books b ON b.book_id = t.book_id
     LEFT JOIN orders o ON o.order_id = t.order_id
     ORDER BY t.created_at DESC'
);

$total = count($items);
$avg = $total ? array_sum(array_column($items, 'rating')) / $total : 0;
$anon = count(array_filter($items, function ($i) { return !empty($i['is_anonymous']); }));

function stars_html($n)
{
    $n = max(0, min(5, (int) $n));
    return '<span class="nv-stars">' . str_repeat('<i class="fas fa-star"></i>', $n)
         . '<span class="off">' . str_repeat('<i class="fas fa-star"></i>', 5 - $n) . '</span></span>';
}

$page_title = 'Testimoni';
include 'includes/header.php';
include 'includes/sidebar.php';
?>

<div class="content-wrapper">
    <section class="content-header">
        <div class="container-fluid">
            <div class="nv-pagehead">
                <div>
                    <h1><i class="fas fa-comment-dots"></i>Testimoni</h1>
                    <p>Ulasan yang ditulis pelanggan setelah pesanan selesai.</p>
                </div>
            </div>
        </div>
    </section>

    <section class="content">
        <div class="container-fluid">
            <?php echo flash_render(); ?>

            <div class="row">
                <div class="col-md-4 mb-3"><div class="nv-stat"><div class="nv-stat__icon nv-stat__icon--navy"><i class="fas fa-comments"></i></div>
                    <div><div class="nv-stat__label">Total ulasan</div><div class="nv-stat__value"><?php echo $total; ?></div></div></div></div>
                <div class="col-md-4 mb-3"><div class="nv-stat"><div class="nv-stat__icon nv-stat__icon--amber"><i class="fas fa-star"></i></div>
                    <div><div class="nv-stat__label">Rata-rata rating</div><div class="nv-stat__value"><?php echo $total ? e(number_format($avg, 1)) : '-'; ?></div></div></div></div>
                <div class="col-md-4 mb-3"><div class="nv-stat"><div class="nv-stat__icon nv-stat__icon--sky"><i class="fas fa-user-secret"></i></div>
                    <div><div class="nv-stat__label">Ditulis anonim</div><div class="nv-stat__value"><?php echo $anon; ?></div></div></div></div>
            </div>

            <div class="card">
                <div class="card-body">
                    <?php if (!$items): ?>
                        <div class="nv-empty"><i class="fas fa-comment-slash"></i>Belum ada ulasan dari pelanggan.</div>
                    <?php else: ?>
                    <table id="testimonialsTable" class="table table-hover" style="width:100%">
                        <thead>
                            <tr>
                                <th>Pelanggan</th><th>Buku</th><th>Rating</th><th>Ulasan</th><th>Tanggal</th>
                                <th class="text-right" data-orderable="false">Aksi</th>
                            </tr>
                        </thead>
                        <tbody>
                        <?php foreach ($items as $t): ?>
                            <tr>
                                <td>
                                    <?php if (!empty($t['is_anonymous'])): ?>
                                        <strong>Anonim</strong>
                                    <?php else: ?>
                                        <strong><?php echo e($t['full_name'] ?: 'Pelanggan'); ?></strong>
                                        <?php if ($t['username']): ?><br><small class="text-muted">@<?php echo e($t['username']); ?></small><?php endif; ?>
                                    <?php endif; ?>
                                </td>
                                <td>
                                    <?php echo e($t['book_title'] ?: '-'); ?>
                                    <?php if ($t['order_number']): ?><br><small><a href="orders-detail.php?id=<?php echo (int) $t['order_id']; ?>"><?php echo e($t['order_number']); ?></a></small><?php endif; ?>
                                </td>
                                <td data-order="<?php echo (int) $t['rating']; ?>"><?php echo stars_html($t['rating']); ?></td>
                                <td style="min-width:240px"><p class="nv-quote"><?php echo e($t['message']); ?></p></td>
                                <td data-order="<?php echo (int) strtotime($t['created_at']); ?>"><?php echo e(formatTanggal($t['created_at'])); ?></td>
                                <td>
                                    <div class="nv-actions">
                                        <form method="post" onsubmit="return confirm('Hapus ulasan ini?');">
                                            <?php echo csrf_field(); ?>
                                            <input type="hidden" name="delete_id" value="<?php echo (int) $t['testimonial_id']; ?>">
                                            <button type="submit" class="btn btn-sm btn-outline-danger" title="Hapus"><i class="fas fa-trash"></i></button>
                                        </form>
                                    </div>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                        </tbody>
                    </table>
                    <?php endif; ?>
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
    if ($('#testimonialsTable').length) { $('#testimonialsTable').DataTable({ autoWidth: false, order: [[4, 'desc']] }); }
});
</script>
<?php
$extra_js = ob_get_clean();
include 'includes/footer.php';

<?php
require_once 'includes/auth.php';
require_once 'includes/books_lib.php';

$database = new Database();
$conn = $database->getConnection();
$conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

// ---------- Hapus buku ----------
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['delete_id'])) {
    if (!csrf_valid()) {
        flash('error', 'Sesi tidak valid. Muat ulang halaman lalu coba lagi.');
    } else {
        $id = (int) $_POST['delete_id'];
        $row = db_rows($conn, 'SELECT title, image FROM books WHERE book_id = :id', [':id' => $id]);
        if (!$row) {
            flash('error', 'Buku tidak ditemukan.');
        } else {
            try {
                $st = $conn->prepare('DELETE FROM books WHERE book_id = :id');
                $st->execute([':id' => $id]);
                book_delete_cover($row[0]['image']);
                flash('success', 'Buku "' . $row[0]['title'] . '" dihapus.');
            } catch (PDOException $ex) {
                error_log('[admin] hapus buku: ' . $ex->getMessage());
                flash('error', 'Buku tidak bisa dihapus karena masih dipakai di pesanan, keranjang, atau wishlist. Ubah stoknya menjadi 0 sebagai gantinya.');
            }
        }
    }
    header('Location: books.php');
    exit;
}

$books = db_rows(
    $conn,
    'SELECT book_id, title, author, category, price, old_price, stock, rating, image, is_featured, is_new, is_discount
     FROM books ORDER BY created_at DESC, book_id DESC'
);

$page_title = 'Buku';
include 'includes/header.php';
include 'includes/sidebar.php';
?>

<div class="content-wrapper">
    <section class="content-header">
        <div class="container-fluid">
            <div class="nv-pagehead">
                <div>
                    <h1><i class="fas fa-book-open"></i>Buku</h1>
                    <p>Kelola katalog buku yang tampil di aplikasi.</p>
                </div>
                <a href="books-add.php" class="btn btn-primary"><i class="fas fa-plus mr-1"></i> Tambah buku</a>
            </div>
        </div>
    </section>

    <section class="content">
        <div class="container-fluid">
            <?php echo flash_render(); ?>

            <div class="card">
                <div class="card-body">
                    <table id="booksTable" class="table table-hover" style="width:100%">
                        <thead>
                            <tr>
                                <th>Buku</th>
                                <th>Kategori</th>
                                <th>Harga</th>
                                <th>Stok</th>
                                <th>Rating</th>
                                <th>Label</th>
                                <th class="text-right" data-orderable="false">Aksi</th>
                            </tr>
                        </thead>
                        <tbody>
                        <?php foreach ($books as $b): ?>
                            <tr>
                                <td data-order="<?php echo e($b['title']); ?>">
                                    <div class="d-flex align-items-center">
                                        <?php $img = cover_url($b['image']); ?>
                                        <?php if ($img !== ''): ?>
                                            <img src="<?php echo e($img); ?>" alt="" class="nv-cover mr-3">
                                        <?php else: ?>
                                            <span class="nv-cover nv-cover--ph mr-3"><i class="fas fa-book"></i></span>
                                        <?php endif; ?>
                                        <div>
                                            <strong><?php echo e($b['title']); ?></strong>
                                            <br><small class="text-muted"><?php echo e($b['author']); ?></small>
                                        </div>
                                    </div>
                                </td>
                                <td><?php echo badge('info', $b['category']); ?></td>
                                <td data-order="<?php echo (float) $b['old_price']; ?>">
                                    <?php
                                    $oldPrice = (float) ($b['old_price'] ?? 0);
                                    $discountPercent = (float) ($b['price'] ?? 0);
                                    if ($b['is_discount'] && $oldPrice > 0 && $discountPercent > 0) {
                                        $sellingPrice = (int) round($oldPrice - ($oldPrice * $discountPercent / 100));
                                        echo '<strong>' . e(formatRupiah($sellingPrice)) . '</strong>';
                                        echo '<br><small class="text-muted"><del>' . e(formatRupiah($oldPrice)) . '</del></small>';
                                    } else {
                                        $displayPrice = $oldPrice > 0 ? $oldPrice : (float) ($b['price'] ?? 0);
                                        echo '<strong>' . e(formatRupiah($displayPrice)) . '</strong>';
                                    }
                                    ?>
                                </td>
                                <td data-order="<?php echo (int) $b['stock']; ?>">
                                    <?php
                                    $stock = (int) $b['stock'];
                                    echo $stock === 0 ? badge('bad', 'Habis') : badge($stock <= 5 ? 'warn' : 'ok', $stock . ' tersedia');
                                    ?>
                                </td>
                                <td data-order="<?php echo (float) $b['rating']; ?>"><span class="nv-stars"><i class="fas fa-star"></i></span> <?php echo e(number_format((float) $b['rating'], 1)); ?></td>
                                <td>
                                    <?php if ($b['is_featured']) { echo badge('info', 'Unggulan') . ' '; } ?>
                                    <?php if ($b['is_new']) { echo badge('ok', 'Baru') . ' '; } ?>
                                    <?php if ($b['is_discount']) { echo badge('bad', 'Diskon'); } ?>
                                </td>
                                <td>
                                    <div class="nv-actions">
                                        <a href="books-edit.php?id=<?php echo (int) $b['book_id']; ?>" class="btn btn-sm btn-light-nv" title="Ubah"><i class="fas fa-pen"></i></a>
                                        <form method="post" onsubmit="return confirm('Hapus buku &quot;<?php echo e(addslashes($b['title'])); ?>&quot;? Tindakan ini tidak bisa dibatalkan.');">
                                            <?php echo csrf_field(); ?>
                                            <input type="hidden" name="delete_id" value="<?php echo (int) $b['book_id']; ?>">
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
    $('#booksTable').DataTable({ autoWidth: false, order: [] });
});
</script>
<?php
$extra_js = ob_get_clean();
include 'includes/footer.php';

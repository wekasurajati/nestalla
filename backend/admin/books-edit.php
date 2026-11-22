<?php
require_once 'includes/auth.php';
require_once 'includes/books_lib.php';

$database = new Database();
$conn = $database->getConnection();
$conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$id = (int) ($_GET['id'] ?? $_POST['book_id'] ?? 0);
$rows = $id > 0 ? db_rows($conn, 'SELECT * FROM books WHERE book_id = :id', [':id' => $id]) : [];
if (!$rows) {
    flash('error', 'Buku tidak ditemukan.');
    header('Location: books.php');
    exit;
}
$book = $rows[0];
$b = $book;
$errors = [];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $b = $_POST;
    if (!csrf_valid()) {
        $errors[] = 'Sesi tidak valid. Muat ulang halaman lalu coba lagi.';
    } else {
        list($data, $errors) = book_read_input($_POST);
        $newImage = null;
        if (!$errors) {
            list($saved, $upErr) = book_save_cover($_FILES['image'] ?? []);
            if ($upErr) {
                $errors[] = $upErr;
            } else {
                $newImage = $saved;
            }
        }
        if (!$errors) {
            try {
                $st = $conn->prepare(
                    'UPDATE books SET title = :title, author = :author, publisher = :publisher, description = :description,
                            price = :price, old_price = :old_price, published_year = :published_year, image = :image,
                            category = :category, stock = :stock, age_rating = :age_rating, rating = :rating,
                            is_featured = :is_featured, is_discount = :is_discount, is_new = :is_new
                     WHERE book_id = :id'
                );
                $st->execute([
                    ':title' => $data['title'], ':author' => $data['author'], ':publisher' => $data['publisher'],
                    ':description' => $data['description'], ':price' => $data['price'], ':old_price' => $data['old_price'],
                    ':published_year' => $data['published_year'], ':image' => $newImage ?? (string) $book['image'],
                    ':category' => $data['category'], ':stock' => $data['stock'], ':age_rating' => $data['age_rating'],
                    ':rating' => $data['rating'], ':is_featured' => $data['is_featured'], ':is_discount' => $data['is_discount'],
                    ':is_new' => $data['is_new'], ':id' => $id,
                ]);
                if ($newImage !== null) {
                    book_delete_cover($book['image']); // buang sampul lama
                }
                flash('success', 'Buku "' . $data['title'] . '" berhasil diperbarui.');
                header('Location: books.php');
                exit;
            } catch (PDOException $ex) {
                error_log('[admin] ubah buku: ' . $ex->getMessage());
                if ($newImage !== null) { book_delete_cover($newImage); }
                $errors[] = 'Perubahan gagal disimpan. Periksa kembali isian formulir.';
            }
        }
    }
}

$categories = book_categories($conn);
$page_title = 'Ubah buku';
include 'includes/header.php';
include 'includes/sidebar.php';
?>

<div class="content-wrapper">
    <section class="content-header">
        <div class="container-fluid">
            <div class="nv-pagehead">
                <div>
                    <h1><i class="fas fa-pen"></i>Ubah buku</h1>
                    <p><?php echo e($book['title']); ?></p>
                </div>
                <a href="books.php" class="btn btn-sm btn-light-nv"><i class="fas fa-arrow-left"></i> Kembali</a>
            </div>
        </div>
    </section>

    <section class="content">
        <div class="container-fluid">
            <?php if ($errors): ?>
                <div class="alert alert-danger"><ul class="mb-0 pl-3"><?php foreach ($errors as $m): ?><li><?php echo e($m); ?></li><?php endforeach; ?></ul></div>
            <?php endif; ?>
            <form method="post" enctype="multipart/form-data" novalidate>
                <?php echo csrf_field(); ?>
                <input type="hidden" name="book_id" value="<?php echo (int) $id; ?>">
                <?php render_book_form($b, $categories, $book['image'], 'Simpan perubahan', 'books.php'); ?>
            </form>
        </div>
    </section>
</div>

<?php
$extra_js = book_form_js();
include 'includes/footer.php';

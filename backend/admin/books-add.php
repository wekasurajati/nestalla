<?php
require_once 'includes/auth.php';
require_once 'includes/books_lib.php';

$database = new Database();
$conn = $database->getConnection();
$conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$errors = [];
$b = ['stock' => '0', 'rating' => '0'];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $b = $_POST;
    if (!csrf_valid()) {
        $errors[] = 'Sesi tidak valid. Muat ulang halaman lalu coba lagi.';
    } else {
        list($data, $errors) = book_read_input($_POST);
        $image = '';
        if (!$errors) {
            list($saved, $upErr) = book_save_cover($_FILES['image'] ?? []);
            if ($upErr) {
                $errors[] = $upErr;
            } else {
                $image = $saved ?? '';
            }
        }
        if (!$errors) {
            try {
                $st = $conn->prepare(
                    'INSERT INTO books (title, author, publisher, description, price, old_price, published_year, image, category, stock, age_rating, rating, is_featured, is_discount, is_new)
                     VALUES (:title, :author, :publisher, :description, :price, :old_price, :published_year, :image, :category, :stock, :age_rating, :rating, :is_featured, :is_discount, :is_new)'
                );
                $st->execute([
                    ':title' => $data['title'], ':author' => $data['author'], ':publisher' => $data['publisher'],
                    ':description' => $data['description'], ':price' => $data['price'], ':old_price' => $data['old_price'],
                    ':published_year' => $data['published_year'], ':image' => $image, ':category' => $data['category'],
                    ':stock' => $data['stock'], ':age_rating' => $data['age_rating'], ':rating' => $data['rating'],
                    ':is_featured' => $data['is_featured'], ':is_discount' => $data['is_discount'], ':is_new' => $data['is_new'],
                ]);
                flash('success', 'Buku "' . $data['title'] . '" berhasil ditambahkan.');
                header('Location: books.php');
                exit;
            } catch (PDOException $ex) {
                error_log('[admin] tambah buku: ' . $ex->getMessage());
                if ($image !== '') { book_delete_cover($image); }
                $errors[] = 'Buku gagal disimpan. Periksa kembali isian formulir.';
            }
        }
    }
}

$categories = book_categories($conn);
$page_title = 'Tambah buku';
include 'includes/header.php';
include 'includes/sidebar.php';
?>

<div class="content-wrapper">
    <section class="content-header">
        <div class="container-fluid">
            <div class="nv-pagehead">
                <div>
                    <h1><i class="fas fa-plus"></i>Tambah buku</h1>
                    <p>Isi data buku baru untuk katalog.</p>
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
                <?php render_book_form($b, $categories, '', 'Simpan buku', 'books.php'); ?>
            </form>
        </div>
    </section>
</div>

<?php
$extra_js = book_form_js();
include 'includes/footer.php';

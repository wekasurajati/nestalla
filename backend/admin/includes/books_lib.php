<?php
// File: admin/includes/books_lib.php
// Fungsi bantu untuk halaman buku: validasi input, unggah sampul, dan formulir.

const BOOK_COVER_MAX_BYTES = 2097152; // 2 MB

// Folder sampul yang dibaca aplikasi: backend/image/covers
function book_cover_dir()
{
    return dirname(__DIR__, 2) . '/image/covers/';
}

function book_cover_is_safe_name($name)
{
    return is_string($name) && $name !== '' && preg_match('/^[A-Za-z0-9._-]+$/', $name) === 1 && strpos($name, '..') === false;
}

// Hapus berkas sampul lama (hanya nama file aman di folder covers; path lama diabaikan)
function book_delete_cover($image)
{
    $name = trim((string) $image);
    if (!book_cover_is_safe_name($name)) {
        return;
    }
    $path = book_cover_dir() . $name;
    if (is_file($path)) {
        @unlink($path);
    }
}

// Simpan sampul yang diunggah. Mengembalikan [namaFile|null, pesanError|null].
function book_save_cover(array $file)
{
    if (!isset($file['error']) || $file['error'] === UPLOAD_ERR_NO_FILE) {
        return [null, null];
    }
    if ($file['error'] !== UPLOAD_ERR_OK) {
        return [null, 'Unggahan sampul gagal (kode ' . (int) $file['error'] . '). Ukuran file mungkin melebihi batas server.'];
    }
    if ($file['size'] > BOOK_COVER_MAX_BYTES) {
        return [null, 'Ukuran sampul maksimal 2 MB.'];
    }
    $info = @getimagesize($file['tmp_name']);
    if (!$info) {
        return [null, 'File yang diunggah bukan gambar yang valid.'];
    }
    $types = [IMAGETYPE_JPEG => 'jpg', IMAGETYPE_PNG => 'png', IMAGETYPE_GIF => 'gif', IMAGETYPE_WEBP => 'webp'];
    if (!isset($types[$info[2]])) {
        return [null, 'Format sampul harus JPG, PNG, GIF, atau WebP.'];
    }
    $dir = book_cover_dir();
    if (!is_dir($dir) && !@mkdir($dir, 0775, true)) {
        return [null, 'Folder sampul tidak bisa dibuat. Periksa izin folder backend/image.'];
    }
    $name = 'book_' . bin2hex(random_bytes(8)) . '.' . $types[$info[2]];
    if (!move_uploaded_file($file['tmp_name'], $dir . $name)) {
        return [null, 'Sampul gagal disimpan ke server.'];
    }
    return [$name, null];
}

// Baca dan validasi input formulir. Mengembalikan [dataSiapSimpan, daftarError].
function book_read_input(array $src)
{
    $errors = [];
    $len = function ($s) { return function_exists('mb_strlen') ? mb_strlen($s) : strlen($s); };
    $text = function ($k) use ($src) { return trim((string) ($src[$k] ?? '')); };

    $d = [
        'title' => $text('title'), 'author' => $text('author'), 'publisher' => $text('publisher'),
        'description' => $text('description'), 'category' => $text('category'), 'age_rating' => $text('age_rating'),
    ];
    if ($d['title'] === '' || $len($d['title']) > 255) { $errors[] = 'Judul wajib diisi (maksimal 255 karakter).'; }
    if ($d['author'] === '' || $len($d['author']) > 150) { $errors[] = 'Penulis wajib diisi (maksimal 150 karakter).'; }
    if ($d['category'] === '' || $len($d['category']) > 100) { $errors[] = 'Kategori wajib diisi (maksimal 100 karakter).'; }
    if ($len($d['publisher']) > 100) { $errors[] = 'Penerbit maksimal 100 karakter.'; }
    if ($len($d['age_rating']) > 10) { $errors[] = 'Klasifikasi usia maksimal 10 karakter.'; }

    $price = $text('price');
    if ($price === '' || !is_numeric($price) || $price < 0 || $price > 100) { $errors[] = 'Diskon wajib berupa angka 0 sampai 100 (persen).'; }
    $d['price'] = is_numeric($price) ? (int) round($price) : 0;

    $old = $text('old_price');
    if ($old !== '' && (!is_numeric($old) || $old < 0)) { $errors[] = 'Harga asli harus berupa angka 0 atau lebih.'; }
    $d['old_price'] = ($old !== '' && is_numeric($old) && $old > 0) ? (int) round($old) : null;

    $stock = $text('stock');
    if ($stock === '' || !ctype_digit($stock)) { $errors[] = 'Stok wajib berupa bilangan bulat 0 atau lebih.'; }
    $d['stock'] = ctype_digit($stock) ? (int) $stock : 0;

    $year = $text('published_year');
    if ($year !== '' && (!ctype_digit($year) || $year < 1000 || $year > (int) date('Y') + 1)) { $errors[] = 'Tahun terbit tidak valid.'; }
    $d['published_year'] = ($year !== '' && ctype_digit($year)) ? (int) $year : null;
    $d['publisher'] = $d['publisher'] === '' ? null : $d['publisher'];
    $d['age_rating'] = $d['age_rating'] === '' ? null : $d['age_rating'];

    $d['is_featured'] = isset($src['is_featured']) ? 1 : 0;
    $d['is_new'] = isset($src['is_new']) ? 1 : 0;
    $d['is_discount'] = isset($src['is_discount']) ? 1 : 0;

    return [$d, $errors];
}

function book_categories(PDO $conn)
{
    $rows = db_rows($conn, "SELECT DISTINCT category FROM books WHERE category IS NOT NULL AND category <> '' ORDER BY category");
    return array_column($rows, 'category');
}

function book_checked($b, $key)
{
    return !empty($b[$key]) ? 'checked' : '';
}

// Isi formulir buku (dipakai halaman tambah dan ubah). $b = nilai yang tampil.
function render_book_form(array $b, array $categories, $currentImage, $submitLabel, $cancelUrl)
{
    $cover = $currentImage ? cover_url($currentImage) : '';
    ?>
    <div class="row">
        <div class="col-lg-8">
            <div class="card">
                <div class="card-header"><h3 class="card-title">Informasi buku</h3></div>
                <div class="card-body">
                    <div class="form-group">
                        <label for="title">Judul <span class="nv-req">*</span></label>
                        <input type="text" id="title" name="title" class="form-control" maxlength="255" required value="<?php echo e($b['title'] ?? ''); ?>">
                    </div>
                    <div class="row">
                        <div class="col-md-6 form-group">
                            <label for="author">Penulis <span class="nv-req">*</span></label>
                            <input type="text" id="author" name="author" class="form-control" maxlength="150" required value="<?php echo e($b['author'] ?? ''); ?>">
                        </div>
                        <div class="col-md-6 form-group">
                            <label for="publisher">Penerbit</label>
                            <input type="text" id="publisher" name="publisher" class="form-control" maxlength="100" value="<?php echo e($b['publisher'] ?? ''); ?>">
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="description">Deskripsi</label>
                        <textarea id="description" name="description" class="form-control" rows="5"><?php echo e($b['description'] ?? ''); ?></textarea>
                    </div>
                    <div class="row">
                        <div class="col-md-6 form-group">
                            <label for="price">Diskon (%) <span class="nv-req">*</span></label>
                            <input type="number" id="price" name="price" class="form-control" min="0" max="100" step="1" required value="<?php echo e($b['price'] ?? ''); ?>">
                        </div>
                        <div class="col-md-6 form-group">
                            <label for="old_price">Harga asli (Rp)</label>
                            <input type="number" id="old_price" name="old_price" class="form-control" min="0" step="1" value="<?php echo e($b['old_price'] ?? ''); ?>">
                            <span class="nv-help">Harga dasar sebelum diskon dihitung. Kosongkan bila tidak ada diskon.</span>
                        </div>
                    </div>
                    <div class="row">
                        <div class="col-md-6 form-group">
                            <label for="category">Kategori <span class="nv-req">*</span></label>
                            <input type="text" id="category" name="category" class="form-control" list="categoryList" maxlength="100" required value="<?php echo e($b['category'] ?? ''); ?>">
                            <datalist id="categoryList">
                                <?php foreach ($categories as $c): ?><option value="<?php echo e($c); ?>"><?php endforeach; ?>
                            </datalist>
                            <span class="nv-help">Pilih dari saran atau ketik kategori baru.</span>
                        </div>
                        <div class="col-md-6 form-group">
                            <label for="stock">Stok <span class="nv-req">*</span></label>
                            <input type="number" id="stock" name="stock" class="form-control" min="0" step="1" required value="<?php echo e($b['stock'] ?? '0'); ?>">
                        </div>
                    </div>
                    <div class="row">
                        <div class="col-md-6 form-group">
                            <label for="published_year">Tahun terbit</label>
                            <input type="number" id="published_year" name="published_year" class="form-control" min="1000" max="<?php echo (int) date('Y') + 1; ?>" value="<?php echo e($b['published_year'] ?? ''); ?>">
                        </div>
                        <div class="col-md-6 form-group">
                            <label for="age_rating">Klasifikasi usia</label>
                            <input type="text" id="age_rating" name="age_rating" class="form-control" maxlength="10" placeholder="mis. SU, 13+, 17+" value="<?php echo e($b['age_rating'] ?? ''); ?>">
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="col-lg-4">
            <div class="card">
                <div class="card-header"><h3 class="card-title">Sampul</h3></div>
                <div class="card-body">
                    <?php if ($cover): ?>
                        <img id="coverPreview" src="<?php echo e($cover); ?>" alt="Sampul" class="nv-cover-preview">
                    <?php else: ?>
                        <img id="coverPreview" src="" alt="" class="nv-cover-preview" style="display:none">
                        <div id="coverPlaceholder" class="nv-cover-preview nv-cover-preview--ph"><i class="fas fa-image"></i></div>
                    <?php endif; ?>
                    <div class="custom-file">
                        <input type="file" class="custom-file-input" id="image" name="image" accept="image/jpeg,image/png,image/gif,image/webp">
                        <label class="custom-file-label" for="image">Pilih gambar…</label>
                    </div>
                    <span class="nv-help">JPG, PNG, GIF, atau WebP. Maksimal 2 MB.<?php echo $cover ? ' Kosongkan untuk mempertahankan sampul sekarang.' : ''; ?></span>
                </div>
            </div>

            <div class="card">
                <div class="card-header"><h3 class="card-title">Label</h3></div>
                <div class="card-body">
                    
                    <div class="custom-control custom-switch mb-2">
                        <input type="checkbox" class="custom-control-input" id="is_featured" name="is_featured" value="1" <?php echo book_checked($b, 'is_featured'); ?>>
                        <label class="custom-control-label" for="is_featured">Buku unggulan</label>
                    </div>
                    <div class="custom-control custom-switch mb-2">
                        <input type="checkbox" class="custom-control-input" id="is_new" name="is_new" value="1" <?php echo book_checked($b, 'is_new'); ?>>
                        <label class="custom-control-label" for="is_new">Buku baru</label>
                    </div>
                    <div class="custom-control custom-switch">
                        <input type="checkbox" class="custom-control-input" id="is_discount" name="is_discount" value="1" <?php echo book_checked($b, 'is_discount'); ?>>
                        <label class="custom-control-label" for="is_discount">Sedang diskon</label>
                    </div>
                </div>
            </div>

            <button type="submit" class="btn btn-primary btn-block mb-2"><i class="fas fa-save mr-1"></i> <?php echo e($submitLabel); ?></button>
            <a href="<?php echo e($cancelUrl); ?>" class="btn btn-light-nv btn-block">Batal</a>
        </div>
    </div>
    <?php
}

// JavaScript pratinjau sampul (dikirim lewat $extra_js)
function book_form_js()
{
    return <<<'HTML'
<script>
$(function () {
    $('#image').on('change', function () {
        var f = this.files && this.files[0];
        $(this).next('.custom-file-label').text(f ? f.name : 'Pilih gambar…');
        if (!f) { return; }
        var r = new FileReader();
        r.onload = function (e) {
            $('#coverPreview').attr('src', e.target.result).show();
            $('#coverPlaceholder').hide();
        };
        r.readAsDataURL(f);
    });
});
</script>
HTML;
}

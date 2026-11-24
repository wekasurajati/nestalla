<?php
require_once 'includes/auth.php';
require_once 'includes/shipping_lib.php';

$database = new Database();
$conn = $database->getConnection();
$conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$errors = [];
$form = ['carrier_name' => '', 'contact_phone' => '', 'contact_email' => '', 'is_active' => '1'];

// ---------- Aksi ----------
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $act = (string) ($_POST['action'] ?? '');
    if (!csrf_valid()) {
        flash('error', 'Sesi tidak valid. Muat ulang halaman lalu coba lagi.');
        header('Location: shipping.php');
        exit;
    }
    try {
        if ($act === 'add_carrier') {
            // Input pertama: nama ekspedisi. Setelah disimpan, lanjut ke tarif per kota.
            list($d, $errors) = ship_read_carrier($_POST);
            if (!$errors && ship_carrier_name_taken($conn, $d['name'], 0)) {
                $errors[] = 'Ekspedisi "' . $d['name'] . '" sudah ada. Pilih dari daftar di bawah, lalu atur tarifnya.';
            }
            if ($errors) {
                $form = $_POST;
            } else {
                $st = $conn->prepare(
                    'INSERT INTO shipping_carriers (carrier_name, contact_phone, contact_email, is_active)
                     VALUES (:n, :p, :e, :a)'
                );
                $st->execute([':n' => $d['name'], ':p' => $d['phone'], ':e' => $d['email'], ':a' => $d['active']]);
                $newId = (int) $conn->lastInsertId();
                flash('success', 'Ekspedisi "' . $d['name'] . '" disimpan. Sekarang isi tarif pengiriman per kota.');
                header('Location: shipping-rates.php?id=' . $newId);
                exit;
            }
        } elseif ($act === 'update_carrier') {
            $id = (int) ($_POST['carrier_id'] ?? 0);
            list($d, $errs) = ship_read_carrier($_POST);
            if ($id <= 0 || !db_rows($conn, 'SELECT carrier_id FROM shipping_carriers WHERE carrier_id = :id', [':id' => $id])) {
                $errs[] = 'Ekspedisi tidak ditemukan.';
            } elseif (!$errs && ship_carrier_name_taken($conn, $d['name'], $id)) {
                $errs[] = 'Ekspedisi "' . $d['name'] . '" sudah ada.';
            }
            if ($errs) {
                flash('error', implode(' ', $errs));
            } else {
                $st = $conn->prepare(
                    'UPDATE shipping_carriers SET carrier_name = :n, contact_phone = :p, contact_email = :e, is_active = :a
                     WHERE carrier_id = :id'
                );
                $st->execute([':n' => $d['name'], ':p' => $d['phone'], ':e' => $d['email'], ':a' => $d['active'], ':id' => $id]);
                flash('success', 'Ekspedisi "' . $d['name'] . '" diperbarui.');
            }
            header('Location: shipping.php');
            exit;
        } elseif ($act === 'toggle_carrier') {
            $id = (int) ($_POST['carrier_id'] ?? 0);
            $row = db_rows($conn, 'SELECT carrier_name, is_active FROM shipping_carriers WHERE carrier_id = :id', [':id' => $id]);
            if (!$row) {
                flash('error', 'Ekspedisi tidak ditemukan.');
            } else {
                $new = ((int) $row[0]['is_active']) === 1 ? 0 : 1;
                $conn->prepare('UPDATE shipping_carriers SET is_active = :a WHERE carrier_id = :id')
                     ->execute([':a' => $new, ':id' => $id]);
                flash('success', 'Ekspedisi "' . $row[0]['carrier_name'] . '" '
                    . ($new === 1 ? 'diaktifkan. Pelanggan bisa memilihnya saat checkout.' : 'dinonaktifkan. Pelanggan tidak bisa memilihnya saat checkout.'));
            }
            header('Location: shipping.php');
            exit;
        } elseif ($act === 'delete_carrier') {
            $id = (int) ($_POST['carrier_id'] ?? 0);
            $row = db_rows($conn, 'SELECT carrier_name FROM shipping_carriers WHERE carrier_id = :id', [':id' => $id]);
            if (!$row) {
                flash('error', 'Ekspedisi tidak ditemukan.');
            } else {
                $conn->prepare('DELETE FROM shipping_carriers WHERE carrier_id = :id')->execute([':id' => $id]);
                flash('success', 'Ekspedisi "' . $row[0]['carrier_name'] . '" dan semua tarifnya dihapus.');
            }
            header('Location: shipping.php');
            exit;
        }
    } catch (PDOException $ex) {
        error_log('[admin] pengiriman: ' . $ex->getMessage());
        flash('error', 'Perubahan gagal disimpan. Coba lagi.');
        header('Location: shipping.php');
        exit;
    }
}

// ---------- Data ----------
$carriers = db_rows(
    $conn,
    'SELECT c.carrier_id, c.carrier_name, c.contact_phone, c.contact_email, c.is_active,
            (SELECT COUNT(*) FROM shipping_rates r WHERE r.carrier_id = c.carrier_id) AS rate_count,
            (SELECT COUNT(*) FROM shipping_rates r WHERE r.carrier_id = c.carrier_id AND r.is_active = 1) AS rate_active,
            (SELECT COUNT(*) FROM orders o WHERE o.shipping_carrier_id = c.carrier_id) AS order_count
     FROM shipping_carriers c
     ORDER BY c.carrier_name'
);

$page_title = 'Pengiriman';
include 'includes/header.php';
include 'includes/sidebar.php';
?>

<div class="content-wrapper">
    <section class="content-header">
        <div class="container-fluid">
            <div class="nv-pagehead">
                <div>
                    <h1><i class="fas fa-truck"></i>Pengiriman</h1>
                    <p>Atur ekspedisi dan tarif ongkos kirim per kota.</p>
                </div>
            </div>
        </div>
    </section>

    <section class="content">
        <div class="container-fluid">
            <?php echo flash_render(); ?>
            <?php if ($errors): ?>
                <div class="alert alert-danger"><ul class="mb-0 pl-3"><?php foreach ($errors as $m): ?><li><?php echo e($m); ?></li><?php endforeach; ?></ul></div>
            <?php endif; ?>

            <div class="card">
                <div class="card-header"><h3 class="card-title">1. Tambah ekspedisi</h3></div>
                <div class="card-body">
                    <form method="post" class="js-once" novalidate>
                        <?php echo csrf_field(); ?>
                        <input type="hidden" name="action" value="add_carrier">
                        <div class="form-row">
                            <div class="form-group col-md-4">
                                <label for="a_name">Nama ekspedisi <span class="text-danger">*</span></label>
                                <input type="text" id="a_name" name="carrier_name" class="form-control" maxlength="100"
                                       placeholder="Contoh: JNE" value="<?php echo e($form['carrier_name'] ?? ''); ?>">
                            </div>
                            <div class="form-group col-md-3">
                                <label for="a_phone">Telepon</label>
                                <input type="text" id="a_phone" name="contact_phone" class="form-control" maxlength="20"
                                       value="<?php echo e($form['contact_phone'] ?? ''); ?>">
                            </div>
                            <div class="form-group col-md-3">
                                <label for="a_email">Email</label>
                                <input type="email" id="a_email" name="contact_email" class="form-control" maxlength="100"
                                       value="<?php echo e($form['contact_email'] ?? ''); ?>">
                            </div>
                            <div class="form-group col-md-2 d-flex align-items-end">
                                <div class="custom-control custom-switch mb-2">
                                    <input type="checkbox" class="custom-control-input" id="a_active" name="is_active" value="1"
                                           <?php echo !empty($form['is_active']) ? 'checked' : ''; ?>>
                                    <label class="custom-control-label" for="a_active">Aktif</label>
                                </div>
                            </div>
                        </div>
                        <button type="submit" class="btn btn-primary"><i class="fas fa-save mr-1"></i> Simpan, lalu isi tarif</button>
                        <span class="nv-help ml-2">Setelah disimpan, kamu langsung diarahkan untuk mengisi tarif per kota.</span>
                    </form>
                </div>
            </div>

            <div class="card">
                <div class="card-header"><h3 class="card-title"><?php echo count($carriers); ?> ekspedisi</h3></div>
                <div class="card-body">
                    <?php if (!$carriers): ?>
                        <div class="nv-empty"><i class="fas fa-truck"></i>Belum ada ekspedisi. Tambahkan yang pertama di atas.</div>
                    <?php else: ?>
                    <table id="carriersTable" class="table table-hover" style="width:100%">
                        <thead>
                            <tr>
                                <th>Ekspedisi</th>
                                <th>Kontak</th>
                                <th>Tarif</th>
                                <th>Status</th>
                                <th class="text-right" data-orderable="false">Aksi</th>
                            </tr>
                        </thead>
                        <tbody>
                        <?php foreach ($carriers as $c): ?>
                            <?php $active = ((int) $c['is_active']) === 1; ?>
                            <tr>
                                <td><strong><?php echo e($c['carrier_name']); ?></strong></td>
                                <td>
                                    <?php if (!empty($c['contact_phone'])): ?><small class="text-muted"><i class="fas fa-phone mr-1"></i><?php echo e($c['contact_phone']); ?></small><br><?php endif; ?>
                                    <?php if (!empty($c['contact_email'])): ?><small class="text-muted"><i class="fas fa-envelope mr-1"></i><?php echo e($c['contact_email']); ?></small><?php endif; ?>
                                    <?php if (empty($c['contact_phone']) && empty($c['contact_email'])): ?><span class="text-muted">-</span><?php endif; ?>
                                </td>
                                <td data-order="<?php echo (int) $c['rate_count']; ?>">
                                    <?php if ((int) $c['rate_count'] === 0): ?>
                                        <?php echo badge('warn', 'Belum ada tarif'); ?>
                                    <?php else: ?>
                                        <strong><?php echo (int) $c['rate_count']; ?></strong> kota
                                        <br><small class="text-muted"><?php echo (int) $c['rate_active']; ?> aktif</small>
                                    <?php endif; ?>
                                </td>
                                <td><?php echo $active ? badge('ok', 'Aktif') : badge('muted', 'Nonaktif'); ?></td>
                                <td>
                                    <div class="nv-actions">
                                        <a href="shipping-rates.php?id=<?php echo (int) $c['carrier_id']; ?>" class="btn btn-sm btn-primary" title="Atur tarif per kota"><i class="fas fa-map-marked-alt"></i> Atur tarif</a>
                                        <button type="button" class="btn btn-sm btn-light-nv" title="Ubah ekspedisi" data-toggle="modal" data-target="#carrierModal"
                                                data-id="<?php echo (int) $c['carrier_id']; ?>"
                                                data-name="<?php echo e($c['carrier_name']); ?>"
                                                data-phone="<?php echo e($c['contact_phone']); ?>"
                                                data-email="<?php echo e($c['contact_email']); ?>"
                                                data-active="<?php echo $active ? '1' : '0'; ?>"><i class="fas fa-pen"></i></button>
                                        <form method="post" class="js-once">
                                            <?php echo csrf_field(); ?>
                                            <input type="hidden" name="action" value="toggle_carrier">
                                            <input type="hidden" name="carrier_id" value="<?php echo (int) $c['carrier_id']; ?>">
                                            <button type="submit" class="btn btn-sm btn-light-nv" title="<?php echo $active ? 'Nonaktifkan' : 'Aktifkan'; ?>"><i class="fas <?php echo $active ? 'fa-toggle-on' : 'fa-toggle-off'; ?>"></i></button>
                                        </form>
                                        <form method="post" onsubmit="return confirm('Hapus ekspedisi &quot;<?php echo e(addslashes($c['carrier_name'])); ?>&quot;? <?php echo (int) $c['rate_count']; ?> tarif ikut terhapus<?php echo (int) $c['order_count'] > 0 ? ' dan ' . (int) $c['order_count'] . ' pesanan lama tidak lagi menampilkan ekspedisi ini' : ''; ?>. Tindakan ini tidak bisa dibatalkan. Untuk berhenti memakainya, cukup nonaktifkan.');">
                                            <?php echo csrf_field(); ?>
                                            <input type="hidden" name="action" value="delete_carrier">
                                            <input type="hidden" name="carrier_id" value="<?php echo (int) $c['carrier_id']; ?>">
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

<div class="modal fade" id="carrierModal" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <form method="post" class="modal-content js-once" style="border:0;border-radius:16px" novalidate>
            <div class="modal-header" style="border-bottom:1px solid #E6EBF3">
                <h5 class="modal-title font-weight-bold">Ubah ekspedisi</h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Tutup">&times;</button>
            </div>
            <div class="modal-body">
                <?php echo csrf_field(); ?>
                <input type="hidden" name="action" value="update_carrier">
                <input type="hidden" name="carrier_id" id="c_id">
                <div class="form-group">
                    <label for="c_name">Nama ekspedisi <span class="text-danger">*</span></label>
                    <input type="text" id="c_name" name="carrier_name" class="form-control" maxlength="100">
                </div>
                <div class="form-group">
                    <label for="c_phone">Telepon</label>
                    <input type="text" id="c_phone" name="contact_phone" class="form-control" maxlength="20">
                </div>
                <div class="form-group">
                    <label for="c_email">Email</label>
                    <input type="email" id="c_email" name="contact_email" class="form-control" maxlength="100">
                </div>
                <div class="custom-control custom-switch">
                    <input type="checkbox" class="custom-control-input" id="c_active" name="is_active" value="1">
                    <label class="custom-control-label" for="c_active">Aktif (bisa dipilih saat checkout)</label>
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
    if ($('#carriersTable').length) {
        $('#carriersTable').DataTable({ autoWidth: false, order: [[0, 'asc']] });
    }
    $('#carrierModal').on('show.bs.modal', function (ev) {
        var b = $(ev.relatedTarget);
        $('#c_id').val(b.attr('data-id'));
        $('#c_name').val(b.attr('data-name'));
        $('#c_phone').val(b.attr('data-phone') || '');
        $('#c_email').val(b.attr('data-email') || '');
        $('#c_active').prop('checked', b.attr('data-active') === '1');
    });
    // Cegah klik ganda pada tombol simpan
    $('form.js-once').on('submit', function () {
        $(this).find('button[type=submit]').prop('disabled', true);
    });
    $(window).on('pageshow', function (e) {
        if (e.originalEvent && e.originalEvent.persisted) {
            $('form.js-once button[type=submit]').prop('disabled', false);
        }
    });
});
</script>
<?php
$extra_js = ob_get_clean();
include 'includes/footer.php';

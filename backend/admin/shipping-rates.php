<?php
require_once 'includes/auth.php';
require_once 'includes/shipping_lib.php';

$database = new Database();
$conn = $database->getConnection();
$conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$carrierId = (int) ($_GET['id'] ?? $_POST['carrier_id'] ?? 0);
$crow = $carrierId > 0
    ? db_rows($conn, 'SELECT carrier_id, carrier_name, is_active FROM shipping_carriers WHERE carrier_id = :id', [':id' => $carrierId])
    : [];
if (!$crow) {
    flash('error', 'Ekspedisi tidak ditemukan.');
    header('Location: shipping.php');
    exit;
}
$carrier = $crow[0];
$self = 'shipping-rates.php?id=' . $carrierId;

$errors = [];
$lastProv = (string) ($_SESSION['ship_last_prov'][$carrierId] ?? '');
$form = ['province' => $lastProv, 'city' => '', 'price' => '', 'is_active' => '1'];

// ---------- Aksi ----------
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $act = (string) ($_POST['action'] ?? '');
    if (!csrf_valid()) {
        flash('error', 'Sesi tidak valid. Muat ulang halaman lalu coba lagi.');
        header('Location: ' . $self);
        exit;
    }
    try {
        if ($act === 'add_rate') {
            // Input kedua: tarif ke satu kota
            list($d, $errors) = ship_read_rate($_POST);
            if (!$errors && ship_rate_duplicate($conn, $carrierId, $d['province'], $d['city'], 0)) {
                $errors[] = 'Tarif ' . $carrier['carrier_name'] . ' ke ' . $d['city'] . ', ' . $d['province']
                    . ' sudah ada. Ubah harganya lewat tombol Ubah di daftar.';
            }
            if ($errors) {
                $form = $_POST;
            } else {
                $st = $conn->prepare(
                    'INSERT INTO shipping_rates (carrier_id, province, city, price, is_active)
                     VALUES (:c, :p, :ct, :pr, :a)'
                );
                $st->execute([':c' => $carrierId, ':p' => $d['province'], ':ct' => $d['city'], ':pr' => $d['price'], ':a' => $d['active']]);
                $_SESSION['ship_last_prov'][$carrierId] = $d['province']; // memudahkan input kota berikutnya
                flash('success', 'Tarif ke ' . $d['city'] . ', ' . $d['province'] . ' disimpan: ' . formatRupiah($d['price']) . '.');
                header('Location: ' . $self);
                exit;
            }
        } elseif ($act === 'update_rate') {
            $rateId = (int) ($_POST['rate_id'] ?? 0);
            list($d, $errs) = ship_read_rate($_POST);
            $own = $rateId > 0
                ? db_rows($conn, 'SELECT rate_id FROM shipping_rates WHERE rate_id = :r AND carrier_id = :c', [':r' => $rateId, ':c' => $carrierId])
                : [];
            if (!$own) {
                $errs[] = 'Tarif tidak ditemukan.';
            } elseif (!$errs && ship_rate_duplicate($conn, $carrierId, $d['province'], $d['city'], $rateId)) {
                $errs[] = 'Tarif ke ' . $d['city'] . ', ' . $d['province'] . ' sudah ada untuk ekspedisi ini.';
            }
            if ($errs) {
                flash('error', implode(' ', $errs));
            } else {
                $st = $conn->prepare(
                    'UPDATE shipping_rates SET province = :p, city = :ct, price = :pr, is_active = :a
                     WHERE rate_id = :r AND carrier_id = :c'
                );
                $st->execute([':p' => $d['province'], ':ct' => $d['city'], ':pr' => $d['price'], ':a' => $d['active'], ':r' => $rateId, ':c' => $carrierId]);
                flash('success', 'Tarif ke ' . $d['city'] . ', ' . $d['province'] . ' diperbarui: ' . formatRupiah($d['price']) . '.');
            }
            header('Location: ' . $self);
            exit;
        } elseif ($act === 'toggle_rate') {
            $rateId = (int) ($_POST['rate_id'] ?? 0);
            $row = db_rows($conn, 'SELECT city, is_active FROM shipping_rates WHERE rate_id = :r AND carrier_id = :c', [':r' => $rateId, ':c' => $carrierId]);
            if (!$row) {
                flash('error', 'Tarif tidak ditemukan.');
            } else {
                $new = ((int) $row[0]['is_active']) === 1 ? 0 : 1;
                $conn->prepare('UPDATE shipping_rates SET is_active = :a WHERE rate_id = :r AND carrier_id = :c')
                     ->execute([':a' => $new, ':r' => $rateId, ':c' => $carrierId]);
                flash('success', 'Tarif ke ' . $row[0]['city'] . ($new === 1 ? ' diaktifkan.' : ' dinonaktifkan.'));
            }
            header('Location: ' . $self);
            exit;
        } elseif ($act === 'delete_rate') {
            $rateId = (int) ($_POST['rate_id'] ?? 0);
            $row = db_rows($conn, 'SELECT city FROM shipping_rates WHERE rate_id = :r AND carrier_id = :c', [':r' => $rateId, ':c' => $carrierId]);
            if (!$row) {
                flash('error', 'Tarif tidak ditemukan.');
            } else {
                $conn->prepare('DELETE FROM shipping_rates WHERE rate_id = :r AND carrier_id = :c')->execute([':r' => $rateId, ':c' => $carrierId]);
                flash('success', 'Tarif ke ' . $row[0]['city'] . ' dihapus.');
            }
            header('Location: ' . $self);
            exit;
        }
    } catch (PDOException $ex) {
        error_log('[admin] tarif pengiriman: ' . $ex->getMessage());
        flash('error', 'Perubahan gagal disimpan. Coba lagi.');
        header('Location: ' . $self);
        exit;
    }
}

// ---------- Data ----------
$rates = db_rows(
    $conn,
    'SELECT rate_id, province, city, price, is_active FROM shipping_rates WHERE carrier_id = :c ORDER BY province, city',
    [':c' => $carrierId]
);

$carrierActive = ((int) $carrier['is_active']) === 1;
$page_title = 'Tarif ' . $carrier['carrier_name'];
include 'includes/header.php';
include 'includes/sidebar.php';
?>

<div class="content-wrapper">
    <section class="content-header">
        <div class="container-fluid">
            <div class="nv-pagehead">
                <div>
                    <h1><i class="fas fa-map-marked-alt"></i>Tarif <?php echo e($carrier['carrier_name']); ?></h1>
                    <p>Ongkos kirim per kota tujuan.</p>
                </div>
                <div>
                    <?php echo $carrierActive ? badge('ok', 'Ekspedisi aktif') : badge('muted', 'Ekspedisi nonaktif'); ?>
                    <a href="shipping.php" class="btn btn-sm btn-light-nv ml-2"><i class="fas fa-arrow-left"></i> Kembali</a>
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

            <?php if (!$carrierActive): ?>
                <div class="alert alert-warning"><i class="fas fa-exclamation-triangle mr-1"></i> Ekspedisi ini nonaktif, jadi pelanggan belum bisa memilihnya saat checkout. Aktifkan di halaman Pengiriman.</div>
            <?php endif; ?>

            <div class="alert alert-info">
                <i class="fas fa-info-circle mr-1"></i>
                Pilih provinsi, lalu kota / kabupaten. Daftarnya sama dengan yang dipakai aplikasi, jadi nama tarif otomatis cocok dengan alamat pelanggan.
                Kalau namanya tidak cocok, ongkos kirim di checkout menjadi Rp0. Daftar wilayah diambil server dari internet saat pertama kali, lalu disimpan.
            </div>

            <div class="card">
                <div class="card-header"><h3 class="card-title">2. Tambah tarif ke kota</h3></div>
                <div class="card-body">
                    <form method="post" class="js-once" id="addRateForm" novalidate>
                        <?php echo csrf_field(); ?>
                        <input type="hidden" name="action" value="add_rate">
                        <input type="hidden" name="carrier_id" value="<?php echo (int) $carrierId; ?>">
                        <div class="form-row">
                            <div class="form-group col-md-3">
                                <label for="r_prov">Provinsi <span class="text-danger">*</span></label>
                                <select id="r_prov" name="province" class="custom-select"><option value="">Memuat provinsi…</option></select>
                                <input type="text" id="r_prov_txt" name="province" class="form-control" maxlength="100"
                                       autocomplete="off" placeholder="Ketik provinsi" style="display:none" disabled>
                            </div>
                            <div class="form-group col-md-3">
                                <label for="r_city">Kota / kabupaten <span class="text-danger">*</span></label>
                                <select id="r_city" name="city" class="custom-select" disabled><option value="">Pilih provinsi dulu</option></select>
                                <input type="text" id="r_city_txt" name="city" class="form-control" maxlength="100"
                                       autocomplete="off" placeholder="Ketik kota / kabupaten" style="display:none" disabled>
                            </div>
                            <div class="form-group col-md-3">
                                <label for="r_price">Ongkos kirim <span class="text-danger">*</span></label>
                                <div class="input-group">
                                    <div class="input-group-prepend"><span class="input-group-text">Rp</span></div>
                                    <input type="number" id="r_price" name="price" class="form-control" min="0" step="1"
                                           inputmode="numeric" placeholder="15000" value="<?php echo e($form['price'] ?? ''); ?>">
                                </div>
                            </div>
                            <div class="form-group col-md-3 d-flex align-items-end">
                                <div class="custom-control custom-switch mb-2">
                                    <input type="checkbox" class="custom-control-input" id="r_active" name="is_active" value="1"
                                           <?php echo !empty($form['is_active']) ? 'checked' : ''; ?>>
                                    <label class="custom-control-label" for="r_active">Aktif</label>
                                </div>
                            </div>
                        </div>
                        <div class="mb-3 small">
                            <span id="r_region_msg"></span>
                            <a href="#" id="r_manual">Isi manual</a>
                        </div>
                        <button type="submit" class="btn btn-primary"><i class="fas fa-plus mr-1"></i> Simpan tarif</button>
                        <span class="nv-help ml-2">Harganya bisa diubah kapan saja lewat tombol Ubah di daftar.</span>
                    </form>
                </div>
            </div>

            <div class="card">
                <div class="card-header"><h3 class="card-title"><?php echo count($rates); ?> tarif</h3></div>
                <div class="card-body">
                    <?php if (!$rates): ?>
                        <div class="nv-empty"><i class="fas fa-map-marked-alt"></i>Belum ada tarif untuk <?php echo e($carrier['carrier_name']); ?>. Tambahkan kota tujuan pertama di atas.</div>
                    <?php else: ?>
                    <table id="ratesTable" class="table table-hover" style="width:100%">
                        <thead>
                            <tr>
                                <th>Provinsi</th>
                                <th>Kota / kabupaten</th>
                                <th>Ongkos kirim</th>
                                <th>Status</th>
                                <th class="text-right" data-orderable="false">Aksi</th>
                            </tr>
                        </thead>
                        <tbody>
                        <?php foreach ($rates as $r): ?>
                            <?php $ra = ((int) $r['is_active']) === 1; ?>
                            <tr>
                                <td><?php echo e($r['province']); ?></td>
                                <td><strong><?php echo e($r['city']); ?></strong></td>
                                <td data-order="<?php echo (int) $r['price']; ?>"><strong><?php echo e(formatRupiah($r['price'])); ?></strong></td>
                                <td><?php echo $ra ? badge('ok', 'Aktif') : badge('muted', 'Nonaktif'); ?></td>
                                <td>
                                    <div class="nv-actions">
                                        <button type="button" class="btn btn-sm btn-primary" title="Ubah tarif" data-toggle="modal" data-target="#rateModal"
                                                data-id="<?php echo (int) $r['rate_id']; ?>"
                                                data-province="<?php echo e($r['province']); ?>"
                                                data-city="<?php echo e($r['city']); ?>"
                                                data-price="<?php echo (int) $r['price']; ?>"
                                                data-active="<?php echo $ra ? '1' : '0'; ?>"><i class="fas fa-pen"></i> Ubah</button>
                                        <form method="post" class="js-once">
                                            <?php echo csrf_field(); ?>
                                            <input type="hidden" name="action" value="toggle_rate">
                                            <input type="hidden" name="carrier_id" value="<?php echo (int) $carrierId; ?>">
                                            <input type="hidden" name="rate_id" value="<?php echo (int) $r['rate_id']; ?>">
                                            <button type="submit" class="btn btn-sm btn-light-nv" title="<?php echo $ra ? 'Nonaktifkan' : 'Aktifkan'; ?>"><i class="fas <?php echo $ra ? 'fa-toggle-on' : 'fa-toggle-off'; ?>"></i></button>
                                        </form>
                                        <form method="post" onsubmit="return confirm('Hapus tarif ke &quot;<?php echo e(addslashes($r['city'])); ?>&quot;? Tindakan ini tidak bisa dibatalkan.');">
                                            <?php echo csrf_field(); ?>
                                            <input type="hidden" name="action" value="delete_rate">
                                            <input type="hidden" name="carrier_id" value="<?php echo (int) $carrierId; ?>">
                                            <input type="hidden" name="rate_id" value="<?php echo (int) $r['rate_id']; ?>">
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

<div class="modal fade" id="rateModal" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <form method="post" class="modal-content js-once" id="rateForm" style="border:0;border-radius:16px" novalidate>
            <div class="modal-header" style="border-bottom:1px solid #E6EBF3">
                <h5 class="modal-title font-weight-bold">Ubah tarif</h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Tutup">&times;</button>
            </div>
            <div class="modal-body">
                <?php echo csrf_field(); ?>
                <input type="hidden" name="action" value="update_rate">
                <input type="hidden" name="carrier_id" value="<?php echo (int) $carrierId; ?>">
                <input type="hidden" name="rate_id" id="m_rate_id">
                <div class="form-group">
                    <label for="m_prov">Provinsi <span class="text-danger">*</span></label>
                    <select id="m_prov" name="province" class="custom-select"><option value="">Memuat provinsi…</option></select>
                    <input type="text" id="m_prov_txt" name="province" class="form-control" maxlength="100" autocomplete="off" placeholder="Ketik provinsi" style="display:none" disabled>
                </div>
                <div class="form-group">
                    <label for="m_city">Kota / kabupaten <span class="text-danger">*</span></label>
                    <select id="m_city" name="city" class="custom-select" disabled><option value="">Pilih provinsi dulu</option></select>
                    <input type="text" id="m_city_txt" name="city" class="form-control" maxlength="100" autocomplete="off" placeholder="Ketik kota / kabupaten" style="display:none" disabled>
                </div>
                <div class="mb-3 small">
                    <span id="m_region_msg"></span>
                    <a href="#" id="m_manual">Isi manual</a>
                </div>
                <div class="form-group">
                    <label for="m_price">Ongkos kirim <span class="text-danger">*</span></label>
                    <div class="input-group">
                        <div class="input-group-prepend"><span class="input-group-text">Rp</span></div>
                        <input type="number" id="m_price" name="price" class="form-control" min="0" step="1" inputmode="numeric">
                    </div>
                </div>
                <div class="custom-control custom-switch">
                    <input type="checkbox" class="custom-control-input" id="m_active" name="is_active" value="1">
                    <label class="custom-control-label" for="m_active">Aktif</label>
                </div>
            </div>
            <div class="modal-footer" style="border-top:1px solid #E6EBF3">
                <button type="button" class="btn btn-light-nv" data-dismiss="modal">Batal</button>
                <button type="submit" class="btn btn-primary">Simpan perubahan</button>
            </div>
        </form>
    </div>
</div>

<?php
ob_start();
?>
<script>
$(function () {
    if ($('#ratesTable').length) {
        $('#ratesTable').DataTable({ autoWidth: false, order: [[0, 'asc'], [1, 'asc']] });
    }

    // ===== Pilihan wilayah berantai (provinsi -> kota/kabupaten) =====
    // Sumber dan penulisan nama sama dengan aplikasi (RegionRepository),
    // supaya cocok persis dengan alamat pelanggan saat checkout.
    // Browser meminta ke region.php (server PHP), karena emsifa.github.io memblokir CORS.
    var KEEP_UPPER = ['DKI', 'DI', 'NTB', 'NTT'];
    var regionCache = {};

    function titleCase(s) {
        return String(s).split(' ').map(function (w) {
            if (w === '' || KEEP_UPPER.indexOf(w) !== -1) { return w; }
            return w.charAt(0).toUpperCase() + w.slice(1).toLowerCase();
        }).join(' ');
    }

    function getRegions(path) {
        if (regionCache[path]) { return $.Deferred().resolve(regionCache[path]).promise(); }
        return $.ajax({ url: path, dataType: 'json', timeout: 25000 }).then(function (data) {
            var items = [];
            $.each(data, function (_, e) { items.push({ id: String(e.id), name: titleCase(e.name) }); });
            regionCache[path] = items;
            return items;
        });
    }

    function norm(s) { return String(s || '').toLowerCase().replace(/\s+/g, ' ').replace(/^ | $/g, ''); }
    function stripPrefix(s) { return norm(s).replace(/^(kabupaten|kota administrasi|kota adm\.|kota)\s+/, ''); }

    // Cari satu opsi yang cocok dengan nama. Cocok persis dulu, lalu tanpa awalan Kabupaten/Kota.
    function matchOption($sel, name) {
        var n = norm(name);
        if (n === '') { return null; }
        var exact = $sel.find('option').filter(function () { return this.value !== '' && norm(this.value) === n; });
        if (exact.length === 1) { return { $el: exact, loose: false }; }
        var s = stripPrefix(name);
        var loose = $sel.find('option').filter(function () { return this.value !== '' && stripPrefix(this.value) === s; });
        return loose.length === 1 ? { $el: loose, loose: true } : null;
    }

    function RegionPicker(px) {
        var $prov = $('#' + px + '_prov'), $city = $('#' + px + '_city');
        var $provT = $('#' + px + '_prov_txt'), $cityT = $('#' + px + '_city_txt');
        var $msg = $('#' + px + '_region_msg'), $manual = $('#' + px + '_manual');
        var manual = false, seq = 0, provPromise = null;

        function fill($sel, items, placeholder) {
            $sel.empty().append($('<option>').val('').text(placeholder));
            $.each(items, function (_, it) {
                $sel.append($('<option>').val(it.name).text(it.name).attr('data-id', it.id));
            });
        }
        function say(text, cls, actions) {
            $msg.empty().removeClass('text-danger text-muted text-warning').addClass(cls || 'text-muted');
            if (!text) { return; }
            $msg.append(document.createTextNode(text + ' '));
            $.each(actions || [], function (_, a) {
                $('<a href="#" class="mr-2"></a>').text(a.label).on('click', function (e) { e.preventDefault(); a.fn(); }).appendTo($msg);
            });
        }
        function resetCity(placeholder) {
            seq++;
            fill($city, [], placeholder);
            $city.prop('disabled', true);
        }

        function loadProvinces() {
            $prov.prop('disabled', true);
            fill($prov, [], 'Memuat provinsi…');
            resetCity('Pilih provinsi dulu');
            return getRegions('region.php?type=provinces').then(function (items) {
                fill($prov, items, 'Pilih provinsi');
                $prov.prop('disabled', false);
                return items;
            }, function () {
                fill($prov, [], 'Gagal memuat');
                say('Gagal memuat daftar provinsi (server perlu internet saat pertama kali).', 'text-danger', [
                    { label: 'Coba lagi', fn: function () { provPromise = null; ensureProvinces(); } },
                    { label: 'Isi manual', fn: function () { setManual(true); } }
                ]);
                return $.Deferred().reject().promise();
            });
        }
        function ensureProvinces() {
            if (!provPromise || provPromise.state() === 'rejected') { provPromise = loadProvinces(); }
            return provPromise;
        }
        function loadCities(provId) {
            var my = ++seq;
            $city.prop('disabled', true);
            fill($city, [], 'Memuat kota / kabupaten…');
            return getRegions('region.php?type=regencies&id=' + encodeURIComponent(provId)).then(function (items) {
                if (my === seq) {
                    fill($city, items, 'Pilih kota / kabupaten');
                    $city.prop('disabled', false);
                }
                return items;
            }, function () {
                if (my === seq) {
                    fill($city, [], 'Gagal memuat');
                    say('Gagal memuat kota / kabupaten.', 'text-danger', [
                        { label: 'Coba lagi', fn: function () { loadCities(provId); } },
                        { label: 'Isi manual', fn: function () { setManual(true); } }
                    ]);
                }
                return $.Deferred().reject().promise();
            });
        }

        function setManual(on) {
            if (on) {
                $provT.val($prov.val() || $provT.val());
                $cityT.val($city.val() || $cityT.val());
                $prov.hide().prop('disabled', true);
                $city.hide().prop('disabled', true);
                $provT.prop('disabled', false).show();
                $cityT.prop('disabled', false).show();
                $manual.text('Pakai daftar wilayah');
                say('Ketik persis seperti di alamat pelanggan, misalnya "Jawa Tengah" dan "Kabupaten Pemalang".', 'text-muted');
            } else {
                $provT.hide().prop('disabled', true);
                $cityT.hide().prop('disabled', true);
                $prov.show().prop('disabled', $prov.find('option').length < 2);
                $city.show().prop('disabled', $prov.val() === '' || $city.find('option').length < 2);
                $manual.text('Isi manual');
                say('');
            }
            manual = on;
        }

        $prov.on('change', function () {
            var id = $prov.find('option:selected').attr('data-id');
            say('');
            if (id) { loadCities(id); } else { resetCity('Pilih provinsi dulu'); }
        });
        $manual.on('click', function (e) { e.preventDefault(); setManual(!manual); });

        // Pilih provinsi dan kota berdasarkan nama tersimpan. Mengembalikan promise.
        function preselect(provName, cityName) {
            var done = $.Deferred();
            setManual(false);
            $prov.val('');
            resetCity('Pilih provinsi dulu');
            if ($.trim(provName) === '') {
                ensureProvinces();
                return done.resolve().promise();
            }
            ensureProvinces().then(function () {
                var m = matchOption($prov, provName);
                if (!m) {
                    say('Provinsi "' + provName + '" tidak ada di daftar wilayah. Pilih ulang.', 'text-warning');
                    done.resolve();
                    return;
                }
                $prov.val(m.$el.val());
                loadCities(m.$el.attr('data-id')).then(function () {
                    if ($.trim(cityName) === '') { return; }
                    var c = matchOption($city, cityName);
                    if (c) {
                        $city.val(c.$el.val());
                        if (c.loose || m.loose) {
                            say('Nama "' + cityName + '" dicocokkan dengan "' + c.$el.val() + '". Simpan supaya cocok dengan alamat pelanggan.', 'text-warning');
                        }
                    } else {
                        say('Kota "' + cityName + '" tidak ada di daftar wilayah, atau cocok dengan lebih dari satu. Pilih ulang.', 'text-warning');
                    }
                }).always(function () { done.resolve(); });
            }, function () { done.resolve(); });
            return done.promise();
        }

        function valid() {
            var ok;
            if (manual) {
                ok = $.trim($provT.val()) !== '' && $.trim($cityT.val()) !== '';
                if (!ok) { say('Provinsi dan kota wajib diisi.', 'text-danger'); }
            } else {
                ok = $prov.val() !== '' && $city.val() !== '';
                if (!ok) { say('Pilih provinsi, lalu kota / kabupaten.', 'text-danger'); }
            }
            return ok;
        }

        ensureProvinces();
        return { preselect: preselect, valid: valid };
    }

    var rp = RegionPicker('r');
    var mp = RegionPicker('m');

    // Form tambah: isi ulang pilihan (setelah error, atau provinsi terakhir yang dipakai)
    rp.preselect(
        <?php echo json_encode((string) ($form['province'] ?? ''), JSON_HEX_TAG | JSON_HEX_AMP); ?>,
        <?php echo json_encode((string) ($form['city'] ?? ''), JSON_HEX_TAG | JSON_HEX_AMP); ?>
    ).then(function () {
        if ($('#r_prov').val() !== '' && $('#r_city').val() === '' && !$('#r_city').prop('disabled')) {
            $('#r_city').trigger('focus');
        }
    });

    // Modal ubah
    $('#rateModal').on('show.bs.modal', function (ev) {
        var b = $(ev.relatedTarget);
        $('#m_rate_id').val(b.attr('data-id'));
        $('#m_price').val(b.attr('data-price'));
        $('#m_active').prop('checked', b.attr('data-active') === '1');
        mp.preselect(b.attr('data-province'), b.attr('data-city'));
    });

    // Validasi pilihan wilayah, lalu cegah klik ganda (urutan pemasangan penting)
    $('#addRateForm').on('submit', function (ev) {
        if (!rp.valid()) { ev.preventDefault(); ev.stopImmediatePropagation(); return false; }
    });
    $('#rateForm').on('submit', function (ev) {
        if (!mp.valid()) { ev.preventDefault(); ev.stopImmediatePropagation(); return false; }
    });
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

<?php
// File: admin/includes/promos_lib.php
// Validasi dan formulir kode promo. Aturan: tipe percentage = persen (1-100),
// free_shipping = nominal ongkir yang ditanggung (Rp). Batas pemakaian 0 = tanpa batas.

function promo_types()
{
    return ['percentage' => 'Diskon persen', 'free_shipping' => 'Gratis ongkir'];
}

function promo_read_input(array $src, PDO $conn, $ignoreId = 0)
{
    $errors = [];
    $t = function ($k) use ($src) { return trim((string) ($src[$k] ?? '')); };

    $code = strtoupper($t('code'));
    if (!preg_match('/^[A-Z0-9_-]{3,50}$/', $code)) {
        $errors[] = 'Kode promo 3–50 karakter: huruf, angka, tanda minus atau garis bawah.';
    } else {
        $dup = db_scalar($conn, 'SELECT COUNT(*) FROM promo_codes WHERE code = :c AND promo_id <> :id', [':c' => $code, ':id' => (int) $ignoreId]);
        if ((int) $dup > 0) { $errors[] = 'Kode promo "' . $code . '" sudah dipakai.'; }
    }

    $type = $t('type');
    if (!isset(promo_types()[$type])) { $errors[] = 'Jenis promo tidak valid.'; }

    $value = $t('value');
    if (!is_numeric($value) || $value <= 0) {
        $errors[] = 'Nilai promo harus lebih dari 0.';
    } elseif ($type === 'percentage' && $value > 100) {
        $errors[] = 'Diskon persen tidak boleh lebih dari 100.';
    }

    $from = DateTime::createFromFormat('Y-m-d', $t('valid_from'));
    $until = DateTime::createFromFormat('Y-m-d', $t('valid_until'));
    if (!$from || !$until) {
        $errors[] = 'Tanggal berlaku tidak valid.';
    } elseif ($until < $from) {
        $errors[] = 'Tanggal berakhir tidak boleh sebelum tanggal mulai.';
    }

    $limit = $t('usage_limit');
    if ($limit === '') { $limit = '0'; }
    if (!ctype_digit($limit)) { $errors[] = 'Batas pemakaian harus bilangan bulat 0 atau lebih.'; }

    return [[
        'code' => $code, 'type' => $type, 'value' => is_numeric($value) ? round((float) $value, 2) : 0,
        'description' => $t('description'), 'valid_from' => $from ? $from->format('Y-m-d') : null,
        'valid_until' => $until ? $until->format('Y-m-d') : null,
        'usage_limit' => ctype_digit($limit) ? (int) $limit : 0, 'is_active' => isset($src['is_active']) ? 1 : 0,
    ], $errors];
}

function render_promo_form(array $p, $submitLabel)
{
    $type = $p['type'] ?? 'percentage';
    ?>
    <div class="row">
        <div class="col-lg-8">
            <div class="card">
                <div class="card-header"><h3 class="card-title">Detail promo</h3></div>
                <div class="card-body">
                    <div class="form-group">
                        <label for="code">Kode promo <span class="nv-req">*</span></label>
                        <input type="text" id="code" name="code" class="form-control text-uppercase" maxlength="50" required value="<?php echo e($p['code'] ?? ''); ?>" placeholder="mis. HEMAT10">
                        <span class="nv-help">Otomatis menjadi huruf besar. Pelanggan mengetik kode ini saat checkout.</span>
                    </div>
                    <div class="row">
                        <div class="col-md-6 form-group">
                            <label for="promoType">Jenis <span class="nv-req">*</span></label>
                            <select name="type" id="promoType" class="custom-select" required>
                                <?php foreach (promo_types() as $k => $label): ?>
                                    <option value="<?php echo e($k); ?>" <?php echo $type === $k ? 'selected' : ''; ?>><?php echo e($label); ?></option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                        <div class="col-md-6 form-group">
                            <label for="promoValue">Nilai <span class="nv-req">*</span></label>
                            <div class="input-group">
                                <input type="number" name="value" id="promoValue" class="form-control" min="0" step="0.01" required value="<?php echo e($p['value'] ?? ''); ?>">
                                <div class="input-group-append"><span class="input-group-text" id="valueUnit">%</span></div>
                            </div>
                            <span class="nv-help" id="valueHelp"></span>
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="description">Deskripsi</label>
                        <textarea id="description" name="description" class="form-control" rows="3" placeholder="Keterangan singkat yang tampil untuk pelanggan"><?php echo e($p['description'] ?? ''); ?></textarea>
                    </div>
                    <div class="row">
                        <div class="col-md-6 form-group">
                            <label for="valid_from">Berlaku mulai <span class="nv-req">*</span></label>
                            <input type="date" id="valid_from" name="valid_from" class="form-control" required value="<?php echo e($p['valid_from'] ?? date('Y-m-d')); ?>">
                        </div>
                        <div class="col-md-6 form-group">
                            <label for="valid_until">Berlaku sampai <span class="nv-req">*</span></label>
                            <input type="date" id="valid_until" name="valid_until" class="form-control" required value="<?php echo e($p['valid_until'] ?? date('Y-m-d', strtotime('+1 month'))); ?>">
                        </div>
                    </div>
                    <div class="form-group mb-0">
                        <label for="usage_limit">Batas pemakaian</label>
                        <input type="number" id="usage_limit" name="usage_limit" class="form-control" min="0" step="1" value="<?php echo e($p['usage_limit'] ?? '0'); ?>">
                        <span class="nv-help">Isi 0 untuk pemakaian tanpa batas.</span>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-lg-4">
            <div class="card">
                <div class="card-header"><h3 class="card-title">Status</h3></div>
                <div class="card-body">
                    <div class="custom-control custom-switch">
                        <input type="checkbox" class="custom-control-input" id="is_active" name="is_active" value="1" <?php echo (!isset($p['is_active']) || !empty($p['is_active'])) ? 'checked' : ''; ?>>
                        <label class="custom-control-label" for="is_active">Aktif</label>
                    </div>
                    <span class="nv-help">Promo aktif bisa langsung dipakai pelanggan.</span>
                </div>
            </div>
            <button type="submit" class="btn btn-primary btn-block mb-2"><i class="fas fa-save mr-1"></i> <?php echo e($submitLabel); ?></button>
            <a href="promos.php" class="btn btn-light-nv btn-block">Batal</a>
        </div>
    </div>
    <?php
}

function promo_form_js()
{
    return <<<'HTML'
<script>
$(function () {
    function syncType() {
        var t = $('#promoType').val();
        if (t === 'percentage') {
            $('#valueUnit').text('%'); $('#promoValue').attr('max', 100);
            $('#valueHelp').text('Persentase diskon, mis. 10 untuk 10%.');
        } else {
            $('#valueUnit').text('Rp'); $('#promoValue').removeAttr('max');
            $('#valueHelp').text('Nominal ongkir yang ditanggung, mis. 15000.');
        }
    }
    $('#promoType').on('change', syncType); syncType();
});
</script>
HTML;
}

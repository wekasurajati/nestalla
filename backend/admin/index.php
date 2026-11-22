<?php
require_once 'includes/auth.php';
require_once 'includes/orders_lib.php';

$database = new Database();
$conn = $database->getConnection();

// ---------- Data ----------
$totalBooks     = (int) db_scalar($conn, 'SELECT COUNT(*) FROM books');
$totalCustomers = (int) db_scalar($conn, "SELECT COUNT(*) FROM users WHERE role = 'customer'");
$totalOrders    = (int) db_scalar($conn, 'SELECT COUNT(*) FROM orders');
$pendingOrders  = (int) db_scalar($conn, "SELECT COUNT(*) FROM orders WHERE status = 'pending'");
$activePromos   = (int) db_scalar($conn, 'SELECT COUNT(*) FROM promo_codes WHERE is_active = 1');
$revenue        = (float) db_scalar(
    $conn,
    "SELECT COALESCE(SUM(total_amount), 0) FROM orders WHERE (payment_status = 'paid' OR status = 'completed') AND status <> 'cancelled'"
);

$lowStock = db_rows($conn, 'SELECT book_id, title, author, stock FROM books WHERE stock <= 5 ORDER BY stock ASC, title ASC LIMIT 5');

$recent = db_rows(
    $conn,
    'SELECT o.order_id, o.order_number, o.total_amount, o.status, o.payment_status, o.created_at, u.full_name
     FROM orders o LEFT JOIN users u ON u.user_id = o.user_id
     ORDER BY o.created_at DESC LIMIT 6'
);

// Pesanan 7 hari terakhir
$perDay = [];
foreach (db_rows($conn, 'SELECT DATE(created_at) AS d, COUNT(*) AS c FROM orders WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 6 DAY) GROUP BY DATE(created_at)') as $r) {
    $perDay[$r['d']] = (int) $r['c'];
}
$dayLabels = [];
$dayCounts = [];
for ($i = 6; $i >= 0; $i--) {
    $ts = strtotime("-$i day");
    $dayLabels[] = date('d/m', $ts);
    $dayCounts[] = $perDay[date('Y-m-d', $ts)] ?? 0;
}

// Sebaran status
$toneColor = ['ok' => '#1E9E6A', 'warn' => '#E39A1B', 'info' => '#3066BE', 'bad' => '#D8453F', 'muted' => '#9AA5BB'];
$statusLabels = [];
$statusCounts = [];
$statusColors = [];
foreach (db_rows($conn, 'SELECT status, COUNT(*) AS c FROM orders GROUP BY status ORDER BY c DESC') as $r) {
    $statusLabels[] = status_label($r['status']);
    $statusCounts[] = (int) $r['c'];
    $statusColors[] = $toneColor[status_tone($r['status'])] ?? '#9AA5BB';
}

$hari = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
$bulan = ['', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
$today = $hari[(int) date('w')] . ', ' . date('j') . ' ' . $bulan[(int) date('n')] . ' ' . date('Y');

$page_title = 'Dashboard';
include 'includes/header.php';
include 'includes/sidebar.php';
?>

<div class="content-wrapper">
    <div class="content-header">
        <div class="container-fluid">
            <div class="nv-hello">
                <h2>Halo, <?php echo e($_SESSION['admin_name'] ?? 'Admin'); ?> 👋</h2>
                <p><?php echo e($today); ?> &middot; <?php echo $pendingOrders; ?> pesanan menunggu diproses.</p>
            </div>
        </div>
    </div>

    <section class="content">
        <div class="container-fluid">
            <?php echo flash_render(); ?>

            <div class="row">
                <div class="col-sm-6 col-xl-3 mb-3">
                    <div class="nv-stat">
                        <div class="nv-stat__icon nv-stat__icon--navy"><i class="fas fa-book-open"></i></div>
                        <div>
                            <div class="nv-stat__label">Total buku</div>
                            <div class="nv-stat__value"><?php echo number_format($totalBooks, 0, ',', '.'); ?></div>
                            <div class="nv-stat__hint"><?php echo count($lowStock); ?> buku stok menipis</div>
                        </div>
                    </div>
                </div>
                <div class="col-sm-6 col-xl-3 mb-3">
                    <div class="nv-stat">
                        <div class="nv-stat__icon nv-stat__icon--sky"><i class="fas fa-receipt"></i></div>
                        <div>
                            <div class="nv-stat__label">Total pesanan</div>
                            <div class="nv-stat__value"><?php echo number_format($totalOrders, 0, ',', '.'); ?></div>
                            <div class="nv-stat__hint"><?php echo $pendingOrders; ?> menunggu</div>
                        </div>
                    </div>
                </div>
                <div class="col-sm-6 col-xl-3 mb-3">
                    <div class="nv-stat">
                        <div class="nv-stat__icon nv-stat__icon--amber"><i class="fas fa-users"></i></div>
                        <div>
                            <div class="nv-stat__label">Pelanggan</div>
                            <div class="nv-stat__value"><?php echo number_format($totalCustomers, 0, ',', '.'); ?></div>
                            <div class="nv-stat__hint"><?php echo $activePromos; ?> promo aktif</div>
                        </div>
                    </div>
                </div>
                <div class="col-sm-6 col-xl-3 mb-3">
                    <div class="nv-stat">
                        <div class="nv-stat__icon nv-stat__icon--green"><i class="fas fa-wallet"></i></div>
                        <div>
                            <div class="nv-stat__label">Pendapatan</div>
                            <div class="nv-stat__value"><?php echo e(formatRupiah($revenue)); ?></div>
                            <div class="nv-stat__hint">Pesanan lunas atau selesai</div>
                        </div>
                    </div>
                </div>
            </div>

            <div class="row">
                <div class="col-lg-8 mb-3">
                    <div class="card h-100">
                        <div class="card-header"><h3 class="card-title">Pesanan 7 hari terakhir</h3></div>
                        <div class="card-body">
                            <?php if ($totalOrders === 0): ?>
                                <div class="nv-empty"><i class="fas fa-chart-column"></i>Belum ada pesanan untuk ditampilkan.</div>
                            <?php else: ?>
                                <div style="height:260px"><canvas id="chartDays"></canvas></div>
                            <?php endif; ?>
                        </div>
                    </div>
                </div>
                <div class="col-lg-4 mb-3">
                    <div class="card h-100">
                        <div class="card-header"><h3 class="card-title">Status pesanan</h3></div>
                        <div class="card-body">
                            <?php if ($totalOrders === 0): ?>
                                <div class="nv-empty"><i class="fas fa-chart-pie"></i>Belum ada data.</div>
                            <?php else: ?>
                                <div style="height:260px"><canvas id="chartStatus"></canvas></div>
                            <?php endif; ?>
                        </div>
                    </div>
                </div>
            </div>

            <div class="row">
                <div class="col-lg-8 mb-3">
                    <div class="card h-100">
                        <div class="card-header d-flex align-items-center justify-content-between">
                            <h3 class="card-title mb-0">Pesanan terbaru</h3>
                            <a href="orders.php" class="btn btn-sm btn-light-nv">Lihat semua</a>
                        </div>
                        <div class="card-body p-0">
                            <?php if (!$recent): ?>
                                <div class="nv-empty"><i class="fas fa-receipt"></i>Belum ada pesanan.</div>
                            <?php else: ?>
                                <div class="table-responsive">
                                    <table class="table table-hover mb-0">
                                        <thead><tr><th>Pesanan</th><th>Pelanggan</th><th>Total</th><th>Status</th></tr></thead>
                                        <tbody>
                                        <?php foreach ($recent as $o): ?>
                                            <tr>
                                                <td>
                                                    <a href="orders-detail.php?id=<?php echo (int) $o['order_id']; ?>"><strong><?php echo e($o['order_number']); ?></strong></a>
                                                    <br><small class="text-muted"><?php echo e(formatTanggal($o['created_at'])); ?></small>
                                                </td>
                                                <td><?php echo e($o['full_name'] ?? 'Pelanggan'); ?></td>
                                                <td><strong><?php echo e(formatRupiah($o['total_amount'])); ?></strong></td>
                                                <td><?php echo badge(status_tone($o['status']), status_label($o['status'])); ?></td>
                                            </tr>
                                        <?php endforeach; ?>
                                        </tbody>
                                    </table>
                                </div>
                            <?php endif; ?>
                        </div>
                    </div>
                </div>
                <div class="col-lg-4 mb-3">
                    <div class="card h-100">
                        <div class="card-header d-flex align-items-center justify-content-between">
                            <h3 class="card-title mb-0">Stok menipis</h3>
                            <a href="books.php" class="btn btn-sm btn-light-nv">Kelola buku</a>
                        </div>
                        <div class="card-body">
                            <?php if (!$lowStock): ?>
                                <div class="nv-empty"><i class="fas fa-circle-check"></i>Semua stok aman.</div>
                            <?php else: ?>
                                <?php foreach ($lowStock as $b): ?>
                                    <div class="nv-kv">
                                        <span><strong class="text-dark"><?php echo e($b['title']); ?></strong><br><small><?php echo e($b['author']); ?></small></span>
                                        <span><?php echo badge((int) $b['stock'] === 0 ? 'bad' : 'warn', (int) $b['stock'] === 0 ? 'Habis' : 'Sisa ' . (int) $b['stock']); ?></span>
                                    </div>
                                <?php endforeach; ?>
                            <?php endif; ?>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>
</div>

<?php
$flags = JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT | JSON_UNESCAPED_UNICODE;
ob_start();
?>
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
<script>
(function () {
    if (typeof Chart === 'undefined') { return; }
    Chart.defaults.font.family = "'Plus Jakarta Sans', system-ui, sans-serif";
    Chart.defaults.color = '#6B778F';

    var days = document.getElementById('chartDays');
    if (days) {
        new Chart(days, {
            type: 'bar',
            data: {
                labels: <?php echo json_encode($dayLabels, $flags); ?>,
                datasets: [{ label: 'Pesanan', data: <?php echo json_encode($dayCounts, $flags); ?>,
                             backgroundColor: '#3066BE', borderRadius: 8, maxBarThickness: 38 }]
            },
            options: {
                maintainAspectRatio: false,
                plugins: { legend: { display: false } },
                scales: { y: { beginAtZero: true, ticks: { precision: 0 }, grid: { color: '#EEF1F7' } }, x: { grid: { display: false } } }
            }
        });
    }

    var status = document.getElementById('chartStatus');
    if (status) {
        new Chart(status, {
            type: 'doughnut',
            data: {
                labels: <?php echo json_encode($statusLabels, $flags); ?>,
                datasets: [{ data: <?php echo json_encode($statusCounts, $flags); ?>,
                             backgroundColor: <?php echo json_encode($statusColors, $flags); ?>, borderWidth: 0 }]
            },
            options: { maintainAspectRatio: false, cutout: '68%', plugins: { legend: { position: 'bottom' } } }
        });
    }
})();
</script>
<?php
$extra_js = ob_get_clean();
include 'includes/footer.php';

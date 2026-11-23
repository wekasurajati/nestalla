<?php
$current = basename($_SERVER['PHP_SELF']);
$menu = [
    ['label' => null, 'items' => [
        ['Dashboard', 'fa-chart-pie', 'index.php', ['index.php']],
    ]],
    ['label' => 'Katalog', 'items' => [
        ['Buku', 'fa-book-open', 'books.php', ['books.php', 'books-add.php', 'books-edit.php']],
    ]],
    ['label' => 'Penjualan', 'items' => [
        ['Pesanan', 'fa-receipt', 'orders.php', ['orders.php', 'orders-detail.php']],
        ['Kode Promo', 'fa-ticket-alt', 'promos.php', ['promos.php', 'promos-add.php', 'promos-edit.php']],
    ]],
    ['label' => 'Pelanggan', 'items' => [
        ['Pengguna', 'fa-users', 'users.php', ['users.php']],
        ['Testimoni', 'fa-comment-dots', 'testimonials.php', ['testimonials.php']],
    ]],
];
?>
    <aside class="main-sidebar nv-sidebar elevation-0">
        <a href="index.php" class="brand-link">
            <img class="nv-brand-full" src="../assets/nestalla-logo.png" alt="Nestalla Online Bookstore">
            <img class="nv-brand-mark" src="../assets/nestalla-mark.png" alt="Nestalla">
            <span class="nv-brand-tag">ADMIN</span>
        </a>
        <div class="sidebar">
            <nav>
                <ul class="nav nav-pills nav-sidebar flex-column" role="menu">
                    <?php foreach ($menu as $group): ?>
                        <?php if ($group['label']): ?>
                            <li class="nv-nav-label"><?php echo e($group['label']); ?></li>
                        <?php endif; ?>
                        <?php foreach ($group['items'] as $item): ?>
                            <li class="nav-item">
                                <a href="<?php echo e($item[2]); ?>" class="nav-link <?php echo in_array($current, $item[3], true) ? 'active' : ''; ?>">
                                    <i class="nav-icon fas <?php echo e($item[1]); ?>"></i>
                                    <p><?php echo e($item[0]); ?></p>
                                </a>
                            </li>
                        <?php endforeach; ?>
                    <?php endforeach; ?>
                    <li class="nv-nav-label">Akun</li>
                    <li class="nav-item">
                        <a href="logout.php" class="nav-link">
                            <i class="nav-icon fas fa-sign-out-alt"></i>
                            <p>Keluar</p>
                        </a>
                    </li>
                </ul>
            </nav>
        </div>
    </aside>

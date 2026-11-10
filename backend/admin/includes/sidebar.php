<!-- Main Sidebar Container -->
<aside class="main-sidebar sidebar-dark-primary elevation-4">
    <!-- Brand Logo -->
    <a href="index.php" class="brand-link">
        <i class="fas fa-book brand-image" style="font-size: 2rem; opacity: .8"></i>
        <span class="brand-text font-weight-light">Letterbook Admin</span>
    </a>

    <!-- Sidebar -->
    <div class="sidebar">
        <!-- Sidebar user panel -->
        <div class="user-panel mt-3 pb-3 mb-3 d-flex">
            <div class="image">
                <i class="fas fa-user-circle" style="font-size: 2.1rem; color: #c2c7d0;"></i>
            </div>
            <div class="info">
                <a href="#" class="d-block"><?php echo $_SESSION['admin_name']; ?></a>
            </div>
        </div>

        <!-- Sidebar Menu -->
        <nav class="mt-2">
            <ul class="nav nav-pills nav-sidebar flex-column" data-widget="treeview" role="menu" data-accordion="false">
                
                <!-- Dashboard -->
                <li class="nav-item">
                    <a href="index.php" class="nav-link <?php echo (basename($_SERVER['PHP_SELF']) == 'index.php') ? 'active' : ''; ?>">
                        <i class="nav-icon fas fa-tachometer-alt"></i>
                        <p>Dashboard</p>
                    </a>
                </li>

                <!-- Books Management -->
                <li class="nav-item">
                    <a href="books.php" class="nav-link <?php echo (basename($_SERVER['PHP_SELF']) == 'books.php') ? 'active' : ''; ?>">
                        <i class="nav-icon fas fa-book"></i>
                        <p>Books</p>
                    </a>
                </li>

                <!-- Orders Management -->
                <li class="nav-item">
                    <a href="orders.php" class="nav-link <?php echo (basename($_SERVER['PHP_SELF']) == 'orders.php') ? 'active' : ''; ?>">
                        <i class="nav-icon fas fa-shopping-cart"></i>
                        <p>Orders</p>
                    </a>
                </li>

                <!-- Users Management -->
                <li class="nav-item">
                    <a href="users.php" class="nav-link <?php echo (basename($_SERVER['PHP_SELF']) == 'users.php') ? 'active' : ''; ?>">
                        <i class="nav-icon fas fa-users"></i>
                        <p>Users</p>
                    </a>
                </li>

                <!-- Promo Codes -->
                <li class="nav-item">
                    <a href="promos.php" class="nav-link <?php echo (basename($_SERVER['PHP_SELF']) == 'promos.php') ? 'active' : ''; ?>">
                        <i class="nav-icon fas fa-tag"></i>
                        <p>Promo Codes</p>
                    </a>
                </li>

                <!-- Testimonial -->
                 <li class="nav-item">
                <a href="testimonials.php" class="nav-link <?php echo (basename($_SERVER['PHP_SELF']) == 'testimonials.php') ? 'active' : ''; ?>">
                    <i class="nav-icon fas fa-comments"></i>
                    <p>Testimonials</p>
                </a>
                </li>

                <!-- Divider -->
                <li class="nav-header">SETTINGS</li>

                <!-- Settings -->
                <li class="nav-item">
                    <a href="settings.php" class="nav-link">
                        <i class="nav-icon fas fa-cog"></i>
                        <p>Settings</p>
                    </a>
                </li>

                <!-- Logout -->
                <li class="nav-item">
                    <a href="logout.php" class="nav-link">
                        <i class="nav-icon fas fa-sign-out-alt"></i>
                        <p>Logout</p>
                    </a>
                </li>

            </ul>
        </nav>
        <!-- /.sidebar-menu -->
    </div>
    <!-- /.sidebar -->
</aside>
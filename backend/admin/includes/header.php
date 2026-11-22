<?php
// Dipakai semua halaman admin. Set $page_title sebelum include.
if (!function_exists('e')) {
    function e($value) { return htmlspecialchars((string) $value, ENT_QUOTES, 'UTF-8'); }
}
$admin_name = $_SESSION['admin_name'] ?? 'Admin';
$initial = strtoupper(function_exists('mb_substr') ? mb_substr($admin_name, 0, 1) : substr($admin_name, 0, 1));
?>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><?php echo isset($page_title) ? e($page_title) . ' - ' : ''; ?>Nestalla Admin</title>

    <link rel="icon" type="image/png" href="../assets/nestalla-mark.png">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="../assets/adminlte/plugins/fontawesome-free/css/all.min.css">
    <link rel="stylesheet" href="../assets/adminlte/dist/css/adminlte.min.css">
    <link rel="stylesheet" href="../assets/adminlte/plugins/datatables-bs4/css/dataTables.bootstrap4.min.css">
    <link rel="stylesheet" href="../assets/nestalla-admin.css?v=2">
</head>
<body class="hold-transition sidebar-mini layout-fixed layout-navbar-fixed">
<div class="wrapper">

    <nav class="main-header navbar navbar-expand navbar-white navbar-light">
        <ul class="navbar-nav">
            <li class="nav-item">
                <a class="nav-link" data-widget="pushmenu" href="#" role="button" aria-label="Buka atau tutup menu"><i class="fas fa-bars"></i></a>
            </li>
        </ul>
        <ul class="navbar-nav ml-auto">
            <li class="nav-item dropdown">
                <a class="nav-link nv-user" data-toggle="dropdown" href="#">
                    <span class="nv-avatar"><?php echo e($initial); ?></span>
                    <span class="d-none d-md-block text-left">
                        <strong><?php echo e($admin_name); ?></strong>
                        <small>@<?php echo e($_SESSION['admin_username'] ?? 'admin'); ?></small>
                    </span>
                </a>
                <div class="dropdown-menu dropdown-menu-right">
                    <span class="dropdown-item-text text-muted small">Masuk sebagai <?php echo e($_SESSION['admin_username'] ?? 'admin'); ?></span>
                    <div class="dropdown-divider"></div>
                    <a href="logout.php" class="dropdown-item"><i class="fas fa-sign-out-alt mr-2"></i> Keluar</a>
                </div>
            </li>
        </ul>
    </nav>

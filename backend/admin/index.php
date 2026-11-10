<?php
require_once 'includes/auth.php';

$database = new Database();
$conn = $database->getConnection();

// Get statistics
$query_books = "SELECT COUNT(*) as total FROM books";
$stmt_books = $conn->prepare($query_books);
$stmt_books->execute();
$total_books = $stmt_books->fetch(PDO::FETCH_ASSOC)['total'];

$query_orders = "SELECT COUNT(*) as total FROM orders";
$stmt_orders = $conn->prepare($query_orders);
$stmt_orders->execute();
$total_orders = $stmt_orders->fetch(PDO::FETCH_ASSOC)['total'];

$query_users = "SELECT COUNT(*) as total FROM users WHERE role = 'customer'";
$stmt_users = $conn->prepare($query_users);
$stmt_users->execute();
$total_users = $stmt_users->fetch(PDO::FETCH_ASSOC)['total'];

$query_promos = "SELECT COUNT(*) as total FROM promo_codes WHERE is_active = TRUE";
$stmt_promos = $conn->prepare($query_promos);
$stmt_promos->execute();
$total_promos = $stmt_promos->fetch(PDO::FETCH_ASSOC)['total'];

// Total revenue
$query_revenue = "SELECT SUM(total_amount) as total FROM orders WHERE status = 'completed'";
$stmt_revenue = $conn->prepare($query_revenue);
$stmt_revenue->execute();
$total_revenue = $stmt_revenue->fetch(PDO::FETCH_ASSOC)['total'] ?? 0;

// Recent orders
$query_recent = "SELECT o.*, u.full_name FROM orders o 
                 LEFT JOIN users u ON o.user_id = u.user_id 
                 ORDER BY o.created_at DESC LIMIT 5";
$stmt_recent = $conn->prepare($query_recent);
$stmt_recent->execute();
$recent_orders = $stmt_recent->fetchAll(PDO::FETCH_ASSOC);

$page_title = "Dashboard";
include 'includes/header.php';
include 'includes/sidebar.php';
?>

<!-- Content Wrapper -->
<div class="content-wrapper">
    <!-- Content Header -->
    <div class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h1 class="m-0">Dashboard</h1>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item active">Dashboard</li>
                    </ol>
                </div>
            </div>
        </div>
    </div>

    <!-- Main content -->
    <section class="content">
        <div class="container-fluid">
            
            <!-- Info boxes -->
            <div class="row">
                <div class="col-lg-3 col-6">
                    <div class="small-box bg-info">
                        <div class="inner">
                            <h3><?php echo $total_books; ?></h3>
                            <p>Total Books</p>
                        </div>
                        <div class="icon">
                            <i class="fas fa-book"></i>
                        </div>
                        <a href="books.php" class="small-box-footer">More info <i class="fas fa-arrow-circle-right"></i></a>
                    </div>
                </div>

                <div class="col-lg-3 col-6">
                    <div class="small-box bg-success">
                        <div class="inner">
                            <h3><?php echo $total_orders; ?></h3>
                            <p>Total Orders</p>
                        </div>
                        <div class="icon">
                            <i class="fas fa-shopping-cart"></i>
                        </div>
                        <a href="orders.php" class="small-box-footer">More info <i class="fas fa-arrow-circle-right"></i></a>
                    </div>
                </div>

                <div class="col-lg-3 col-6">
                    <div class="small-box bg-warning">
                        <div class="inner">
                            <h3><?php echo $total_users; ?></h3>
                            <p>Total Users</p>
                        </div>
                        <div class="icon">
                            <i class="fas fa-users"></i>
                        </div>
                        <a href="users.php" class="small-box-footer">More info <i class="fas fa-arrow-circle-right"></i></a>
                    </div>
                </div>

                <div class="col-lg-3 col-6">
                    <div class="small-box bg-danger">
                        <div class="inner">
                            <h3><?php echo $total_promos; ?></h3>
                            <p>Active Promos</p>
                        </div>
                        <div class="icon">
                            <i class="fas fa-tag"></i>
                        </div>
                        <a href="promos.php" class="small-box-footer">More info <i class="fas fa-arrow-circle-right"></i></a>
                    </div>
                </div>
            </div>

            <!-- Revenue Card -->
            <div class="row">
                <div class="col-md-12">
                    <div class="card">
                        <div class="card-header">
                            <h3 class="card-title"><i class="fas fa-dollar-sign"></i> Total Revenue</h3>
                        </div>
                        <div class="card-body">
                            <h2 class="text-success"><?php echo formatRupiah($total_revenue); ?></h2>
                            <p class="text-muted">From completed orders</p>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Recent Orders -->
            <div class="row">
                <div class="col-md-12">
                    <div class="card">
                        <div class="card-header">
                            <h3 class="card-title"><i class="fas fa-list"></i> Recent Orders</h3>
                        </div>
                        <div class="card-body p-0">
                            <table class="table table-striped">
                                <thead>
                                    <tr>
                                        <th>Order Number</th>
                                        <th>Customer</th>
                                        <th>Total</th>
                                        <th>Status</th>
                                        <th>Date</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php if(count($recent_orders) > 0): ?>
                                        <?php foreach($recent_orders as $order): ?>
                                        <tr>
                                            <td><?php echo $order['order_number']; ?></td>
                                            <td><?php echo $order['customer_name'] ?? 'Guest'; ?></td>
                                            <td><?php echo formatRupiah($order['total_amount']); ?></td>
                                            <td>
                                                <?php
                                                $badge_class = '';
                                                switch($order['status']) {
                                                    case 'pending': $badge_class = 'warning'; break;
                                                    case 'processing': $badge_class = 'info'; break;
                                                    case 'completed': $badge_class = 'success'; break;
                                                    case 'cancelled': $badge_class = 'danger'; break;
                                                }
                                                ?>
                                                <span class="badge badge-<?php echo $badge_class; ?>">
                                                    <?php echo ucfirst($order['status']); ?>
                                                </span>
                                            </td>
                                            <td><?php echo formatTanggal($order['created_at']); ?></td>
                                        </tr>
                                        <?php endforeach; ?>
                                    <?php else: ?>
                                        <tr>
                                            <td colspan="5" class="text-center">No orders yet</td>
                                        </tr>
                                    <?php endif; ?>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>

        </div>
    </section>
</div>

<?php include 'includes/footer.php'; ?>

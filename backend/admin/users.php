<?php
require_once 'includes/auth.php';

$database = new Database();
$conn = $database->getConnection();

// Get all users (customers only)
$query = "SELECT * FROM users WHERE role = 'customer' ORDER BY created_at DESC";
$stmt = $conn->prepare($query);
$stmt->execute();
$users = $stmt->fetchAll(PDO::FETCH_ASSOC);

$page_title = "Users Management";
include 'includes/header.php';
include 'includes/sidebar.php';
?>

<!-- Content Wrapper -->
<div class="content-wrapper">
    <!-- Content Header -->
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h1><i class="fas fa-users"></i> Users Management</h1>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item"><a href="index.php">Home</a></li>
                        <li class="breadcrumb-item active">Users</li>
                    </ol>
                </div>
            </div>
        </div>
    </section>

    <!-- Main content -->
    <section class="content">
        <div class="container-fluid">
            
            <div class="card">
                <div class="card-header">
                    <h3 class="card-title">All Customers</h3>
                </div>
                <div class="card-body">
                    <table id="usersTable" class="table table-bordered table-striped datatable">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Name</th>
                                <th>Email</th>
                                <th>Phone</th>
                                <th>Registered</th>
                                <th>Orders</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach($users as $user): ?>
                            <?php
                            // Get user's order count
                            $query_orders = "SELECT COUNT(*) as total FROM orders WHERE user_id = :user_id";
                            $stmt_orders = $conn->prepare($query_orders);
                            $stmt_orders->bindParam(':user_id', $user['user_id']);
                            $stmt_orders->execute();
                            $order_count = $stmt_orders->fetch(PDO::FETCH_ASSOC)['total'];
                            ?>
                            <tr>
                                <td><?php echo $user['user_id']; ?></td>
                                <td>
                                    <strong><?php echo htmlspecialchars($user['full_name']); ?></strong>
                                    <br><small class="text-muted">@<?php echo htmlspecialchars($user['username']); ?></small>
                                </td>
                                <td>
                                    <i class="fas fa-envelope"></i>
                                    <?php echo htmlspecialchars($user['email']); ?>
                                </td>
                                <td>
                                    <?php if($user['phone']): ?>
                                        <i class="fas fa-phone"></i>
                                        <?php echo htmlspecialchars($user['phone']); ?>
                                    <?php else: ?>
                                        <span class="text-muted">-</span>
                                    <?php endif; ?>
                                </td>
                                <td><?php echo formatTanggal($user['created_at']); ?></td>
                                <td>
                                    <?php if($order_count > 0): ?>
                                        <span class="badge badge-success"><?php echo $order_count; ?> orders</span>
                                    <?php else: ?>
                                        <span class="badge badge-secondary">No orders</span>
                                    <?php endif; ?>
                                </td>
                                <td>
                                    <a href="users-detail.php?id=<?php echo $user['user_id']; ?>" 
                                       class="btn btn-info btn-sm"
                                       title="View Details">
                                        <i class="fas fa-eye"></i>
                                    </a>
                                </td>
                            </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            </div>

        </div>
    </section>
</div>

<?php include 'includes/footer.php'; ?>
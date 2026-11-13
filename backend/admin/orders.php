<?php
require_once 'includes/auth.php';

$database = new Database();
$conn = $database->getConnection();

$success = '';
$error = '';

// Handle Status Update WITH EMAIL
if(isset($_POST['update_status'])) {
    $order_id = $_POST['order_id'];
    $new_status = $_POST['status'];
    
    try {
        // Get order details first
        $query = "SELECT * FROM orders WHERE order_id = :order_id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':order_id', $order_id);
        $stmt->execute();
        $order_info = $stmt->fetch(PDO::FETCH_ASSOC);
        
        // Update status
        $query = "UPDATE orders SET status = :status, updated_at = NOW() WHERE order_id = :id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':status', $new_status);
        $stmt->bindParam(':id', $order_id);
        
        if($stmt->execute()) {
            // Send email notification
            try {
                require_once '../config/email.php';
                $emailService = new EmailService();
                $emailService->sendOrderStatusUpdate(
                    $order_info['customer_email'],
                    $order_info['customer_name'],
                    $order_info['order_number'],
                    $new_status
                );
                
                $success = 'Order status updated and email sent successfully!';
            } catch (Exception $e) {
                error_log('Failed to send status update email: ' . $e->getMessage());
                $success = 'Order status updated (email notification failed)';
            }
        }
    } catch(Exception $e) {
        $error = 'Error updating status: ' . $e->getMessage();
    }
}

// Get all orders with user info
$query = "SELECT o.*, u.full_name, u.email 
          FROM orders o 
          LEFT JOIN users u ON o.user_id = u.user_id 
          ORDER BY o.created_at DESC";
$stmt = $conn->prepare($query);
$stmt->execute();
$orders = $stmt->fetchAll(PDO::FETCH_ASSOC);

$page_title = "Orders Management";
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
                    <h1><i class="fas fa-shopping-cart"></i> Orders Management</h1>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item"><a href="index.php">Home</a></li>
                        <li class="breadcrumb-item active">Orders</li>
                    </ol>
                </div>
            </div>
        </div>
    </section>

    <!-- Main content -->
    <section class="content">
        <div class="container-fluid">
            
            <?php if($success): ?>
            <div class="alert alert-success alert-dismissible">
                <button type="button" class="close" data-dismiss="alert">&times;</button>
                <i class="icon fas fa-check"></i> <?php echo $success; ?>
            </div>
            <?php endif; ?>

            <?php if($error): ?>
            <div class="alert alert-danger alert-dismissible">
                <button type="button" class="close" data-dismiss="alert">&times;</button>
                <i class="icon fas fa-ban"></i> <?php echo $error; ?>
            </div>
            <?php endif; ?>

            <div class="card">
                <div class="card-header">
                    <h3 class="card-title">All Orders</h3>
                </div>
                <div class="card-body">
                    <table id="ordersTable" class="table table-bordered table-striped datatable">
                        <thead>
                            <tr>
                                <th>Order #</th>
                                <th>Customer</th>
                                <th>Total</th>
                                <th>Payment</th>
                                <th>Status</th>
                                <th>Date</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach($orders as $order): ?>
                            <tr>
                                <td>
                                    <strong><?php echo $order['order_number']; ?></strong>
                                </td>
                                <td>
                                    <strong><?php echo htmlspecialchars($order['customer_name']); ?></strong>
                                    <br><small class="text-muted"><?php echo htmlspecialchars($order['customer_email']); ?></small>
                                    <br><small class="text-muted"><?php echo htmlspecialchars($order['customer_phone']); ?></small>
                                </td>
                                <td>
                                    <strong><?php echo formatRupiah($order['total_amount']); ?></strong>
                                    <?php if($order['discount_amount'] > 0): ?>
                                        <br><small class="text-success">Discount: -<?php echo formatRupiah($order['discount_amount']); ?></small>
                                    <?php endif; ?>
                                </td>
                                <td>
                                    <?php 
                                    $payment_icons = [
                                        'bank' => 'fa-university',
                                        'ewallet' => 'fa-wallet',
                                        'cod' => 'fa-hand-holding-usd',
                                        'credit' => 'fa-credit-card'
                                    ];
                                    $icon = $payment_icons[$order['payment_method']] ?? 'fa-money-bill';
                                    ?>
                                    <i class="fas <?php echo $icon; ?>"></i>
                                    <?php echo ucfirst($order['payment_method']); ?>
                                </td>
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
                                <td>
                                    <?php echo formatTanggal($order['created_at']); ?>
                                </td>
                                <td>
                                    <div class="btn-group">
                                        <a href="orders-detail.php?id=<?php echo $order['order_id']; ?>" 
                                           class="btn btn-info btn-sm" 
                                           title="View Details">
                                            <i class="fas fa-eye"></i>
                                        </a>
                                        <button type="button" 
                                                class="btn btn-primary btn-sm" 
                                                data-toggle="modal" 
                                                data-target="#statusModal<?php echo $order['order_id']; ?>"
                                                title="Update Status">
                                            <i class="fas fa-edit"></i>
                                        </button>
                                    </div>

                                    

                                    <!-- Status Update Modal -->
                                    <div class="modal fade" id="statusModal<?php echo $order['order_id']; ?>">
                                        <div class="modal-dialog">
                                            <div class="modal-content">
                                                <div class="modal-header">
                                                    <h4 class="modal-title">Update Order Status</h4>
                                                    <button type="button" class="close" data-dismiss="modal">&times;</button>
                                                </div>
                                                <form method="POST">
                                                    <div class="modal-body">
                                                        <input type="hidden" name="order_id" value="<?php echo $order['order_id']; ?>">
                                                        <div class="form-group">
                                                            <label>Order Number:</label>
                                                            <p><strong><?php echo $order['order_number']; ?></strong></p>
                                                        </div>
                                                        <div class="form-group">
                                                            <label>New Status:</label>
                                                            <select name="status" class="form-control" required>
                                                                <option value="pending" <?php echo ($order['status'] == 'pending') ? 'selected' : ''; ?>>Pending</option>
                                                                <option value="processing" <?php echo ($order['status'] == 'processing') ? 'selected' : ''; ?>>Processing</option>
                                                                <option value="completed" <?php echo ($order['status'] == 'completed') ? 'selected' : ''; ?>>Completed</option>
                                                                <option value="cancelled" <?php echo ($order['status'] == 'cancelled') ? 'selected' : ''; ?>>Cancelled</option>
                                                            </select>
                                                        </div>
                                                    </div>
                                                    <div class="modal-footer">
                                                        <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                                                        <button type="submit" name="update_status" class="btn btn-primary">Update Status</button>
                                                    </div>
                                                </form>
                                            </div>
                                        </div>
                                    </div>
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
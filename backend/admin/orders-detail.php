<?php
require_once 'includes/auth.php';

$database = new Database();
$conn = $database->getConnection();

// ✅ HANDLE STATUS UPDATE WITH EMAIL
if (isset($_POST['update_status'])) {
    $order_id = intval($_POST['order_id']);
    $new_status = $_POST['status'];
    
    try {
        // Get order details first
        $query = "SELECT * FROM orders WHERE order_id = :order_id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':order_id', $order_id);
        $stmt->execute();
        $order_info = $stmt->fetch(PDO::FETCH_ASSOC);
        
        // Update status
        $query = "UPDATE orders SET status = :status WHERE order_id = :order_id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':status', $new_status);
        $stmt->bindParam(':order_id', $order_id);
        
        if ($stmt->execute()) {
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
                
                $_SESSION['success'] = 'Order status updated and email sent successfully!';
            } catch (Exception $e) {
                error_log('Failed to send status update email: ' . $e->getMessage());
                $_SESSION['success'] = 'Order status updated (email notification failed)';
            }
            
            header('Location: orders-detail.php?id=' . $order_id);
            exit();
        }
    } catch (Exception $e) {
        $_SESSION['error'] = 'Failed to update order status: ' . $e->getMessage();
    }
}

// Get order ID from URL
if(!isset($_GET['id'])) {
    header("Location: orders.php");
    exit;
}

$order_id = $_GET['id'];

// Get order data
$query = "SELECT o.*, u.full_name, u.email 
          FROM orders o 
          LEFT JOIN users u ON o.user_id = u.user_id 
          WHERE o.order_id = :id";
$stmt = $conn->prepare($query);
$stmt->bindParam(':id', $order_id);
$stmt->execute();
$order = $stmt->fetch(PDO::FETCH_ASSOC);

if(!$order) {
    header("Location: orders.php");
    exit;
}

// Get order items
$query = "SELECT oi.*, b.title, b.author, b.image 
          FROM order_items oi 
          LEFT JOIN books b ON oi.book_id = b.book_id 
          WHERE oi.order_id = :id";
$stmt = $conn->prepare($query);
$stmt->bindParam(':id', $order_id);
$stmt->execute();
$order_items = $stmt->fetchAll(PDO::FETCH_ASSOC);
$page_title = "Order Detail";
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
                    <h1><i class="fas fa-file-invoice"></i> Order Detail</h1>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item"><a href="index.php">Home</a></li>
                        <li class="breadcrumb-item"><a href="orders.php">Orders</a></li>
                        <li class="breadcrumb-item active">Detail</li>
                    </ol>
                </div>
            </div>
        </div>
    </section>

    <!-- Main content -->
    <section class="content">
        <div class="container-fluid">
            
            <?php if (isset($_SESSION['success'])): ?>
                <div class="alert alert-success alert-dismissible fade show">
                    <button type="button" class="close" data-dismiss="alert">&times;</button>
                    <?php 
                        echo $_SESSION['success']; 
                        unset($_SESSION['success']);
                    ?>
                </div>
            <?php endif; ?>

            <?php if (isset($_SESSION['error'])): ?>
                <div class="alert alert-danger alert-dismissible fade show">
                    <button type="button" class="close" data-dismiss="alert">&times;</button>
                    <?php 
                        echo $_SESSION['error']; 
                        unset($_SESSION['error']);
                    ?>
                </div>
            <?php endif; ?>
            
            <div class="row">
                <!-- Order Information -->
                <div class="col-md-8">
                    
                    <!-- Order Header -->
                    <div class="card">
                        <div class="card-header">
                            <h3 class="card-title">
                                <i class="fas fa-info-circle"></i> Order Information
                            </h3>
                            <div class="card-tools">
                                <?php
                                $badge_class = '';
                                switch($order['status']) {
                                    case 'pending': $badge_class = 'warning'; break;
                                    case 'processing': $badge_class = 'info'; break;
                                    case 'completed': $badge_class = 'success'; break;
                                    case 'cancelled': $badge_class = 'danger'; break;
                                }
                                ?>
                                <span class="badge badge-<?php echo $badge_class; ?> badge-lg">
                                    <?php echo ucfirst($order['status']); ?>
                                </span>
                            </div>
                        </div>
                        <div class="card-body">
                            <div class="row">
                                <div class="col-md-6">
                                    <p><strong>Order Number:</strong><br>
                                    <span class="text-primary"><?php echo $order['order_number']; ?></span></p>
                                    
                                    <p><strong>Order Date:</strong><br>
                                    <?php echo formatTanggal($order['created_at']); ?></p>
                                    
                                    <p><strong>Payment Method:</strong><br>
                                    <?php 
                                    $payment_icons = [
                                        'bank' => 'fa-university',
                                        'ewallet' => 'fa-wallet',
                                        'cod' => 'fa-hand-holding-usd',
                                        'credit' => 'fa-credit-card'
                                    ];
                                    $icon = $payment_icons[$order['payment_method']] ?? 'fa-money-bill';
                                    ?>
                                    <i class="fas <?php echo $icon; ?>"></i> <?php echo ucfirst($order['payment_method']); ?>
                                    </p>
                                </div>
                                <div class="col-md-6">
                                    <?php if($order['promo_code']): ?>
                                    <p><strong>Promo Code:</strong><br>
                                    <span class="badge badge-success"><?php echo $order['promo_code']; ?></span></p>
                                    <?php endif; ?>
                                    
                                    <?php if($order['notes']): ?>
                                    <p><strong>Order Notes:</strong><br>
                                    <?php echo nl2br(htmlspecialchars($order['notes'])); ?></p>
                                    <?php endif; ?>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Order Items -->
                    <div class="card">
                        <div class="card-header">
                            <h3 class="card-title">
                                <i class="fas fa-shopping-bag"></i> Order Items
                            </h3>
                        </div>
                        <div class="card-body p-0">
                            <table class="table table-striped">
                                <thead>
                                    <tr>
                                        <th>Book</th>
                                        <th>Price</th>
                                        <th>Quantity</th>
                                        <th>Subtotal</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php foreach($order_items as $item): ?>
                                    <tr>
                                        <td>
                                            <div class="d-flex align-items-center">
                                                <?php if(!empty($item['image'])): ?>
                                                <img src="../<?php echo $item['image']; ?>" 
                                                     alt="<?php echo htmlspecialchars($item['title']); ?>"
                                                     style="width: 50px; height: auto; margin-right: 15px; border-radius: 5px;">
                                                <?php endif; ?>
                                                <div>
                                                    <strong><?php echo htmlspecialchars($item['title']); ?></strong>
                                                    <br><small class="text-muted">by <?php echo htmlspecialchars($item['author']); ?></small>
                                                </div>
                                            </div>
                                        </td>
                                        <td><?php echo formatRupiah($item['price']); ?></td>
                                        <td><span class="badge badge-secondary"><?php echo $item['quantity']; ?></span></td>
                                        <td><strong><?php echo formatRupiah($item['subtotal']); ?></strong></td>
                                    </tr>
                                    <?php endforeach; ?>
                                </tbody>
                            </table>
                        </div>
                    </div>

                    <!-- Shipping Address -->
                    <div class="card">
                        <div class="card-header">
                            <h3 class="card-title">
                                <i class="fas fa-map-marker-alt"></i> Shipping Address
                            </h3>
                        </div>
                        <div class="card-body">
                            <p><strong><?php echo htmlspecialchars($order['customer_name']); ?></strong></p>
                            <p>
                                <?php echo htmlspecialchars($order['shipping_address']); ?><br>
                                <?php echo htmlspecialchars($order['city']); ?>, <?php echo htmlspecialchars($order['postal_code']); ?><br>
                                <?php echo htmlspecialchars($order['province']); ?>
                            </p>
                            <p>
                                <i class="fas fa-phone"></i> <?php echo htmlspecialchars($order['customer_phone']); ?><br>
                                <i class="fas fa-envelope"></i> <?php echo htmlspecialchars($order['customer_email']); ?>
                            </p>
                        </div>
                    </div>

                </div>

                <!-- Order Summary (Sidebar) -->
                <div class="col-md-4">
                    
                    <!-- Price Summary -->
                    <div class="card">
                        <div class="card-header">
                            <h3 class="card-title">
                                <i class="fas fa-calculator"></i> Price Summary
                            </h3>
                        </div>
                        <div class="card-body">
                            <table class="table">
                                <tr>
                                    <td>Subtotal</td>
                                    <td class="text-right">
                                        <?php 
                                        $subtotal = $order['total_amount'] - $order['shipping_cost'] - $order['tax'] + $order['discount_amount'];
                                        echo formatRupiah($subtotal); 
                                        ?>
                                    </td>
                                </tr>
                                <tr>
                                    <td>Shipping</td>
                                    <td class="text-right"><?php echo formatRupiah($order['shipping_cost']); ?></td>
                                </tr>
                                <tr>
                                    <td>Tax (11%)</td>
                                    <td class="text-right"><?php echo formatRupiah($order['tax']); ?></td>
                                </tr>
                                <?php if($order['discount_amount'] > 0): ?>
                                <tr class="text-success">
                                    <td>Discount</td>
                                    <td class="text-right">-<?php echo formatRupiah($order['discount_amount']); ?></td>
                                </tr>
                                <?php endif; ?>
                                <tr class="border-top">
                                    <td><strong>Total</strong></td>
                                    <td class="text-right">
                                        <h4 class="text-primary">
                                            <?php echo formatRupiah($order['total_amount']); ?>
                                        </h4>
                                    </td>
                                </tr>
                            </table>
                        </div>
                    </div>

                    <!-- Actions -->
                    <div class="card">
                        <div class="card-header">
                            <h3 class="card-title">
                                <i class="fas fa-cog"></i> Actions
                            </h3>
                        </div>
                        <div class="card-body">
                            <a href="orders.php" class="btn btn-secondary btn-block">
                                <i class="fas fa-arrow-left"></i> Back to Orders
                            </a>
                            
                            <button type="button" class="btn btn-primary btn-block" data-toggle="modal" data-target="#statusModal">
                                <i class="fas fa-edit"></i> Update Status & Send Email
                            </button>
                            
                            <button onclick="window.print()" class="btn btn-info btn-block">
                                <i class="fas fa-print"></i> Print Invoice
                            </button>
                        </div>
                    </div>

                    <!-- Customer Info -->
                    <?php if($order['full_name']): ?>
                    <div class="card">
                        <div class="card-header">
                            <h3 class="card-title">
                                <i class="fas fa-user"></i> Customer Info
                            </h3>
                        </div>
                        <div class="card-body">
                            <p><strong><?php echo htmlspecialchars($order['full_name']); ?></strong></p>
                            <p>
                                <i class="fas fa-envelope"></i> <?php echo htmlspecialchars($order['email']); ?>
                            </p>
                            <a href="users.php" class="btn btn-sm btn-outline-primary">
                                View Customer Profile
                            </a>
                        </div>
                    </div>
                    <?php endif; ?>

                </div>
            </div>

        </div>
    </section>
</div>

<!-- ✅ Status Update Modal (UPDATED FORM ACTION) -->
<div class="modal fade" id="statusModal">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title">Update Order Status</h4>
                <button type="button" class="close" data-dismiss="modal">&times;</button>
            </div>
            <form method="POST" action="">
                <div class="modal-body">
                    <input type="hidden" name="order_id" value="<?php echo $order['order_id']; ?>">
                    <div class="form-group">
                        <label>Current Status:</label>
                        <p><span class="badge badge-<?php echo $badge_class; ?>"><?php echo ucfirst($order['status']); ?></span></p>
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
                    <div class="alert alert-info">
                        <i class="fas fa-info-circle"></i> An email notification will be sent to the customer automatically.
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                    <button type="submit" name="update_status" class="btn btn-primary">
                        <i class="fas fa-paper-plane"></i> Update & Send Email
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<style>
@media print {
    .main-sidebar, .main-header, .content-header, .card-header .card-tools, 
    .btn, .modal, .breadcrumb {
        display: none !important;
    }
    .content-wrapper {
        margin: 0 !important;
        padding: 0 !important;
    }
}
</style>

<?php include 'includes/footer.php'; ?>
<?php
session_start();
require_once '../config/database.php';

// Check if admin is logged in
if (!isset($_SESSION['admin_id'])) {
    header('Location: login.php');
    exit();
}

$database = new Database();
$conn = $database->getConnection();

// Handle approve/reject/delete actions
if (isset($_POST['action']) && isset($_POST['testimonial_id'])) {
    $testimonial_id = intval($_POST['testimonial_id']);
    $action = $_POST['action'];
    
    if ($action === 'approve') {
        $query = "UPDATE testimonials SET status = 'approved' WHERE testimonial_id = :id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':id', $testimonial_id);
        if ($stmt->execute()) {
            $_SESSION['success'] = 'Testimonial approved successfully';
        }
    } else if ($action === 'reject') {
        $query = "UPDATE testimonials SET status = 'rejected' WHERE testimonial_id = :id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':id', $testimonial_id);
        if ($stmt->execute()) {
            $_SESSION['success'] = 'Testimonial rejected';
        }
    } else if ($action === 'delete') {
        $query = "DELETE FROM testimonials WHERE testimonial_id = :id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':id', $testimonial_id);
        if ($stmt->execute()) {
            $_SESSION['success'] = 'Testimonial deleted successfully';
        }
    }
    
    header('Location: testimonials.php');
    exit();
}

// Get filter
$filter = isset($_GET['filter']) ? $_GET['filter'] : 'all';

// Fetch testimonials
$query = "SELECT t.*, u.full_name, u.email, o.order_number 
          FROM testimonials t 
          JOIN users u ON t.user_id = u.user_id 
          LEFT JOIN orders o ON t.order_id = o.order_id";

if ($filter !== 'all') {
    $query .= " WHERE t.status = :status";
}

$query .= " ORDER BY t.created_at DESC";

$stmt = $conn->prepare($query);

if ($filter !== 'all') {
    $stmt->bindParam(':status', $filter);
}

$stmt->execute();
$testimonials = $stmt->fetchAll(PDO::FETCH_ASSOC);

// Count by status
$query_counts = "SELECT 
                    SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending_count,
                    SUM(CASE WHEN status = 'approved' THEN 1 ELSE 0 END) as approved_count,
                    SUM(CASE WHEN status = 'rejected' THEN 1 ELSE 0 END) as rejected_count,
                    COUNT(*) as total_count
                FROM testimonials";
$stmt_counts = $conn->prepare($query_counts);
$stmt_counts->execute();
$counts = $stmt_counts->fetch(PDO::FETCH_ASSOC);

include 'includes/header.php';
?>

<div class="content-wrapper">
    <div class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h1 class="m-0">Testimonials Management</h1>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item"><a href="index.php">Home</a></li>
                        <li class="breadcrumb-item active">Testimonials</li>
                    </ol>
                </div>
            </div>
        </div>
    </div>

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

            <!-- Stats Cards -->
            <div class="row mb-3">
                <div class="col-md-3">
                    <div class="small-box bg-warning">
                        <div class="inner">
                            <h3><?php echo $counts['pending_count']; ?></h3>
                            <p>Pending Reviews</p>
                        </div>
                        <div class="icon">
                            <i class="fas fa-clock"></i>
                        </div>
                        <a href="?filter=pending" class="small-box-footer">View <i class="fas fa-arrow-circle-right"></i></a>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="small-box bg-success">
                        <div class="inner">
                            <h3><?php echo $counts['approved_count']; ?></h3>
                            <p>Approved Reviews</p>
                        </div>
                        <div class="icon">
                            <i class="fas fa-check-circle"></i>
                        </div>
                        <a href="?filter=approved" class="small-box-footer">View <i class="fas fa-arrow-circle-right"></i></a>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="small-box bg-danger">
                        <div class="inner">
                            <h3><?php echo $counts['rejected_count']; ?></h3>
                            <p>Rejected Reviews</p>
                        </div>
                        <div class="icon">
                            <i class="fas fa-times-circle"></i>
                        </div>
                        <a href="?filter=rejected" class="small-box-footer">View <i class="fas fa-arrow-circle-right"></i></a>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="small-box bg-info">
                        <div class="inner">
                            <h3><?php echo $counts['total_count']; ?></h3>
                            <p>Total Reviews</p>
                        </div>
                        <div class="icon">
                            <i class="fas fa-comments"></i>
                        </div>
                        <a href="?filter=all" class="small-box-footer">View All <i class="fas fa-arrow-circle-right"></i></a>
                    </div>
                </div>
            </div>

            <!-- Testimonials Table -->
            <div class="card">
                <div class="card-header">
                    <h3 class="card-title">
                        <?php 
                            if ($filter === 'pending') echo 'Pending Reviews';
                            else if ($filter === 'approved') echo 'Approved Reviews';
                            else if ($filter === 'rejected') echo 'Rejected Reviews';
                            else echo 'All Reviews';
                        ?>
                        (<?php echo count($testimonials); ?>)
                    </h3>
                </div>
                <div class="card-body">
                    <?php if (count($testimonials) === 0): ?>
                        <div class="alert alert-info">
                            <i class="fas fa-info-circle"></i> No testimonials found.
                        </div>
                    <?php else: ?>
                        <div class="table-responsive">
                            <table class="table table-bordered table-hover">
                                <thead>
                                    <tr>
                                        <th width="5%">ID</th>
                                        <th width="15%">Customer</th>
                                        <th width="10%">Rating</th>
                                        <th width="35%">Review</th>
                                        <th width="10%">Order</th>
                                        <th width="10%">Status</th>
                                        <th width="10%">Date</th>
                                        <th width="15%">Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php foreach ($testimonials as $testimonial): ?>
                                        <tr>
                                            <td><?php echo $testimonial['testimonial_id']; ?></td>
                                            <td>
                                                <strong><?php echo htmlspecialchars($testimonial['full_name']); ?></strong><br>
                                                <small class="text-muted"><?php echo htmlspecialchars($testimonial['email']); ?></small>
                                            </td>
                                            <td>
                                                <?php
                                                    for ($i = 1; $i <= 5; $i++) {
                                                        if ($i <= $testimonial['rating']) {
                                                            echo '<i class="fas fa-star text-warning"></i>';
                                                        } else {
                                                            echo '<i class="far fa-star text-warning"></i>';
                                                        }
                                                    }
                                                ?>
                                            </td>
                                            <td><?php echo nl2br(htmlspecialchars($testimonial['message'])); ?></td>
                                            <td>
                                                <?php if ($testimonial['order_number']): ?>
                                                    <span class="badge badge-info"><?php echo $testimonial['order_number']; ?></span>
                                                <?php else: ?>
                                                    <span class="text-muted">-</span>
                                                <?php endif; ?>
                                            </td>
                                            <td>
                                                <?php
                                                    $status_badges = [
                                                        'pending' => 'warning',
                                                        'approved' => 'success',
                                                        'rejected' => 'danger'
                                                    ];
                                                    $badge = $status_badges[$testimonial['status']];
                                                ?>
                                                <span class="badge badge-<?php echo $badge; ?>">
                                                    <?php echo ucfirst($testimonial['status']); ?>
                                                </span>
                                            </td>
                                            <td>
                                                <small><?php echo date('d M Y', strtotime($testimonial['created_at'])); ?></small>
                                            </td>
                                            <td>
                                                <?php if ($testimonial['status'] === 'pending'): ?>
                                                    <form method="POST" style="display: inline;">
                                                        <input type="hidden" name="testimonial_id" value="<?php echo $testimonial['testimonial_id']; ?>">
                                                        <input type="hidden" name="action" value="approve">
                                                        <button type="submit" class="btn btn-sm btn-success" title="Approve">
                                                            <i class="fas fa-check"></i>
                                                        </button>
                                                    </form>
                                                    <form method="POST" style="display: inline;">
                                                        <input type="hidden" name="testimonial_id" value="<?php echo $testimonial['testimonial_id']; ?>">
                                                        <input type="hidden" name="action" value="reject">
                                                        <button type="submit" class="btn btn-sm btn-warning" title="Reject">
                                                            <i class="fas fa-times"></i>
                                                        </button>
                                                    </form>
                                                <?php elseif ($testimonial['status'] === 'approved'): ?>
                                                    <form method="POST" style="display: inline;">
                                                        <input type="hidden" name="testimonial_id" value="<?php echo $testimonial['testimonial_id']; ?>">
                                                        <input type="hidden" name="action" value="reject">
                                                        <button type="submit" class="btn btn-sm btn-warning" title="Reject">
                                                            <i class="fas fa-times"></i>
                                                        </button>
                                                    </form>
                                                <?php elseif ($testimonial['status'] === 'rejected'): ?>
                                                    <form method="POST" style="display: inline;">
                                                        <input type="hidden" name="testimonial_id" value="<?php echo $testimonial['testimonial_id']; ?>">
                                                        <input type="hidden" name="action" value="approve">
                                                        <button type="submit" class="btn btn-sm btn-success" title="Approve">
                                                            <i class="fas fa-check"></i>
                                                        </button>
                                                    </form>
                                                <?php endif; ?>
                                                
                                                <form method="POST" style="display: inline;" onsubmit="return confirm('Are you sure you want to delete this testimonial?');">
                                                    <input type="hidden" name="testimonial_id" value="<?php echo $testimonial['testimonial_id']; ?>">
                                                    <input type="hidden" name="action" value="delete">
                                                    <button type="submit" class="btn btn-sm btn-danger" title="Delete">
                                                        <i class="fas fa-trash"></i>
                                                    </button>
                                                </form>
                                            </td>
                                        </tr>
                                    <?php endforeach; ?>
                                </tbody>
                            </table>
                        </div>
                    <?php endif; ?>
                </div>
            </div>

        </div>
    </section>
</div>

<?php include 'includes/footer.php'; ?>
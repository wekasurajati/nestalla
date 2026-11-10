<?php
require_once 'includes/auth.php';

$database = new Database();
$conn = $database->getConnection();

$success = '';
$error = '';

// Handle Delete
if(isset($_GET['delete'])) {
    $promo_id = $_GET['delete'];
    
    try {
        $query = "DELETE FROM promo_codes WHERE promo_id = :id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':id', $promo_id);
        
        if($stmt->execute()) {
            $success = 'Promo code deleted successfully!';
        }
    } catch(Exception $e) {
        $error = 'Error deleting promo: ' . $e->getMessage();
    }
}

// Handle Toggle Active
if(isset($_GET['toggle'])) {
    $promo_id = $_GET['toggle'];
    
    try {
        $query = "UPDATE promo_codes SET is_active = NOT is_active WHERE promo_id = :id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':id', $promo_id);
        
        if($stmt->execute()) {
            $success = 'Promo code status updated!';
        }
    } catch(Exception $e) {
        $error = 'Error updating promo: ' . $e->getMessage();
    }
}

// Get all promo codes
$query = "SELECT * FROM promo_codes ORDER BY created_at DESC";
$stmt = $conn->prepare($query);
$stmt->execute();
$promos = $stmt->fetchAll(PDO::FETCH_ASSOC);

$page_title = "Promo Codes Management";
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
                    <h1><i class="fas fa-tag"></i> Promo Codes Management</h1>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item"><a href="index.php">Home</a></li>
                        <li class="breadcrumb-item active">Promo Codes</li>
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
                    <h3 class="card-title">All Promo Codes</h3>
                    <div class="card-tools">
                        <a href="promos-add.php" class="btn btn-success btn-sm">
                            <i class="fas fa-plus"></i> Add New Promo
                        </a>
                    </div>
                </div>
                <div class="card-body">
                    <table class="table table-bordered table-striped">
                        <thead>
                            <tr>
                                <th>Code</th>
                                <th>Type</th>
                                <th>Value</th>
                                <th>Description</th>
                                <th>Valid Period</th>
                                <th>Usage</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach($promos as $promo): ?>
                            <tr>
                                <td>
                                    <strong class="text-primary"><?php echo $promo['code']; ?></strong>
                                </td>
                                <td>
                                    <?php if($promo['type'] == 'percentage'): ?>
                                        <span class="badge badge-info">Percentage</span>
                                    <?php else: ?>
                                        <span class="badge badge-success">Free Shipping</span>
                                    <?php endif; ?>
                                </td>
                                <td>
                                    <?php if($promo['type'] == 'percentage'): ?>
                                        <strong><?php echo $promo['value']; ?>%</strong>
                                    <?php else: ?>
                                        <strong><?php echo formatRupiah($promo['value']); ?></strong>
                                    <?php endif; ?>
                                </td>
                                <td><?php echo htmlspecialchars($promo['description']); ?></td>
                                <td>
                                    <small>
                                        <?php echo date('d M Y', strtotime($promo['valid_from'])); ?>
                                        <br>to<br>
                                        <?php echo date('d M Y', strtotime($promo['valid_until'])); ?>
                                    </small>
                                </td>
                                <td>
                                    <?php echo $promo['used_count']; ?> / 
                                    <?php echo $promo['usage_limit'] > 0 ? $promo['usage_limit'] : '∞'; ?>
                                </td>
                                <td>
                                    <?php if($promo['is_active']): ?>
                                        <span class="badge badge-success">Active</span>
                                    <?php else: ?>
                                        <span class="badge badge-secondary">Inactive</span>
                                    <?php endif; ?>
                                </td>
                                <td>
                                    <div class="btn-group">
                                        <a href="?toggle=<?php echo $promo['promo_id']; ?>" 
                                           class="btn btn-<?php echo $promo['is_active'] ? 'warning' : 'success'; ?> btn-sm"
                                           title="<?php echo $promo['is_active'] ? 'Deactivate' : 'Activate'; ?>">
                                            <i class="fas fa-<?php echo $promo['is_active'] ? 'ban' : 'check'; ?>"></i>
                                        </a>
                                        <a href="promos-edit.php?id=<?php echo $promo['promo_id']; ?>" 
                                           class="btn btn-info btn-sm"
                                           title="Edit">
                                            <i class="fas fa-edit"></i>
                                        </a>
                                        <a href="?delete=<?php echo $promo['promo_id']; ?>" 
                                           class="btn btn-danger btn-sm btn-delete"
                                           title="Delete"
                                           onclick="return confirm('Are you sure you want to delete this promo code?');">
                                            <i class="fas fa-trash"></i>
                                        </a>
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
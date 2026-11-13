<?php
require_once 'includes/auth.php';

$database = new Database();
$conn = $database->getConnection();

$error = '';
$success = '';

// Get promo ID
if(!isset($_GET['id'])) {
    header("Location: promos.php");
    exit;
}

$promo_id = $_GET['id'];

// Get promo data
$query = "SELECT * FROM promo_codes WHERE promo_id = :id";
$stmt = $conn->prepare($query);
$stmt->bindParam(':id', $promo_id);
$stmt->execute();
$promo = $stmt->fetch(PDO::FETCH_ASSOC);

if(!$promo) {
    header("Location: promos.php");
    exit;
}

// Handle Form Submit
if($_SERVER['REQUEST_METHOD'] == 'POST') {
    $code = strtoupper(trim($_POST['code']));
    $type = $_POST['type'];
    $value = floatval($_POST['value']);
    $description = trim($_POST['description']);
    $valid_from = $_POST['valid_from'];
    $valid_until = $_POST['valid_until'];
    $usage_limit = !empty($_POST['usage_limit']) ? intval($_POST['usage_limit']) : 0;
    $is_active = isset($_POST['is_active']) ? 1 : 0;
    
    if(empty($code) || empty($type) || empty($value)) {
        $error = 'Please fill all required fields!';
    } else {
        try {
            // Check if code already exists (except current promo)
            $query = "SELECT promo_id FROM promo_codes WHERE code = :code AND promo_id != :id";
            $stmt = $conn->prepare($query);
            $stmt->bindParam(':code', $code);
            $stmt->bindParam(':id', $promo_id);
            $stmt->execute();
            
            if($stmt->rowCount() > 0) {
                $error = 'Promo code already exists!';
            } else {
                $query = "UPDATE promo_codes SET 
                          code = :code, 
                          type = :type, 
                          value = :value, 
                          description = :description, 
                          valid_from = :valid_from, 
                          valid_until = :valid_until, 
                          usage_limit = :usage_limit, 
                          is_active = :is_active
                          WHERE promo_id = :id";
                
                $stmt = $conn->prepare($query);
                $stmt->bindParam(':code', $code);
                $stmt->bindParam(':type', $type);
                $stmt->bindParam(':value', $value);
                $stmt->bindParam(':description', $description);
                $stmt->bindParam(':valid_from', $valid_from);
                $stmt->bindParam(':valid_until', $valid_until);
                $stmt->bindParam(':usage_limit', $usage_limit);
                $stmt->bindParam(':is_active', $is_active);
                $stmt->bindParam(':id', $promo_id);
                
                if($stmt->execute()) {
                    $success = 'Promo code updated successfully!';
                    // Refresh data
                    $stmt = $conn->prepare("SELECT * FROM promo_codes WHERE promo_id = :id");
                    $stmt->bindParam(':id', $promo_id);
                    $stmt->execute();
                    $promo = $stmt->fetch(PDO::FETCH_ASSOC);
                }
            }
        } catch(Exception $e) {
            $error = 'Error updating promo: ' . $e->getMessage();
        }
    }
}

$page_title = "Edit Promo Code";
include 'includes/header.php';
include 'includes/sidebar.php';
?>

<!-- Content Wrapper -->
<div class="content-wrapper">
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h1><i class="fas fa-edit"></i> Edit Promo Code</h1>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item"><a href="index.php">Home</a></li>
                        <li class="breadcrumb-item"><a href="promos.php">Promo Codes</a></li>
                        <li class="breadcrumb-item active">Edit</li>
                    </ol>
                </div>
            </div>
        </div>
    </section>

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

            <form method="POST">
                <div class="row">
                    <div class="col-md-8">
                        <div class="card">
                            <div class="card-header">
                                <h3 class="card-title">Promo Information</h3>
                            </div>
                            <div class="card-body">
                                <div class="form-group">
                                    <label>Promo Code <span class="text-danger">*</span></label>
                                    <input type="text" name="code" class="form-control" required 
                                           value="<?php echo htmlspecialchars($promo['code']); ?>"
                                           style="text-transform: uppercase;">
                                </div>

                                <div class="row">
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label>Type <span class="text-danger">*</span></label>
                                            <select name="type" id="promoType" class="form-control" required>
                                                <option value="">Select Type</option>
                                                <option value="percentage" <?php echo ($promo['type'] == 'percentage') ? 'selected' : ''; ?>>Percentage Discount</option>
                                                <option value="free_shipping" <?php echo ($promo['type'] == 'free_shipping') ? 'selected' : ''; ?>>Free Shipping</option>
                                            </select>
                                        </div>
                                    </div>
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label>Value <span class="text-danger">*</span></label>
                                            <div class="input-group">
                                                <input type="number" name="value" id="promoValue" class="form-control" 
                                                       required min="0" step="0.01" value="<?php echo $promo['value']; ?>">
                                                <div class="input-group-append">
                                                    <span class="input-group-text" id="valueUnit">
                                                        <?php echo ($promo['type'] == 'percentage') ? '%' : 'Rp'; ?>
                                                    </span>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <div class="form-group">
                                    <label>Description</label>
                                    <textarea name="description" class="form-control" rows="3"><?php echo htmlspecialchars($promo['description'] ?? ''); ?></textarea>
                                </div>

                                <div class="row">
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label>Valid From <span class="text-danger">*</span></label>
                                            <input type="date" name="valid_from" class="form-control" required 
                                                   value="<?php echo $promo['valid_from']; ?>">
                                        </div>
                                    </div>
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label>Valid Until <span class="text-danger">*</span></label>
                                            <input type="date" name="valid_until" class="form-control" required 
                                                   value="<?php echo $promo['valid_until']; ?>">
                                        </div>
                                    </div>
                                </div>

                                <div class="form-group">
                                    <label>Usage Limit</label>
                                    <input type="number" name="usage_limit" class="form-control" min="0" 
                                           value="<?php echo $promo['usage_limit']; ?>">
                                    <small class="text-muted">Leave 0 for unlimited usage</small>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="col-md-4">
                        <div class="card">
                            <div class="card-header">
                                <h3 class="card-title">Status</h3>
                            </div>
                            <div class="card-body">
                                <div class="form-check">
                                    <input type="checkbox" name="is_active" class="form-check-input" id="active"
                                           <?php echo $promo['is_active'] ? 'checked' : ''; ?>>
                                    <label class="form-check-label" for="active">
                                        <strong>Active</strong>
                                        <br><small class="text-muted">Promo can be used</small>
                                    </label>
                                </div>
                            </div>
                        </div>

                        <div class="card">
                            <div class="card-header">
                                <h3 class="card-title">Usage Stats</h3>
                            </div>
                            <div class="card-body">
                                <p><strong>Used:</strong> <?php echo $promo['used_count']; ?> times</p>
                                <p><strong>Limit:</strong> <?php echo $promo['usage_limit'] > 0 ? $promo['usage_limit'] : 'Unlimited'; ?></p>
                                <?php if($promo['usage_limit'] > 0): ?>
                                <div class="progress">
                                    <div class="progress-bar" style="width: <?php echo ($promo['used_count'] / $promo['usage_limit']) * 100; ?>%"></div>
                                </div>
                                <?php endif; ?>
                            </div>
                        </div>

                        <button type="submit" class="btn btn-primary btn-block">
                            <i class="fas fa-save"></i> Update Promo
                        </button>
                        <a href="promos.php" class="btn btn-secondary btn-block">
                            <i class="fas fa-arrow-left"></i> Back to List
                        </a>
                    </div>
                </div>
            </form>

        </div>
    </section>
</div>

<script>
// Change value unit based on type
document.getElementById('promoType').addEventListener('change', function() {
    const valueUnit = document.getElementById('valueUnit');
    
    if(this.value === 'percentage') {
        valueUnit.textContent = '%';
    } else if(this.value === 'free_shipping') {
        valueUnit.textContent = 'Rp';
    }
});
</script>

<?php include 'includes/footer.php'; ?>
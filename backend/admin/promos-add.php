<?php
require_once 'includes/auth.php';

$database = new Database();
$conn = $database->getConnection();

$error = '';
$success = '';

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
    
    // Validation
    if(empty($code) || empty($type) || empty($value)) {
        $error = 'Please fill all required fields!';
    } else {
        try {
            // Check if code already exists
            $query = "SELECT promo_id FROM promo_codes WHERE code = :code";
            $stmt = $conn->prepare($query);
            $stmt->bindParam(':code', $code);
            $stmt->execute();
            
            if($stmt->rowCount() > 0) {
                $error = 'Promo code already exists!';
            } else {
                $query = "INSERT INTO promo_codes (code, type, value, description, valid_from, valid_until, usage_limit, is_active) 
                          VALUES (:code, :type, :value, :description, :valid_from, :valid_until, :usage_limit, :is_active)";
                
                $stmt = $conn->prepare($query);
                $stmt->bindParam(':code', $code);
                $stmt->bindParam(':type', $type);
                $stmt->bindParam(':value', $value);
                $stmt->bindParam(':description', $description);
                $stmt->bindParam(':valid_from', $valid_from);
                $stmt->bindParam(':valid_until', $valid_until);
                $stmt->bindParam(':usage_limit', $usage_limit);
                $stmt->bindParam(':is_active', $is_active);
                
                if($stmt->execute()) {
                    $success = 'Promo code added successfully!';
                    header("refresh:2;url=promos.php");
                }
            }
        } catch(Exception $e) {
            $error = 'Error adding promo: ' . $e->getMessage();
        }
    }
}

$page_title = "Add Promo Code";
include 'includes/header.php';
include 'includes/sidebar.php';
?>

<!-- Content Wrapper -->
<div class="content-wrapper">
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h1><i class="fas fa-plus"></i> Add Promo Code</h1>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item"><a href="index.php">Home</a></li>
                        <li class="breadcrumb-item"><a href="promos.php">Promo Codes</a></li>
                        <li class="breadcrumb-item active">Add</li>
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
                                           placeholder="e.g., WELCOME10" style="text-transform: uppercase;">
                                    <small class="text-muted">Will be automatically converted to uppercase</small>
                                </div>

                                <div class="row">
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label>Type <span class="text-danger">*</span></label>
                                            <select name="type" id="promoType" class="form-control" required>
                                                <option value="">Select Type</option>
                                                <option value="percentage">Percentage Discount</option>
                                                <option value="free_shipping">Free Shipping</option>
                                            </select>
                                        </div>
                                    </div>
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label>Value <span class="text-danger">*</span></label>
                                            <div class="input-group">
                                                <input type="number" name="value" id="promoValue" class="form-control" 
                                                       required min="0" step="0.01">
                                                <div class="input-group-append">
                                                    <span class="input-group-text" id="valueUnit">%</span>
                                                </div>
                                            </div>
                                            <small class="text-muted" id="valueHelp">Enter discount percentage (e.g., 10 for 10%)</small>
                                        </div>
                                    </div>
                                </div>

                                <div class="form-group">
                                    <label>Description</label>
                                    <textarea name="description" class="form-control" rows="3" 
                                              placeholder="Brief description of the promo"></textarea>
                                </div>

                                <div class="row">
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label>Valid From <span class="text-danger">*</span></label>
                                            <input type="date" name="valid_from" class="form-control" required 
                                                   value="<?php echo date('Y-m-d'); ?>">
                                        </div>
                                    </div>
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label>Valid Until <span class="text-danger">*</span></label>
                                            <input type="date" name="valid_until" class="form-control" required 
                                                   value="<?php echo date('Y-m-d', strtotime('+1 month')); ?>">
                                        </div>
                                    </div>
                                </div>

                                <div class="form-group">
                                    <label>Usage Limit</label>
                                    <input type="number" name="usage_limit" class="form-control" min="0" value="0">
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
                                    <input type="checkbox" name="is_active" class="form-check-input" id="active" checked>
                                    <label class="form-check-label" for="active">
                                        <strong>Active</strong>
                                        <br><small class="text-muted">Promo can be used immediately</small>
                                    </label>
                                </div>
                            </div>
                        </div>

                        <div class="card">
                            <div class="card-header">
                                <h3 class="card-title">Quick Examples</h3>
                            </div>
                            <div class="card-body">
                                <p><strong>Percentage Discount:</strong></p>
                                <ul class="text-sm">
                                    <li>Code: WELCOME10</li>
                                    <li>Type: Percentage</li>
                                    <li>Value: 10</li>
                                    <li>Result: 10% off</li>
                                </ul>
                                
                                <p class="mt-3"><strong>Free Shipping:</strong></p>
                                <ul class="text-sm">
                                    <li>Code: FREESHIP</li>
                                    <li>Type: Free Shipping</li>
                                    <li>Value: 15000</li>
                                    <li>Result: Free shipping (Rp15,000 off)</li>
                                </ul>
                            </div>
                        </div>

                        <button type="submit" class="btn btn-success btn-block">
                            <i class="fas fa-save"></i> Create Promo
                        </button>
                        <a href="promos.php" class="btn btn-secondary btn-block">
                            <i class="fas fa-times"></i> Cancel
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
    const valueHelp = document.getElementById('valueHelp');
    const valueInput = document.getElementById('promoValue');
    
    if(this.value === 'percentage') {
        valueUnit.textContent = '%';
        valueHelp.textContent = 'Enter discount percentage (e.g., 10 for 10%)';
        valueInput.setAttribute('max', '100');
    } else if(this.value === 'free_shipping') {
        valueUnit.textContent = 'Rp';
        valueHelp.textContent = 'Enter shipping cost amount (e.g., 15000)';
        valueInput.removeAttribute('max');
    }
});
</script>

<?php include 'includes/footer.php'; ?>
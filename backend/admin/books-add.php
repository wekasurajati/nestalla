<?php
require_once 'includes/auth.php';

$database = new Database();
$conn = $database->getConnection();

$error = '';
$success = '';

// Menangani submit form
if($_SERVER['REQUEST_METHOD'] == 'POST') {
    $title = trim($_POST['title']);
    $author = trim($_POST['author']);
    $description = trim($_POST['description']);
    $price = floatval($_POST['price']);
    $old_price = !empty($_POST['old_price']) ? floatval($_POST['old_price']) : 0;
    $category = trim($_POST['category']);
    $stock = intval($_POST['stock']);
    $rating = floatval($_POST['rating']);
    $is_featured = isset($_POST['is_featured']) ? 1 : 0;
    $is_new = isset($_POST['is_new']) ? 1 : 0;
    $is_discount = isset($_POST['is_discount']) ? 1 : 0;
    
    // Menangani up gambar
    $image_path = '';
    if(isset($_FILES['image']) && $_FILES['image']['error'] == 0) {
        $allowed = ['jpg', 'jpeg', 'png', 'gif'];
        $filename = $_FILES['image']['name'];
        $filetype = pathinfo($filename, PATHINFO_EXTENSION);
        
        if(in_array(strtolower($filetype), $allowed)) {
            $upload_dir = '../assets/uploads/books/';
            
            // Create directory if not exists
            if(!is_dir($upload_dir)) {
                mkdir($upload_dir, 0777, true);
            }
            
            $new_filename = 'book_' . time() . '_' . uniqid() . '.' . $filetype;
            $upload_path = $upload_dir . $new_filename;
            
            if(move_uploaded_file($_FILES['image']['tmp_name'], $upload_path)) {
                $image_path = 'assets/uploads/books/' . $new_filename;
            } else {
                $error = 'Failed to upload image!';
            }
        } else {
            $error = 'Invalid file type! Only JPG, JPEG, PNG, GIF allowed.';
        }
    }
    
    if(empty($error)) {
        try {
            $query = "INSERT INTO books (title, author, description, price, old_price, image, category, stock, rating, is_featured, is_new, is_discount) 
                      VALUES (:title, :author, :description, :price, :old_price, :image, :category, :stock, :rating, :is_featured, :is_new, :is_discount)";
            
            $stmt = $conn->prepare($query);
            $stmt->bindParam(':title', $title);
            $stmt->bindParam(':author', $author);
            $stmt->bindParam(':description', $description);
            $stmt->bindParam(':price', $price);
            $stmt->bindParam(':old_price', $old_price);
            $stmt->bindParam(':image', $image_path);
            $stmt->bindParam(':category', $category);
            $stmt->bindParam(':stock', $stock);
            $stmt->bindParam(':rating', $rating);
            $stmt->bindParam(':is_featured', $is_featured);
            $stmt->bindParam(':is_new', $is_new);
            $stmt->bindParam(':is_discount', $is_discount);
            
            if($stmt->execute()) {
                $success = 'Book added successfully!';
                // Redirect after 2 seconds
                header("refresh:2;url=books.php");
            }
        } catch(Exception $e) {
            $error = 'Error adding book: ' . $e->getMessage();
        }
    }
}

$page_title = "Add New Book";
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
                    <h1><i class="fas fa-plus"></i> Add New Book</h1>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item"><a href="index.php">Home</a></li>
                        <li class="breadcrumb-item"><a href="books.php">Books</a></li>
                        <li class="breadcrumb-item active">Add</li>
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

            <form method="POST" enctype="multipart/form-data">
                <div class="row">
                    <div class="col-md-8">
                        <div class="card">
                            <div class="card-header">
                                <h3 class="card-title">Book Information</h3>
                            </div>
                            <div class="card-body">
                                <div class="form-group">
                                    <label>Title <span class="text-danger">*</span></label>
                                    <input type="text" name="title" class="form-control" required>
                                </div>

                                <div class="form-group">
                                    <label>Author <span class="text-danger">*</span></label>
                                    <input type="text" name="author" class="form-control" required>
                                </div>

                                <div class="form-group">
                                    <label>Description</label>
                                    <textarea name="description" class="form-control" rows="5"></textarea>
                                </div>

                                <div class="row">
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label>Price (Rp) <span class="text-danger">*</span></label>
                                            <input type="number" name="price" class="form-control" required min="0" step="0.01">
                                        </div>
                                    </div>
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label>Old Price (Rp)</label>
                                            <input type="number" name="old_price" class="form-control" min="0" step="0.01">
                                            <small class="text-muted">Leave empty if no discount</small>
                                        </div>
                                    </div>
                                </div>

                                <div class="row">
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label>Category</label>
                                            <select name="category" class="form-control">
                                                <option value="">Select Category</option>
                                                <option value="Fiction">Fiction</option>
                                                <option value="Self-Help">Self-Help</option>
                                                <option value="Science">Science</option>
                                                <option value="Cooking">Cooking</option>
                                                <option value="Politics">Politics</option>
                                                <option value="Music">Music</option>
                                                <option value="Other">Other</option>
                                            </select>
                                        </div>
                                    </div>
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label>Stock <span class="text-danger">*</span></label>
                                            <input type="number" name="stock" class="form-control" required min="0" value="0">
                                        </div>
                                    </div>
                                </div>

                                <div class="form-group">
                                    <label>Rating (0.0 - 5.0)</label>
                                    <input type="number" name="rating" class="form-control" min="0" max="5" step="0.1" value="0">
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="col-md-4">
                        <div class="card">
                            <div class="card-header">
                                <h3 class="card-title">Book Image</h3>
                            </div>
                            <div class="card-body">
                                <div class="form-group">
                                    <label>Upload Cover Image</label>
                                    <input type="file" name="image" class="form-control-file" accept="image/*">
                                    <small class="text-muted">JPG, JPEG, PNG, GIF (Max 2MB)</small>
                                </div>

                                <div id="imagePreview" style="display:none; margin-top: 10px;">
                                    <img id="preview" src="" style="max-width: 100%; border-radius: 5px;">
                                </div>
                            </div>
                        </div>

                        <div class="card">
                            <div class="card-header">
                                <h3 class="card-title">Book Status</h3>
                            </div>
                            <div class="card-body">
                                <div class="form-check">
                                    <input type="checkbox" name="is_featured" class="form-check-input" id="featured">
                                    <label class="form-check-label" for="featured">
                                        <strong>Featured Book</strong>
                                        <br><small class="text-muted">Show in featured section</small>
                                    </label>
                                </div>

                                <div class="form-check mt-2">
                                    <input type="checkbox" name="is_new" class="form-check-input" id="new">
                                    <label class="form-check-label" for="new">
                                        <strong>New Arrival</strong>
                                        <br><small class="text-muted">Show in new books section</small>
                                    </label>
                                </div>

                                <div class="form-check mt-2">
                                    <input type="checkbox" name="is_discount" class="form-check-input" id="discount">
                                    <label class="form-check-label" for="discount">
                                        <strong>On Discount</strong>
                                        <br><small class="text-muted">Show discount badge</small>
                                    </label>
                                </div>
                            </div>
                        </div>

                        <button type="submit" class="btn btn-success btn-block">
                            <i class="fas fa-save"></i> Save Book
                        </button>
                        <a href="books.php" class="btn btn-secondary btn-block">
                            <i class="fas fa-times"></i> Cancel
                        </a>
                    </div>
                </div>
            </form>

        </div>
    </section>
</div>

<script>
// Image preview
document.querySelector('input[name="image"]').addEventListener('change', function(e) {
    const file = e.target.files[0];
    if(file) {
        const reader = new FileReader();
        reader.onload = function(e) {
            document.getElementById('preview').src = e.target.result;
            document.getElementById('imagePreview').style.display = 'block';
        }
        reader.readAsDataURL(file);
    }
});
</script>

<?php include 'includes/footer.php'; ?>
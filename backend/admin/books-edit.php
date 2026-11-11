<?php
require_once 'includes/auth.php';

$database = new Database();
$conn = $database->getConnection();

$error = '';
$success = '';

// Mendapatkan Buku ID from URL
if(!isset($_GET['id'])) {
    header("Location: books.php");
    exit;
}

$book_id = $_GET['id'];

// Get data buku
$query = "SELECT * FROM books WHERE book_id = :id";
$stmt = $conn->prepare($query);
$stmt->bindParam(':id', $book_id);
$stmt->execute();
$book = $stmt->fetch(PDO::FETCH_ASSOC);

if(!$book) {
    header("Location: books.php");
    exit;
}

// Handle Form Submit disiniii
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
    
    $image_path = $book['image']; // Keep old image by default
    
    // Handle image upload disinii
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
                // Delete old image if exists
                if(!empty($book['image']) && file_exists('../' . $book['image'])) {
                    unlink('../' . $book['image']);
                }
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
            $query = "UPDATE books SET 
                      title = :title, 
                      author = :author, 
                      description = :description, 
                      price = :price, 
                      old_price = :old_price, 
                      image = :image, 
                      category = :category, 
                      stock = :stock, 
                      rating = :rating, 
                      is_featured = :is_featured, 
                      is_new = :is_new, 
                      is_discount = :is_discount,
                      updated_at = NOW()
                      WHERE book_id = :id";
            
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
            $stmt->bindParam(':id', $book_id);
            
            if($stmt->execute()) {
                $success = 'Book updated successfully!';
                // Refresh book data
                $stmt = $conn->prepare("SELECT * FROM books WHERE book_id = :id");
                $stmt->bindParam(':id', $book_id);
                $stmt->execute();
                $book = $stmt->fetch(PDO::FETCH_ASSOC);
            }
        } catch(Exception $e) {
            $error = 'Error updating book: ' . $e->getMessage();
        }
    }
}

$page_title = "Edit Book";
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
                    <h1><i class="fas fa-edit"></i> Edit Book</h1>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item"><a href="index.php">Home</a></li>
                        <li class="breadcrumb-item"><a href="books.php">Books</a></li>
                        <li class="breadcrumb-item active">Edit</li>
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
                                    <input type="text" name="title" class="form-control" 
                                           value="<?php echo htmlspecialchars($book['title']); ?>" required>
                                </div>

                                <div class="form-group">
                                    <label>Author <span class="text-danger">*</span></label>
                                    <input type="text" name="author" class="form-control" 
                                           value="<?php echo htmlspecialchars($book['author']); ?>" required>
                                </div>

                                <div class="form-group">
                                    <label>Description</label>
                                    <textarea name="description" class="form-control" rows="5"><?php echo htmlspecialchars($book['description'] ?? ''); ?></textarea>
                                </div>

                                <div class="row">
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label>Price (Rp) <span class="text-danger">*</span></label>
                                            <input type="number" name="price" class="form-control" 
                                                   value="<?php echo $book['price']; ?>" required min="0" step="0.01">
                                        </div>
                                    </div>
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label>Old Price (Rp)</label>
                                            <input type="number" name="old_price" class="form-control" 
                                                   value="<?php echo $book['old_price'] ?? 0; ?>" min="0" step="0.01">
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
                                                <option value="Fiction" <?php echo ($book['category'] == 'Fiction') ? 'selected' : ''; ?>>Fiction</option>
                                                <option value="Self-Help" <?php echo ($book['category'] == 'Self-Help') ? 'selected' : ''; ?>>Self-Help</option>
                                                <option value="Science" <?php echo ($book['category'] == 'Science') ? 'selected' : ''; ?>>Science</option>
                                                <option value="Cooking" <?php echo ($book['category'] == 'Cooking') ? 'selected' : ''; ?>>Cooking</option>
                                                <option value="Politics" <?php echo ($book['category'] == 'Politics') ? 'selected' : ''; ?>>Politics</option>
                                                <option value="Music" <?php echo ($book['category'] == 'Music') ? 'selected' : ''; ?>>Music</option>
                                                <option value="Other" <?php echo ($book['category'] == 'Other') ? 'selected' : ''; ?>>Other</option>
                                            </select>
                                        </div>
                                    </div>
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label>Stock <span class="text-danger">*</span></label>
                                            <input type="number" name="stock" class="form-control" 
                                                   value="<?php echo $book['stock']; ?>" required min="0">
                                        </div>
                                    </div>
                                </div>

                                <div class="form-group">
                                    <label>Rating (0.0 - 5.0)</label>
                                    <input type="number" name="rating" class="form-control" 
                                           value="<?php echo $book['rating']; ?>" min="0" max="5" step="0.1">
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
                                <?php if(!empty($book['image'])): ?>
                                <div class="mb-3">
                                    <label>Current Image:</label><br>
                                    <img src="../<?php echo $book['image']; ?>" 
                                         alt="<?php echo htmlspecialchars($book['title']); ?>" 
                                         style="max-width: 100%; border-radius: 5px; border: 1px solid #ddd;">
                                </div>
                                <?php endif; ?>

                                <div class="form-group">
                                    <label>Upload New Image</label>
                                    <input type="file" name="image" class="form-control-file" accept="image/*">
                                    <small class="text-muted">Leave empty to keep current image</small>
                                </div>

                                <div id="imagePreview" style="display:none; margin-top: 10px;">
                                    <label>Preview:</label><br>
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
                                    <input type="checkbox" name="is_featured" class="form-check-input" id="featured"
                                           <?php echo $book['is_featured'] ? 'checked' : ''; ?>>
                                    <label class="form-check-label" for="featured">
                                        <strong>Featured Book</strong>
                                        <br><small class="text-muted">Show in featured section</small>
                                    </label>
                                </div>

                                <div class="form-check mt-2">
                                    <input type="checkbox" name="is_new" class="form-check-input" id="new"
                                           <?php echo $book['is_new'] ? 'checked' : ''; ?>>
                                    <label class="form-check-label" for="new">
                                        <strong>New Arrival</strong>
                                        <br><small class="text-muted">Show in new books section</small>
                                    </label>
                                </div>

                                <div class="form-check mt-2">
                                    <input type="checkbox" name="is_discount" class="form-check-input" id="discount"
                                           <?php echo $book['is_discount'] ? 'checked' : ''; ?>>
                                    <label class="form-check-label" for="discount">
                                        <strong>On Discount</strong>
                                        <br><small class="text-muted">Show discount badge</small>
                                    </label>
                                </div>
                            </div>
                        </div>

                        <button type="submit" class="btn btn-primary btn-block">
                            <i class="fas fa-save"></i> Update Book
                        </button>
                        <a href="books.php" class="btn btn-secondary btn-block">
                            <i class="fas fa-arrow-left"></i> Back to List
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
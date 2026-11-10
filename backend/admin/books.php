<?php
require_once 'includes/auth.php';

$database = new Database();
$conn = $database->getConnection();

$success = '';
$error = '';

// Handle Delete disisniii
if(isset($_GET['delete'])) {
    $book_id = $_GET['delete'];
    
    try {
        // Get image filename to delete
        $query = "SELECT image FROM books WHERE book_id = :id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':id', $book_id);
        $stmt->execute();
        $book = $stmt->fetch(PDO::FETCH_ASSOC);
        
        // Delete buku from database disini yaaa
        $query = "DELETE FROM books WHERE book_id = :id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':id', $book_id);
        
        if($stmt->execute()) {
            // Delete image file if exists
            if($book && !empty($book['image'])) {
                $image_path = "../" . $book['image'];
                if(file_exists($image_path)) {
                    unlink($image_path);
                }
            }
            $success = 'Book deleted successfully!';
        }
    } catch(Exception $e) {
        $error = 'Error deleting book: ' . $e->getMessage();
    }
}

// Get all books
$query = "SELECT * FROM books ORDER BY created_at DESC";
$stmt = $conn->prepare($query);
$stmt->execute();
$books = $stmt->fetchAll(PDO::FETCH_ASSOC);

$page_title = "Books Management";
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
                    <h1><i class="fas fa-book"></i> Books Management</h1>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item"><a href="index.php">Home</a></li>
                        <li class="breadcrumb-item active">Books</li>
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
                    <h3 class="card-title">All Books</h3>
                    <div class="card-tools">
                        <a href="books-add.php" class="btn btn-success btn-sm">
                            <i class="fas fa-plus"></i> Add New Book
                        </a>
                    </div>
                </div>
                <div class="card-body">
                    <table id="booksTable" class="table table-bordered table-striped datatable">
                        <thead>
                            <tr>
                                <th width="80">Image</th>
                                <th>Title</th>
                                <th>Author</th>
                                <th>Category</th>
                                <th>Price</th>
                                <th>Stock</th>
                                <th>Status</th>
                                <th width="150">Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach($books as $book): ?>
                            <tr>
                                <td>
                                    <?php if(!empty($book['image'])): ?>
                                        <img src="../<?php echo $book['image']; ?>" 
                                             alt="<?php echo htmlspecialchars($book['title']); ?>" 
                                             style="width: 50px; height: auto; border-radius: 5px;">
                                    <?php else: ?>
                                        <div style="width: 50px; height: 70px; background: #ddd; border-radius: 5px; display: flex; align-items: center; justify-content: center;">
                                            <i class="fas fa-image text-muted"></i>
                                        </div>
                                    <?php endif; ?>
                                </td>
                                <td>
                                    <strong><?php echo htmlspecialchars($book['title']); ?></strong>
                                    <?php if($book['is_featured']): ?>
                                        <span class="badge badge-primary">Featured</span>
                                    <?php endif; ?>
                                    <?php if($book['is_new']): ?>
                                        <span class="badge badge-success">New</span>
                                    <?php endif; ?>
                                    <?php if($book['is_discount']): ?>
                                        <span class="badge badge-danger">Discount</span>
                                    <?php endif; ?>
                                </td>
                                <td><?php echo htmlspecialchars($book['author']); ?></td>
                                <td>
                                    <span class="badge badge-info">
                                        <?php echo htmlspecialchars($book['category'] ?? 'Uncategorized'); ?>
                                    </span>
                                </td>
                                <td>
                                    <strong><?php echo formatRupiah($book['price']); ?></strong>
                                    <?php if($book['old_price'] > 0): ?>
                                        <br><small class="text-muted"><del><?php echo formatRupiah($book['old_price']); ?></del></small>
                                    <?php endif; ?>
                                </td>
<td>
    <?php if($book['stock'] > 10): ?>
        <span class="badge badge-success"><?php echo $book['stock']; ?></span>
    <?php elseif($book['stock'] > 0): ?>
        <span class="badge badge-warning">
            <i class="fas fa-exclamation-triangle"></i> <?php echo $book['stock']; ?>
        </span>
    <?php else: ?>
        <span class="badge badge-danger">
            <i class="fas fa-times-circle"></i> Out of Stock
        </span>
    <?php endif; ?>
</td>
                                <td>
                                    <i class="fas fa-star text-warning"></i>
                                    <?php echo number_format($book['rating'], 1); ?>
                                </td>
                                <td>
                                    <div class="btn-group">
                                        <a href="books-edit.php?id=<?php echo $book['book_id']; ?>" 
                                           class="btn btn-info btn-sm" 
                                           title="Edit">
                                            <i class="fas fa-edit"></i>
                                        </a>
                                        <a href="?delete=<?php echo $book['book_id']; ?>" 
                                           class="btn btn-danger btn-sm btn-delete" 
                                           title="Delete"
                                           onclick="return confirm('Are you sure you want to delete this book?');">
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
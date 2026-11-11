<?php


require_once 'config.php';

$database = new Database();
$conn = $database->getConnection();

// GET single book by ID or all books 
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    
    // Get single book detail
    if (isset($_GET['id'])) {
        $book_id = intval($_GET['id']);
        
        $query = "SELECT * FROM books WHERE book_id = :id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':id', $book_id);
        $stmt->execute();
        
        $book = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($book) {
            sendSuccess('Book retrieved successfully', $book);
        } else {
            sendError('Book not found', 404);
        }
    }
    
    // Get all books or filtered books
    else {
        $query = "SELECT * FROM books WHERE 1=1";
        $params = [];
        
        // Filter by category
        if (isset($_GET['category']) && !empty($_GET['category'])) {
            $query .= " AND category = :category";
            $params[':category'] = $_GET['category'];
        }
        
        // Filter by featured
        if (isset($_GET['featured']) && $_GET['featured'] == '1') {
            $query .= " AND is_featured = 1";
        }
        
        // Filter by new
        if (isset($_GET['new']) && $_GET['new'] == '1') {
            $query .= " AND is_new = 1";
        }
        
        // Filter by discount
        if (isset($_GET['discount']) && $_GET['discount'] == '1') {
            $query .= " AND is_discount = 1";
        }
        
        // Search by title or author
        if (isset($_GET['search']) && !empty($_GET['search'])) {
            $query .= " AND (title LIKE :search OR author LIKE :search)";
            $params[':search'] = '%' . $_GET['search'] . '%';
        }
        
        // Limit
        $limit = isset($_GET['limit']) ? intval($_GET['limit']) : 100;
        $query .= " ORDER BY created_at DESC LIMIT :limit";
        
        $stmt = $conn->prepare($query);
        
        // Bind parameters
        foreach ($params as $key => $value) {
            $stmt->bindValue($key, $value);
        }
        $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
        
        $stmt->execute();
        $books = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        sendSuccess('Books retrieved successfully', [
            'count' => count($books),
            'books' => $books
        ]);
    }
}

// Method not allowed
else {
    sendError('Method not allowed', 405);
}
?>
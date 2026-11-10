<?php


require_once 'config.php';

$database = new Database();
$conn = $database->getConnection();

if (!isset($_SESSION['user_id'])) {
    sendError('Please login first', 401);
}

$user_id = $_SESSION['user_id'];

// ========================================
// GET USER'S WISHLIST
// ========================================
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    
    try {
        $query = "SELECT w.*, b.title, b.author, b.price, b.old_price, b.image, b.stock, b.rating 
                  FROM wishlist w 
                  JOIN books b ON w.book_id = b.book_id 
                  WHERE w.user_id = :user_id 
                  ORDER BY w.created_at DESC";
        
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':user_id', $user_id);
        $stmt->execute();
        
        $wishlist_items = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        sendSuccess('Wishlist retrieved successfully', [
            'items' => $wishlist_items,
            'count' => count($wishlist_items)
        ]);
        
    } catch (Exception $e) {
        sendError('Failed to get wishlist: ' . $e->getMessage(), 500);
    }
}

// ========================================
// ADD TO WISHLIST
// ========================================
else if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    
    $data = json_decode(file_get_contents("php://input"), true);
    
    if (empty($data['book_id'])) {
        sendError('Book ID is required');
    }
    
    $book_id = intval($data['book_id']);
    
    try {
        // Check if book exists
        $query = "SELECT book_id FROM books WHERE book_id = :book_id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':book_id', $book_id);
        $stmt->execute();
        
        if ($stmt->rowCount() === 0) {
            sendError('Book not found', 404);
        }
        
        // Check if already in wishlist
        $query = "SELECT wishlist_id FROM wishlist WHERE user_id = :user_id AND book_id = :book_id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':user_id', $user_id);
        $stmt->bindParam(':book_id', $book_id);
        $stmt->execute();
        
        if ($stmt->rowCount() > 0) {
            sendError('Book already in wishlist');
        }
        
        // Insert to wishlist
        $query = "INSERT INTO wishlist (user_id, book_id) VALUES (:user_id, :book_id)";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':user_id', $user_id);
        $stmt->bindParam(':book_id', $book_id);
        $stmt->execute();
        
        sendSuccess('Added to wishlist successfully', [
            'wishlist_id' => $conn->lastInsertId()
        ]);
        
    } catch (Exception $e) {
        sendError('Failed to add to wishlist: ' . $e->getMessage(), 500);
    }
}

// ========================================
// REMOVE FROM WISHLIST
// ========================================
else if ($_SERVER['REQUEST_METHOD'] === 'DELETE') {
    
    if (!isset($_GET['book_id'])) {
        sendError('Book ID is required');
    }
    
    $book_id = intval($_GET['book_id']);
    
    try {
        $query = "DELETE FROM wishlist WHERE user_id = :user_id AND book_id = :book_id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':user_id', $user_id);
        $stmt->bindParam(':book_id', $book_id);
        $stmt->execute();
        
        if ($stmt->rowCount() > 0) {
            sendSuccess('Removed from wishlist successfully');
        } else {
            sendError('Item not found in wishlist', 404);
        }
        
    } catch (Exception $e) {
        sendError('Failed to remove from wishlist: ' . $e->getMessage(), 500);
    }
}

// ========================================
// CHECK IF BOOK IN WISHLIST
// ========================================
else if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['check'])) {
    
    if (!isset($_GET['book_id'])) {
        sendError('Book ID is required');
    }
    
    $book_id = intval($_GET['book_id']);
    
    try {
        $query = "SELECT wishlist_id FROM wishlist WHERE user_id = :user_id AND book_id = :book_id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':user_id', $user_id);
        $stmt->bindParam(':book_id', $book_id);
        $stmt->execute();
        
        sendSuccess('Check completed', [
            'in_wishlist' => $stmt->rowCount() > 0
        ]);
        
    } catch (Exception $e) {
        sendError('Failed to check wishlist: ' . $e->getMessage(), 500);
    }
}

// Method not allowed
else {
    sendError('Method not allowed', 405);
}
?>
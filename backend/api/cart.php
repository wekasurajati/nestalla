<?php


require_once 'config.php';

$database = new Database();
$conn = $database->getConnection();

if (!isset($_SESSION['user_id'])) {
    sendError('Please login first', 401);
}

$user_id = $_SESSION['user_id'];

// ========================================
// GET USER'S CART
// ========================================
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    
    try {
        $query = "SELECT c.*, b.title, b.author, b.price, b.image, b.stock 
                  FROM cart c 
                  JOIN books b ON c.book_id = b.book_id 
                  WHERE c.user_id = :user_id 
                  ORDER BY c.created_at DESC";
        
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':user_id', $user_id);
        $stmt->execute();
        
        $cart_items = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Calculate total
        $total = 0;
        foreach ($cart_items as $item) {
            $total += $item['price'] * $item['quantity'];
        }
        
        sendSuccess('Cart retrieved successfully', [
            'items' => $cart_items,
            'total' => $total,
            'count' => count($cart_items)
        ]);
        
    } catch (Exception $e) {
        sendError('Failed to get cart: ' . $e->getMessage(), 500);
    }
}


// ADD TO CART

else if ($_SERVER['REQUEST_METHOD'] === 'POST' && (!isset($_GET['action']) || $_GET['action'] === 'add')) {
    
    $data = json_decode(file_get_contents("php://input"), true);
    
    if (empty($data['book_id'])) {
        sendError('Book ID is required');
    }
    
    $book_id = intval($data['book_id']);
    $quantity = isset($data['quantity']) ? intval($data['quantity']) : 1;
    
    if ($quantity < 1) {
        sendError('Invalid quantity');
    }
    
    try {
        // Check book stock
        $query = "SELECT stock, title FROM books WHERE book_id = :book_id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':book_id', $book_id);
        $stmt->execute();
        $book = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$book) {
            sendError('Book not found', 404);
        }
        
        if ($book['stock'] < $quantity) {
            sendError('Insufficient stock. Available: ' . $book['stock']);
        }
        
        // Check if already in cart
        $query = "SELECT * FROM cart WHERE user_id = :user_id AND book_id = :book_id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':user_id', $user_id);
        $stmt->bindParam(':book_id', $book_id);
        $stmt->execute();
        
        if ($stmt->rowCount() > 0) {
            // Update quantity
            $cart_item = $stmt->fetch(PDO::FETCH_ASSOC);
            $new_quantity = $cart_item['quantity'] + $quantity;
            
            if ($new_quantity > $book['stock']) {
                sendError('Cannot add more. Maximum stock: ' . $book['stock']);
            }
            
            $query = "UPDATE cart SET quantity = :quantity WHERE cart_id = :cart_id";
            $stmt = $conn->prepare($query);
            $stmt->bindParam(':quantity', $new_quantity);
            $stmt->bindParam(':cart_id', $cart_item['cart_id']);
            $stmt->execute();
            
            sendSuccess('Cart updated successfully');
        } else {
            // Insert new
            $query = "INSERT INTO cart (user_id, book_id, quantity) VALUES (:user_id, :book_id, :quantity)";
            $stmt = $conn->prepare($query);
            $stmt->bindParam(':user_id', $user_id);
            $stmt->bindParam(':book_id', $book_id);
            $stmt->bindParam(':quantity', $quantity);
            $stmt->execute();
            
            sendSuccess('Added to cart successfully');
        }
        
    } catch (Exception $e) {
        sendError('Failed to add to cart: ' . $e->getMessage(), 500);
    }
}

// ========================================
// UPDATE CART ITEM QUANTITY
// ========================================
else if ($_SERVER['REQUEST_METHOD'] === 'PUT') {
    
    $data = json_decode(file_get_contents("php://input"), true);
    
    if (empty($data['cart_id']) || empty($data['quantity'])) {
        sendError('Cart ID and quantity are required');
    }
    
    $cart_id = intval($data['cart_id']);
    $quantity = intval($data['quantity']);
    
    if ($quantity < 1) {
        sendError('Invalid quantity');
    }
    
    try {
        // Get cart item
        $query = "SELECT c.*, b.stock FROM cart c 
                  JOIN books b ON c.book_id = b.book_id 
                  WHERE c.cart_id = :cart_id AND c.user_id = :user_id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':cart_id', $cart_id);
        $stmt->bindParam(':user_id', $user_id);
        $stmt->execute();
        
        if ($stmt->rowCount() === 0) {
            sendError('Cart item not found', 404);
        }
        
        $cart_item = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($quantity > $cart_item['stock']) {
            sendError('Insufficient stock. Available: ' . $cart_item['stock']);
        }
        
        // Update quantity
        $query = "UPDATE cart SET quantity = :quantity WHERE cart_id = :cart_id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':quantity', $quantity);
        $stmt->bindParam(':cart_id', $cart_id);
        $stmt->execute();
        
        sendSuccess('Cart updated successfully');
        
    } catch (Exception $e) {
        sendError('Failed to update cart: ' . $e->getMessage(), 500);
    }
}

// ========================================
// DELETE CART ITEM
// ========================================
else if ($_SERVER['REQUEST_METHOD'] === 'DELETE') {
    
    if (!isset($_GET['cart_id'])) {
        sendError('Cart ID is required');
    }
    
    $cart_id = intval($_GET['cart_id']);
    
    try {
        $query = "DELETE FROM cart WHERE cart_id = :cart_id AND user_id = :user_id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':cart_id', $cart_id);
        $stmt->bindParam(':user_id', $user_id);
        $stmt->execute();
        
        if ($stmt->rowCount() > 0) {
            sendSuccess('Item removed from cart');
        } else {
            sendError('Cart item not found', 404);
        }
        
    } catch (Exception $e) {
        sendError('Failed to remove item: ' . $e->getMessage(), 500);
    }
}

// ========================================
// CLEAR CART
// ========================================
else if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_GET['action']) && $_GET['action'] === 'clear') {
    
    try {
        $query = "DELETE FROM cart WHERE user_id = :user_id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':user_id', $user_id);
        $stmt->execute();
        
        sendSuccess('Cart cleared successfully');
        
    } catch (Exception $e) {
        sendError('Failed to clear cart: ' . $e->getMessage(), 500);
    }
}

// Method not allowed
else {
    sendError('Method not allowed', 405);
}
?>
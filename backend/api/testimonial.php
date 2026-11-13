<?php

require_once 'config.php';

$database = new Database();
$conn = $database->getConnection();

// ========================================
// GET APPROVED TESTIMONIALS (for homepage)
// ========================================
if ($_SERVER['REQUEST_METHOD'] === 'GET' && !isset($_GET['action'])) {
    
    try {
        $query = "SELECT t.*, u.full_name, u.username 
                  FROM testimonials t 
                  JOIN users u ON t.user_id = u.user_id 
                  WHERE t.status = 'approved' 
                  ORDER BY t.created_at DESC 
                  LIMIT 10";
        
        $stmt = $conn->prepare($query);
        $stmt->execute();
        
        $testimonials = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        sendSuccess('Testimonials retrieved successfully', [
            'testimonials' => $testimonials,
            'count' => count($testimonials)
        ]);
        
    } catch (Exception $e) {
        sendError('Failed to get testimonials: ' . $e->getMessage(), 500);
    }
}

// ========================================
// GET USER'S TESTIMONIALS
// ========================================
else if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['action']) && $_GET['action'] === 'my_testimonials') {
    
    if (!isset($_SESSION['user_id'])) {
        sendError('Please login first', 401);
    }
    
    $user_id = $_SESSION['user_id'];
    
    try {
        $query = "SELECT t.*, o.order_number 
                  FROM testimonials t 
                  LEFT JOIN orders o ON t.order_id = o.order_id 
                  WHERE t.user_id = :user_id 
                  ORDER BY t.created_at DESC";
        
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':user_id', $user_id);
        $stmt->execute();
        
        $testimonials = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        sendSuccess('User testimonials retrieved successfully', [
            'testimonials' => $testimonials,
            'count' => count($testimonials)
        ]);
        
    } catch (Exception $e) {
        sendError('Failed to get testimonials: ' . $e->getMessage(), 500);
    }
}

// ========================================
// SUBMIT TESTIMONIAL
// ========================================
else if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    
    if (!isset($_SESSION['user_id'])) {
        sendError('Please login first', 401);
    }
    
    $data = json_decode(file_get_contents("php://input"), true);
    
    if (empty($data['message'])) {
        sendError('Message is required');
    }
    
    $user_id = $_SESSION['user_id'];
    $message = trim($data['message']);
    $rating = isset($data['rating']) ? intval($data['rating']) : 5;
    $order_id = isset($data['order_id']) ? intval($data['order_id']) : null;
    
    // Validate rating
    if ($rating < 1 || $rating > 5) {
        sendError('Rating must be between 1 and 5');
    }
    
    try {
        // Check if user already submitted testimonial for this order
        if ($order_id) {
            $query = "SELECT testimonial_id FROM testimonials WHERE user_id = :user_id AND order_id = :order_id";
            $stmt = $conn->prepare($query);
            $stmt->bindParam(':user_id', $user_id);
            $stmt->bindParam(':order_id', $order_id);
            $stmt->execute();
            
            if ($stmt->rowCount() > 0) {
                sendError('You have already submitted a testimonial for this order');
            }
        }
        
        // Insert testimonial
        $query = "INSERT INTO testimonials (user_id, order_id, rating, message, status) 
                  VALUES (:user_id, :order_id, :rating, :message, 'pending')";
        
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':user_id', $user_id);
        $stmt->bindParam(':order_id', $order_id);
        $stmt->bindParam(':rating', $rating);
        $stmt->bindParam(':message', $message);
        
        if ($stmt->execute()) {
            sendSuccess('Testimonial submitted successfully. Waiting for admin approval.', [
                'testimonial_id' => $conn->lastInsertId()
            ]);
        }
        
    } catch (Exception $e) {
        sendError('Failed to submit testimonial: ' . $e->getMessage(), 500);
    }
}

// ========================================
// DELETE TESTIMONIAL (user can delete their own)
// ========================================
else if ($_SERVER['REQUEST_METHOD'] === 'DELETE') {
    
    if (!isset($_SESSION['user_id'])) {
        sendError('Please login first', 401);
    }
    
    if (!isset($_GET['testimonial_id'])) {
        sendError('Testimonial ID is required');
    }
    
    $user_id = $_SESSION['user_id'];
    $testimonial_id = intval($_GET['testimonial_id']);
    
    try {
        // Check if testimonial belongs to user
        $query = "SELECT testimonial_id FROM testimonials WHERE testimonial_id = :id AND user_id = :user_id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':id', $testimonial_id);
        $stmt->bindParam(':user_id', $user_id);
        $stmt->execute();
        
        if ($stmt->rowCount() === 0) {
            sendError('Testimonial not found or unauthorized', 404);
        }
        
        // Delete testimonial
        $query = "DELETE FROM testimonials WHERE testimonial_id = :id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':id', $testimonial_id);
        $stmt->execute();
        
        sendSuccess('Testimonial deleted successfully');
        
    } catch (Exception $e) {
        sendError('Failed to delete testimonial: ' . $e->getMessage(), 500);
    }
}

// Method not allowed
else {
    sendError('Method not allowed', 405);
}
?>
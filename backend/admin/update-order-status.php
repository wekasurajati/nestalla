<?php
session_start();
require_once '../config/database.php';
require_once '../config/email.php';

if (!isset($_SESSION['admin_id'])) {
    header('Location: login.php');
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['order_id']) && isset($_POST['status'])) {
    $order_id = intval($_POST['order_id']);
    $status = $_POST['status'];
    
    $database = new Database();
    $conn = $database->getConnection();
    
    try {
        // Get order details
        $query = "SELECT * FROM orders WHERE order_id = :order_id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':order_id', $order_id);
        $stmt->execute();
        $order = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$order) {
            $_SESSION['error'] = 'Order not found';
            header('Location: orders.php');
            exit();
        }
        
        // Update status
        $query = "UPDATE orders SET status = :status WHERE order_id = :order_id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':status', $status);
        $stmt->bindParam(':order_id', $order_id);
        
        if ($stmt->execute()) {
            // Send email notification
            try {
                $emailService = new EmailService();
                $emailService->sendOrderStatusUpdate(
                    $order['customer_email'],
                    $order['customer_name'],
                    $order['order_number'],
                    $status
                );
            } catch (Exception $e) {
                error_log('Failed to send status update email: ' . $e->getMessage());
            }
            
            $_SESSION['success'] = 'Order status updated successfully';
        }
        
    } catch (Exception $e) {
        $_SESSION['error'] = 'Failed to update order status: ' . $e->getMessage();
    }
    
    header('Location: orders.php');
    exit();
}

header('Location: orders.php');
exit();
?>
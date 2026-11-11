<?php

require_once 'config.php';

$database = new Database();
$conn = $database->getConnection();

// ✅ TAMBAHKAN INI
if(isset($_POST['update_status'])) {
    $order_id = intval($_POST['order_id']);
    $new_status = $_POST['status'];
    
    try {
        $query = "SELECT * FROM orders WHERE order_id = :order_id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':order_id', $order_id);
        $stmt->execute();
        $order_info = $stmt->fetch(PDO::FETCH_ASSOC);
        
        $query = "UPDATE orders SET status = :status WHERE order_id = :order_id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':status', $new_status);
        $stmt->bindParam(':order_id', $order_id);
        
        if($stmt->execute()) {
            try {
                require_once '../config/email.php';
                $emailService = new EmailService();
                $emailService->sendOrderStatusUpdate(
                    $order_info['customer_email'],
                    $order_info['customer_name'],
                    $order_info['order_number'],
                    $new_status
                );
                
                $_SESSION['success'] = "Order status updated and email sent!";
            } catch (Exception $e) {
                error_log('Email error: ' . $e->getMessage());
                $_SESSION['success'] = "Order status updated (email failed)";
            }
        }
    } catch (Exception $e) {
        $_SESSION['error'] = 'Update failed: ' . $e->getMessage();
    }
    
    header("Location: orders.php");
    exit;
}

// ========================================
// GET ORDERS BY USER EMAIL (✅ TAMBAHKAN INI - BARU)
// ========================================
if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['user_email'])) {
    
    $email = $_GET['user_email'];
    
    try {
        $query = "SELECT * FROM orders 
                  WHERE customer_email = :email 
                  ORDER BY created_at DESC";
        
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':email', $email);
        $stmt->execute();
        
        $orders = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Get items for each order
        foreach ($orders as &$order) {
            $query_items = "SELECT oi.*, b.image, b.title 
                           FROM order_items oi 
                           JOIN books b ON oi.book_id = b.book_id 
                           WHERE oi.order_id = :order_id";
            $stmt_items = $conn->prepare($query_items);
            $stmt_items->bindParam(':order_id', $order['order_id']);
            $stmt_items->execute();
            $order['items'] = $stmt_items->fetchAll(PDO::FETCH_ASSOC);
        }
        
        sendSuccess('Orders retrieved successfully', [
            'orders' => $orders,
            'count' => count($orders)
        ]);
        
    } catch (Exception $e) {
        sendError('Failed to get orders: ' . $e->getMessage(), 500);
    }
}

// ========================================
// GET SINGLE ORDER BY ID (✅ TAMBAHKAN INI - BARU)
// ========================================
else if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['order_id'])) {
    
    $order_id = intval($_GET['order_id']);
    
    try {
        $query = "SELECT * FROM orders WHERE order_id = :order_id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':order_id', $order_id);
        $stmt->execute();
        
        $order = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$order) {
            sendError('Order not found', 404);
        }
        
        // Get order items
        $query_items = "SELECT oi.*, b.image, b.title 
                       FROM order_items oi 
                       JOIN books b ON oi.book_id = b.book_id 
                       WHERE oi.order_id = :order_id";
        $stmt_items = $conn->prepare($query_items);
        $stmt_items->bindParam(':order_id', $order_id);
        $stmt_items->execute();
        $order['items'] = $stmt_items->fetchAll(PDO::FETCH_ASSOC);
        
        sendSuccess('Order retrieved successfully', $order);
        
    } catch (Exception $e) {
        sendError('Failed to get order: ' . $e->getMessage(), 500);
    }
}


// CREATE new order
else if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    
    // Get POST data
    $data = json_decode(file_get_contents("php://input"), true);
    
    // Validate required fields
    $required = ['customer_name', 'customer_email', 'customer_phone', 'shipping_address', 
                 'city', 'postal_code', 'province', 'payment_method', 'items'];
    
    foreach ($required as $field) {
        if (empty($data[$field])) {
            sendError("Field '$field' is required");
        }
    }
    
    // Validate items array
    if (!is_array($data['items']) || count($data['items']) == 0) {
        sendError('Cart items are required');
    }
    
    try {
        $conn->beginTransaction();
        
        // ========================================
        // TAMBAHAN: CEK STOCK DULU SEBELUM PROSES
        // ========================================
        foreach ($data['items'] as $item) {
            $query_check = "SELECT stock, title FROM books WHERE book_id = :book_id";
            $stmt_check = $conn->prepare($query_check);
            $stmt_check->bindParam(':book_id', $item['book_id']);
            $stmt_check->execute();
            $book = $stmt_check->fetch(PDO::FETCH_ASSOC);
            
            // Cek apakah buku ada
            if (!$book) {
                $conn->rollBack();
                sendError('Book not found: ' . $item['title']);
            }
            
            // Cek apakah stock cukup
            if ($book['stock'] < $item['quantity']) {
                $conn->rollBack();
                sendError('Insufficient stock for: ' . $book['title'] . '. Available: ' . $book['stock']);
            }
        }
        // ========================================
        // END PENGECEKAN STOCK
        // ========================================
        
        // Calculate totals
        $subtotal = 0;
        foreach ($data['items'] as $item) {
            $subtotal += $item['price'] * $item['quantity'];
        }
        
        $shipping_cost = isset($data['shipping_cost']) ? floatval($data['shipping_cost']) : 15000;
        $tax_rate = 0.11; // 11%
        $discount_amount = 0;
        
        // Check promo code if provided
        $promo_code = isset($data['promo_code']) ? trim($data['promo_code']) : null;
        
        if ($promo_code) {
            $query = "SELECT * FROM promo_codes 
                      WHERE code = :code 
                      AND is_active = 1 
                      AND valid_from <= CURDATE() 
                      AND valid_until >= CURDATE()";
            $stmt = $conn->prepare($query);
            $stmt->bindParam(':code', $promo_code);
            $stmt->execute();
            $promo = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if ($promo) {
                // Check usage limit
                if ($promo['usage_limit'] > 0 && $promo['used_count'] >= $promo['usage_limit']) {
                    sendError('Promo code usage limit reached');
                }
                
                if ($promo['type'] == 'percentage') {
                    $discount_amount = $subtotal * ($promo['value'] / 100);
                } else if ($promo['type'] == 'free_shipping') {
                    $discount_amount = $shipping_cost;
                    $shipping_cost = 0;
                }
                
                // Update promo usage count
                $query = "UPDATE promo_codes SET used_count = used_count + 1 WHERE promo_id = :id";
                $stmt = $conn->prepare($query);
                $stmt->bindParam(':id', $promo['promo_id']);
                $stmt->execute();
            }
        }
        
        $subtotal_after_discount = $subtotal - $discount_amount;
        $tax = round($subtotal_after_discount * $tax_rate);
        $total_amount = $subtotal_after_discount + $shipping_cost + $tax;
        
        // Generate order number
        $order_number = 'LB-' . date('Y') . '-' . str_pad(rand(1, 9999), 4, '0', STR_PAD_LEFT);
        
        // Insert order
        $query = "INSERT INTO orders (
                    order_number, customer_name, customer_email, customer_phone,
                    shipping_address, city, postal_code, province,
                    payment_method, total_amount, shipping_cost, tax, discount_amount,
                    promo_code, notes, status
                  ) VALUES (
                    :order_number, :customer_name, :customer_email, :customer_phone,
                    :shipping_address, :city, :postal_code, :province,
                    :payment_method, :total_amount, :shipping_cost, :tax, :discount_amount,
                    :promo_code, :notes, 'pending'
                  )";
        
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':order_number', $order_number);
        $stmt->bindParam(':customer_name', $data['customer_name']);
        $stmt->bindParam(':customer_email', $data['customer_email']);
        $stmt->bindParam(':customer_phone', $data['customer_phone']);
        $stmt->bindParam(':shipping_address', $data['shipping_address']);
        $stmt->bindParam(':city', $data['city']);
        $stmt->bindParam(':postal_code', $data['postal_code']);
        $stmt->bindParam(':province', $data['province']);
        $stmt->bindParam(':payment_method', $data['payment_method']);
        $stmt->bindParam(':total_amount', $total_amount);
        $stmt->bindParam(':shipping_cost', $shipping_cost);
        $stmt->bindParam(':tax', $tax);
        $stmt->bindParam(':discount_amount', $discount_amount);
        $stmt->bindParam(':promo_code', $promo_code);
        
        $notes = isset($data['notes']) ? $data['notes'] : null;
        $stmt->bindParam(':notes', $notes);
        
        $stmt->execute();
        $order_id = $conn->lastInsertId();
        
        // Insert order items
        $query = "INSERT INTO order_items (order_id, book_id, quantity, price, subtotal) 
                  VALUES (:order_id, :book_id, :quantity, :price, :subtotal)";
        $stmt = $conn->prepare($query);
        
        foreach ($data['items'] as $item) {
            $item_subtotal = $item['price'] * $item['quantity'];
            
            // Insert order item
            $stmt->bindParam(':order_id', $order_id);
            $stmt->bindParam(':book_id', $item['book_id']);
            $stmt->bindParam(':quantity', $item['quantity']);
            $stmt->bindParam(':price', $item['price']);
            $stmt->bindParam(':subtotal', $item_subtotal);
            $stmt->execute();
            
            // ========================================
            // TAMBAHAN: UPDATE STOCK (KURANGI)
            // ========================================
            $query_update = "UPDATE books 
                            SET stock = stock - :quantity 
                            WHERE book_id = :book_id";
            $stmt_update = $conn->prepare($query_update);
            $stmt_update->bindParam(':quantity', $item['quantity']);
            $stmt_update->bindParam(':book_id', $item['book_id']);
            $stmt_update->execute();
            // ========================================
            // END UPDATE STOCK
            // ========================================
        }
        
        $conn->commit();

        // ✅ SEND ORDER CONFIRMATION EMAIL
        try {
            require_once __DIR__ . '/../config/email.php';
            $emailService = new EmailService();
            
            // Prepare items for email
            $email_items = [];
            foreach ($data['items'] as $item) {
                $email_items[] = [
                    'title' => $item['title'],
                    'quantity' => $item['quantity'],
                    'price' => $item['price']
                ];
            }
            
            $emailService->sendOrderConfirmation(
                $data['customer_email'],
                $data['customer_name'],
                $order_number,
                $total_amount,
                $email_items
            );
        } catch (Exception $e) {
            error_log('Failed to send order confirmation email: ' . $e->getMessage());
        }

        sendSuccess('Order created successfully', [
            'order_id' => $order_id,
            'order_number' => $order_number,
            'total_amount' => $total_amount
        ]);
                
    } catch (Exception $e) {
        $conn->rollBack();
        sendError('Failed to create order: ' . $e->getMessage(), 500);
    }
}

// Method not allowed
else {
    sendError('Method not allowed', 405);
}
?>
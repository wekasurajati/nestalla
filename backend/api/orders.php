<?php

require_once 'config.php';

$database = new Database();
$conn = $database->getConnection();

// ========================================
// UPDATE STATUS (Admin web UI - tetap)
// ========================================
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
            // Ambil info user dari user_addresses untuk email
            $user_email = $order_info['user_id'] ? null : null;
            if ($order_info && !empty($order_info['address_id'])) {
                $addrStmt = $conn->prepare('SELECT ua.*, u.email, u.full_name FROM user_addresses ua JOIN users u ON ua.user_id = u.user_id WHERE ua.address_id = :aid');
                $addrStmt->bindParam(':aid', $order_info['address_id']);
                $addrStmt->execute();
                $addrInfo = $addrStmt->fetch(PDO::FETCH_ASSOC);
                if ($addrInfo) {
                    try {
                        require_once '../config/email.php';
                        $emailService = new EmailService();
                        $emailService->sendOrderStatusUpdate(
                            $addrInfo['email'],
                            $addrInfo['full_name'],
                            $order_info['order_number'],
                            $new_status
                        );
                        $_SESSION['success'] = "Order status updated and email sent!";
                    } catch (Exception $e) {
                        error_log('Email error: ' . $e->getMessage());
                        $_SESSION['success'] = "Order status updated (email failed)";
                    }
                }
            }
            $_SESSION['success'] = $_SESSION['success'] ?? "Order status updated!";
        }
    } catch (Exception $e) {
        $_SESSION['error'] = 'Update failed: ' . $e->getMessage();
    }
    
    header("Location: orders.php");
    exit;
}

// ========================================
// GET ORDERS BY USER (API - pakai token)
// ========================================
if ($_SERVER['REQUEST_METHOD'] === 'GET' && !isset($_GET['order_id'])) {
    $user_id = getAuthUserId();
    if (!$user_id) {
        sendError('Please login first', 401);
    }

    try {
        $query = "SELECT o.*, ua.label, ua.recipient_name, ua.phone, ua.address, ua.district, ua.city, ua.province, ua.postal_code 
                  FROM orders o 
                  LEFT JOIN user_addresses ua ON o.address_id = ua.address_id 
                  WHERE o.user_id = :id 
                  ORDER BY o.created_at DESC";
        
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':id', $user_id);
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
// GET SINGLE ORDER BY ID (API - pakai token)
// ========================================
else if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['order_id'])) {
    
    $user_id = getAuthUserId();
    if (!$user_id) {
        sendError('Please login first', 401);
    }

    $order_id = intval($_GET['order_id']);
    
    try {
        $query = "SELECT o.*, ua.label, ua.recipient_name, ua.phone, ua.address, ua.district, ua.city, ua.province, ua.postal_code 
                  FROM orders o 
                  LEFT JOIN user_addresses ua ON o.address_id = ua.address_id 
                  WHERE o.order_id = :order_id AND o.user_id = :uid";
        
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':order_id', $order_id);
        $stmt->bindParam(':uid', $user_id);
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


// CREATE new order (API - pakai token)
else if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    
    $user_id = getAuthUserId();
    if (!$user_id) {
        sendError('Please login first', 401);
    }
    
    // Get POST data
    $data = json_decode(file_get_contents("php://input"), true);
    
    // Validate required fields
    $required = ['address_id', 'payment_method', 'items'];
    
    foreach ($required as $field) {
        if (empty($data[$field])) {
            sendError("Field '$field' wajib diisi");
        }
    }
    
    // Validate items array
    if (!is_array($data['items']) || count($data['items']) == 0) {
        sendError('Item keranjang wajib diisi');
    }
    
    // Verify address belongs to user
    $addrStmt = $conn->prepare('SELECT address_id FROM user_addresses WHERE address_id = :aid AND user_id = :uid');
    $addrStmt->bindParam(':aid', $data['address_id']);
    $addrStmt->bindParam(':uid', $user_id);
    $addrStmt->execute();
    if (!$addrStmt->fetch()) {
        sendError('Alamat tidak ditemukan atau tidak milik Anda', 404);
    }
    
    try {
        $conn->beginTransaction();
        
        // Cek stock dulu sebelum proses
        foreach ($data['items'] as $item) {
            $query_check = "SELECT stock, title FROM books WHERE book_id = :book_id";
            $stmt_check = $conn->prepare($query_check);
            $stmt_check->bindParam(':book_id', $item['book_id']);
            $stmt_check->execute();
            $book = $stmt_check->fetch(PDO::FETCH_ASSOC);
            
            if (!$book) {
                $conn->rollBack();
                sendError('Buku tidak ditemukan: ' . $item['title']);
            }
            
            if ($book['stock'] < $item['quantity']) {
                $conn->rollBack();
                sendError('Stok tidak cukup untuk: ' . $book['title'] . '. Tersedia: ' . $book['stock']);
            }
        }
        
        // Hitung total
        $subtotal = 0;
        foreach ($data['items'] as $item) {
            $subtotal += $item['price'] * $item['quantity'];
        }
        
        $shipping_cost = isset($data['shipping_cost']) ? floatval($data['shipping_cost']) : 15000;
        $tax_rate = 0.11;
        $discount_amount = 0;
        
        // Cek promo code
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
                if ($promo['usage_limit'] > 0 && $promo['used_count'] >= $promo['usage_limit']) {
                    sendError('Batas penggunaan promo tercapai');
                }
                
                if ($promo['type'] == 'percentage') {
                    $discount_amount = $subtotal * ($promo['value'] / 100);
                } else if ($promo['type'] == 'free_shipping') {
                    $discount_amount = $shipping_cost;
                    $shipping_cost = 0;
                }
                
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
        
        // Insert order (tanpa kolom shipping, pakai address_id + user_id)
        $query = "INSERT INTO orders (
                    order_number, user_id, address_id, promo_id,
                    payment_method, total_amount, shipping_cost, tax, discount_amount,
                    notes, status
                  ) VALUES (
                    :order_number, :user_id, :address_id, :promo_id,
                    :payment_method, :total_amount, :shipping_cost, :tax, :discount_amount,
                    :notes, 'pending'
                  )";
        
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':order_number', $order_number);
        $stmt->bindParam(':user_id', $user_id);
        $stmt->bindParam(':address_id', $data['address_id']);
        
        $promo_id = null;
        if ($promo_code) {
            $promoStmt = $conn->prepare('SELECT promo_id FROM promo_codes WHERE code = :code');
            $promoStmt->bindParam(':code', $promo_code);
            $promoStmt->execute();
            $promoRow = $promoStmt->fetch(PDO::FETCH_ASSOC);
            $promo_id = $promoRow ? (int) $promoRow['promo_id'] : null;
        }
        $stmt->bindParam(':promo_id', $promo_id);
        $stmt->bindParam(':payment_method', $data['payment_method']);
        $stmt->bindParam(':total_amount', $total_amount);
        $stmt->bindParam(':shipping_cost', $shipping_cost);
        $stmt->bindParam(':tax', $tax);
        $stmt->bindParam(':discount_amount', $discount_amount);
        
        $notes = isset($data['notes']) ? $data['notes'] : null;
        $stmt->bindParam(':notes', $notes);
        
        $stmt->execute();
        $order_id = $conn->lastInsertId();
        
        // Insert order items
        $query = "INSERT INTO order_items (order_id, book_id, quantity, price) 
                  VALUES (:order_id, :book_id, :quantity, :price)";
        $stmt = $conn->prepare($query);
        
        foreach ($data['items'] as $item) {
            $stmt->bindParam(':order_id', $order_id);
            $stmt->bindParam(':book_id', $item['book_id']);
            $stmt->bindParam(':quantity', $item['quantity']);
            $stmt->bindParam(':price', $item['price']);
            $stmt->execute();
            
            // Update stock
            $query_update = "UPDATE books SET stock = stock - :quantity WHERE book_id = :book_id";
            $stmt_update = $conn->prepare($query_update);
            $stmt_update->bindParam(':quantity', $item['quantity']);
            $stmt_update->bindParam(':book_id', $item['book_id']);
            $stmt_update->execute();
        }
        
        $conn->commit();
        
        // Kirim email konfirmasi
        try {
            require_once __DIR__ . '/../config/email.php';
            $emailService = new EmailService();
            
            $email_items = [];
            foreach ($data['items'] as $item) {
                $email_items[] = [
                    'title' => $item['title'],
                    'quantity' => $item['quantity'],
                    'price' => $item['price']
                ];
            }
            
            // Ambil email dan nama user
            $userStmt = $conn->prepare('SELECT email, full_name FROM users WHERE user_id = :uid');
            $userStmt->bindParam(':uid', $user_id);
            $userStmt->execute();
            $userInfo = $userStmt->fetch(PDO::FETCH_ASSOC);
            
            if ($userInfo) {
                $emailService->sendOrderConfirmation(
                    $userInfo['email'],
                    $userInfo['full_name'],
                    $order_number,
                    $total_amount,
                    $email_items
                );
            }
        } catch (Exception $e) {
            error_log('Failed to send order confirmation email: ' . $e->getMessage());
        }

        sendSuccess('Order berhasil dibuat', [
            'order_id' => $order_id,
            'order_number' => $order_number,
            'total_amount' => $total_amount
        ]);
                
    } catch (Exception $e) {
        $conn->rollBack();
        sendError('Gagal membuat order: ' . $e->getMessage(), 500);
    }
}

// Method not allowed
else {
    sendError('Method not allowed', 405);
}

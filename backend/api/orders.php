<?php

require_once 'config.php';

$database = new Database();
$conn = $database->getConnection();

// ========================================
// FUNGSI BERSAMA: Terapkan status Midtrans ke order
// ========================================
function applyMidtransStatus($conn, $order, $midtrans) {
    $midtransStatus = $midtrans['transaction_status'] ?? '';
    $fraudStatus = $midtrans['fraud_status'] ?? '';
    $paymentType = $midtrans['payment_type'] ?? null;

    $newPaymentStatus = $order['payment_status'];
    $newOrderStatus = $order['status'];

    if ($midtransStatus === 'settlement' || ($midtransStatus === 'capture' && $fraudStatus === 'accept')) {
        $newPaymentStatus = 'paid';
        $newOrderStatus = 'processing';
    } elseif ($midtransStatus === 'pending') {
        // tidak berubah
    } elseif ($midtransStatus === 'deny' || $midtransStatus === 'failure') {
        $newPaymentStatus = 'failed';
        $newOrderStatus = 'cancelled';
    } elseif ($midtransStatus === 'cancel') {
        $newPaymentStatus = 'cancelled';
        $newOrderStatus = 'cancelled';
    } elseif ($midtransStatus === 'expire') {
        $newPaymentStatus = 'expired';
        $newOrderStatus = 'cancelled';
    }

    $changed = ($newPaymentStatus !== $order['payment_status'] || $newOrderStatus !== $order['status']);

    // Update order
    $query = "UPDATE orders SET payment_status = :ps, status = :os" .
        ($paymentType !== null ? ', payment_method = :pm' : '') .
        " WHERE order_id = :oid";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':ps', $newPaymentStatus);
    $stmt->bindParam(':os', $newOrderStatus);
    $stmt->bindParam(':oid', $order['order_id']);
    if ($paymentType !== null) {
        $stmt->bindParam(':pm', $paymentType);
    }
    $stmt->execute();

    // Saat PERTAMA KALI menjadi 'paid': kurangi stok dan naikkan used_count promo (idempotent)
    if ($changed && $newPaymentStatus === 'paid' && $order['payment_status'] !== 'paid') {
        // Kurangi stok buku
        $stmtItems = $conn->prepare('SELECT book_id, quantity FROM order_items WHERE order_id = :oid');
        $stmtItems->bindParam(':oid', $order['order_id']);
        $stmtItems->execute();
        $items = $stmtItems->fetchAll(PDO::FETCH_ASSOC);
        foreach ($items as $item) {
            $stmtUpd = $conn->prepare('UPDATE books SET stock = stock - :qty WHERE book_id = :bid AND stock >= :qty');
            $stmtUpd->bindParam(':qty', $item['quantity']);
            $stmtUpd->bindParam(':bid', $item['book_id']);
            $stmtUpd->execute();
        }

        // Naikkan used_count promo (hanya sekali)
        if (!empty($order['promo_id'])) {
            $stmtPromo = $conn->prepare('UPDATE promo_codes SET used_count = used_count + 1 WHERE promo_id = :pid AND used_count < usage_limit');
            $stmtPromo->bindParam(':pid', $order['promo_id']);
            $stmtPromo->execute();
        }
    }

    return [
        'order_id' => $order['order_id'],
        'status' => $newOrderStatus,
        'payment_status' => $newPaymentStatus,
        'payment_method' => $paymentType ?? $order['payment_method'],
        'total_amount' => (float) $order['total_amount'],
    ];
}

// ========================================
// FUNGSI BERSAMA: Kadaluarkan pesanan pending yang sudah lewat waktu
// ========================================
function expireStaleOrders($conn, $user_id = null) {
    try {
        $where = "payment_status = 'pending' AND created_at < DATE_SUB(NOW(), INTERVAL " . PAYMENT_EXPIRY_MINUTES . " MINUTE)";
        $params = [];

        if ($user_id !== null) {
            $where .= " AND user_id = :uid";
            $params[':uid'] = $user_id;
        }

        $query = "SELECT order_id, merchant_order_id, payment_status FROM orders WHERE " . $where;
        $stmt = $conn->prepare($query);
        foreach ($params as $key => $value) {
            $stmt->bindValue($key, $value);
        }
        $stmt->execute();
        $orders = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $urls = midtransBaseUrls();

        foreach ($orders as $order) {
            try {
                $merchantOrderId = $order['merchant_order_id'];
                $statusUrl = $urls['core'] . '/v2/' . $merchantOrderId . '/status';

                list($httpCode, $midtrans) = midtransRequest('GET', $statusUrl);

                if ($httpCode === 200 && isset($midtrans['transaction_status'])) {
                    $tempOrder = [
                        'order_id' => $order['order_id'],
                        'payment_status' => $order['payment_status'],
                        'status' => 'pending',
                    ];
                    applyMidtransStatus($conn, $tempOrder, $midtrans);
                } elseif ($httpCode === 404) {
                    // Tidak ada transaksi di Midtrans dan sudah lewat batas waktu: expire lokal
                    $upd = $conn->prepare("UPDATE orders SET payment_status='expired', status='cancelled' WHERE order_id=:oid AND payment_status='pending'");
                    $upd->bindParam(':oid', $order['order_id']);
                    $upd->execute();
                }
            } catch (Exception $e) {
                error_log('expireStaleOrders: ' . $e->getMessage());
                continue;
            }
        }
    } catch (Exception $e) {
        error_log('expireStaleOrders fatal: ' . $e->getMessage());
    }
}

// ========================================
// UPDATE STATUS (Admin web UI - tetap)
// ========================================
if (isset($_POST['update_status'])) {
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

        if ($stmt->execute()) {
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
if ($_SERVER['REQUEST_METHOD'] === 'GET' && !isset($_GET['order_id']) && !isset($_GET['action'])) {
    $user_id = getAuthUserId();
    if (!$user_id) {
        sendError('Please login first', 401);
    }

    // Kadaluarkan pesanan pending yang lewat waktu
    expireStaleOrders($conn, $user_id);

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
else if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['order_id']) && !isset($_GET['action'])) {

    $user_id = getAuthUserId();
    if (!$user_id) {
        sendError('Please login first', 401);
    }

    // Kadaluarkan pesanan pending yang lewat waktu
    expireStaleOrders($conn, $user_id);

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

        // Cek status pembayaran ke Midtrans jika masih pending
        if ($order['payment_status'] === 'pending' && !empty($order['merchant_order_id'])) {
            $urls = midtransBaseUrls();
            $statusUrl = $urls['core'] . '/v2/' . $order['merchant_order_id'] . '/status';
            list($httpCode, $midtrans) = midtransRequest('GET', $statusUrl);

            if ($httpCode === 200 && isset($midtrans['transaction_status'])) {
                $order = applyMidtransStatus($conn, $order, $midtrans);
            }
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

// ========================================
// GET CHECK PAYMENT (API - pakai token)
// ========================================
else if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['action']) && $_GET['action'] === 'check_payment') {
    $user_id = getAuthUserId();
    if (!$user_id) {
        sendError('Please login first', 401);
    }

    $order_id = isset($_GET['order_id']) ? intval($_GET['order_id']) : 0;
    if (!$order_id) {
        sendError('order_id wajib diisi');
    }

    try {
        $query = "SELECT * FROM orders WHERE order_id = :oid AND user_id = :uid";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':oid', $order_id);
        $stmt->bindParam(':uid', $user_id);
        $stmt->execute();
        $order = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$order) {
            sendError('Order not found', 404);
        }

        if (empty($order['merchant_order_id'])) {
            sendError('Order tidak memiliki transaksi Midtrans', 400);
        }

        $urls = midtransBaseUrls();
        $statusUrl = $urls['core'] . '/v2/' . $order['merchant_order_id'] . '/status';
        list($httpCode, $midtrans) = midtransRequest('GET', $statusUrl);

        if ($httpCode === 404) {
            // Midtrans belum memiliki transaksi, anggap masih pending
            sendSuccess('Payment status retrieved', [
                'order_id' => $order_id,
                'status' => $order['status'],
                'payment_status' => $order['payment_status'],
                'payment_method' => $order['payment_method'],
                'total_amount' => (float) $order['total_amount'],
            ]);
        }

        if ($httpCode !== 200) {
            sendError('Gagal memeriksa status pembayaran ke Midtrans', 502);
        }

        $result = applyMidtransStatus($conn, $order, $midtrans);
        sendSuccess('Payment status retrieved', $result);

    } catch (Exception $e) {
        sendError('Failed to check payment: ' . $e->getMessage(), 500);
    }
}

// ========================================
// CREATE new order (API - pakai token)
// ========================================
else if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_GET['action']) && $_GET['action'] === 'create') {

    $user_id = getAuthUserId();
    if (!$user_id) {
        sendError('Please login first', 401);
    }

    // Kadaluarkan pesanan pending yang lewat waktu untuk user ini
    expireStaleOrders($conn, $user_id);

    // Get POST data
    $data = json_decode(file_get_contents("php://input"), true);

    // Validate required fields
    $required = ['address_id', 'shipping_carrier_id', 'items'];
    foreach ($required as $field) {
        if (empty($data[$field])) {
            sendError("Field '$field' wajib diisi");
        }
    }

    // Validate items array
    if (!is_array($data['items']) || count($data['items']) == 0) {
        sendError('Item keranjang wajib diisi');
    }

    foreach ($data['items'] as $item) {
        if (!isset($item['book_id']) || !isset($item['quantity']) || $item['quantity'] < 1) {
            sendError('Setiap item harus memiliki book_id dan quantity >= 1');
        }
    }

    // Verify address belongs to user
    $addrStmt = $conn->prepare('SELECT address_id, province, city FROM user_addresses WHERE address_id = :aid AND user_id = :uid');
    $addrStmt->bindParam(':aid', $data['address_id']);
    $addrStmt->bindParam(':uid', $user_id);
    $addrStmt->execute();
    $address = $addrStmt->fetch(PDO::FETCH_ASSOC);
    if (!$address) {
        sendError('Alamat tidak ditemukan atau tidak milik Anda', 404);
    }

    // Verify shipping carrier
    $carrierId = intval($data['shipping_carrier_id']);
    $carrierStmt = $conn->prepare('SELECT carrier_id FROM shipping_carriers WHERE carrier_id = :cid AND is_active = 1');
    $carrierStmt->bindParam(':cid', $carrierId);
    $carrierStmt->execute();
    if (!$carrierStmt->fetch()) {
        sendError('Shipping carrier tidak valid atau tidak aktif', 400);
    }

    // Get shipping rate for this address
    $shippingCost = 0;
    $rateStmt = $conn->prepare('SELECT price FROM shipping_rates WHERE carrier_id = :cid AND province = :prov AND city = :city AND is_active = 1 ORDER BY price ASC LIMIT 1');
    $rateStmt->bindParam(':cid', $carrierId);
    $rateStmt->bindParam(':prov', $address['province']);
    $rateStmt->bindParam(':city', $address['city']);
    $rateStmt->execute();
    $rate = $rateStmt->fetch(PDO::FETCH_ASSOC);
    if ($rate) {
        $shippingCost = (float) $rate['price'];
    }

    // Hitung subtotal dari server (harga dari tabel books, jangan percaya aplikasi)
    $subtotal = 0;
    $bookDetails = []; // untuk item_details Midtrans

    foreach ($data['items'] as $item) {
        $bookStmt = $conn->prepare('SELECT book_id, title, price, stock FROM books WHERE book_id = :bid');
        $bookStmt->bindParam(':bid', $item['book_id']);
        $bookStmt->execute();
        $book = $bookStmt->fetch(PDO::FETCH_ASSOC);

        if (!$book) {
            sendError('Buku tidak ditemukan: ID ' . $item['book_id'], 404);
        }

        if ($book['stock'] < $item['quantity']) {
            sendError('Stok tidak cukup untuk: ' . $book['title'] . '. Tersedia: ' . $book['stock'], 400);
        }

        $subtotal += (float) $book['price'] * (int) $item['quantity'];

        $bookDetails[] = [
            'id' => $book['book_id'],
            'price' => (int) $book['price'],
            'quantity' => (int) $item['quantity'],
            'name' => substr($book['title'], 0, 50),
        ];
    }

    // Promo code
    $promoCode = isset($data['promo_code']) ? trim($data['promo_code']) : null;
    $promoId = null;
    $discountAmount = 0;

    if ($promoCode) {
        $promoStmt = $conn->prepare('SELECT * FROM promo_codes WHERE code = :code AND is_active = 1 AND valid_from <= CURDATE() AND valid_until >= CURDATE()');
        $promoStmt->bindParam(':code', $promoCode);
        $promoStmt->execute();
        $promo = $promoStmt->fetch(PDO::FETCH_ASSOC);

        if (!$promo) {
            sendError('Invalid or expired promo code', 400);
        }

        if ($promo['usage_limit'] > 0 && $promo['used_count'] >= $promo['usage_limit']) {
            sendError('Batas penggunaan promo tercapai', 400);
        }

        $promoId = (int) $promo['promo_id'];

        if ($promo['type'] == 'percentage') {
            $discountAmount = (float) $subtotal * ((float) $promo['value'] / 100);
        } elseif ($promo['type'] == 'free_shipping') {
            $discountAmount = $shippingCost;
            $shippingCost = 0;
        }
    }

    $tax = 0;
    $totalAmount = (float) $subtotal - $discountAmount + $shippingCost + $tax;
    if ($totalAmount < 0) {
        $totalAmount = 0;
    }
    $totalAmount = (int) round($totalAmount);

    // Generate merchant_order_id dan order_number
    $merchantOrderId = 'NST-' . date('ymdHis') . '-' . str_pad(random_int(1, 9999), 4, '0', STR_PAD_LEFT);
    $merchantOrderId = preg_replace('/[^A-Za-z0-9_-]/', '', $merchantOrderId);
    $merchantOrderId = substr($merchantOrderId, 0, 50);
    $orderNumber = $merchantOrderId;

    $notes = isset($data['notes']) ? $data['notes'] : null;

    try {
        $conn->beginTransaction();

        // Insert order
        $query = "INSERT INTO orders (
                    order_number, user_id, address_id, shipping_carrier_id, promo_id,
                    payment_method, total_amount, shipping_cost, tax, discount_amount,
                    notes, status, payment_status, merchant_order_id
                  ) VALUES (
                    :order_number, :user_id, :address_id, :shipping_carrier_id, :promo_id,
                    'midtrans', :total_amount, :shipping_cost, :tax, :discount_amount,
                    :notes, 'pending', 'pending', :merchant_order_id
                  )";

        $stmt = $conn->prepare($query);
        $stmt->bindParam(':order_number', $orderNumber);
        $stmt->bindParam(':user_id', $user_id);
        $stmt->bindParam(':address_id', $data['address_id']);
        $stmt->bindParam(':shipping_carrier_id', $carrierId);
        $stmt->bindParam(':promo_id', $promoId);
        $stmt->bindParam(':total_amount', $totalAmount);
        $stmt->bindParam(':shipping_cost', $shippingCost);
        $stmt->bindParam(':tax', $tax);
        $stmt->bindParam(':discount_amount', $discountAmount);
        $stmt->bindParam(':notes', $notes);
        $stmt->bindParam(':merchant_order_id', $merchantOrderId);
        $stmt->execute();
        $orderId = (int) $conn->lastInsertId();

        // Insert order items
        $query = "INSERT INTO order_items (order_id, book_id, quantity, price) 
                  VALUES (:order_id, :book_id, :quantity, :price)";
        $stmt = $conn->prepare($query);

        foreach ($data['items'] as $item) {
            $bookStmt = $conn->prepare('SELECT price FROM books WHERE book_id = :bid');
            $bookStmt->bindParam(':bid', $item['book_id']);
            $bookStmt->execute();
            $bookPrice = $bookStmt->fetch(PDO::FETCH_ASSOC);

            $stmt->bindParam(':order_id', $orderId);
            $stmt->bindParam(':book_id', $item['book_id']);
            $stmt->bindParam(':quantity', $item['quantity']);
            $stmt->bindParam(':price', $bookPrice['price']);
            $stmt->execute();
        }

        // Minta Snap token ke Midtrans
        $urls = midtransBaseUrls();

        $itemDetails = $bookDetails;
        // Tambahkan entri Ongkos Kirim
        if ($shippingCost > 0) {
            $itemDetails[] = [
                'id' => 'shipping',
                'price' => (int) $shippingCost,
                'quantity' => 1,
                'name' => 'Ongkos Kirim',
            ];
        }
        // Tambahkan entri Diskon Promo (harga negatif)
        if ($discountAmount > 0) {
            $itemDetails[] = [
                'id' => 'discount',
                'price' => -(int) round($discountAmount),
                'quantity' => 1,
                'name' => 'Diskon Promo',
            ];
        }

        // Ambil data user untuk customer_details
        $userStmt = $conn->prepare('SELECT full_name, email, phone FROM users WHERE user_id = :uid');
        $userStmt->bindParam(':uid', $user_id);
        $userStmt->execute();
        $userInfo = $userStmt->fetch(PDO::FETCH_ASSOC);

        $snapBody = [
            'transaction_details' => [
                'order_id' => $merchantOrderId,
                'gross_amount' => $totalAmount,
            ],
            'item_details' => $itemDetails,
            'customer_details' => [
                'first_name' => $userInfo['full_name'] ?? 'Customer',
                'email' => $userInfo['email'] ?? '',
                'phone' => $userInfo['phone'] ?? '',
            ],
            'expiry' => [
                'unit' => 'minutes',
                'duration' => PAYMENT_EXPIRY_MINUTES,
            ],
            'callbacks' => [
                'finish' => PAYMENT_FINISH_URL,
            ],
        ];

        list($snapHttpCode, $snapResponse) = midtransRequest('POST', $urls['snap'], $snapBody);

        if (!isset($snapResponse['token']) || empty($snapResponse['token'])) {
            $conn->rollBack();
            sendError('Gagal membuat pembayaran', 502);
        }

        $snapToken = $snapResponse['token'] ?? '';
        $snapRedirectUrl = $snapResponse['redirect_url'] ?? '';

        // Simpan token dan redirect_url
        $query = "UPDATE orders SET snap_token = :token, snap_redirect_url = :url WHERE order_id = :oid";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':token', $snapToken);
        $stmt->bindParam(':url', $snapRedirectUrl);
        $stmt->bindParam(':oid', $orderId);
        $stmt->execute();

        $conn->commit();

        sendSuccess('Order berhasil dibuat', [
            'order_id' => $orderId,
            'order_number' => $orderNumber,
            'merchant_order_id' => $merchantOrderId,
            'total_amount' => $totalAmount,
            'snap_token' => $snapToken,
            'snap_redirect_url' => $snapRedirectUrl,
            'expires_at' => date('Y-m-d H:i:s', time() + PAYMENT_EXPIRY_MINUTES * 60),
        ]);

    } catch (Exception $e) {
        $conn->rollBack();
        sendError('Gagal membuat order: ' . $e->getMessage(), 500);
    }
}

// ========================================
// MIDTRANS NOTIFICATION (Webhook - TANPA login)
// ========================================
else if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_GET['action']) && $_GET['action'] === 'midtrans_notification') {

    $data = json_decode(file_get_contents("php://input"), true);

    if (empty($data['order_id']) || empty($data['status_code']) || empty($data['gross_amount']) || empty($data['signature_key'])) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'Missing fields']);
        exit;
    }

    // Verifikasi signature
    $serverKey = env('MIDTRANS_SERVER_KEY', '');
    $expectedSignature = hash('sha512', $data['order_id'] . $data['status_code'] . $data['gross_amount'] . $serverKey);

    if ($data['signature_key'] !== $expectedSignature) {
        http_response_code(401);
        echo json_encode(['status' => 'error', 'message' => 'Invalid signature']);
        exit;
    }

    $merchantOrderId = $data['order_id'];

    try {
        // Cari order berdasarkan merchant_order_id
        $stmt = $conn->prepare('SELECT * FROM orders WHERE merchant_order_id = :moid');
        $stmt->bindParam(':moid', $merchantOrderId);
        $stmt->execute();
        $order = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$order) {
            http_response_code(404);
            echo json_encode(['status' => 'error', 'message' => 'Order not found']);
            exit;
        }

        applyMidtransStatus($conn, $order, $data);

        http_response_code(200);
        echo json_encode(['status' => 'success']);
    } catch (Exception $e) {
        error_log('Midtrans notification error: ' . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Internal error']);
    }
    exit;
}

// Method not allowed
else {
    sendError('Method not allowed', 405);
}

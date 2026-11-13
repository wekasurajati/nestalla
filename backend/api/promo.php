<?php


require_once 'config.php';

$database = new Database();
$conn = $database->getConnection();

// VALIDATE promo code
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    
    $data = json_decode(file_get_contents("php://input"), true);
    
    if (empty($data['code'])) {
        sendError('Promo code is required');
    }
    
    if (empty($data['subtotal'])) {
        sendError('Subtotal is required');
    }
    
    $code = strtoupper(trim($data['code']));
    $subtotal = floatval($data['subtotal']);
    $shipping_cost = isset($data['shipping_cost']) ? floatval($data['shipping_cost']) : 15000;
    
    try {
        $query = "SELECT * FROM promo_codes 
                  WHERE code = :code 
                  AND is_active = 1 
                  AND valid_from <= CURDATE() 
                  AND valid_until >= CURDATE()";
        
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':code', $code);
        $stmt->execute();
        
        $promo = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$promo) {
            sendError('Invalid or expired promo code', 404);
        }
        
        // Check usage limit
        if ($promo['usage_limit'] > 0 && $promo['used_count'] >= $promo['usage_limit']) {
            sendError('Promo code usage limit reached');
        }
        
        // Calculate discount
        $discount_amount = 0;
        $new_shipping_cost = $shipping_cost;
        $discount_type = '';
        
        if ($promo['type'] == 'percentage') {
            $discount_amount = $subtotal * ($promo['value'] / 100);
            $discount_type = $promo['value'] . '% discount';
        } else if ($promo['type'] == 'free_shipping') {
            $discount_amount = $shipping_cost;
            $new_shipping_cost = 0;
            $discount_type = 'Free shipping';
        }
        
        sendSuccess('Promo code is valid', [
            'code' => $promo['code'],
            'type' => $promo['type'],
            'value' => $promo['value'],
            'description' => $promo['description'],
            'discount_amount' => $discount_amount,
            'discount_type' => $discount_type,
            'new_shipping_cost' => $new_shipping_cost
        ]);
        
    } catch (Exception $e) {
        sendError('Failed to validate promo: ' . $e->getMessage(), 500);
    }
}

// Method not allowed
else {
    sendError('Method not allowed', 405);
}
?>

<?php

require_once 'config.php';

$database = new Database();
$conn = $database->getConnection();

// ========================================
// GET SHIPPING CARRIERS AND RATES
// ========================================
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $province = isset($_GET['province']) ? trim($_GET['province']) : null;
    $city = isset($_GET['city']) ? trim($_GET['city']) : null;

    // Ambil semua carrier aktif
    $query = "SELECT * FROM shipping_carriers WHERE is_active = 1 ORDER BY carrier_name ASC";
    $stmt = $conn->prepare($query);
    $stmt->execute();
    $carriers = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $result = [];

    foreach ($carriers as $carrier) {
        $carrierId = (int) $carrier['carrier_id'];

        // Ambil rate untuk carrier ini (filter provinsi/kota jika disediakan)
        $rateQuery = "SELECT * FROM shipping_rates WHERE carrier_id = :cid AND is_active = 1";
        $rateParams = [':cid' => $carrierId];

        if ($province) {
            $rateQuery .= " AND province = :province";
            $rateParams[':province'] = $province;
        }
        if ($city) {
            $rateQuery .= " AND city = :city";
            $rateParams[':city'] = $city;
        }

        $rateQuery .= " ORDER BY price ASC";
        $rateStmt = $conn->prepare($rateQuery);
        foreach ($rateParams as $key => $value) {
            $rateStmt->bindValue($key, $value);
        }
        $rateStmt->execute();
        $rates = $rateStmt->fetchAll(PDO::FETCH_ASSOC);

        $result[] = [
            'id' => (int) $carrier['carrier_id'],
            'name' => $carrier['carrier_name'],
            'price' => !empty($rates) ? (float) $rates[0]['price'] : 0,
            'rates' => array_map(function ($r) {
                return [
                    'id' => (int) $r['rate_id'],
                    'province' => $r['province'],
                    'city' => $r['city'],
                    'price' => (float) $r['price'],
                ];
            }, $rates),
        ];
    }

    sendSuccess('Shipping carriers retrieved', $result);
}

// Method not allowed
sendError('Method not allowed', 405);

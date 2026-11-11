<?php

require_once 'config.php';

$database = new Database();
$conn = $database->getConnection();

// ========================================
// LIST ALAMAT (GET)
// ========================================
if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['action']) && $_GET['action'] === 'addresses') {
    $user_id = getAuthUserId();
    if (!$user_id) {
        sendError('Please login first', 401);
    }

    $stmt = $conn->prepare('SELECT * FROM user_addresses WHERE user_id = :id ORDER BY is_default DESC, created_at DESC');
    $stmt->bindParam(':id', $user_id);
    $stmt->execute();
    $addresses = $stmt->fetchAll(PDO::FETCH_ASSOC);

    sendSuccess('Daftar alamat', $addresses);
}

// ========================================
// TAMBAH ALAMAT (POST)
// ========================================
else if ($_SERVER['REQUEST_METHOD'] === 'POST' && !isset($_GET['action'])) {
    $user_id = getAuthUserId();
    if (!$user_id) {
        sendError('Please login first', 401);
    }

    $data = json_decode(file_get_contents("php://input"), true);

    $required = ['recipient_name', 'phone', 'address', 'city', 'province', 'postal_code'];
    foreach ($required as $field) {
        if (empty($data[$field])) {
            sendError("Field '{$field}' wajib diisi");
        }
    }

    $label = isset($data['label']) ? trim($data['label']) : null;
    $recipient_name = trim($data['recipient_name']);
    $phone = trim($data['phone']);
    $address = trim($data['address']);
    $district = isset($data['district']) ? trim($data['district']) : null;
    $city = trim($data['city']);
    $province = trim($data['province']);
    $postal_code = trim($data['postal_code']);
    $latitude = isset($data['latitude']) ? (float) $data['latitude'] : null;
    $longitude = isset($data['longitude']) ? (float) $data['longitude'] : null;
    $is_default = isset($data['is_default']) && $data['is_default'] === true ? 1 : 0;

    try {
        // Jika ditandai default, matikan default alamat lain
        if ($is_default) {
            $stmt = $conn->prepare('UPDATE user_addresses SET is_default = 0 WHERE user_id = :id');
            $stmt->bindParam(':id', $user_id);
            $stmt->execute();
        }

        $stmt = $conn->prepare("INSERT INTO user_addresses (user_id, label, recipient_name, phone, address, district, city, province, postal_code, latitude, longitude, is_default) 
                                VALUES (:user_id, :label, :recipient_name, :phone, :address, :district, :city, :province, :postal_code, :latitude, :longitude, :is_default)");
        $stmt->bindParam(':user_id', $user_id);
        $stmt->bindParam(':label', $label);
        $stmt->bindParam(':recipient_name', $recipient_name);
        $stmt->bindParam(':phone', $phone);
        $stmt->bindParam(':address', $address);
        $stmt->bindParam(':district', $district);
        $stmt->bindParam(':city', $city);
        $stmt->bindParam(':province', $province);
        $stmt->bindParam(':postal_code', $postal_code);
        $stmt->bindParam(':latitude', $latitude);
        $stmt->bindParam(':longitude', $longitude);
        $stmt->bindParam(':is_default', $is_default);
        $stmt->execute();

        $address_id = $conn->lastInsertId();

        sendSuccess('Alamat berhasil ditambahkan', ['address_id' => (int) $address_id]);
    } catch (Exception $e) {
        sendError('Gagal menambahkan alamat: ' . $e->getMessage(), 500);
    }
}

// ========================================
// SET DEFAULT ALAMAT (POST action=set_default)
// ========================================
else if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_GET['action']) && $_GET['action'] === 'set_default') {
    $user_id = getAuthUserId();
    if (!$user_id) {
        sendError('Please login first', 401);
    }

    $data = json_decode(file_get_contents("php://input"), true);

    if (empty($data['address_id'])) {
        sendError('address_id wajib diisi');
    }

    $address_id = (int) $data['address_id'];

    try {
        $conn->beginTransaction();

        // Matikan semua default untuk user ini
        $stmt = $conn->prepare('UPDATE user_addresses SET is_default = 0 WHERE user_id = :id');
        $stmt->bindParam(':id', $user_id);
        $stmt->execute();

        // Set alamat yang dipilih sebagai default
        $stmt = $conn->prepare('UPDATE user_addresses SET is_default = 1 WHERE address_id = :id AND user_id = :uid');
        $stmt->bindParam(':id', $address_id);
        $stmt->bindParam(':uid', $user_id);
        $stmt->execute();

        if ($stmt->rowCount() === 0) {
            $conn->rollBack();
            sendError('Alamat tidak ditemukan atau tidak milik Anda', 404);
        }

        $conn->commit();
        sendSuccess('Alamat utama diperbarui');
    } catch (Exception $e) {
        $conn->rollBack();
        sendError('Gagal memperbarui alamat utama: ' . $e->getMessage(), 500);
    }
}

// ========================================
// UBAH ALAMAT (PUT)
// ========================================
else if ($_SERVER['REQUEST_METHOD'] === 'PUT' && isset($_GET['action']) && $_GET['action'] === 'addresses') {
    $user_id = getAuthUserId();
    if (!$user_id) {
        sendError('Please login first', 401);
    }

    $address_id = isset($_GET['id']) ? (int) $_GET['id'] : 0;
    if (!$address_id) {
        sendError('address_id wajib disertakan');
    }

    $data = json_decode(file_get_contents("php://input"), true);

    $is_default = isset($data['is_default']) && $data['is_default'] === true ? 1 : 0;

    try {
        $conn->beginTransaction();

        // Jika ditandai default, matikan default alamat lain
        if ($is_default) {
            $stmt = $conn->prepare('UPDATE user_addresses SET is_default = 0 WHERE user_id = :id AND address_id != :aid');
            $stmt->bindParam(':id', $user_id);
            $stmt->bindParam(':aid', $address_id);
            $stmt->execute();
        }

        $fields = [];
        $params = [];

        $updatable = [
            'label' => 'label',
            'recipient_name' => 'recipient_name',
            'phone' => 'phone',
            'address' => 'address',
            'district' => 'district',
            'city' => 'city',
            'province' => 'province',
            'postal_code' => 'postal_code',
            'latitude' => 'latitude',
            'longitude' => 'longitude',
            'is_default' => 'is_default',
        ];

        foreach ($updatable as $inputKey => $dbKey) {
            if (array_key_exists($inputKey, $data)) {
                $fields[] = "{$dbKey} = :{$inputKey}";
                $params[$inputKey] = $data[$inputKey];
            }
        }

        if (empty($fields)) {
            $conn->rollBack();
            sendError('Tidak ada field yang diupdate');
        }

        $params['id'] = $address_id;
        $params['uid'] = $user_id;

        $sql = "UPDATE user_addresses SET " . implode(', ', $fields) . " WHERE address_id = :id AND user_id = :uid";
        $stmt = $conn->prepare($sql);

        foreach ($params as $key => $value) {
            $stmt->bindValue(":$key", $value);
        }

        $stmt->execute();

        if ($stmt->rowCount() === 0) {
            $conn->rollBack();
            sendError('Alamat tidak ditemukan atau tidak milik Anda', 404);
        }

        $conn->commit();
        sendSuccess('Alamat berhasil diperbarui');
    } catch (Exception $e) {
        $conn->rollBack();
        sendError('Gagal memperbarui alamat: ' . $e->getMessage(), 500);
    }
}

// ========================================
// HAPUS ALAMAT (DELETE)
// ========================================
else if ($_SERVER['REQUEST_METHOD'] === 'DELETE' && isset($_GET['action']) && $_GET['action'] === 'addresses') {
    $user_id = getAuthUserId();
    if (!$user_id) {
        sendError('Please login first', 401);
    }

    $address_id = isset($_GET['id']) ? (int) $_GET['id'] : 0;
    if (!$address_id) {
        sendError('address_id wajib disertakan');
    }

    try {
        $conn->beginTransaction();

        // Cek apakah alamat adalah default
        $stmt = $conn->prepare('SELECT is_default FROM user_addresses WHERE address_id = :id AND user_id = :uid');
        $stmt->bindParam(':id', $address_id);
        $stmt->bindParam(':uid', $user_id);
        $stmt->execute();
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$row) {
            $conn->rollBack();
            sendError('Alamat tidak ditemukan atau tidak milik Anda', 404);
        }

        $was_default = (int) $row['is_default'] === 1;

        // Hapus alamat
        $stmt = $conn->prepare('DELETE FROM user_addresses WHERE address_id = :id AND user_id = :uid');
        $stmt->bindParam(':id', $address_id);
        $stmt->bindParam(':uid', $user_id);
        $stmt->execute();

        // Jika alamat yang dihapus adalah default, set alamat lain sebagai default
        if ($was_default) {
            $stmt = $conn->prepare('SELECT address_id FROM user_addresses WHERE user_id = :uid ORDER BY created_at ASC LIMIT 1');
            $stmt->bindParam(':uid', $user_id);
            $stmt->execute();
            $next = $stmt->fetch(PDO::FETCH_ASSOC);

            if ($next) {
                $stmt = $conn->prepare('UPDATE user_addresses SET is_default = 1 WHERE address_id = :id');
                $stmt->bindParam(':id', $next['address_id']);
                $stmt->execute();
            }
        }

        $conn->commit();
        sendSuccess('Alamat berhasil dihapus');
    } catch (Exception $e) {
        $conn->rollBack();
        sendError('Gagal menghapus alamat: ' . $e->getMessage(), 500);
    }
}

// Method not allowed
else {
    sendError('Method not allowed', 405);
}

<?php




require_once 'config.php';

$database = new Database();
$conn = $database->getConnection();


// REGISTER

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_GET['action']) && $_GET['action'] === 'register') {
    
    $data = json_decode(file_get_contents("php://input"), true);
    
    $required = ['username', 'email', 'password', 'full_name'];
    foreach ($required as $field) {
        if (empty($data[$field])) {
            sendError("Field '{$field}' is required");
        }
    }
    
    if (!filter_var($data['email'], FILTER_VALIDATE_EMAIL)) {
        sendError('Invalid email format');
    }
    
    if (strlen($data['password']) < 6) {
        sendError('Password must be at least 6 characters');
    }
    
    $username = strtolower(trim($data['username']));
    $email = strtolower(trim($data['email']));
    $full_name = trim($data['full_name']);
    $phone = isset($data['phone']) ? trim($data['phone']) : null;
    
    try {
        // Check username exists
        $query = "SELECT user_id FROM users WHERE username = :username";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':username', $username);
        $stmt->execute();
        
        if ($stmt->rowCount() > 0) {
            sendError('Username already exists');
        }
        
        // Check email exists
        $query = "SELECT user_id FROM users WHERE email = :email";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':email', $email);
        $stmt->execute();
        
        if ($stmt->rowCount() > 0) {
            sendError('Email already exists');
        }
        
        // Hash password
        $password_hash = password_hash($data['password'], PASSWORD_DEFAULT);
        
        // Insert user
        $query = "INSERT INTO users (username, email, password, full_name, phone, role) 
                  VALUES (:username, :email, :password, :full_name, :phone, 'customer')";
        
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':username', $username);
        $stmt->bindParam(':email', $email);
        $stmt->bindParam(':password', $password_hash);
        $stmt->bindParam(':full_name', $full_name);
        $stmt->bindParam(':phone', $phone);
        
       if ($stmt->execute()) {
         $user_id = $conn->lastInsertId();
    
        // Auto login after register
        $_SESSION['user_id'] = $user_id;
        $_SESSION['username'] = $username;
        $_SESSION['full_name'] = $full_name;
        $_SESSION['email'] = $email;
    
        // ✅ SEND WELCOME EMAIL
        try {
            require_once __DIR__ . '/../config/email.php';
            $emailService = new EmailService();
            $emailService->sendWelcomeEmail($email, $full_name);
        } catch (Exception $e) {
            error_log('Failed to send welcome email: ' . $e->getMessage());
        }
        $token = createApiToken($conn, $user_id);
        sendSuccess('Registration successful', [
            'user_id' => $user_id,
            'username' => $username,
            'full_name' => $full_name,
            'email' => $email
        ]);
    }
        
    } catch (Exception $e) {
        sendError('Registration failed: ' . $e->getMessage(), 500);
    }
}


// LOGIN USER

else if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_GET['action']) && $_GET['action'] === 'login') {
    
    $data = json_decode(file_get_contents("php://input"), true);
    
    if (empty($data['username']) || empty($data['password'])) {
        sendError('Username and password are required');
    }
    
    $username = strtolower(trim($data['username']));
    $password = $data['password'];
    
    try {
        $query = "SELECT * FROM users WHERE (username = :username OR email = :username) AND role = 'customer'";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':username', $username);
        $stmt->execute();
        
        if ($stmt->rowCount() > 0) {
            $user = $stmt->fetch(PDO::FETCH_ASSOC);
            
            // Verify password
            if (password_verify($password, $user['password'])) {
                
                // Set session
                $_SESSION['user_id'] = $user['user_id'];
                $_SESSION['username'] = $user['username'];
                $_SESSION['full_name'] = $user['full_name'];
                $_SESSION['email'] = $user['email'];
                
                $token = createApiToken($conn, $user['user_id']);

sendSuccess('Login successful', [
    'token' => $token,
    'user_id' => $user['user_id'],
    'username' => $user['username'],
    'full_name' => $user['full_name'],
    'email' => $user['email'],
    'phone' => $user['phone'],
    'role' => $user['role'],
    'birth_date' => $user['birth_date']
]);
} else {
    sendError('Invalid username or password', 401);
}
} else {
    sendError('Invalid username or password', 401);
}
        
    } catch (Exception $e) {
        sendError('Login failed: ' . $e->getMessage(), 500);
    }
}

// ========================================
// LOGOUT
// ========================================
else if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_GET['action']) && $_GET['action'] === 'logout') {
    revokeApiToken($conn);
    session_destroy();
    sendSuccess('Logout successful');
}
// ========================================
// CHECK SESSION (Get current user)
// ========================================
else if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['action']) && $_GET['action'] === 'check') {
    $uid = getAuthUserId();
    if (!$uid) {
        sendError('Not logged in', 401);
    }
    $stmt = $conn->prepare('SELECT user_id, username, full_name, email, phone, birth_date, role FROM users WHERE user_id = :id');
    $stmt->bindParam(':id', $uid);
    $stmt->execute();
    sendSuccess('User is logged in', $stmt->fetch(PDO::FETCH_ASSOC));
}

// ========================================
// UPDATE PROFILE
// ========================================
else if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_GET['action']) && $_GET['action'] === 'update_profile') {

    $user_id = getAuthUserId();
    if (!$user_id) {
        sendError('Please login first', 401);
    }

    $data = json_decode(file_get_contents("php://input"), true);

    if (empty($data['full_name'])) {
        sendError('Full name is required');
    }

    $full_name = trim($data['full_name']);
    $phone = (isset($data['phone']) && trim($data['phone']) !== '') ? trim($data['phone']) : null;

    $birth_date = null;
    if (!empty($data['birth_date'])) {
        $d = DateTime::createFromFormat('Y-m-d', $data['birth_date']);
        if (!$d || $d->format('Y-m-d') !== $data['birth_date'] || $d > new DateTime()) {
            sendError('Invalid birth date');
        }
        $birth_date = $data['birth_date'];
    }

    try {
        $stmt = $conn->prepare("UPDATE users SET full_name = :full_name, phone = :phone, birth_date = :birth_date WHERE user_id = :user_id");
        $stmt->bindParam(':full_name', $full_name);
        $stmt->bindParam(':phone', $phone);
        $stmt->bindParam(':birth_date', $birth_date);
        $stmt->bindParam(':user_id', $user_id);
        $stmt->execute();

        sendSuccess('Profile updated successfully', [
            'full_name' => $full_name,
            'phone' => $phone,
            'birth_date' => $birth_date
        ]);
    } catch (Exception $e) {
        sendError('Failed to update profile: ' . $e->getMessage(), 500);
    }
}

// ========================================
// CHANGE PASSWORD
// ========================================
else if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_GET['action']) && $_GET['action'] === 'change_password') {
    
    if (!isset($_SESSION['user_id'])) {
        sendError('Please login first', 401);
    }
    
    $data = json_decode(file_get_contents("php://input"), true);
    
    if (empty($data['current_password']) || empty($data['new_password'])) {
        sendError('Current password and new password are required');
    }
    
    if (strlen($data['new_password']) < 6) {
        sendError('New password must be at least 6 characters');
    }
    
    $user_id = $_SESSION['user_id'];
    $current_password = $data['current_password'];
    $new_password = $data['new_password'];
    
    try {
        // Get current password hash
        $query = "SELECT password FROM users WHERE user_id = :user_id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':user_id', $user_id);
        $stmt->execute();
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        
        // Verify current password
        if (!password_verify($current_password, $user['password'])) {
            sendError('Current password is incorrect');
        }
        
        // Hash new password
        $new_password_hash = password_hash($new_password, PASSWORD_DEFAULT);
        
        // Update password
        $query = "UPDATE users SET password = :password WHERE user_id = :user_id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':password', $new_password_hash);
        $stmt->bindParam(':user_id', $user_id);
        
        if ($stmt->execute()) {
            // ✅ SEND PASSWORD CHANGED EMAIL
            try {
                require_once __DIR__ . '/../config/email.php';
                $emailService = new EmailService();
                $emailService->sendPasswordChangedEmail($_SESSION['email'], $_SESSION['full_name']);
            } catch (Exception $e) {
                error_log('Failed to send password changed email: ' . $e->getMessage());
            }
            
            sendSuccess('Password changed successfully');
        }
        
    } catch (Exception $e) {
        sendError('Failed to change password: ' . $e->getMessage(), 500);
    }
}

// ========================================
// DELETE ACCOUNT
// ========================================
else if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_GET['action']) && $_GET['action'] === 'delete_account') {
    
    if (!isset($_SESSION['user_id'])) {
        sendError('Please login first', 401);
    }
    
    $user_id = $_SESSION['user_id'];
    
    try {
        $conn->beginTransaction();
        
        // Delete cart
        $query = "DELETE FROM cart WHERE user_id = :user_id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':user_id', $user_id);
        $stmt->execute();
        
        // Delete wishlist
        $query = "DELETE FROM wishlist WHERE user_id = :user_id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':user_id', $user_id);
        $stmt->execute();
        
        // Delete user
        $query = "DELETE FROM users WHERE user_id = :user_id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':user_id', $user_id);
        $stmt->execute();
        
        $conn->commit();
        
        // Destroy session
        session_destroy();
        
        sendSuccess('Account deleted successfully');
        
    } catch (Exception $e) {
        $conn->rollBack();
        sendError('Failed to delete account: ' . $e->getMessage(), 500);
    }
}

// ========================================
// UPLOAD AVATAR
// ========================================
else if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_GET['action']) && $_GET['action'] === 'upload_avatar') {
    $user_id = getAuthUserId();
    if (!$user_id) {
        sendError('Please login first', 401);
    }

    if (!isset($_FILES['avatar']) || $_FILES['avatar']['error'] !== UPLOAD_ERR_OK) {
        sendError('File avatar tidak ditemukan atau gagal diunggah', 400);
    }

    $file = $_FILES['avatar'];

    if ($file['size'] > 2 * 1024 * 1024) {
        sendError('Ukuran file maksimal 2 MB', 400);
    }

    $finfo = finfo_open(FILEINFO_MIME_TYPE);
    $mime = finfo_file($finfo, $file['tmp_name']);
    finfo_close($finfo);
    $allowed = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
    if (!in_array($mime, $allowed, true)) {
        sendError('Hanya file gambar (JPG, PNG, WEBP) yang diperbolehkan', 400);
    }

    $uploadDir = __DIR__ . '/../image/avatars/';
    if (!is_dir($uploadDir)) {
        mkdir($uploadDir, 0755, true);
    }

    $ext = pathinfo($file['name'], PATHINFO_EXTENSION);
    $filename = 'avatar_' . $user_id . '_' . uniqid('', true) . '.' . $ext;
    $destination = $uploadDir . $filename;

    if (!move_uploaded_file($file['tmp_name'], $destination)) {
        sendError('Gagal menyimpan file avatar', 500);
    }

    $stmt = $conn->prepare('SELECT avatar FROM users WHERE user_id = :id');
    $stmt->bindParam(':id', $user_id);
    $stmt->execute();
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if ($row && !empty($row['avatar'])) {
        $oldPath = $uploadDir . $row['avatar'];
        if (file_exists($oldPath)) {
            @unlink($oldPath);
        }
    }

    $stmt = $conn->prepare('UPDATE users SET avatar = :avatar WHERE user_id = :id');
    $stmt->bindParam(':avatar', $filename);
    $stmt->bindParam(':id', $user_id);
    $stmt->execute();

    sendSuccess('Foto profil berhasil diperbarui', ['avatar' => $filename]);
}

// Method not allowed
else {
    sendError('Method not allowed', 405);
}
?>
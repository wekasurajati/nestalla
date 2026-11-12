<?php




require_once 'config.php';

$database = new Database();
$conn = $database->getConnection();

require_once '../config/email.php';
$emailService = new EmailService();


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
            
            // Akun tanpa kata sandi (dibuat lewat Google) diperlakukan seperti kata sandi salah
            if ($user['password'] === null) {
                sendError('Invalid username or password', 401);
            }

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
    'birth_date' => $user['birth_date'],
    'avatar' => $user['avatar'] ?? null,
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
// GOOGLE LOGIN
// ========================================
else if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_GET['action']) && $_GET['action'] === 'google_login') {

    $data = json_decode(file_get_contents("php://input"), true);
    $idToken = trim($data['id_token'] ?? '');
    if ($idToken === '') {
        sendError('ID token is required');
    }

    try {
        $google = verifyGoogleIdToken($idToken);
    } catch (Exception $e) {
        sendError('Tidak dapat menghubungi Google. Coba lagi.', 502);
    }
    if (!$google) {
        sendError('Token Google tidak valid', 401);
    }

    $sub = $google['sub'];
    $email = strtolower(trim($google['email']));
    $googleName = trim($google['name'] ?? '');

    try {
        $conn->beginTransaction();
        $isNewAccount = false;

        // 1. Identitas Google ini sudah pernah tertaut ke sebuah akun?
        $stmt = $conn->prepare("SELECT user_id FROM user_auth_providers WHERE provider = 'google' AND provider_id = :sub");
        $stmt->bindParam(':sub', $sub);
        $stmt->execute();
        $user_id = $stmt->fetchColumn();

        if (!$user_id) {
            // 2. Email sudah terdaftar? Kalau ya, pakai akun lama (nama dan kata sandi TIDAK diubah)
            $stmt = $conn->prepare('SELECT user_id FROM users WHERE email = :email');
            $stmt->bindParam(':email', $email);
            $stmt->execute();
            $user_id = $stmt->fetchColumn();

            if (!$user_id) {
                // 3. Belum ada: buat akun baru tanpa kata sandi
                $username = generateUniqueUsername($conn, $email);
                $full_name = $googleName !== '' ? $googleName : $username;

                $stmt = $conn->prepare("INSERT INTO users (username, email, password, full_name, role) VALUES (:username, :email, NULL, :full_name, 'customer')");
                $stmt->bindParam(':username', $username);
                $stmt->bindParam(':email', $email);
                $stmt->bindParam(':full_name', $full_name);
                $stmt->execute();
                $user_id = (int) $conn->lastInsertId();
                $isNewAccount = true;
            } else {
                // Akun lama sudah tertaut ke akun Google yang berbeda?
                $stmt = $conn->prepare("SELECT provider_id FROM user_auth_providers WHERE user_id = :user_id AND provider = 'google'");
                $stmt->bindParam(':user_id', $user_id);
                $stmt->execute();
                $existing = $stmt->fetchColumn();
                if ($existing && $existing !== $sub) {
                    $conn->rollBack();
                    sendError('Akun ini sudah tertaut dengan akun Google lain', 409);
                }
            }

            // Tautkan identitas Google ke akun tersebut
            $stmt = $conn->prepare("INSERT INTO user_auth_providers (user_id, provider, provider_id) VALUES (:user_id, 'google', :sub)");
            $stmt->bindParam(':user_id', $user_id);
            $stmt->bindParam(':sub', $sub);
            $stmt->execute();
        }

        // Ambil data akun
        $stmt = $conn->prepare('SELECT * FROM users WHERE user_id = :id');
        $stmt->bindParam(':id', $user_id);
        $stmt->execute();
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        // Sama seperti login biasa: hanya akun customer yang boleh masuk aplikasi
        if (!$user || $user['role'] !== 'customer') {
            $conn->rollBack();
            sendError('Akun tidak dapat digunakan di aplikasi', 403);
        }

        $token = createApiToken($conn, $user_id);
        $conn->commit();

        sendSuccess('Login successful', [
            'token' => $token,
            'user_id' => $user['user_id'],
            'username' => $user['username'],
            'full_name' => $user['full_name'],
            'email' => $user['email'],
            'phone' => $user['phone'] ?? null,
            'birth_date' => $user['birth_date'] ?? null,
            'avatar' => $user['avatar'] ?? null,
            'role' => $user['role'],
            'is_new_account' => $isNewAccount,
            'has_password' => $user['password'] !== null
        ]);

    } catch (Exception $e) {
        if ($conn->inTransaction()) {
            $conn->rollBack();
        }
        sendError('Google login failed: ' . $e->getMessage(), 500);
    }
}

// ========================================
// CHANGE PASSWORD
// ========================================
else if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_GET['action']) && $_GET['action'] === 'change_password') {

    $user_id = getAuthUserId();
    if (!$user_id) {
        sendError('Please login first', 401);
    }

    $data = json_decode(file_get_contents("php://input"), true);

    if (empty($data['current_password']) || empty($data['new_password'])) {
        sendError('Current password and new password are required');
    }

    if (strlen($data['new_password']) < 6) {
        sendError('New password must be at least 6 characters');
    }

    $current_password = $data['current_password'];
    $new_password = $data['new_password'];

    try {
        // Ambil hash kata sandi, plus email dan nama untuk email pemberitahuan
        $query = "SELECT password, email, full_name FROM users WHERE user_id = :user_id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':user_id', $user_id);
        $stmt->execute();
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        // Verifikasi kata sandi lama
        if (!$user || $user['password'] === null || !password_verify($current_password, $user['password'])) {
            sendError('Current password is incorrect');
        }

        // Hash kata sandi baru
        $new_password_hash = password_hash($new_password, PASSWORD_DEFAULT);

        // Update kata sandi
        $query = "UPDATE users SET password = :password WHERE user_id = :user_id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':password', $new_password_hash);
        $stmt->bindParam(':user_id', $user_id);

        if ($stmt->execute()) {
            // Kirim email pemberitahuan
            try {
                require_once __DIR__ . '/../config/email.php';
                $emailService = new EmailService();
                $emailService->sendPasswordChangedEmail($user['email'], $user['full_name']);
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

// ========================================
// FORGOT PASSWORD
// ========================================
else if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_GET['action']) && $_GET['action'] === 'forgot_password') {

    $data = json_decode(file_get_contents("php://input"), true);

    if (empty($data['email']) || !filter_var($data['email'], FILTER_VALIDATE_EMAIL)) {
        sendError('Email tidak valid', 400);
    }

    $email = strtolower(trim($data['email']));

    try {
        // Cari user (jangan revelasikan apakah email terdaftar)
        $stmt = $conn->prepare('SELECT user_id FROM users WHERE email = :email LIMIT 1');
        $stmt->bindParam(':email', $email);
        $stmt->execute();
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$user) {
            // Email tidak terdaftar: tetap balas sukses generik untuk mencegah enumerasi
            sendSuccess('Jika email terdaftar, kode OTP telah dikirim.', null);
            exit();
        }

        $userId = (int) $user['user_id'];

        // Hapus permintaan reset sebelumnya untuk email/user ini
        $stmtDel = $conn->prepare('DELETE FROM password_resets WHERE email = :email');
        $stmtDel->bindParam(':email', $email);
        $stmtDel->execute();

        // Generate OTP 6 digit
        $otp = sprintf('%06d', mt_rand(0, 999999));
        $otpHash = password_hash($otp, PASSWORD_DEFAULT);
        $otpExpiresAt = date('Y-m-d H:i:s', strtotime('+10 minutes'));

        // Simpan ke password_resets
        $stmtIns = $conn->prepare(
            'INSERT INTO password_resets (user_id, email, otp_hash, otp_expires_at, otp_attempts) 
             VALUES (:user_id, :email, :otp_hash, :otp_expires_at, 0)'
        );
        $stmtIns->bindParam(':user_id', $userId, PDO::PARAM_INT);
        $stmtIns->bindParam(':email', $email);
        $stmtIns->bindParam(':otp_hash', $otpHash);
        $stmtIns->bindParam(':otp_expires_at', $otpExpiresAt);
        $stmtIns->execute();

        // Kirim email OTP
        $userName = '';
        $stmtName = $conn->prepare('SELECT full_name FROM users WHERE user_id = :id LIMIT 1');
        $stmtName->bindParam(':id', $userId, PDO::PARAM_INT);
        $stmtName->execute();
        $rowName = $stmtName->fetch(PDO::FETCH_ASSOC);
        if ($rowName) {
            $userName = $rowName['full_name'];
        }

        $emailService->sendOtpEmail($email, $userName, $otp, 10);

        // Balas sukses generik (tidak revela apakah email terdaftar)
        sendSuccess('Jika email terdaftar, kode OTP telah dikirim ke email Anda.', null);
    } catch (Exception $e) {
        error_log('Forgot password error: ' . $e->getMessage());
        sendError('Gagal memproses permintaan reset kata sandi', 500);
    }
}

// ========================================
// VERIFY OTP
// ========================================
else if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_GET['action']) && $_GET['action'] === 'verify_otp') {

    $data = json_decode(file_get_contents("php://input"), true);

    if (empty($data['email']) || empty($data['otp'])) {
        sendError('Email dan kode OTP wajib diisi', 400);
    }

    $email = strtolower(trim($data['email']));
    $otp = trim($data['otp']);

    try {
        $stmt = $conn->prepare(
            'SELECT id, user_id, otp_hash, otp_expires_at, otp_attempts 
             FROM password_resets 
             WHERE email = :email 
             ORDER BY created_at DESC 
             LIMIT 1'
        );
        $stmt->bindParam(':email', $email);
        $stmt->execute();
        $reset = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$reset) {
            sendError('Kode OTP tidak valid atau telah kadaluarsa', 400);
        }

        // Cek batas percobaan
        if ((int) $reset['otp_attempts'] >= 3) {
            sendError('Terlalu banyak percobaan. Silakan minta kode OTP baru.', 400);
        }

        // Cek kedaluwarsa
        if (strtotime($reset['otp_expires_at']) < time()) {
            sendError('Kode OTP telah kadaluarsa', 400);
        }

        // Verifikasi OTP
        if (!password_verify($otp, $reset['otp_hash'])) {
            // Increment attempts
            $stmtUpd = $conn->prepare('UPDATE password_resets SET otp_attempts = otp_attempts + 1 WHERE id = :id');
            $stmtUpd->bindParam(':id', $reset['id'], PDO::PARAM_INT);
            $stmtUpd->execute();
            sendError('Kode OTP tidak valid', 400);
        }

        // OTP valid: buat reset token (single use, 15 menit)
        $resetToken = bin2hex(random_bytes(32));
        $resetTokenExpiresAt = date('Y-m-d H:i:s', strtotime('+15 minutes'));

        $stmtUpd = $conn->prepare(
            'UPDATE password_resets 
             SET reset_token = :reset_token, 
                 reset_token_expires_at = :reset_token_expires_at, 
                 reset_token_used = 0 
             WHERE id = :id'
        );
        $stmtUpd->bindParam(':reset_token', $resetToken);
        $stmtUpd->bindParam(':reset_token_expires_at', $resetTokenExpiresAt);
        $stmtUpd->bindParam(':id', $reset['id'], PDO::PARAM_INT);
        $stmtUpd->execute();

        sendSuccess('Kode OTP valid', [
            'reset_token' => $resetToken,
            'expires_in' => 900
        ]);
    } catch (Exception $e) {
        error_log('Verify OTP error: ' . $e->getMessage());
        sendError('Gagal memverifikasi kode OTP', 500);
    }
}

// ========================================
// RESET PASSWORD
// ========================================
else if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_GET['action']) && $_GET['action'] === 'reset_password') {

    $data = json_decode(file_get_contents("php://input"), true);

    if (empty($data['reset_token']) || empty($data['new_password'])) {
        sendError('Token reset dan kata sandi baru wajib diisi', 400);
    }

    $resetToken = trim($data['reset_token']);
    $newPassword = trim($data['new_password']);

    if (strlen($newPassword) < 6) {
        sendError('Kata sandi baru minimal 6 karakter', 400);
    }

    try {
        $stmt = $conn->prepare(
            'SELECT pr.id, pr.user_id, pr.reset_token_expires_at, pr.reset_token_used, u.email 
             FROM password_resets pr 
             JOIN users u ON u.user_id = pr.user_id 
             WHERE pr.reset_token = :reset_token 
             LIMIT 1'
        );
        $stmt->bindParam(':reset_token', $resetToken);
        $stmt->execute();
        $reset = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$reset) {
            sendError('Token reset tidak valid', 400);
        }

        // Cek apakah token sudah digunakan
        if ((int) $reset['reset_token_used'] === 1) {
            sendError('Token reset telah digunakan', 400);
        }

        // Cek kedaluwarsa
        if (strtotime($reset['reset_token_expires_at']) < time()) {
            sendError('Token reset telah kadaluarsa', 400);
        }

        // Update password user
        $passwordHash = password_hash($newPassword, PASSWORD_DEFAULT);
        $stmtUpd = $conn->prepare('UPDATE users SET password = :password WHERE user_id = :id');
        $stmtUpd->bindParam(':password', $passwordHash);
        $stmtUpd->bindParam(':id', $reset['user_id'], PDO::PARAM_INT);
        $stmtUpd->execute();

        // Tandai token sebagai digunakan
        $stmtUsed = $conn->prepare('UPDATE password_resets SET reset_token_used = 1 WHERE id = :id');
        $stmtUsed->bindParam(':id', $reset['id'], PDO::PARAM_INT);
        $stmtUsed->execute();

        // Kirim email notifikasi passwordChanged
        $emailService->sendPasswordChangedEmail($reset['email'], 'Pengguna');

        sendSuccess('Kata sandi berhasil diperbarui', null);
    } catch (Exception $e) {
        error_log('Reset password error: ' . $e->getMessage());
        sendError('Gagal mengubah kata sandi', 500);
    }
}

// Method not allowed
else {
    sendError('Method not allowed', 405);
}
?>
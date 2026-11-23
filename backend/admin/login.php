<?php
session_start();

if (!empty($_SESSION['admin_logged_in']) && $_SESSION['admin_logged_in'] === true) {
    header('Location: index.php');
    exit;
}

require_once '../config/database.php';

function h($v) { return htmlspecialchars((string) $v, ENT_QUOTES, 'UTF-8'); }

if (empty($_SESSION['csrf'])) {
    $_SESSION['csrf'] = bin2hex(random_bytes(32));
}

$error = '';
$username = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = trim($_POST['username'] ?? '');
    $password = (string) ($_POST['password'] ?? '');

    if (!isset($_POST['csrf']) || !hash_equals($_SESSION['csrf'], (string) $_POST['csrf'])) {
        $error = 'Sesi tidak valid. Muat ulang halaman lalu coba lagi.';
    } elseif ($username === '' || $password === '') {
        $error = 'Username dan kata sandi wajib diisi.';
    } else {
        try {
            $database = new Database();
            $conn = $database->getConnection();
            $stmt = $conn->prepare("SELECT user_id, username, full_name, password FROM users WHERE username = :u AND role = 'admin' LIMIT 1");
            $stmt->bindParam(':u', $username);
            $stmt->execute();
            $user = $stmt->fetch(PDO::FETCH_ASSOC);

            if ($user && !empty($user['password']) && password_verify($password, $user['password'])) {
                session_regenerate_id(true);
                $_SESSION['admin_logged_in'] = true;
                $_SESSION['admin_id'] = $user['user_id'];
                $_SESSION['admin_username'] = $user['username'];
                $_SESSION['admin_name'] = $user['full_name'];
                $_SESSION['csrf'] = bin2hex(random_bytes(32));
                header('Location: index.php');
                exit;
            }
            usleep(400000); // memperlambat tebakan kata sandi
            $error = 'Username atau kata sandi salah.';
        } catch (Throwable $ex) {
            error_log('[admin-login] ' . $ex->getMessage());
            $error = 'Tidak dapat terhubung ke database. Pastikan MySQL menyala.';
        }
    }
}
?>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Masuk - Nestalla Admin</title>
    <link rel="icon" type="image/png" href="../assets/nestalla-mark.png">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="../assets/adminlte/plugins/fontawesome-free/css/all.min.css">
    <style>
        *{box-sizing:border-box}
        body{margin:0;min-height:100vh;display:flex;font-family:'Plus Jakarta Sans',system-ui,-apple-system,'Segoe UI',sans-serif;color:#1E2A44;background:#fff}
        .hero{flex:1.1;color:#fff;padding:3rem 3.5rem;display:flex;flex-direction:column;justify-content:space-between;
              background:radial-gradient(900px 500px at 10% 0%,#3066BE 0%,rgba(48,102,190,0) 60%),linear-gradient(160deg,#12294F,#1B3A6B)}
        .plate{display:inline-block;background:#fff;border-radius:18px;padding:.9rem 1.3rem;box-shadow:0 14px 34px rgba(0,0,0,.22)}
        .plate img{display:block;height:48px;width:auto}
        .mlogo{display:none;margin:0 0 1.5rem}
        .mlogo img{height:44px;width:auto}
        .hero h1{font-size:2.3rem;line-height:1.15;margin:0 0 .8rem;letter-spacing:-.02em;font-weight:800}
        .hero p{margin:0;max-width:30rem;opacity:.8;line-height:1.6}
        .hero small{opacity:.6}
        .panel{flex:1;display:flex;align-items:center;justify-content:center;padding:2rem}
        .box{width:100%;max-width:380px}
        .box h2{margin:0 0 .3rem;font-size:1.6rem;font-weight:800;letter-spacing:-.02em;color:#12294F}
        .box .sub{margin:0 0 1.6rem;color:#6B778F}
        label{display:block;font-size:.82rem;font-weight:700;margin:0 0 .4rem;color:#3B4763}
        .field{position:relative;margin-bottom:1.1rem}
        .field i{position:absolute;left:14px;top:50%;transform:translateY(-50%);color:#8793AB}
        .field input{width:100%;padding:.8rem 1rem .8rem 2.6rem;border:1px solid #D9E0EC;border-radius:12px;font:inherit;outline:0;background:#fff}
        .field input:focus{border-color:#3066BE;box-shadow:0 0 0 4px rgba(48,102,190,.14)}
        button{width:100%;border:0;border-radius:12px;padding:.9rem;font:inherit;font-weight:700;color:#fff;cursor:pointer;
               background:linear-gradient(135deg,#1B3A6B,#3066BE);box-shadow:0 10px 22px rgba(27,58,107,.28)}
        button:hover{filter:brightness(1.06)}
        .err{background:#FBE5E3;color:#A32B26;border-radius:12px;padding:.75rem 1rem;margin-bottom:1.1rem;font-size:.9rem}
        @media(max-width:860px){.hero{display:none}.mlogo{display:block}}
    </style>
</head>
<body>
    <section class="hero">
        <div><span class="plate"><img src="../assets/nestalla-logo.png" alt="Nestalla Online Bookstore"></span></div>
        <div>
            <h1>Kelola toko bukumu<br>dalam satu tempat.</h1>
            <p>Pantau pesanan, atur katalog buku, dan kelola promo serta pelanggan dari panel admin Nestalla.</p>
        </div>
        <small>&copy; <?php echo date('Y'); ?> Nestalla</small>
    </section>

    <section class="panel">
        <form class="box" method="post" action="" autocomplete="on">
            <div class="mlogo"><img src="../assets/nestalla-logo.png" alt="Nestalla"></div>
            <h2>Selamat datang</h2>
            <p class="sub">Masuk dengan akun admin untuk melanjutkan.</p>

            <?php if ($error): ?>
                <div class="err"><i class="fas fa-circle-exclamation"></i> <?php echo h($error); ?></div>
            <?php endif; ?>

            <input type="hidden" name="csrf" value="<?php echo h($_SESSION['csrf']); ?>">

            <label for="username">Username</label>
            <div class="field">
                <i class="fas fa-user"></i>
                <input id="username" name="username" type="text" value="<?php echo h($username); ?>" placeholder="Masukkan username" required autofocus autocomplete="username">
            </div>

            <label for="password">Kata sandi</label>
            <div class="field">
                <i class="fas fa-lock"></i>
                <input id="password" name="password" type="password" placeholder="Masukkan kata sandi" required autocomplete="current-password">
            </div>

            <button type="submit">Masuk</button>
        </form>
    </section>
</body>
</html>

<?php
// File: admin/logout.php
session_start();

// Hapus semua session
$_SESSION = array();

// Destroy session
session_destroy();

// Redirect ke login
header("Location: login.php");
exit;
?>
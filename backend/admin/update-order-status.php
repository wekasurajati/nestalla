<?php
// Pengubahan status kini dilakukan langsung dari orders.php dan orders-detail.php
// (dengan perlindungan CSRF). File ini dipertahankan hanya agar tautan lama tidak error.
header('Location: orders.php');
exit;

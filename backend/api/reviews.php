<?php
// ========================================
// ULASAN PRODUK (untuk aplikasi - pakai token)
//   GET  reviews.php?book_id=ID    -> daftar ulasan sebuah buku (publik)
//   POST reviews.php               -> kirim ulasan (wajib login)
//        body: {"order_id":1,"book_id":2,"rating":5,"message":"...","is_anonymous":false}
// testimonial.php dibiarkan apa adanya karena masih dipakai website lama.
// ========================================

require_once 'config.php';

$database = new Database();
$conn = $database->getConnection();

// ----------------------------------------
// GET: ulasan sebuah buku
// ----------------------------------------
if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['book_id'])) {
    $book_id = intval($_GET['book_id']);

    try {
        $stmt = $conn->prepare("SELECT t.testimonial_id, t.rating, t.message, t.created_at,
                                       u.full_name, u.username, u.avatar
                                FROM testimonials t
                                JOIN users u ON t.user_id = u.user_id
                                WHERE t.book_id = :bid
                                ORDER BY t.created_at DESC
                                LIMIT 50");
        $stmt->bindParam(':bid', $book_id);
        $stmt->execute();
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $reviews = [];
        $sum = 0;
        foreach ($rows as $r) {
            $name = trim($r['full_name'] ?: $r['username']);
            $reviews[] = [
                'name'       => $name,
                'comment'    => $r['message'] ?? '',
                'rating'     => (int) $r['rating'],
                'avatar_url' => empty($r['avatar']) ? '' : $r['avatar'],
                'created_at' => $r['created_at'],
            ];
            $sum += (int) $r['rating'];
        }

        sendSuccess('Reviews retrieved successfully', [
            'reviews' => $reviews,
            'count'   => count($reviews),
            'average' => count($reviews) ? round($sum / count($reviews), 2) : 0,
        ]);
    } catch (Exception $e) {
        sendError('Failed to get reviews: ' . $e->getMessage(), 500);
    }
}

// ----------------------------------------
// POST: kirim ulasan
// ----------------------------------------
else if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $user_id = getAuthUserId();
    if (!$user_id) {
        sendError('Please login first', 401);
    }

    $data = json_decode(file_get_contents('php://input'), true);
    if (!is_array($data)) {
        sendError('Data tidak valid');
    }

    $order_id = intval($data['order_id'] ?? 0);
    $book_id = intval($data['book_id'] ?? 0);
    $rating = intval($data['rating'] ?? 0);
    $message = trim((string) ($data['message'] ?? ''));

    if ($order_id <= 0) {
        sendError("Field 'order_id' wajib diisi");
    }
    if ($rating < 1 || $rating > 5) {
        sendError('Rating harus 1 sampai 5');
    }
    $len = mb_strlen($message, 'UTF-8');
    if ($len > 2000) {
        sendError('Ulasan maksimal 2000 karakter');
    }

    try {
        // Pesanan harus milik user dan sudah selesai
        $stmt = $conn->prepare('SELECT status FROM orders WHERE order_id = :oid AND user_id = :uid');
        $stmt->bindParam(':oid', $order_id);
        $stmt->bindParam(':uid', $user_id);
        $stmt->execute();
        $order = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$order) {
            sendError('Order not found', 404);
        }
        if ($order['status'] !== 'completed') {
            sendError('Hanya pesanan yang sudah selesai yang bisa diulas', 403);
        }

        // Buku harus ada di pesanan. Kalau book_id kosong, pakai buku pertama.
        $stmt = $conn->prepare('SELECT book_id FROM order_items WHERE order_id = :oid ORDER BY order_item_id');
        $stmt->bindParam(':oid', $order_id);
        $stmt->execute();
        $book_ids = array_map('intval', $stmt->fetchAll(PDO::FETCH_COLUMN));

        if ($book_id <= 0) {
            $book_id = $book_ids[0] ?? 0;
        }
        if (!in_array($book_id, $book_ids, true)) {
            sendError('Buku tidak ada di pesanan ini', 404);
        }

        // Satu ulasan per (pesanan, buku)
        $stmt = $conn->prepare('SELECT 1 FROM testimonials WHERE order_id = :oid AND book_id = :bid');
        $stmt->bindParam(':oid', $order_id);
        $stmt->bindParam(':bid', $book_id);
        $stmt->execute();
        if ($stmt->fetch()) {
            sendError('Pesanan ini sudah diulas', 409);
        }

        $conn->beginTransaction();

        $stmt = $conn->prepare('INSERT INTO testimonials (user_id, book_id, order_id, rating, message)
                                VALUES (:uid, :bid, :oid, :rating, :message)');
        $stmt->bindParam(':uid', $user_id);
        $stmt->bindParam(':bid', $book_id);
        $stmt->bindParam(':oid', $order_id);
        $stmt->bindParam(':rating', $rating);
        $stmt->bindParam(':message', $message);
        $stmt->execute();
        $review_id = $conn->lastInsertId();

        // Perbarui rata-rata rating buku
        $stmt = $conn->prepare('UPDATE books
                                SET rating = (SELECT ROUND(AVG(rating), 2) FROM testimonials WHERE book_id = :bid)
                                WHERE book_id = :bid2');
        $stmt->bindParam(':bid', $book_id);
        $stmt->bindParam(':bid2', $book_id);
        $stmt->execute();

        $conn->commit();

        sendSuccess('Ulasan berhasil dikirim', ['review_id' => (int) $review_id]);

    } catch (Exception $e) {
        if ($conn->inTransaction()) $conn->rollBack();
        sendError('Gagal mengirim ulasan: ' . $e->getMessage(), 500);
    }
}

else {
    sendError('Method not allowed', 405);
}

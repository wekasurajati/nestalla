<?php


require_once 'config.php';

$database = new Database();
$conn = $database->getConnection();

// GET single book by ID or all books 
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    
    // Get single book detail
    if (isset($_GET['id'])) {
        $book_id = intval($_GET['id']);
        
        $query = "SELECT * FROM books WHERE book_id = :id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':id', $book_id);
        $stmt->execute();
        
        $book = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($book) {
            // Fetch reviews for this book
            $reviewQuery = "SELECT t.rating, t.message, t.created_at,
                                   u.full_name, u.username, u.avatar
                            FROM testimonials t
                            JOIN users u ON t.user_id = u.user_id
                            WHERE t.book_id = :bid
                            ORDER BY t.created_at DESC";
            $reviewStmt = $conn->prepare($reviewQuery);
            $reviewStmt->bindParam(':bid', $book_id);
            $reviewStmt->execute();
            $reviewRows = $reviewStmt->fetchAll(PDO::FETCH_ASSOC);
            
            $reviews = [];
            foreach ($reviewRows as $r) {
                $name = trim($r['full_name'] ?: $r['username']);
                $reviews[] = [
                    'name'       => $name,
                    'comment'    => $r['message'] ?? '',
                    'rating'     => (int) $r['rating'],
                    'avatar_url' => empty($r['avatar']) ? '' : $r['avatar'],
                ];
            }
            
            $book['reviews'] = $reviews;
            
            // Hitung rating rata-rata dari ulasan pelanggan (testimonials)
            $sum = 0;
            foreach ($reviews as $r) {
                $sum += (int) $r['rating'];
            }
            $book['rating'] = count($reviews) > 0 ? round($sum / count($reviews), 1) : 0;
            
            sendSuccess('Book retrieved successfully', $book);
        } else {
            sendError('Book not found', 404);
        }
    }
    
    // Get all books or filtered books
    else {
        $query = "SELECT * FROM books WHERE 1=1";
        $params = [];
        
        // Filter by category
        if (isset($_GET['category']) && !empty($_GET['category'])) {
            $query .= " AND category = :category";
            $params[':category'] = $_GET['category'];
        }
        
        // Filter by featured
        if (isset($_GET['featured']) && $_GET['featured'] == '1') {
            $query .= " AND is_featured = 1";
        }
        
        // Filter by new
        if (isset($_GET['new']) && $_GET['new'] == '1') {
            $query .= " AND is_new = 1";
        }
        
        // Filter by discount
        if (isset($_GET['discount']) && $_GET['discount'] == '1') {
            $query .= " AND is_discount = 1";
        }
        
        // Search by title or author
        if (isset($_GET['search']) && !empty($_GET['search'])) {
            $query .= " AND (title LIKE :search OR author LIKE :search)";
            $params[':search'] = '%' . $_GET['search'] . '%';
        }
        
        // Limit
        $limit = isset($_GET['limit']) ? intval($_GET['limit']) : 100;
        $query .= " ORDER BY created_at DESC LIMIT :limit";
        
        $stmt = $conn->prepare($query);
        
        // Bind parameters
        foreach ($params as $key => $value) {
            $stmt->bindValue($key, $value);
        }
        $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
        
        $stmt->execute();
        $books = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Hitung rating rata-rata dari ulasan pelanggan untuk setiap buku
        foreach ($books as &$book) {
            $bookId = intval($book['book_id']);
            $ratingStmt = $conn->prepare('SELECT ROUND(AVG(rating), 1) as avg_rating FROM testimonials WHERE book_id = :bid');
            $ratingStmt->bindParam(':bid', $bookId);
            $ratingStmt->execute();
            $avgRating = $ratingStmt->fetchColumn();
            $book['rating'] = $avgRating ? (float) $avgRating : 0;
        }
        unset($book);
        
        sendSuccess('Books retrieved successfully', [
            'count' => count($books),
            'books' => $books
        ]);
    }
}

// Method not allowed
else {
    sendError('Method not allowed', 405);
}
?>
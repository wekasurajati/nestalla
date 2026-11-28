<?php

require_once 'config.php';

$database = new Database();
$conn = $database->getConnection();

$userId = getAuthUserId();
if (!$userId) {
    sendError('Please login first', 401);
}

function requestJson(): array
{
    $data = json_decode(file_get_contents('php://input'), true);
    return is_array($data) ? $data : [];
}

function requestedId(array $data): int
{
    $id = filter_var($data['id'] ?? null, FILTER_VALIDATE_INT);
    if (!$id || $id < 1) {
        sendError('id tidak valid');
    }
    return (int) $id;
}

$action = $_GET['action'] ?? '';
$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET' && $action === 'list') {
    try {
        $stmt = $conn->prepare("
            SELECT id, title, message, type, is_read, created_at
            FROM notifications
            WHERE user_id = :uid
            ORDER BY created_at DESC
        ");
        $stmt->bindValue(':uid', $userId, PDO::PARAM_INT);
        $stmt->execute();
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $notifications = [];
        foreach ($rows as $row) {
            $notifications[] = [
                'id' => (string) $row['id'],
                'title' => $row['title'],
                'message' => $row['message'],
                'type' => $row['type'],
                'isRead' => (bool) $row['is_read'],
                'createdAt' => $row['created_at'],
            ];
        }

        $unreadCount = 0;
        foreach ($notifications as $n) {
            if (!$n['isRead']) $unreadCount++;
        }

        sendSuccess('Daftar notifikasi', [
            'count' => count($notifications),
            'unreadCount' => $unreadCount,
            'notifications' => $notifications,
        ]);
    } catch (Exception $e) {
        sendError('Gagal memuat notifikasi: ' . $e->getMessage(), 500);
    }
} elseif ($method === 'POST' && $action === 'mark_read') {
    $id = requestedId(requestJson());
    try {
        $stmt = $conn->prepare("SELECT id FROM notifications WHERE id = :id AND user_id = :uid");
        $stmt->bindValue(':id', $id, PDO::PARAM_INT);
        $stmt->bindValue(':uid', $userId, PDO::PARAM_INT);
        $stmt->execute();
        if (!$stmt->fetch()) {
            sendError('Notifikasi tidak ditemukan', 404);
        }

        $stmt = $conn->prepare("UPDATE notifications SET is_read = 1 WHERE id = :id AND user_id = :uid");
        $stmt->bindValue(':id', $id, PDO::PARAM_INT);
        $stmt->bindValue(':uid', $userId, PDO::PARAM_INT);
        $stmt->execute();

        sendSuccess('Notifikasi ditandai dibaca', []);
    } catch (Exception $e) {
        sendError('Gagal menandai notifikasi: ' . $e->getMessage(), 500);
    }
} elseif ($method === 'POST' && $action === 'mark_all_read') {
    try {
        $stmt = $conn->prepare("UPDATE notifications SET is_read = 1 WHERE user_id = :uid AND is_read = 0");
        $stmt->bindValue(':uid', $userId, PDO::PARAM_INT);
        $stmt->execute();
        $updated = $stmt->rowCount();
        sendSuccess('Semua notifikasi ditandai dibaca', ['updated' => (int) $updated]);
    } catch (Exception $e) {
        sendError('Gagal menandai notifikasi: ' . $e->getMessage(), 500);
    }
} elseif ($method === 'DELETE' && $action === 'delete') {
    $id = requestedId(requestJson());
    try {
        $stmt = $conn->prepare("DELETE FROM notifications WHERE id = :id AND user_id = :uid");
        $stmt->bindValue(':id', $id, PDO::PARAM_INT);
        $stmt->bindValue(':uid', $userId, PDO::PARAM_INT);
        $stmt->execute();
        $deleted = $stmt->rowCount();
        sendSuccess('Notifikasi dihapus', ['deleted' => (int) $deleted]);
    } catch (Exception $e) {
        sendError('Gagal menghapus notifikasi: ' . $e->getMessage(), 500);
    }
} elseif ($method === 'POST' && $action === 'create') {
    $data = requestJson();
    $title = trim($data['title'] ?? '');
    $message = trim($data['message'] ?? '');
    $type = $data['type'] ?? 'general';

    if (!$title || !$message) {
        sendError('Title dan message wajib diisi');
    }

    if (!in_array($type, ['account', 'order', 'promotion', 'general'], true)) {
        $type = 'general';
    }

    try {
        $stmt = $conn->prepare("
            INSERT INTO notifications (user_id, title, message, type, is_read, created_at)
            VALUES (:uid, :title, :message, :type, 0, NOW())
        ");
        $stmt->bindValue(':uid', $userId, PDO::PARAM_INT);
        $stmt->bindValue(':title', $title);
        $stmt->bindValue(':message', $message);
        $stmt->bindValue(':type', $type);
        $stmt->execute();
        $id = (int) $conn->lastInsertId();

        sendSuccess('Notifikasi dibuat', [
            'id' => (string) $id,
            'title' => $title,
            'message' => $message,
            'type' => $type,
            'isRead' => false,
            'createdAt' => date('Y-m-d H:i:s'),
        ]);
    } catch (Exception $e) {
        sendError('Gagal membuat notifikasi: ' . $e->getMessage(), 500);
    }
} else {
    sendError('Method not allowed', 405);
}

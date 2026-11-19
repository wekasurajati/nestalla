<?php

require_once 'config.php';

$database = new Database();
$conn = $database->getConnection();

$userId = getAuthUserId();
if (!$userId) {
    sendError('Please login first', 401);
}

function notificationPayload(array $row): array
{
    return [
        'id' => (string) $row['id'],
        'title' => $row['title'],
        'message' => $row['message'],
        'createdAt' => $row['created_at'],
        'type' => $row['type'],
        'isRead' => (bool) $row['is_read'],
    ];
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

function findNotification(PDO $conn, int $userId, int $id): ?array
{
    $stmt = $conn->prepare("SELECT id, title, message, type, is_read, DATE_FORMAT(created_at, '%Y-%m-%dT%H:%i:%s+07:00') AS created_at FROM notifications WHERE id = :id AND user_id = :user_id LIMIT 1");
    $stmt->bindValue(':id', $id, PDO::PARAM_INT);
    $stmt->bindValue(':user_id', $userId, PDO::PARAM_INT);
    $stmt->execute();
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    return $row ? notificationPayload($row) : null;
}

$action = $_GET['action'] ?? '';
$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET' && $action === 'list') {
    try {
        $stmt = $conn->prepare("SELECT id, title, message, type, is_read, DATE_FORMAT(created_at, '%Y-%m-%dT%H:%i:%s+07:00') AS created_at FROM notifications WHERE user_id = :user_id ORDER BY created_at DESC, id DESC");
        $stmt->bindValue(':user_id', $userId, PDO::PARAM_INT);
        $stmt->execute();

        $items = array_map('notificationPayload', $stmt->fetchAll(PDO::FETCH_ASSOC));
        $unreadCount = 0;
        foreach ($items as $item) {
            if (!$item['isRead']) {
                $unreadCount++;
            }
        }

        sendSuccess('Daftar notifikasi', [
            'count' => count($items),
            'unreadCount' => $unreadCount,
            'notifications' => $items,
        ]);
    } catch (Exception $e) {
        sendError('Gagal memuat notifikasi', 500);
    }
} elseif ($method === 'POST' && $action === 'mark_read') {
    $id = requestedId(requestJson());
    try {
        if (!findNotification($conn, $userId, $id)) {
            sendError('Notifikasi tidak ditemukan', 404);
        }
        $stmt = $conn->prepare('UPDATE notifications SET is_read = 1 WHERE id = :id AND user_id = :user_id');
        $stmt->bindValue(':id', $id, PDO::PARAM_INT);
        $stmt->bindValue(':user_id', $userId, PDO::PARAM_INT);
        $stmt->execute();
        sendSuccess('Notifikasi ditandai dibaca', findNotification($conn, $userId, $id));
    } catch (Exception $e) {
        sendError('Gagal memperbarui notifikasi', 500);
    }
} elseif ($method === 'POST' && $action === 'mark_all_read') {
    try {
        $stmt = $conn->prepare('UPDATE notifications SET is_read = 1 WHERE user_id = :user_id AND is_read = 0');
        $stmt->bindValue(':user_id', $userId, PDO::PARAM_INT);
        $stmt->execute();
        sendSuccess('Semua notifikasi ditandai dibaca', ['updated' => $stmt->rowCount()]);
    } catch (Exception $e) {
        sendError('Gagal memperbarui notifikasi', 500);
    }
} elseif ($method === 'DELETE' && $action === 'delete') {
    $id = requestedId(requestJson());
    try {
        $stmt = $conn->prepare('DELETE FROM notifications WHERE id = :id AND user_id = :user_id');
        $stmt->bindValue(':id', $id, PDO::PARAM_INT);
        $stmt->bindValue(':user_id', $userId, PDO::PARAM_INT);
        $stmt->execute();
        if ($stmt->rowCount() === 0) {
            sendError('Notifikasi tidak ditemukan', 404);
        }
        sendSuccess('Notifikasi dihapus', ['deleted' => 1]);
    } catch (Exception $e) {
        sendError('Gagal menghapus notifikasi', 500);
    }
} elseif ($method === 'POST' && $action === 'create') {
    $data = requestJson();
    try {
        $stmt = $conn->prepare('SELECT role FROM users WHERE user_id = :id LIMIT 1');
        $stmt->bindValue(':id', $userId, PDO::PARAM_INT);
        $stmt->execute();
        if ($stmt->fetchColumn() !== 'admin') {
            sendError('Hanya admin yang boleh membuat notifikasi', 403);
        }

        $title = trim((string) ($data['title'] ?? ''));
        $message = trim((string) ($data['message'] ?? ''));
        if ($title === '' || $message === '') {
            sendError('title dan message wajib diisi');
        }

        $type = trim((string) ($data['type'] ?? 'general'));
        if ($type === '') {
            $type = 'general';
        }
        if (!in_array($type, ['account', 'order', 'promotion', 'general'], true)) {
            sendError('type tidak valid');
        }

        $targetId = filter_var($data['user_id'] ?? null, FILTER_VALIDATE_INT);
        if (!$targetId || $targetId < 1) {
            sendError('user_id penerima wajib diisi');
        }
        $stmt = $conn->prepare('SELECT 1 FROM users WHERE user_id = :id LIMIT 1');
        $stmt->bindValue(':id', (int) $targetId, PDO::PARAM_INT);
        $stmt->execute();
        if (!$stmt->fetchColumn()) {
            sendError('User penerima tidak ditemukan', 404);
        }

        $stmt = $conn->prepare('INSERT INTO notifications (user_id, title, message, type, is_read) VALUES (:user_id, :title, :message, :type, 0)');
        $stmt->bindValue(':user_id', (int) $targetId, PDO::PARAM_INT);
        $stmt->bindValue(':title', $title);
        $stmt->bindValue(':message', $message);
        $stmt->bindValue(':type', $type);
        $stmt->execute();

        $newId = (int) $conn->lastInsertId();
        sendSuccess('Notifikasi dibuat', findNotification($conn, (int) $targetId, $newId));
    } catch (Exception $e) {
        sendError('Gagal membuat notifikasi', 500);
    }
} else {
    sendError('Method not allowed', 405);
}

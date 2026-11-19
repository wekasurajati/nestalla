USE nestalla;

CREATE TABLE IF NOT EXISTS `notifications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `title` varchar(150) NOT NULL,
  `message` text NOT NULL,
  `type` enum('account','order','promotion','general') NOT NULL DEFAULT 'general',
  `is_read` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_notifications_user_created` (`user_id`,`created_at`),
  CONSTRAINT `fk_notifications_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

DROP TRIGGER IF EXISTS `trg_notifications_welcome`;

DELIMITER //
CREATE TRIGGER `trg_notifications_welcome`
AFTER INSERT ON `users`
FOR EACH ROW
BEGIN
  INSERT INTO `notifications` (`user_id`, `title`, `message`, `type`, `is_read`, `created_at`)
  VALUES (
    NEW.user_id,
    'Akun berhasil dibuat',
    CONCAT('Selamat datang di Nestalla, ', NEW.full_name, '. Akunmu sudah aktif dan siap digunakan.'),
    'account',
    0,
    NOW()
  );
END//
DELIMITER ;

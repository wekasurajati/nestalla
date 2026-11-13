-- Migration: 2026-11-12_password_resets.sql
-- Tabel untuk verifikasi OTP dan token reset kata sandi

USE nestalla;

CREATE TABLE IF NOT EXISTS `password_resets` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `email` varchar(100) NOT NULL,
  `otp_hash` char(64) NOT NULL,
  `otp_expires_at` datetime NOT NULL,
  `otp_attempts` int(11) NOT NULL DEFAULT 0,
  `reset_token` char(64) DEFAULT NULL,
  `reset_token_expires_at` datetime DEFAULT NULL,
  `reset_token_used` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_password_resets_email` (`email`),
  KEY `idx_password_resets_user` (`user_id`),
  CONSTRAINT `fk_password_resets_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

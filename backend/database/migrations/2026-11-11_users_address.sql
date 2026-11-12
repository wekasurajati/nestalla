-- Migration: 2026-11-11_users_address.sql
-- Tambah tabel user_addresses dan ubah struktur tabel orders
-- Hapus kolom shipping info dari orders, ganti dengan address_id

-- ========================================
-- Tabel user_addresses
-- ========================================
CREATE TABLE IF NOT EXISTS `user_addresses` (
  `address_id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `label` varchar(50) DEFAULT NULL,
  `recipient_name` varchar(100) NOT NULL,
  `phone` varchar(20) NOT NULL,
  `address` text NOT NULL,
  `district` varchar(100) DEFAULT NULL,
  `city` varchar(100) NOT NULL,
  `province` varchar(100) NOT NULL,
  `postal_code` varchar(10) NOT NULL,
  `latitude` decimal(10,8) DEFAULT NULL,
  `longitude` decimal(11,8) DEFAULT NULL,
  `is_default` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`address_id`),
  KEY `idx_user_addresses_user` (`user_id`),
  KEY `idx_user_addresses_default` (`user_id`, `is_default`),
  CONSTRAINT `fk_user_addresses_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ========================================
-- Tabel orders: hapus kolom shipping, tambah address_id
-- ========================================
ALTER TABLE `orders`
  DROP COLUMN `customer_name`,
  DROP COLUMN `customer_email`,
  DROP COLUMN `customer_phone`,
  DROP COLUMN `shipping_address`,
  DROP COLUMN `city`,
  DROP COLUMN `province`,
  DROP COLUMN `postal_code`,
  ADD COLUMN `address_id` int(11) DEFAULT NULL AFTER `promo_id`,
  ADD KEY `fk_orders_address` (`address_id`);

ALTER TABLE `orders`
  ADD CONSTRAINT `fk_orders_address` FOREIGN KEY (`address_id`) REFERENCES `user_addresses` (`address_id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Waktu pembuatan: 20 Nov 2026 pada 02.00
-- Versi server: 10.11.16-MariaDB
-- Versi PHP: 8.5.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Basis data: `nestalla`
--

-- --------------------------------------------------------

--
-- Struktur dari tabel `api_tokens`
--

CREATE TABLE `api_tokens` (
  `token_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `token` char(64) NOT NULL,
  `expires_at` datetime NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `books`
--

CREATE TABLE `books` (
  `book_id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `author` varchar(150) NOT NULL,
  `publisher` varchar(100) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `price` decimal(12,0) NOT NULL DEFAULT 0,
  `old_price` decimal(12,0) DEFAULT NULL,
  `published_year` int(11) DEFAULT NULL,
  `image` varchar(255) DEFAULT NULL,
  `category` varchar(100) DEFAULT NULL,
  `stock` int(11) NOT NULL DEFAULT 0,
  `age_rating` varchar(10) DEFAULT NULL,
  `rating` decimal(3,2) NOT NULL DEFAULT 0.00,
  `is_featured` tinyint(1) NOT NULL DEFAULT 0,
  `is_discount` tinyint(1) NOT NULL DEFAULT 0,
  `is_new` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ;

-- --------------------------------------------------------

--
-- Struktur dari tabel `cart`
--

CREATE TABLE `cart` (
  `cart_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `book_id` int(11) NOT NULL,
  `quantity` int(11) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ;

-- --------------------------------------------------------

--
-- Struktur dari tabel `orders`
--

CREATE TABLE `orders` (
  `order_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `promo_id` int(11) DEFAULT NULL,
  `address_id` int(11) DEFAULT NULL,
  `shipping_carrier_id` int(11) DEFAULT NULL,
  `order_number` varchar(50) NOT NULL,
  `payment_method` enum('bank','ewallet','cod','credit','midtrans') NOT NULL DEFAULT 'cod',
  `shipping_cost` decimal(12,0) NOT NULL DEFAULT 0,
  `tax` decimal(12,0) NOT NULL DEFAULT 0,
  `discount_amount` decimal(12,0) NOT NULL DEFAULT 0,
  `total_amount` decimal(12,0) NOT NULL DEFAULT 0,
  `notes` text DEFAULT NULL,
  `status` enum('pending','processing','shipped','completed','cancelled') NOT NULL DEFAULT 'pending',
  `payment_status` enum('pending','paid','failed','expired') NOT NULL DEFAULT 'pending',
  `snap_token` varchar(255) DEFAULT NULL,
  `snap_redirect_url` varchar(500) DEFAULT NULL,
  `merchant_order_id` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ;

-- --------------------------------------------------------

--
-- Struktur dari tabel `order_items`
--

CREATE TABLE `order_items` (
  `order_item_id` int(11) NOT NULL,
  `order_id` int(11) NOT NULL,
  `book_id` int(11) NOT NULL,
  `quantity` int(11) NOT NULL DEFAULT 1,
  `price` decimal(12,0) NOT NULL
) ;

-- --------------------------------------------------------

--
-- Struktur dari tabel `password_resets`
--

CREATE TABLE `password_resets` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `email` varchar(100) NOT NULL,
  `otp_hash` char(64) NOT NULL,
  `otp_expires_at` datetime NOT NULL,
  `otp_attempts` int(11) NOT NULL DEFAULT 0,
  `reset_token` char(64) DEFAULT NULL,
  `reset_token_expires_at` datetime DEFAULT NULL,
  `reset_token_used` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `promo_codes`
--

CREATE TABLE `promo_codes` (
  `promo_id` int(11) NOT NULL,
  `code` varchar(50) NOT NULL,
  `type` enum('percentage','free_shipping') NOT NULL,
  `value` decimal(12,2) NOT NULL DEFAULT 0.00,
  `description` text DEFAULT NULL,
  `valid_from` date DEFAULT NULL,
  `valid_until` date DEFAULT NULL,
  `usage_limit` int(11) DEFAULT NULL,
  `used_count` int(11) NOT NULL DEFAULT 0,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ;

-- --------------------------------------------------------

--
-- Struktur dari tabel `shipping_carriers`
--

CREATE TABLE `shipping_carriers` (
  `carrier_id` int(11) NOT NULL,
  `carrier_name` varchar(100) NOT NULL,
  `contact_phone` varchar(20) DEFAULT NULL,
  `contact_email` varchar(100) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `shipping_rates`
--

CREATE TABLE `shipping_rates` (
  `rate_id` int(11) NOT NULL,
  `carrier_id` int(11) NOT NULL,
  `province` varchar(100) NOT NULL,
  `city` varchar(100) NOT NULL,
  `price` decimal(12,0) NOT NULL DEFAULT 0,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `testimonials`
--

CREATE TABLE `testimonials` (
  `testimonial_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `book_id` int(11) NOT NULL,
  `order_id` int(11) DEFAULT NULL,
  `rating` int(11) NOT NULL,
  `message` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ;

-- --------------------------------------------------------

--
-- Struktur dari tabel `users`
--

CREATE TABLE `users` (
  `user_id` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password` varchar(255) DEFAULT NULL,
  `full_name` varchar(100) NOT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `birth_date` date DEFAULT NULL,
  `role` enum('customer','admin') NOT NULL DEFAULT 'customer',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `avatar` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `user_addresses`
--

CREATE TABLE `user_addresses` (
  `address_id` int(11) NOT NULL,
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
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `user_auth_providers`
--

CREATE TABLE `user_auth_providers` (
  `auth_provider_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `provider` varchar(20) NOT NULL,
  `provider_id` varchar(255) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `wishlist`
--

CREATE TABLE `wishlist` (
  `wishlist_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `book_id` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Indeks untuk tabel yang dibuang
--

--
-- Indeks untuk tabel `api_tokens`
--
ALTER TABLE `api_tokens`
  ADD PRIMARY KEY (`token_id`),
  ADD UNIQUE KEY `token` (`token`),
  ADD KEY `fk_tokens_user` (`user_id`);

--
-- Indeks untuk tabel `books`
--
ALTER TABLE `books`
  ADD PRIMARY KEY (`book_id`),
  ADD KEY `idx_books_category` (`category`),
  ADD KEY `idx_books_title` (`title`);

--
-- Indeks untuk tabel `cart`
--
ALTER TABLE `cart`
  ADD PRIMARY KEY (`cart_id`),
  ADD UNIQUE KEY `uq_cart_user_book` (`user_id`,`book_id`),
  ADD KEY `fk_cart_book` (`book_id`);

--
-- Indeks untuk tabel `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`order_id`),
  ADD UNIQUE KEY `order_number` (`order_number`),
  ADD KEY `fk_orders_user` (`user_id`),
  ADD KEY `fk_orders_promo` (`promo_id`),
  ADD KEY `idx_orders_status` (`status`),
  ADD KEY `fk_orders_address` (`address_id`),
  ADD KEY `fk_orders_shipping_carrier` (`shipping_carrier_id`),
  ADD KEY `idx_orders_payment_status` (`payment_status`);

--
-- Indeks untuk tabel `order_items`
--
ALTER TABLE `order_items`
  ADD PRIMARY KEY (`order_item_id`),
  ADD KEY `fk_oi_order` (`order_id`),
  ADD KEY `fk_oi_book` (`book_id`);

--
-- Indeks untuk tabel `password_resets`
--
ALTER TABLE `password_resets`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_password_resets_email` (`email`),
  ADD KEY `idx_password_resets_user` (`user_id`);

--
-- Indeks untuk tabel `promo_codes`
--
ALTER TABLE `promo_codes`
  ADD PRIMARY KEY (`promo_id`),
  ADD UNIQUE KEY `code` (`code`);

--
-- Indeks untuk tabel `shipping_carriers`
--
ALTER TABLE `shipping_carriers`
  ADD PRIMARY KEY (`carrier_id`);

--
-- Indeks untuk tabel `shipping_rates`
--
ALTER TABLE `shipping_rates`
  ADD PRIMARY KEY (`rate_id`),
  ADD KEY `fk_shipping_rates_carrier` (`carrier_id`),
  ADD KEY `idx_shipping_rates_location` (`province`,`city`);

--
-- Indeks untuk tabel `testimonials`
--
ALTER TABLE `testimonials`
  ADD PRIMARY KEY (`testimonial_id`),
  ADD KEY `fk_testi_user` (`user_id`),
  ADD KEY `fk_testi_book` (`book_id`),
  ADD KEY `fk_testi_order` (`order_id`);

--
-- Indeks untuk tabel `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indeks untuk tabel `user_addresses`
--
ALTER TABLE `user_addresses`
  ADD PRIMARY KEY (`address_id`),
  ADD KEY `idx_user_addresses_user` (`user_id`),
  ADD KEY `idx_user_addresses_default` (`user_id`,`is_default`);

--
-- Indeks untuk tabel `user_auth_providers`
--
ALTER TABLE `user_auth_providers`
  ADD PRIMARY KEY (`auth_provider_id`),
  ADD UNIQUE KEY `uq_provider_sub` (`provider`,`provider_id`),
  ADD UNIQUE KEY `uq_user_provider` (`user_id`,`provider`);

--
-- Indeks untuk tabel `wishlist`
--
ALTER TABLE `wishlist`
  ADD PRIMARY KEY (`wishlist_id`),
  ADD UNIQUE KEY `uq_wishlist_user_book` (`user_id`,`book_id`),
  ADD KEY `fk_wl_book` (`book_id`);

--
-- AUTO_INCREMENT untuk tabel yang dibuang
--

--
-- AUTO_INCREMENT untuk tabel `api_tokens`
--
ALTER TABLE `api_tokens`
  MODIFY `token_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `books`
--
ALTER TABLE `books`
  MODIFY `book_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `cart`
--
ALTER TABLE `cart`
  MODIFY `cart_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `orders`
--
ALTER TABLE `orders`
  MODIFY `order_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `order_items`
--
ALTER TABLE `order_items`
  MODIFY `order_item_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `password_resets`
--
ALTER TABLE `password_resets`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `promo_codes`
--
ALTER TABLE `promo_codes`
  MODIFY `promo_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `shipping_carriers`
--
ALTER TABLE `shipping_carriers`
  MODIFY `carrier_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `shipping_rates`
--
ALTER TABLE `shipping_rates`
  MODIFY `rate_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `testimonials`
--
ALTER TABLE `testimonials`
  MODIFY `testimonial_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `users`
--
ALTER TABLE `users`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `user_addresses`
--
ALTER TABLE `user_addresses`
  MODIFY `address_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `user_auth_providers`
--
ALTER TABLE `user_auth_providers`
  MODIFY `auth_provider_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `wishlist`
--
ALTER TABLE `wishlist`
  MODIFY `wishlist_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- Ketidakleluasaan untuk tabel pelimpahan (Dumped Tables)
--

--
-- Ketidakleluasaan untuk tabel `api_tokens`
--
ALTER TABLE `api_tokens`
  ADD CONSTRAINT `fk_tokens_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ketidakleluasaan untuk tabel `cart`
--
ALTER TABLE `cart`
  ADD CONSTRAINT `fk_cart_book` FOREIGN KEY (`book_id`) REFERENCES `books` (`book_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_cart_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ketidakleluasaan untuk tabel `orders`
--
ALTER TABLE `orders`
  ADD CONSTRAINT `fk_orders_address` FOREIGN KEY (`address_id`) REFERENCES `user_addresses` (`address_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_orders_promo` FOREIGN KEY (`promo_id`) REFERENCES `promo_codes` (`promo_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_orders_shipping_carrier` FOREIGN KEY (`shipping_carrier_id`) REFERENCES `shipping_carriers` (`carrier_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_orders_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE;

--
-- Ketidakleluasaan untuk tabel `order_items`
--
ALTER TABLE `order_items`
  ADD CONSTRAINT `fk_oi_book` FOREIGN KEY (`book_id`) REFERENCES `books` (`book_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_oi_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ketidakleluasaan untuk tabel `password_resets`
--
ALTER TABLE `password_resets`
  ADD CONSTRAINT `fk_password_resets_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Ketidakleluasaan untuk tabel `shipping_rates`
--
ALTER TABLE `shipping_rates`
  ADD CONSTRAINT `fk_shipping_rates_carrier` FOREIGN KEY (`carrier_id`) REFERENCES `shipping_carriers` (`carrier_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ketidakleluasaan untuk tabel `testimonials`
--
ALTER TABLE `testimonials`
  ADD CONSTRAINT `fk_testi_book` FOREIGN KEY (`book_id`) REFERENCES `books` (`book_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_testi_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_testi_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ketidakleluasaan untuk tabel `user_addresses`
--
ALTER TABLE `user_addresses`
  ADD CONSTRAINT `fk_user_addresses_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ketidakleluasaan untuk tabel `user_auth_providers`
--
ALTER TABLE `user_auth_providers`
  ADD CONSTRAINT `fk_uap_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ketidakleluasaan untuk tabel `wishlist`
--
ALTER TABLE `wishlist`
  ADD CONSTRAINT `fk_wl_book` FOREIGN KEY (`book_id`) REFERENCES `books` (`book_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_wl_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

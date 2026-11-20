-- Migration: 2026-11-20_orders_payment_status_cancelled.sql
-- Tambahkan nilai 'cancelled' ke enum payment_status di tabel orders

ALTER TABLE `orders`
  MODIFY COLUMN `payment_status` enum('pending','paid','failed','expired','cancelled') NOT NULL DEFAULT 'pending';

-- Migration: 2026-11-24_orders_tracking_number.sql
-- Tambahkan kolom nomor resi pengiriman ke tabel orders.
-- Diisi admin saat status pesanan diubah menjadi 'shipped'.

ALTER TABLE `orders`
  ADD COLUMN `tracking_number` VARCHAR(100) NULL DEFAULT NULL AFTER `shipping_carrier_id`;

USE nestalla;

-- Tambah kolom discount ke tabel order_items
-- price  = harga asli (old_price dari buku)
-- discount = jumlah diskon per item (sudah dikalikan qty)
ALTER TABLE `order_items` ADD COLUMN `discount` decimal(12,0) NOT NULL DEFAULT 0 AFTER `price`;

-- Verifikasi struktur
DESCRIBE `order_items`;

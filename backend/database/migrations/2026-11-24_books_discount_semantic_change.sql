USE nestalla;

-- Migrasi semantik diskon pada tabel books
--
-- Sebelum migrasi:
--   price       = harga jual terkini (Rp)
--   old_price   = harga coret / asli sebelum diskon (Rp)
--   is_discount = flag diskon
--
-- Sesudah migrasi:
--   price       = persentase diskon (0-100)
--   old_price   = harga asli / dasar (Rp)
--   is_discount = flag diskon (tetap)
--
-- Logika konversi data existing:
--   1. Jika old_price IS NOT NULL dan price < old_price (ada diskon):
--      - price baru = ROUND((old_price - price) / old_price * 100)  (persen)
--      - old_price tetap (menjadi harga asli)
--      - is_discount = 1
--
--   2. Jika old_price IS NULL atau price >= old_price (tidak ada diskon):
--      - price baru = 0
--      - old_price baru = price lama (menjadi harga asli)
--      - is_discount = 0

START TRANSACTION;

-- Konversi buku yang memiliki diskon (old_price tersedia dan price < old_price)
UPDATE books
SET
    price = ROUND((old_price - price) / old_price * 100),
    is_discount = 1
WHERE old_price IS NOT NULL
  AND old_price > 0
  AND price < old_price;

-- Konversi buku yang tidak memiliki diskon:
--   - old_price NULL: pindahkan price lama ke old_price, price jadi 0
--   - old_price tersedia tapi price >= old_price: pindahkan price lama ke old_price, price jadi 0
UPDATE books
SET
    old_price = COALESCE(old_price, price),
    price = 0,
    is_discount = 0
WHERE (old_price IS NULL OR price >= old_price)
  AND price > 0;

-- Untuk baris yang price = 0 dan old_price NULL, biarkan keduanya 0 / NULL
-- (tidak ada harga, tidak ada diskon)

COMMIT;

-- Verifikasi hasil migrasi
SELECT
    book_id,
    title,
    price AS discount_percent,
    old_price AS original_price,
    is_discount
FROM books
ORDER BY book_id;

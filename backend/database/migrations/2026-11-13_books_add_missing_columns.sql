-- Migration: 2026-11-13_books_add_missing_columns.sql
-- Tambahkan kolom yang hilang pada tabel books
-- Kolom is_new direferensikan oleh backend api/books.php filter ?new=1
-- Kolom publisher, published_year, age_rating diperlukan model Flutter Book

USE nestalla;

ALTER TABLE `books`
  ADD COLUMN `publisher` VARCHAR(100) DEFAULT NULL AFTER `author`,
  ADD COLUMN `published_year` INT(11) DEFAULT NULL AFTER `old_price`,
  ADD COLUMN `age_rating` VARCHAR(10) DEFAULT NULL AFTER `stock`,
  ADD COLUMN `is_new` TINYINT(1) NOT NULL DEFAULT 0 AFTER `is_discount`;

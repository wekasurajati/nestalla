-- Migration: 2026-11-19_reviews_app.sql
-- Ulasan dari aplikasi: tambah opsi "Samarkan nama" dan cegah ulasan ganda
-- untuk pasangan (pesanan, buku) yang sama.
USE nestalla;

ALTER TABLE testimonials
  ADD COLUMN is_anonymous TINYINT(1) NOT NULL DEFAULT 0 AFTER message;

ALTER TABLE testimonials
  ADD UNIQUE KEY uq_testimonial_order_book (order_id, book_id);

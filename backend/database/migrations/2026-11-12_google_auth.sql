-- Kata sandi boleh kosong (untuk akun yang dibuat lewat Google)
ALTER TABLE users MODIFY password VARCHAR(255) NULL;

-- Menyimpan identitas Google yang tertaut ke tiap akun
CREATE TABLE IF NOT EXISTS user_auth_providers (
  auth_provider_id  INT AUTO_INCREMENT PRIMARY KEY,
  user_id           INT NOT NULL,
  provider          VARCHAR(20) NOT NULL,
  provider_id       VARCHAR(255) NOT NULL,
  created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_uap_user FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  UNIQUE KEY uq_provider_sub (provider, provider_id),
  UNIQUE KEY uq_user_provider (user_id, provider)
) ENGINE=InnoDB;
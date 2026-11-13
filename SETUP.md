# Panduan Setup Tim Nestalla

Panduan ini untuk menjaga kode, database, dan data rahasia tetap aman dan sinkron di antara 4 anggota tim.
Repo ini **publik**: apa pun yang di-commit bisa dibaca siapa saja.

---

## 1. Struktur repo (satu repo untuk semuanya)

```
nestalla/
├── app/            ← Flutter
├── backend/        ← PHP Native (API + admin)
│   ├── api/
│   ├── admin/
│   ├── assets/
│   ├── config/
│   ├── database/   ← schema dan migrations
│   ├── image/      ← gambar buku (isinya tidak masuk Git)
│   └── PHPMailer/
├── docs/           ← kontrak API, ERD, laporan
├── README.md
└── SETUP.md        ← file ini
```

Backend dan Flutter **satu repo**, supaya perubahan keduanya masuk lewat PR yang sama dan tidak ada dua riwayat Git yang harus dijaga sinkron.

---

## 2. Memindahkan backend ke repo (sudah dikerjakan pemilik backend)

Bagian ini hanya dikerjakan **satu orang**, yaitu pemilik backend, dan sudah selesai. Anggota lain tidak perlu mengulanginya; mereka cukup mengikuti bagian 8.

Untuk dokumentasi, langkah yang dipakai (PowerShell, sesuaikan path):

```powershell
# 1. Salin backend ke repo TANPA folder .git (supaya tidak ada repo di dalam repo)
robocopy "C:\xampp\htdocs\nestalla-api" "C:\Users\lenovo\StudioProjects\Nestalla\nestalla\backend" /E /XD .git

# 2. Ganti nama folder lama sebagai cadangan
ren C:\xampp\htdocs\nestalla-api nestalla-api-old

# 3. Buat "jalan pintas" (junction) dari htdocs ke folder backend di repo
New-Item -ItemType Junction -Path "C:\xampp\htdocs\nestalla-api" -Target "C:\Users\lenovo\StudioProjects\Nestalla\nestalla\backend"
```

Hasilnya: XAMPP tetap membuka `http://localhost/nestalla-api/api/...`, tetapi file aslinya ada di dalam repo. Alamat di Flutter tidak berubah.
Tes: buka `http://localhost/nestalla-api/api/books.php` di browser.

---

## 3. Rahasia: jangan pernah di-commit

`.gitignore` di root repo sudah mengabaikan file berikut:

```
# Backend
backend/config/database.php
backend/config/email.php
backend/image/*
!backend/image/.gitkeep
backend/test-*.php
.env
```

Yang **ada di repo** adalah versi contoh tanpa rahasia: `backend/config/database.example.php` dan `backend/config/email.example.php`.

Setiap anggota menyalin file contoh itu menjadi file asli dan mengisinya sendiri:

```powershell
copy backend\config\database.example.php backend\config\database.php
copy backend\config\email.example.php backend\config\email.php
```

Isi `database.php` dengan host, nama database (`nestalla`), user, dan password MySQL di laptopmu sendiri.

**Penting**
- `auth.php` memanggil `config/email.php`. Kalau file itu tidak ada, register akan error. Jadi setiap anggota **wajib** punya file itu, walaupun isinya akun email palsu. Dengan akun palsu, email tidak terkirim dan register bisa lambat beberapa detik, tetapi tetap berhasil.
- Kalau kata sandi email atau database pernah masuk Git atau pernah dikirim lewat chat, **ganti kata sandi itu sekarang** (untuk Gmail: buat App Password baru dan hapus yang lama). Menghapus file dari Git tidak menghapus riwayatnya.
- Jangan commit file `test-*.php`.
- Sebelum commit, selalu cek `git status` dan pastikan `database.php` dan `email.php` (tanpa `.example`) tidak muncul.

---

## 4. Database: struktur disamakan lewat file

Isi database tiap laptop berbeda-beda (MySQL masing-masing). Yang harus sama adalah **struktur**, dan itu dibagikan lewat file SQL di repo:

```
backend/database/
├── schema.sql          ← semua tabel database nestalla (struktur saja, tanpa data)
└── migrations/         ← perubahan struktur setelah schema.sql (awalnya kosong)
```

Nama database: **`nestalla`**.

`schema.sql` tidak berisi data. Setelah impor, database kosong. Isi datanya sendiri:
- Buku: tambahkan lewat halaman `admin/`.
- Akun uji: daftar lewat endpoint register (Postman atau aplikasi).

**Aturan emas:** setiap perubahan struktur database setelah `schema.sql` ditulis sebagai file di `migrations/` dalam PR yang sama dengan kodenya. Jangan mengubah tabel hanya lewat phpMyAdmin.

Penamaan file migrasi: `TANGGAL_deskripsi.sql`, contoh `2026-11-20_tambah_kolom_isbn.sql`. Contoh isinya:

```sql
USE nestalla;
ALTER TABLE books ADD COLUMN isbn VARCHAR(20) NULL;
```

**Urutan impor untuk database baru:** `schema.sql`, lalu semua file di `migrations/` (urut nama), kalau ada.

**Peringatan:** `schema.sql` berisi `DROP TABLE`. Mengimpornya ulang **menghapus semua data** di laptopmu. Aman saat pengembangan, tapi semua anggota harus tahu.

**Kalau struktur berubah:** pemilik perubahan memperbarui `schema.sql` atau menambah file migrasi di PR yang sama, lalu mengabari grup. Anggota lain menjalankan file migrasi barunya (cukup file baru, bukan semuanya ulang).

---

## 5. Alamat server di Flutter (beda tiap perangkat)

Jangan mengubah `api_config.dart` lalu meng-commit-nya. Pakai nilai yang bisa diganti saat menjalankan:

```dart
class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://10.0.2.2/nestalla-api/api', // emulator Android
  );
}
```

Cara menjalankan:

```powershell
# Emulator Android (default)
flutter run

# Chrome
flutter run -d chrome --dart-define=API_BASE=http://localhost/nestalla-api/api

# HP asli (IP laptop dari ipconfig, satu Wi-Fi)
flutter run --dart-define=API_BASE=http://192.168.1.5/nestalla-api/api
```

Izin Android (dikerjakan **sekali**, lalu di-commit) di `app/android/app/src/main/AndroidManifest.xml`:
- `<uses-permission android:name="android.permission.INTERNET"/>` di atas tag `<application`.
- `android:usesCleartextTraffic="true"` di dalam tag `<application ...>`.

---

## 6. Aturan Git

**Pemilik repo (yang membuat repo di GitHub) mengatur sekali:**

1. Settings → Collaborators → undang ketiga anggota lain.
2. Settings → Branches → Add rule untuk `develop` dan `main`:
   - Require a pull request before merging
   - Require approvals: 1
   - Block force pushes

**Aturan harian:**
- Tidak ada commit langsung ke `develop` atau `main`.
- Satu fitur, satu branch: `feature/nama-fitur`. Contoh: `feature/auth-profile`.
- Pesan commit: `feat: ...`, `fix: ...`, `docs: ...`, `chore: ...`.
- PR kecil dan sering. Minimal satu orang lain me-review sebelum merge. Target review: maksimal 24 jam.
- Jangan commit file hasil generate Flutter (`generated_plugin*`, `GeneratedPluginRegistrant.swift`). Kalau muncul di `git status` tanpa kamu mengubahnya, jalankan `git restore <file>`.
- Jangan commit `build/`, `.dart_tool/`, `.env`, kata sandi, atau token.

**Rutinitas pagi:**
```powershell
git fetch
git merge origin/develop     # ambil kerja teman ke branch-mu
flutter pub get              # kalau ada paket baru
```
Lalu cek `docs/` atau chat apakah ada file migrasi baru yang harus dijalankan.

**Setelah selesai:**
```powershell
git status
git add <file-file-yang-kamu-ubah>   # hindari "git add ." tanpa melihat git status
git commit -m "feat: ..."
git push
```
Lalu buat Pull Request ke `develop`.

**Pindah branch saat ada perubahan yang belum di-commit:** kalau Git menolak dengan pesan "would be overwritten", simpan dulu pekerjaanmu dengan `git stash push -m "wip"`, pindah branch, lalu kembali dan jalankan `git stash pop` di branch asalnya.

---

## 7. File bersama: kabari sebelum mengubah

Perubahan di file berikut mempengaruhi semua orang. Beri tahu di grup dan buat PR kecil khusus untuk perubahan itu:

| File | Kenapa sensitif |
|---|---|
| `app/lib/main.dart` | Daftar provider semua modul |
| `app/lib/core/router/app_router.dart` | Semua rute |
| `app/lib/core/theme/app_theme.dart` | Tampilan seluruh aplikasi |
| `app/pubspec.yaml` | Paket; anggota lain harus `flutter pub get` |
| `backend/api/config.php` | Dipakai semua endpoint |
| `backend/api/auth.php` | Login dan token |
| `backend/database/schema.sql` dan `migrations/*` | Mengubah struktur database semua orang |

Satu modul = satu penanggung jawab (backend dan Flutter-nya). Contoh pembagian: A auth dan profil, B beranda dan pencarian, C buku detail, favorit, dan keranjang, D pesanan dan checkout.

---

## 8. Checklist anggota baru

1. Pasang: Git, Flutter, Android Studio (emulator), XAMPP, Postman, VS Code.
2. `git clone https://github.com/wekasurajati/nestalla.git`
3. Buat junction (satu kali, sesuaikan path; PowerShell dibuka sebagai Administrator kalau ditolak):
   ```powershell
   New-Item -ItemType Junction -Path "C:\xampp\htdocs\nestalla-api" -Target "<PATH_REPO>\backend"
   ```
   Kalau folder `C:\xampp\htdocs\nestalla-api` sudah ada, ganti namanya dulu (misalnya jadi `nestalla-api-old`).
4. Salin file konfigurasi (bagian 3) dan isi sendiri.
5. Start Apache dan MySQL di XAMPP. Buat database `nestalla` di phpMyAdmin, lalu impor `backend/database/schema.sql` dan semua file di `migrations/` kalau ada.
6. Minta zip gambar buku ke pemilik backend, lalu ekstrak ke `backend\image\` (isi folder ini tidak ada di Git).
7. Tes di Postman: `POST http://localhost/nestalla-api/api/auth.php?action=register`, lalu `login`. Tambahkan buku lewat halaman `admin/` kalau perlu data.
8. Dari folder `app/`: `flutter pub get`, lalu `flutter run`.
9. Login dari aplikasi dengan akun yang baru kamu daftarkan.

---

## 9. Masalah yang sering muncul

| Gejala | Penyebab umum |
|---|---|
| `Connection refused` di emulator | Alamat memakai `localhost`; pakai `10.0.2.2` |
| `SQLSTATE[HY000] [2002]` saat membuka endpoint | MySQL di XAMPP belum menyala, atau host/port di `database.php` tidak cocok |
| `Method not allowed` saat membuka `auth.php` di browser | Normal; browser mengirim GET, endpoint butuh POST. Tes lewat Postman |
| Chrome memblokir permintaan (CORS) | `config.php` belum memakai aturan CORS terbaru, atau Apache belum di-restart |
| Token selalu 401 | File `backend/api/.htaccess` tidak ada, atau Apache belum di-restart |
| Register error | `config/email.php` belum dibuat |
| Error "table ... doesn't exist" | `schema.sql` atau file migrasi belum diimpor ke database `nestalla` |
| Gambar buku tidak tampil | Isi `backend/image/` belum disalin dari pemilik backend |
| `git status` penuh file `ios/`, `macos/`, `windows/` | Perbedaan akhiran baris; `git restore :/` setelah memastikan tidak ada pekerjaan asli |
| Aplikasi tidak berubah setelah edit | Hot reload tidak cukup; stop lalu `flutter run` lagi |

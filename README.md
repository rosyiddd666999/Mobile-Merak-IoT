# merak

Aplikasi mobile Flutter untuk peternakan merak (MerakNK / Kampung Merak).

## Setup User Pertama di Server

Backend FastAPI di `https://***REMOVED***` **tidak menyediakan endpoint publik untuk registrasi user baru** (`POST /auth/register` juga butuh JWT). Oleh karena itu, sebelum aplikasi bisa login, user admin pertama harus di-seed langsung ke database server.

### Cara Seed User Pertama (via SSH / langsung di server)

Masuk ke server backend, lalu jalankan salah satu opsi berikut sesuai stack yang dipakai:

**Opsi A — Python script langsung (paling cepat):**

```python
# seed_admin.py - jalankan di server, di folder backend
from app.core.security import hash_password  # sesuaikan import
from app.db.session import SessionLocal
from app.models.user import User  # sesuaikan path model

db = SessionLocal()
admin = User(
    id="admin01",
    email="admin@merak.id",
    password_hash=hash_password("admin123"),  # ganti password default
    nama="Admin Kampung Merak",
    role="admin",
)
db.add(admin)
db.commit()
db.close()
print("Admin user berhasil dibuat")
```

**Opsi B — SQL langsung (jika hash sudah diketahui):**

```sql
-- Ganti <HASH_BCRYPT> dengan hasil dari bcrypt("admin123")
INSERT INTO users (id, email, password_hash, nama, role)
VALUES ('admin01', 'admin@merak.id', '<HASH_BCRYPT>', 'Admin', 'admin');
```

Generate hash bcrypt dengan:
```bash
python3 -c "import bcrypt; print(bcrypt.hashpw(b'admin123', bcrypt.gensalt()).decode())"
```

**Opsi C — Minta developer backend menambahkan endpoint bootstrap:**

Tambahkan endpoint `POST /auth/seed-admin` (publik, **hanya aktif jika tabel users kosong**) yang menerima JSON `{id, email, password, nama, role}` dan membuat user admin pertama. Setelah user pertama dibuat, endpoint ini harus otomatis disabled.

### Setelah User Tersedia

1. Set `API_KEY_ANDROID` dan `BASE_URL` di file `.env` (sudah ada).
2. Jalankan `flutter run`.
3. Login dengan kredensial yang baru di-seed.

## Debugging API

Aplikasi sudah dilengkapi `onError` interceptor pada Dio yang akan log detail error ke console (method, URL, status, response body). Logger **nonaktif** di build release.

Untuk melihat log saat development:
```bash
flutter run
# buka layar yang error
# lihat di terminal output blok "╔══ DIO ERROR ══..."
```

## Original README

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

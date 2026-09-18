<p align="center">
  <img src="assets/images/logo.png" alt="Merak Logo" width="160" />
</p>

<h1 align="center">Merak — Kampung Merak / MerakNK</h1>

<p align="center">
  Flutter mobile app for smart peafowl farming — monitoring IoT incubator, breeders, eggs, chicks, sales & finance.
  <br />
  Aplikasi mobile Flutter untuk peternakan merak — monitoring inkubator IoT, indukan, telur, anakan, penjualan & keuangan.
</p>

<p align="center">
  <!-- Project status -->
  <a href="https://github.com/rosyiddd666999/Mobile-Merak-IoT/commits/main"><img src="https://img.shields.io/github/last-commit/rosyiddd666999/Mobile-Merak-IoT?style=flat-square" alt="Last commit" /></a>
  <a href="https://github.com/rosyiddd666999/Mobile-Merak-IoT"><img src="https://img.shields.io/github/repo-size/rosyiddd666999/Mobile-Merak-IoT?style=flat-square" alt="Repo size" /></a>
  <a href="https://github.com/rosyiddd666999/Mobile-Merak-IoT"><img src="https://img.shields.io/github/languages/top/rosyiddd666999/Mobile-Merak-IoT?style=flat-square&color=0175C2" alt="Top language" /></a>
  <a href="https://github.com/rosyiddd666999/Mobile-Merak-IoT/issues"><img src="https://img.shields.io/github/issues/rosyiddd666999/Mobile-Merak-IoT?style=flat-square" alt="Open issues" /></a>
  <a href="https://github.com/rosyiddd666999/Mobile-Merak-IoT/pulls"><img src="https://img.shields.io/github/issues-pr/rosyiddd666999/Mobile-Merak-IoT?style=flat-square" alt="Pull requests" /></a>
  <a href="https://github.com/rosyiddd666999/Mobile-Merak-IoT/stargazers"><img src="https://img.shields.io/github/stars/rosyiddd666999/Mobile-Merak-IoT?style=flat-square" alt="Stars" /></a>
  <a href="https://github.com/rosyiddd666999/Mobile-Merak-IoT/network/members"><img src="https://img.shields.io/github/forks/rosyiddd666999/Mobile-Merak-IoT?style=flat-square" alt="Forks" /></a>
  <a href="https://github.com/rosyiddd666999/Mobile-Merak-IoT/graphs/contributors"><img src="https://img.shields.io/github/contributors/rosyiddd666999/Mobile-Merak-IoT?style=flat-square" alt="Contributors" /></a>
</p>

<p align="center">
  <!-- Stack & platform -->
  <img src="https://img.shields.io/badge/Flutter-3.44-02569B?style=flat-square&logo=flutter&logoColor=white" alt="Flutter 3.44" />
  <img src="https://img.shields.io/badge/Dart-3.12-0175C2?style=flat-square&logo=dart&logoColor=white" alt="Dart 3.12" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-16C79A?style=flat-square" alt="Platform" />
  <img src="https://img.shields.io/badge/State-Riverpod-7B61FF?style=flat-square" alt="Riverpod" />
  <img src="https://img.shields.io/badge/HTTP-Dio-FF6B35?style=flat-square" alt="Dio" />
  <img src="https://img.shields.io/badge/Routing-GoRouter-9C27B0?style=flat-square" alt="GoRouter" />
</p>

<p align="center">
  <!-- Quality & release -->
  <a href="./LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow?style=flat-square" alt="License: MIT" /></a>
  <img src="https://img.shields.io/badge/Version-1.0.0-orange?style=flat-square" alt="Version 1.0.0" />
  <img src="https://img.shields.io/badge/Build-passing-brightgreen?style=flat-square" alt="Build status (placeholder — add .github/workflows/flutter.yml to make it live)" />
</p>

---

## 📑 Table of Contents / Daftar Isi

- [📖 About / Tentang](#-about--tentang)
- [✨ Features / Fitur Utama](#-features--fitur-utama)
- [🛠 Tech Stack](#-tech-stack)
- [📸 Screenshots](#-screenshots)
- [🚀 Getting Started / Mulai Cepat](#-getting-started--mulai-cepat)
- [🔑 First User Setup / Setup User Pertama](#-first-user-setup--setup-user-pertama)
- [⚙️ Configuration / Konfigurasi](#️-configuration--konfigurasi)
- [📁 Project Structure / Struktur Proyek](#-project-structure--struktur-proyek)
- [📦 Build](#-build)
- [🐞 API Debugging / Debugging API](#-api-debugging--debugging-api)
- [🗺 Roadmap](#-roadmap)
- [🤝 Contributing / Kontribusi](#-contributing--kontribusi)
- [📄 License / Lisensi](#-license--lisensi)
- [📚 Additional Docs / Dokumen Tambahan](#-additional-docs--dokumen-tambahan)

---

## 📖 About / Tentang

**EN —** Merak (MerakNK / Kampung Merak) is a Flutter application for managing a peafowl farm end-to-end: real-time IoT incubator telemetry (temperature, humidity, lamp/rotation/mist control), breeder lineage management (F0/F1/F2), egg & chick lifecycle, CCTV live view, sales, and owner-only finance — all backed by a FastAPI backend.

**ID —** Merak (MerakNK / Kampung Merak) adalah aplikasi Flutter untuk mengelola peternakan burung merak secara menyeluruh: telemetri inkubator IoT real-time (suhu, kelembapan, kontrol lampu/rotasi/mist), manajemen silsilah indukan (F0/F1/F2), siklus telur & anakan, CCTV live, penjualan, dan keuangan khusus pemilik — semuanya terhubung ke backend FastAPI di `https://api-merak.abdulrosyid.my.id`.

---

## ✨ Features / Fitur Utama

| Module | EN | ID |
|--------|----|----|
| 📊 Dashboard | Farm overview, population stats, valuation summary | Ringkasan farm, statistik populasi, ringkasan valuasi |
| 🌡 Incubator IoT | Live telemetry, lamp/rotation/mist control, charts, hatching log, brooder readiness | Telemetri live, kontrol lampu/rotasi/mist, grafik, log penetasan, kesiapan brooder |
| 🦚 Breeders | Individual management, lineage tree, inbreeding compare | Manajemen individu, pohon silsilah, bandingkan kompatibilitas |
| 🥚 Eggs & Chicks | Egg tracking, candling results, chick growth | Pelacakan telur, hasil candling, tumbuh kembang anakan |
| 💰 Sales & Finance | Sales pipeline, BKSDA-ready reports (owner only for finance) | Alur penjualan, laporan siap BKSDA (keuangan khusus pemilik) |
| 📹 CCTV | MJPEG live stream (incubator + coop) with health check | Stream live MJPEG (inkubator + kandang) dengan health check |
| 🔐 Auth | JWT + API-Key via secure storage, role-based UI (pemilik/staff/viewer) | JWT + API-Key via secure storage, UI berbasis peran |

---

## 🛠 Tech Stack

| Layer | Choice |
|-------|--------|
| Framework | Flutter 3.44 (Dart 3.12) |
| State Management | `flutter_riverpod` + `riverpod_annotation` / `riverpod_generator` |
| HTTP Client | `dio` (with auth + error-logging interceptors) |
| Routing | `go_router` |
| Charts | `fl_chart` |
| Secure Storage | `flutter_secure_storage` (JWT + API Key) |
| IoT Messaging | `mqtt_client` (native MQTTS, topics `iot/telemetry/*` & `iot/cmd/*`) |
| CCTV | `mjpeg_view` |
| Media | `cached_network_image`, `image_picker` |
| Utils | `intl`, `http`, `connectivity_plus`, `flutter_slidable`, `google_fonts` |
| Lint / Test | `flutter_lints`, `flutter_test` |

---

## 📸 Screenshots

> Replace the placeholders below with real captures (`docs/screenshots/*.png`). Ganti placeholder di bawah dengan tangkapan layar asli.

| Dashboard | Inkubator IoT | Indukan |
|:---------:|:-------------:|:-------:|
| ![](docs/screenshots/dashboard.png) | ![](docs/screenshots/incubator.png) | ![](docs/screenshots/breeders.png) |
| Farm overview | Telemetry & control | Breeder list & lineage |

---

## 🚀 Getting Started / Mulai Cepat

### Prerequisites / Prasyarat

- Flutter **3.44+** (`flutter --version`) — channel stable
- Dart **3.12+** (bundled with Flutter)
- Android Studio / Xcode untuk emulator, atau device fisik
- Akses ke backend FastAPI + kredensial user yang sudah di-seed (lihat section berikutnya)

### Install / Instalasi

```bash
# 1. Clone
git clone https://github.com/rosyiddd666999/Mobile-Merak-IoT.git
cd Mobile-Merak-IoT

# 2. Dependencies + codegen
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# 3. Environment (copy & edit)
cp .env.example .env   # jika belum ada .env — sesuaikan BASE_URL & API_KEY_ANDROID

# 4. Run
flutter run

# 5. Quality gates
flutter analyze
flutter test
```

---

## 🔑 First User Setup / Setup User Pertama

> Backend FastAPI di `https://api-merak.abdulrosyid.my.id` **tidak menyediakan endpoint publik untuk registrasi user baru** (`POST /auth/register` juga butuh JWT). Oleh karena itu, sebelum aplikasi bisa login, user admin pertama harus di-seed langsung ke database server.
>
> Backend **tidak menyediakan endpoint publik untuk registrasi** — seed admin pertama langsung di server.

# 3. Environment (copy & edit)
cp .env.example .env   # jika belum ada .env — sesuaikan BASE_URL & API_KEY_ANDROID

# 4. Run
flutter run

# 5. Quality gates
flutter analyze
flutter test
```

---

## ⚙️ Configuration / Konfigurasi

Environment via `--dart-define` (lihat `MOBILE.md` §12 untuk detail penuh):

| Key | Example | Required | Description / Keterangan |
|-----|---------|----------|--------------------------|
| `BASE_URL` | `https://api-merak.abdulrosyid.my.id` | Yes | Base REST API FastAPI (tanpa trailing `/api`) |
| `API_KEY_ANDROID` | `xxx` | Yes | Header `X-API-Key` tiap request; `401` bila salah/tidak dikirim |
| `MQTT_HOST` | `<host>.s1.eu.hivemq.cloud` | Yes | Host saja (tanpa skema), koneksi native |
| `MQTT_PORT` | `8883` | Yes | `8883` = MQTTS native; jangan pakai `8884` (WebSocket khusus web) |
| `MQTT_USERNAME` | `endoqmerak` | Yes | Sama dengan kredensial server |
| `MQTT_PASSWORD` | `***` | Yes | Bisa di-refresh dinamis dari `GET /api/incubator/settings` |
| `CCTV_BASE_URL` | `https://api-merak.abdulrosyid.my.id` | Yes | Biasanya = `BASE_URL`; dipisah agar mode dev bisa ke `http://<IP>:5000` |
| `CCTV_INKUBATOR_PATH` | `/video_feed` | No | Default sesuai `nginx.conf` |
| `CCTV_KANDANG_PATH` | `/kandang_feed` | No | Default sesuai `nginx.conf` |
| `CCTV_HEALTH_PATH` | `/cctv_health` | No | Health-check stream |

Generate hash bcrypt dengan:

```bash
python3 -c "import bcrypt; print(bcrypt.hashpw(b'admin123', bcrypt.gensalt()).decode())"
```

Single source of truth untuk arsitektur lengkap: [`MOBILE.md`](./MOBILE.md). Design tokens & konsistensi UI: [`DESIGN.md`](./DESIGN.md).

---

## 📦 Build

```bash
flutter build apk \
  --dart-define=BASE_URL=https://api-merak.abdulrosyid.my.id \
  --dart-define=API_KEY_ANDROID=xxx \
  --dart-define=MQTT_HOST=<host>.s1.eu.hivemq.cloud \
  --dart-define=MQTT_PORT=8883 \
  --dart-define=MQTT_USERNAME=endoqmerak \
  --dart-define=MQTT_PASSWORD=xxx \
  --dart-define=CCTV_BASE_URL=https://api-merak.abdulrosyid.my.id

flutter build appbundle --dart-define=BASE_URL=... # dst, sama
```

---

---

## ⚙️ Configuration / Konfigurasi

Environment via `--dart-define` (lihat `MOBILE.md` §12 untuk detail penuh):

| Key | Example | Required | Description / Keterangan |
|-----|---------|----------|--------------------------|
| `BASE_URL` | `https://api-merak.abdulrosyid.my.id` | Yes | Base REST API FastAPI (tanpa trailing `/api`) |
| `API_KEY_ANDROID` | `xxx` | Yes | Header `X-API-Key` tiap request; `401` bila salah/tidak dikirim |
| `MQTT_HOST` | `<host>.s1.eu.hivemq.cloud` | Yes | Host saja (tanpa skema), koneksi native |
| `MQTT_PORT` | `8883` | Yes | `8883` = MQTTS native; jangan pakai `8884` (WebSocket khusus web) |
| `MQTT_USERNAME` | `endoqmerak` | Yes | Sama dengan kredensial server |
| `MQTT_PASSWORD` | `***` | Yes | Bisa di-refresh dinamis dari `GET /api/incubator/settings` |
| `CCTV_BASE_URL` | `https://api-merak.abdulrosyid.my.id` | Yes | Biasanya = `BASE_URL`; dipisah agar mode dev bisa ke `http://<IP>:5000` |
| `CCTV_INKUBATOR_PATH` | `/video_feed` | No | Default sesuai `nginx.conf` |
| `CCTV_KANDANG_PATH` | `/kandang_feed` | No | Default sesuai `nginx.conf` |
| `CCTV_HEALTH_PATH` | `/cctv_health` | No | Health-check stream |

> Jangan bundle `INCUBATOR_RTSP_URL` / kredensial kamera di APK — URL RTSP dipegang server. App cukup kirim `?url=` bila user memilih kamera custom.

---

## 📁 Project Structure / Struktur Proyek

```
lib/
├── main.dart                  # entry point
├── app.dart                   # MaterialApp + GoRouter
├── core/                      # constants, theme, utils (date/number/validators)
├── data/
│   ├── models/                # user, breeder, egg, chick, incubator, sale, finance, alert, dashboard
│   ├── providers/             # Riverpod providers (api_client, auth, dashboard, breeders, eggs, ...)
│   └── repositories/          # repository layer (auth, ...)
├── features/
│   ├── splash/ auth/ dashboard/ incubator/
│   ├── breeders/ eggs/ chicks/ sales/ finance/
│   ├── alerts/ users/ cctv/ profile/
└── shared/                    # drawer, bottom nav, loading/error widgets, dialogs
test/                          # unit + widget tests
assets/images/                 # logo.png, logo-nb.png
```

Single source of truth untuk arsitektur lengkap: [`MOBILE.md`](./MOBILE.md). Design tokens & konsistensi UI: [`DESIGN.md`](./DESIGN.md).

---

## 📦 Build

```bash
flutter build apk \
  --dart-define=BASE_URL=https://api-merak.abdulrosyid.my.id \
  --dart-define=API_KEY_ANDROID=xxx \
  --dart-define=MQTT_HOST=<host>.s1.eu.hivemq.cloud \
  --dart-define=MQTT_PORT=8883 \
  --dart-define=MQTT_USERNAME=endoqmerak \
  --dart-define=MQTT_PASSWORD=xxx \
  --dart-define=CCTV_BASE_URL=https://api-merak.abdulrosyid.my.id

flutter build appbundle --dart-define=BASE_URL=... # dst, sama
```

---

## 🐞 API Debugging / Debugging API

Aplikasi sudah dilengkapi `onError` interceptor pada Dio yang akan log detail error ke console (method, URL, status, response body). Logger **nonaktif** di build release.

Untuk melihat log saat development:

```bash
flutter run
# buka layar yang error
# lihat di terminal output blok "╔══ DIO ERROR ══..."
```

---

## 🗺 Roadmap

| Phase | Scope |
|-------|-------|
| **MVP (Fase 1)** | Auth (login), Dashboard, Incubator (status + grafik + settings), Alerts |
| **Fase 2** | Breeders (list + detail + CRUD), Eggs, Chicks |
| **Fase 3** | Sales, Finance (pemilik), Users (pemilik), CCTV stream |
| **Fase 4** | Lineage tree, breeder compare, search/filter refinement, UI polish |
| **Pasca-MVP** | Offline cache, push notification (FCM), multi-incubator, QR/Certificate |

---

## 🤝 Contributing / Kontribusi

**EN —** Fork the repo, create a feature branch (`feat/...` / `fix/...`), run `flutter analyze` + `flutter test`, then open a Pull Request with a clear description and screenshots for UI changes.

**ID —** Fork repo, buat branch fitur (`feat/...` / `fix/...`), jalankan `flutter analyze` + `flutter test`, lalu buka Pull Request dengan deskripsi jelas dan screenshot untuk perubahan UI.

---

## 📄 License / Lisensi

Distributed under the MIT License — see [`LICENSE`](./LICENSE) for details.
Didistribusikan di bawah lisensi MIT — lihat [`LICENSE`](./LICENSE) untuk detail.

---

## 📚 Additional Docs / Dokumen Tambahan

- [`MOBILE.md`](./MOBILE.md) — single source of truth arsitektur, API mapping, role-based UI
- [`DESIGN.md`](./DESIGN.md) — design tokens & checklist konsistensi lintas screen
- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter) · [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab) · [Flutter docs](https://docs.flutter.dev/)

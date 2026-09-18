# MOBILE.md — MerakNK / Kampung Merak (Flutter Mobile App)

> Dokumen ini adalah *single source of truth* untuk pengembangan aplikasi mobile Flutter.
> **Backend API**: FastAPI di `fastapi-backend/` — lihat `README.md` dan `AGENT.md` untuk detail endpoint.

---

## 1. Tech Stack

| Layer | Pilihan |
|-------|---------|
| Framework | Flutter (Dart) |
| State Management | **Riverpod** (`flutter_riverpod`) |
| HTTP Client | **Dio** (`dio`) |
| Routing | **GoRouter** (`go_router`) |
| Charts | **fl_chart** (line chart suhu & kelembapan) |
| Secure Storage | **flutter_secure_storage** (token JWT + API Key) |
| Pull-to-Refresh | `RefreshIndicator` built-in |
| Build | APK / App Bundle via `flutter build` |

---

## 2. Autentikasi & Keamanan

- **API Key global**: `X-API-Key` disimpan di `flutter_secure_storage`, disisipkan Dio interceptor ke **setiap** request.
- **JWT Token**: Disimpan di `flutter_secure_storage` setelah login, dikirim via `Authorization: Bearer <token>` untuk endpoint yang butuh login.
- **Logout**: Hapus token dari secure storage, redirect ke login.
- **API Key default**: Di-bundle di BuildConfig (atau env Flutter `--dart-define`) untuk instalasi pertama — user bisa ganti di settings.

---

## 3. Struktur Folder Flutter

```
MerakNK_app/
├── lib/
│   ├── main.dart
│   ├── app.dart                          # MaterialApp + GoRouter
│   │
│   ├── core/
│   │   ├── constants.dart                # base URL, enum mapping, dll
│   │   ├── theme.dart                    # Tema warna (hijau/emas — branding merak)
│   │   └── utils/
│   │       ├── date_formatter.dart
│   │       ├── number_formatter.dart
│   │       └── validators.dart
│   │
│   ├── data/
│   │   ├── models/                       # Dart model classes (dari API)
│   │   │   ├── user.dart
│   │   │   ├── breeder.dart
│   │   │   ├── egg.dart
│   │   │   ├── chick.dart
│   │   │   ├── incubator_settings.dart
│   │   │   ├── incubator_status.dart
│   │   │   ├── sale.dart
│   │   │   ├── finance_entry.dart
│   │   │   ├── alert.dart
│   │   │   └── dashboard_summary.dart
│   │   │
│   │   ├── providers/                    # Riverpod providers
│   │   │   ├── api_client_provider.dart  # Dio instance
│   │   │   ├── auth_provider.dart        # login/logout/token
│   │   │   ├── dashboard_provider.dart
│   │   │   ├── breeders_provider.dart
│   │   │   ├── eggs_provider.dart
│   │   │   ├── chicks_provider.dart
│   │   │   ├── incubator_provider.dart
│   │   │   ├── sales_provider.dart
│   │   │   ├── finance_provider.dart
│   │   │   ├── alerts_provider.dart
│   │   │   └── users_provider.dart
│   │   │
│   │   └── repositories/                 # (opsional) layer repository
│   │       └── auth_repository.dart
│   │
│   ├── features/                         # Setiap fitur = 1 folder
│   │   ├── splash/
│   │   │   └── splash_screen.dart
│   │   │
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── widgets/
│   │   │       └── login_form.dart
│   │   │
│   │   ├── dashboard/
│   │   │   ├── dashboard_screen.dart
│   │   │   └── widgets/
│   │   │       ├── incubator_status_card.dart
│   │   │       ├── stats_card.dart       # total telur, anakan
│   │   │       └── finance_summary_card.dart
│   │   │
│   │   ├── incubator/
│   │   │   ├── incubator_screen.dart     # TabBar: Status | Grafik | Rotasi
│   │   │   ├── settings_screen.dart      # Edit threshold
│   │   │   └── widgets/
│   │   │       ├── status_widget.dart
│   │   │       ├── settings_form.dart
│   │   │
│   │   ├── breeders/
│   │   │   ├── breeders_list_screen.dart
│   │   │   ├── breeder_detail_screen.dart
│   │   │   ├── breeder_form_screen.dart   # Create + Edit
│   │   │   ├── breeder_lineage_screen.dart
│   │   │   ├── breeder_compare_screen.dart
│   │   │   └── widgets/
│   │   │       ├── breeder_card.dart
│   │   │       ├── lineage_tree.dart
│   │   │       └── compare_card.dart
│   │   │
│   │   ├── eggs/
│   │   │   ├── eggs_list_screen.dart
│   │   │   ├── egg_detail_screen.dart
│   │   │   ├── egg_form_screen.dart
│   │   │   └── widgets/
│   │   │       └── egg_card.dart
│   │   │
│   │   ├── chicks/
│   │   │   ├── chicks_list_screen.dart
│   │   │   ├── chick_detail_screen.dart
│   │   │   ├── chick_form_screen.dart
│   │   │   └── widgets/
│   │   │       └── chick_card.dart
│   │   │
│   │   ├── sales/
│   │   │   ├── sales_list_screen.dart
│   │   │   ├── sale_detail_screen.dart
│   │   │   ├── sale_form_screen.dart
│   │   │   └── widgets/
│   │   │       └── sale_card.dart
│   │   │
│   │   ├── finance/                      # Hanya untuk role pemilik
│   │   │   ├── finance_list_screen.dart
│   │   │   ├── finance_form_screen.dart
│   │   │   └── widgets/
│   │   │       └── finance_entry_card.dart
│   │   │
│   │   ├── alerts/
│   │   │   ├── alerts_list_screen.dart
│   │   │   └── widgets/
│   │   │       └── alert_tile.dart
│   │   │
│   │   ├── users/                        # Hanya untuk role pemilik
│   │   │   ├── users_list_screen.dart
│   │   │   ├── user_form_screen.dart
│   │   │   └── widgets/
│   │   │       └── user_tile.dart
│   │   │
│   │   ├── cctv/
│   │   │   └── cctv_screen.dart          # MJPEG stream viewer
│   │   │
│   │   └── profile/
│   │       ├── profile_screen.dart
│   │       └── widgets/
│   │           └── api_key_settings.dart
│   │
│   └── shared/                           # Widget reusable
│       ├── app_drawer.dart               # Navigation drawer
│       ├── app_bottom_nav.dart            # Bottom nav bar
│       ├── loading_widget.dart
│       ├── error_widget.dart
│       └── confirm_dialog.dart
│
├── test/
│   ├── data/
│   │   └── models/                       # Unit test model
│   └── features/                         # Widget test per fitur
│
├── pubspec.yaml
└── README.md
```

---

## 4. Data Models (Dart) — Lengkap

Setiap model memiliki: **fromJson**, **toJson**, **copyWith**.

### 4.1 User

```dart
class User {
  final String id;           // "USR-001"
  final String email;
  final String nama;
  final String role;         // "pemilik" | "staff"
  final DateTime? createdAt;

  User({
    required this.id,
    required this.email,
    required this.nama,
    required this.role,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
  User copyWith({...});
}
```

### 4.2 Breeder

```dart
class Breeder {
  final String id;           // F0: "JB01" (jantan) / "BB01" (betina); anak: "JB01BB02-01"
  final String? nama;
  final String jenisKelamin; // "jantan" | "betina"
  final DateTime? tanggalLahir;
  final String generasi;     // "F0", "F1", ...
  final String varianWarna;  // "Hijau", "Biru", "Putih"
  final String asal;         // "beli" | "ternak_sendiri"
  final String status;       // "breeding" | "resting" | "ready_for_sale"
  final String? fotoUrl;
  final String? parentJantanId;
  final String? parentBetinaId;
  final DateTime? createdAt;

  // Field tambahan dari detail endpoint
  final int totalTelur;
  final double persentaseFertil;
  final int jumlahAnakan;

  Breeder({...});
  factory Breeder.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
  Breeder copyWith({...});
}
```

> **Kontrak ID silsilah:** `id` opsional saat POST — kosongkan agar server generate (`JB01`/`BB01` untuk F0, `{Jantan}{Betina}-{NN}` untuk anak). Saat PUT, `jenisKelamin`/`parentJantanId`/`parentBetinaId` tidak boleh berubah (prefix terkunci; beda prefix → `422`, sudah punya turunan → `400`).

### 4.3 Egg

```dart
class Egg {
  final String id;           // "{indukJantan}{indukBetina}-{nomor}", contoh "JB01BB02-01"
  final int slot;            // 1-100
  final String indukJantanId;
  final String indukBetinaId;
  final String tanggalMasuk; // "2026-04-01"
  final String fertilitas;   // "Fertil" | "Infertil" | "Belum dicek"
  final String akhir;        // "Menetas" | "Gagal" | "Proses"
  final String? catatan;

  Egg({...});
  factory Egg.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
  Egg copyWith({...});
}
```

> **Kontrak ID silsilah:** `id` opsional saat POST (kosong = server generate per pasangan). `indukJantanId`/`indukBetinaId` wajib saat create, terkunci saat update. Rename hanya nomor (`-01`→`-02`); prefix beda → `422`, sudah punya anakan → `400`.

### 4.4 Chick

```dart
class Chick {
  final String id;           // "{eggId}-C{nomor}", contoh "JB01BB02-01-C01"
  final String eggId;
  final String? indukJantanId;  // auto-isi server dari egg (read-only)
  final String? indukBetinaId;  // auto-isi server dari egg (read-only)
  final String tanggalMenetas;  // "2026-07-17"
  final double beratAwal;       // gram
  final String skorKesehatan;
  final String status;       // "newborn" | "growing" | "ready_for_sale" | "sold"
  final String? fotoUrl;
  final String? catatan;

  Chick({...});
  factory Chick.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
  Chick copyWith({...});
}
```

> **Kontrak ID silsilah:** `id` opsional saat POST (kosong = server generate `{eggId}-C{NN}`). `eggId` terkunci saat update. Rename hanya `-C{NN}`; ganti egg → `422`.

### 4.5 IncubatorSettings

> **Kontrak aktual (superset):** `GET /api/incubator/settings` mengembalikan kredensial MQTT (`mqtt_url`, `mqtt_username`, `mqtt_password`, `status`) **plus** threshold (`suhu_min/max`, `kelembapan_min/max`, `interval_rotasi_menit`). `PUT` menerima field threshold saja. Sesuaikan model di bawah dengan menambahkan field MQTT opsional.

```dart
class IncubatorSettings {
  final int id;                    // always 1
  final double suhuMin;            // default 37.0
  final double suhuMax;            // default 38.0
  final double kelembapanMin;      // default 55.0
  final double kelembapanMax;      // default 65.0
  final int intervalRotasiMenit;   // default 240
  final String? updatedBy;
  final DateTime? updatedAt;

  IncubatorSettings({...});
  factory IncubatorSettings.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
  IncubatorSettings copyWith({...});
}
```

### 4.6 IncubatorStatus

```dart
class IncubatorStatus {
  final int id;
  final double suhuSekarang;
  final double kelembapanSekarang;
  final String lampuStatus;     // "ON" | "OFF"
  final DateTime? terakhirRotasi;
  final DateTime? updatedAt;

  IncubatorStatus({...});
  factory IncubatorStatus.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

### 4.7 Sale

```dart
class Sale {
  final String id;            // "SLS-001"
  final String tanggal;
  final String item;
  final String referensiId;
  final String pembeli;
  final int qty;
  final double hargaSatuan;
  final String status;        // "Booking" | "DP" | "Lunas"
  final String? catatan;

  Sale({...});
  factory Sale.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
  Sale copyWith({...});
}
```

### 4.10 FinanceEntry

```dart
class FinanceEntry {
  final String id;            // "FIN-001"
  final String tanggal;
  final String tipe;          // "Pemasukan" | "Pengeluaran"
  final String kategori;      // "Pakan", "Penjualan", "Listrik", "Obat"
  final double jumlah;
  final String? catatan;
  final String createdBy;

  FinanceEntry({...});
  factory FinanceEntry.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
  FinanceEntry copyWith({...});
}
```

### 4.11 Alert

```dart
class Alert {
  final int id;
  final String tipe;          // "suhu" | "kelembapan" | "rotasi_gagal" | "lain"
  final String pesan;
  final String level;         // "info" | "warning" | "critical"
  final bool isRead;
  final DateTime? createdAt;

  Alert({...});
  factory Alert.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
  Alert copyWith({...});
}
```

### 4.12 DashboardSummary

```dart
class DashboardSummary {
  final int totalTelurAktif;
  final int totalAnakanBulanIni;
  final IncubatorStatus? inkubatorStatus;
  final FinanceSummary? financeSummary;   // hanya untuk pemilik

  DashboardSummary({...});
  factory DashboardSummary.fromJson(Map<String, dynamic> json);
}

class FinanceSummary {
  final double totalPemasukan;
  final double totalPengeluaran;
  final double saldo;

  FinanceSummary({...});
  factory FinanceSummary.fromJson(Map<String, dynamic> json);
}
```

### 4.13 BreederCompareItem

```dart
class BreederCompareItem {
  final String id;
  final String? nama;
  final String jenisKelamin;
  final String generasi;
  final String varianWarna;
  final String status;
  final int totalTelur;
  final double persentaseFertil;
  final int jumlahAnakan;

  BreederCompareItem({...});
  factory BreederCompareItem.fromJson(Map<String, dynamic> json);
}
```

### 4.14 BreederLineage

```dart
class BreederLineage {
  final Breeder breeder;
  final Breeder? parentJantan;
  final Breeder? parentBetina;

  BreederLineage({...});
  factory BreederLineage.fromJson(Map<String, dynamic> json);
}
```

### 4.15 AuthResponse

```dart
class AuthResponse {
  final String accessToken;
  final String tokenType;    // "bearer"
  final User user;

  AuthResponse({...});
  factory AuthResponse.fromJson(Map<String, dynamic> json);
}
```

---

## 5. Navigation & Routing (GoRouter)

| Path | Screen | Auth Required |
|------|--------|---------------|
| `/` | Redirect ke `/dashboard` atau `/login` | — |
| `/login` | Login Screen | Tidak |
| `/dashboard` | Dashboard Screen | Ya |
| `/incubator` | Incubator Screen (Tabs) | Ya (read: publik) |
| `/incubator/settings` | Incubator Settings Form | Ya (pemilik/staff) |
| `/cctv` | CCTV Stream Screen | Ya |
| `/breeders` | Breeders List | Tidak (publik GET) |
| `/breeders/new` | Breeder Create Form | Ya |
| `/breeders/:id` | Breeder Detail | Tidak |
| `/breeders/:id/edit` | Breeder Edit Form | Ya |
| `/breeders/:id/lineage` | Lineage Tree | Tidak |
| `/breeders/compare` | Breeder Compare | Tidak |
| `/eggs` | Eggs List | Tidak |
| `/eggs/new` | Egg Create Form | Ya |
| `/eggs/:id` | Egg Detail | Tidak |
| `/eggs/:id/edit` | Egg Edit Form | Ya |
| `/chicks` | Chicks List | Tidak |
| `/chicks/new` | Chick Create Form | Ya |
| `/chicks/:id` | Chick Detail | Tidak |
| `/chicks/:id/edit` | Chick Edit Form | Ya |
| `/sales` | Sales List | Tidak |
| `/sales/new` | Sale Create Form | Ya |
| `/sales/:id` | Sale Detail | Tidak |
| `/sales/:id/edit` | Sale Edit Form | Ya |
| `/finance` | Finance List | Ya (pemilik only) |
| `/finance/new` | Finance Create Form | Ya (pemilik only) |
| `/alerts` | Alerts List | Ya |
| `/users` | Users List | Ya (pemilik only) |
| `/users/new` | User Create Form | Ya (pemilik only) |
| `/profile` | Profile/Settings | Ya |

**Bottom Navigation** (5 tab utama, tanpa tombol back — `RootAppBar` + notif/avatar):
1. **Dashboard** (`/dashboard`, ringkasan + mini grafik → tap ke tab Inkubator)
2. **Inkubator** (`/incubator`: kontrol lampu/rotasi/mist + grafik + CCTV live + penetasan)
3. **Indukan** (`/breeders`)
4. **Telur** (`/eggs`: data telur + anakan)
5. **Keuangan** (`/finance`, khusus pemilik — disembunyikan + redirect untuk role lain)

**Navigation Drawer** berisi akses ke semua modul:
- Dashboard
- Incubator (Status, Grafik, Settings)
- CCTV
- Indukan (Breeders)
- Telur (Eggs)
- Anakan (Chicks)
- Penjualan (Sales)
- Keuangan (Finance) — hanya tampil jika role = pemilik
- Notifikasi (Alerts)
- Pengguna (Users) — hanya tampil jika role = pemilik
- Profil

---

## 6. Layout per Screen (Detail)

### 6.1 Login Screen
- Email field
- Password field
- Button "Masuk"
- Error snackbar jika gagal
- Auto-fill API Key dari secure storage (bisa diedit di Profile)

### 6.2 Dashboard Screen

```
┌────────────────────────────┐
│  Selamat datang, [nama]    │
├────────────────────────────┤
│ ┌───┐ ┌───┐ ┌───┐         │
│ │📊 │ │🐣 │ │💰 │         │
│ │ 12 │ │ 3 │ │5jt│         │
│ │Telur│ │Anak│ │Saldo│     │
│ └───┘ └───┘ └───┘         │
│ (saldo hanya untuk pemilik)│
├────────────────────────────┤
│ [Incubator Status Card]    │
│ 🌡️ 37.5°C  💧 60%         │
│ 💡 ON   🔄 2 jam lalu     │
├────────────────────────────┤
│ [Alert Ringkasan]          │
│ ⚠️ 3 notifikasi belum dibaca│
├────────────────────────────┤
│ [Finance Summary - pemilik]│
│ Pemasukan: Rp5.000.000     │
│ Pengeluaran: Rp2.000.000   │
│ Saldo: Rp3.000.000         │
└────────────────────────────┘
```

### 6.3 Incubator Screen (TabBar)

**Tab 1 — Status:**
- Current temperature (large numeric display)
- Current humidity
- Lamp status (ON/OFF with icon)
- Status indicator (normal/warning/critical)

**Tab 2 — Grafik:**
- fl_chart line chart: temperature (line biru) + humidity (line hijau) vs time
- Range selector (1 jam, 6 jam, 24 jam, 7 hari)

### 6.4 Settings Screen (Incubator)
- Form untuk edit: suhu min, suhu max, kelembapan min, kelembapan max, interval rotasi
- Save button
- Validasi: suhu_min < suhu_max, dll.

### 6.5 Breeders List Screen
- Search bar
- Filter chips (jantan/betina, generasi, status)
- List of breeder cards (nama, jenis kelamin, generasi, varian warna)
- FAB untuk tambah (pemilik/staff only)

### 6.6 Breeder Detail Screen
- Photo (placeholder jika null)
- Nama, jenis kelamin, generasi, varian warna, asal, status
- Tanggal lahir
- Parent info (link ke parent detail)
- Performance metrics: total telur, % fertil, jumlah anakan
- Action buttons: Edit, Lineage, Compare
- Lineage tree (push ke screen baru)

### 6.7 Breeder Form Screen
- Fields sesuai model Breeder
- Dropdown untuk enum: jenis_kelamin, generasi, asal, status, varian_warna
- Tanggal picker
- Select parent jantan & betina dari list breeder
- Mode: Create (POST) / Edit (PUT)
- **Create**: tanpa ID (server generate silsilah otomatis).
- **Edit**: jenis kelamin & parent di-disable (prefix terkunci). Error `422` = prefix diganti, `400` = sudah punya turunan.

### 6.8 Breeder Lineage Screen
- Tree view: 3 generasi ke atas
- Card per breeder, bisa tap untuk lihat detail

### 6.9 Breeder Compare Screen
- Pilih 2+ breeder (search + select chips)
- Side-by-side table: nama, jenis kelamin, generasi, varian, total telur, % fertil, jumlah anakan

### 6.10 Eggs List Screen
- Search bar (cari slot / ID)
- List egg cards (slot, ID, status fertilitas, akhir)
- FAB untuk tambah

### 6.11 Egg Detail Screen
- Slot number, ID
- Induk jantan & betina (link ke breeder detail)
- Tanggal masuk, fertilitas, akhir
- Catatan
- Action: Edit, Delete
- **Create**: tanpa ID (server generate `{Jantan}{Betina}-{NN}`).
- **Edit**: induk di-disable; prefix terkunci. Error `422` = prefix diganti, `400` = sudah punya anakan.

### 6.12 Chicks List Screen
- List chick cards (ID, tanggal menetas, status)
- FAB untuk tambah

### 6.13 Chick Detail Screen
- All fields + photo
- Link ke egg asal
- Induk jantan & betina (auto-inherit, read-only dari server)
- Action: Edit, Delete
- **Create**: tanpa ID (server generate `{eggId}-C{NN}`).
- **Edit**: egg asal di-disable; hanya suffix `-C{NN}` yang berubah. Error `422` = ganti egg.

### 6.14 Sales List Screen
- List sale cards (item, pembeli, status, harga)
- FAB untuk tambah

### 6.15 Sale Detail Screen
- All fields
- Status sale dengan badge warna (Booking/DP/Lunas)
- Action: Edit, Delete

### 6.16 Finance List Screen (pemilik only)
- Summary bar: total pemasukan, pengeluaran, saldo (month/year filter)
- Filter: tipe (Pemasukan/Pengeluaran), kategori, date range
- List entries
- FAB untuk tambah

### 6.17 Alerts Screen
- List alerts dengan badge level (info/warning/critical) dan tipe
- Unread indicator (bold)
- Swipe to mark as read
- Swipe to delete (pemilik only)
- Pull to refresh

### 6.18 Users Screen (pemilik only)
- List users (nama, email, role)
- FAB untuk tambah user

### 6.19 CCTV Screen
- MJPEG stream player (package `mjpeg`)
- URL: `{CCTV_BASE_URL}/video_feed` (inkubator) atau `/kandang_feed` (kandang); dev satu LAN bisa langsung `http://<IP>:5000/video_feed`
- Cek `/cctv_health` dulu, tampilkan status sebelum stream
- URL input kamera custom (diteruskan sebagai query `?url=`) + switch inkubator/kandang
- Timeout stream dipisah dari timeout API; dispose controller saat screen ditutup
- Detail server: `cctv.md`

### 6.20 Profile Screen
- User info: nama, email, role
- API Key settings (edit + test connection)
- Logout button

---

## 7. API Service (Dio + Riverpod)

### 7.1 Konfigurasi Dio

```dart
// api_client_provider.dart
final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://abdulrosyid.my.id',
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 10),
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      // 1. Sertakan X-API-Key
      final apiKey = ref.read(secureStorageProvider).read(key: 'api_key');
      options.headers['X-API-Key'] = apiKey ?? 'dev-api-key-android';

      // 2. Sertakan JWT jika ada
      final token = ref.read(secureStorageProvider).read(key: 'jwt_token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }

      handler.next(options);
    },
    onError: (error, handler) {
      if (error.response?.statusCode == 401) {
        // Token expired / API Key invalid -> force logout
        ref.read(authProvider.notifier).forceLogout();
      }
      handler.next(error);
    },
  ));

  return dio;
});
```

### 7.2 Mapping Endpoint -> Provider Pattern

Setiap modul mengikuti pola yang sama:

```dart
// Contoh: breeders_provider.dart

// 1. AsyncNotifier untuk list
final breedersListProvider = AsyncNotifierProvider<BreedersListNotifier, List<Breeder>>(
  BreedersListNotifier.new,
);

// 2. FutureProvider untuk detail
final breederDetailProvider = FutureProvider.family<Breeder, String>((ref, id) async {
  final dio = ref.read(apiClientProvider);
  final response = await dio.get('/api/breeders/$id');
  return Breeder.fromJson(response.data);
});

// 3. AsyncNotifier untuk form (create/update)
final breederFormProvider = AsyncNotifierProvider.family<BreederFormNotifier, void, Breeder?>(...);
```

### 7.3 Daftar Lengkap Panggilan API

| Method | Endpoint | Provider / Fungsi |
|--------|----------|------------------|
| POST | `/auth/login` | `authProvider.login(email, password)` |
| GET | `/auth/me` | `authProvider.fetchMe()` |
| GET | `/api/dashboard/summary` | `dashboardProvider` |
| GET | `/api/incubator/status` | `incubatorStatusProvider` |
| GET | `/api/incubator/settings` | `incubatorSettingsProvider` |
| PUT | `/api/incubator/settings` | `incubatorSettingsProvider.update(data)` |
| GET | `/api/breeders` | `breedersListProvider` |
| GET | `/api/breeders/{id}` | `breederDetailProvider(id)` |
| GET | `/api/breeders/{id}/lineage` | `breederLineageProvider(id)` |
| GET | `/api/breeders/compare?ids=A,B` | `breederCompareProvider(ids)` |
| POST | `/api/breeders` | `breederFormProvider.create(data)` |
| PUT | `/api/breeders/{id}` | `breederFormProvider.update(id, data)` |
| DELETE | `/api/breeders/{id}` | `breedersListProvider.delete(id)` |
| GET | `/api/eggs` | `eggsListProvider` |
| GET | `/api/eggs/{id}` | `eggDetailProvider(id)` |
| POST | `/api/eggs` | `eggFormProvider.create(data)` |
| PUT | `/api/eggs/{id}` | `eggFormProvider.update(id, data)` |
| DELETE | `/api/eggs/{id}` | `eggsListProvider.delete(id)` |
| GET | `/api/chicks` | `chicksListProvider` |
| GET | `/api/chicks/{id}` | `chickDetailProvider(id)` |
| POST | `/api/chicks` | `chickFormProvider.create(data)` |
| PUT | `/api/chicks/{id}` | `chickFormProvider.update(id, data)` |
| DELETE | `/api/chicks/{id}` | `chicksListProvider.delete(id)` |
| GET | `/api/sales` | `salesListProvider` |
| GET | `/api/sales/{id}` | `saleDetailProvider(id)` |
| POST | `/api/sales` | `saleFormProvider.create(data)` |
| PUT | `/api/sales/{id}` | `saleFormProvider.update(id, data)` |
| DELETE | `/api/sales/{id}` | `salesListProvider.delete(id)` |
| GET | `/api/finance` | `financeListProvider` (pemilik only) |
| GET | `/api/finance/{id}` | `financeDetailProvider(id)` |
| POST | `/api/finance` | `financeFormProvider.create(data)` |
| PUT | `/api/finance/{id}` | `financeFormProvider.update(id, data)` |
| DELETE | `/api/finance/{id}` | `financeListProvider.delete(id)` |
| GET | `/api/alerts` | `alertsListProvider` |
| PUT | `/api/alerts/{id}/read` | `alertsListProvider.markRead(id)` |
| DELETE | `/api/alerts/{id}` | `alertsListProvider.delete(id)` |
| GET | `/api/users` | `usersListProvider` (pemilik only) |
| POST | `/auth/register` | `userFormProvider.create(data)` |
| PUT | `/api/users/{id}` | `userFormProvider.update(id, data)` |
| DELETE | `/api/users/{id}` | `usersListProvider.delete(id)` |

> **Kontrak silsilah (semua POST breeders/eggs/chicks):** field `id` opsional, kosongkan agar server generate. Body PUT tidak boleh mengubah field terkunci (`jenis_kelamin`/`parent_*`, `induk_*`, `egg_id`); `id` di body = id baru yang hanya boleh beda suffix. Error `422` = prefix diganti, `400` = ID dipakai / sudah punya turunan.
>
> **Guard hapus client-side (tanpa cascade diam-diam):** indukan beranak (telur/indukan-anak/anakan) dan telur beranak diblokir dialog informatif; anakan konfirmasi langsung; pengguna: pemilik-only + larangan hapus diri sendiri + pemilik terakhir. `404` saat DELETE = sudah hilang, dianggap sukses. Detail pengguna derivasi dari list (backend tanpa `GET /api/users/:id`).

### 7.4 Pola ID Silsilah (catatan, tanpa kode)

> Breeder F0 `JB{NN}`/`BB{NN}`, telur/anak `{Jantan}{Betina}-{NN}`, chick `{eggId}-C{NN}`. Prefix dibaca langsung dari ID sehingga badge silsilah bisa dirender offline; ID lama (`MRK-`/`EGG-`/`CHK-`) tetap ditampilkan apa adanya.

---

## 8. Role-Based UI

Setiap screen dan action harus cek role user:

- **Pemilik**: Lihat semua menu (termasuk Finance & Users), bisa CRUD semua.
- **Staff**: Tidak melihat menu Finance & Users. Bisa CRUD data operasional.
- **Viewer (tidak login)**: Hanya bisa lihat halaman publik (Breeders, Eggs, Chicks, Incubator, Sales). Tidak bisa Create/Edit/Delete.

Implementasi:

```dart
class RoleGuard extends ConsumerWidget {
  final Widget child;
  final List<String> allowedRoles;

  const RoleGuard({super.key, required this.child, required this.allowedRoles});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null || !allowedRoles.contains(user.role)) {
      return AccessDeniedScreen();
    }
    return child;
  }
}
```

---

## 9. Theming & Branding

- **Warna primer**: Hijau emas (natural/bird theme)
  - `primary`: `#2E7D32` (hijau)
  - `secondary`: `#F9A825` (emas)
  - `surface`: `#F5F5F5`
  - `error`: `#D32F2F`
- **Warna status**:
  - Normal: `#4CAF50` (hijau)
  - Warning: `#FFC107` (kuning)
  - Critical: `#F44336` (merah)
- **Font**: System default atau Google Fonts (Montserrat / Inter)
- **Icons**: Material Icons
- **Dark mode**: Opsional, bisa ditambahkan nanti

---

## 10. Fitur Offline / Caching (Opsional, Pasca-MVP)

- Cache data dashboard dan incubator status dengan `shared_preferences`
- Telemetry logs disimpan lokal untuk grafik offline
- Queue create/update operation saat offline (dengan `workmanager` atau `drift`)

---

## 11. Testing Strategy

| Level | Tools | Scope |
|-------|-------|-------|
| **Unit Test** | `flutter_test` | Model fromJson/toJson, validators, formatters |
| **Widget Test** | `flutter_test` | Per screen: render, loading, error, empty state |
| **Integration Test** | `integration_test` | Login -> Dashboard -> CRUD flow |

> Tambahan silsilah: uji validator menolak ganti prefix dan pastikan form edit tidak mengirim field terkunci.

---

## 12. Environment & Build

### 12.1 Daftar env Flutter (`--dart-define`)

| Key | Contoh | Wajib | Keterangan |
|---|---|---|---|
| `BASE_URL` | `https://abdulrosyid.my.id` | Ya | Base REST API FastAPI (tanpa trailing `/api`) |
| `API_KEY_ANDROID` | `xxx` | Ya | Header `X-API-Key` tiap request; `401` bila salah/tidak dikirim |
| `MQTT_HOST` | `9170ac9...s1.eu.hivemq.cloud` | Ya | Host saja (tanpa skema) agar app bisa pilih koneksi native |
| `MQTT_PORT` | `8883` | Ya | `8883` = MQTTS native; jangan pakai `8884` (itu WebSocket khusus web) |
| `MQTT_USERNAME` | `endoqmerak` | Ya | Sama dengan kredensial server |
| `MQTT_PASSWORD` | `***` | Ya | Bisa di-refresh dinamis dari `GET /api/incubator/settings` |
| `CCTV_BASE_URL` | `https://abdulrosyid.my.id` | Ya | Biasanya = `BASE_URL`; dipisah agar mode dev bisa ke `http://<IP>:5000` langsung |
| `CCTV_INKUBATOR_PATH` | `/video_feed` | Tidak | Default sesuai `nginx.conf` |
| `CCTV_KANDANG_PATH` | `/kandang_feed` | Tidak | Default sesuai `nginx.conf` |
| `CCTV_HEALTH_PATH` | `/cctv_health` | Tidak | Health-check stream |

> Jangan bundle `INCUBATOR_RTSP_URL`/kredensial kamera di APK — URL RTSP dipegang server (env gateway). App cukup kirim `?url=` bila user memilih kamera custom.

**Build command:**

```bash
flutter build apk \
  --dart-define=BASE_URL=https://abdulrosyid.my.id \
  --dart-define=API_KEY_ANDROID=xxx \
  --dart-define=MQTT_HOST=9170ac9caae04bc598c6d6111adfa4a1.s1.eu.hivemq.cloud \
  --dart-define=MQTT_PORT=8883 \
  --dart-define=MQTT_USERNAME=endoqmerak \
  --dart-define=MQTT_PASSWORD=xxx \
  --dart-define=CCTV_BASE_URL=https://abdulrosyid.my.id

flutter build appbundle --dart-define=BASE_URL=... (dst, sama)
```

### 12.2 Alur akses data (agar tanpa error)

**Startup (splash → home):**
```
1. Baca --dart-define → simpan default ke secure storage (sekali, bisa diubah di Profile)
2. GET {BASE_URL}/api/incubator/settings (+ header X-API-Key)
   → 200: simpan mqtt_* + threshold; lanjut
   → 401: API key salah → tampilkan layar perbaiki key, JANGAN lanjut fetch lain
   → exception/timeout: mode offline, tampilkan data cache + banner
3. Hubungkan MQTT native (mqtts://MQTT_HOST:MQTT_PORT) dengan username/password
4. Cek CCTV: GET {CCTV_BASE_URL}{CCTV_HEALTH_PATH} → tampilkan status di kartu CCTV
5. Login (JWT) → fetch list breeders/eggs/chicks/sales
```

**REST API (Dio):** setiap request kirim `X-API-Key`; tambah `Authorization: Bearer` bila sudah login. Mapping error: `401` → kunci/token salah (paksa perbaiki/logout), `404` → data dihapus di server (refresh list), `422` → prefix silsilah diganti (tampilkan detail server), `400` → ID dipakai/sudah punya turunan.

**MQTT native:** konek sekali saat app start (`mqtts`, qos 0, auto-reconnect + backoff). Subscribe telemetri: `iot/telemetry/temperature`, `humidity`, `status_lamp`, `status_motor`, `status_mist`. Publish perintah: `iot/cmd/*` (`lamp_thresh_on/off`, `humidity_thresh_low/high`, `lamp_mode`, `motor_turns`, `motor_trigger`, `mist_trigger`, `candling_mode`, `alert_ack`) — samakan dengan `MQTT_TOPICS` web agar device merespons kedua klien. Daftar topik lengkap: `src/data/constants.js`.

**CCTV:** player MJPEG ke `{CCTV_BASE_URL}{CCTV_INKUBATOR_PATH|CCTV_KANDANG_PATH}` (opsional `?url=` untuk kamera custom). Cek health dulu; timeout stream dipisah dari timeout API (10 dtk) karena koneksi panjang. Detail server: `cctv.md`.

### 12.3 Troubleshooting cepat

| Gejala | Penyebab umum → aksi |
|---|---|
| Semua request `401` | `API_KEY_ANDROID` salah → cek di Profile, test ke `/api/incubator/settings` |
| Timeout semua | `BASE_URL` salah / server mati → cek health endpoint dari browser |
| MQTT tidak konek | Salah port (harus `8883` native, bukan `8884`), kredensial salah, atau TLS diblokir jaringan |
| CCTV blank/hitam | Kamera offline (cek `/cctv_health`), salah `CCTV_BASE_URL`, atau timeout ikut 10 dtk |
| Data telur/anak kosong | Backend belum migrasi (`migrasi_silsilah.sql`) atau salah base URL (port 8000 FastAPI vs 3001 Express) |

```yaml
# pubspec.yaml dependencies (tambahan vs sebelumnya: mqtt_client, mjpeg)
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1
  dio: ^5.7.0
  go_router: ^14.8.0
  flutter_secure_storage: ^9.2.4
  fl_chart: ^0.70.2
  intl: ^0.20.2
  cached_network_image: ^3.4.1
  image_picker: ^1.1.2
  mqtt_client: ^10.0.0      # MQTT native (telemetri + perintah iot/cmd/*)
  mjpeg: ^1.0.0             # MJPEG stream viewer CCTV

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  build_runner: ^2.4.14
  riverpod_generator: ^2.6.3
```

---

## 13. Urutan Prioritas Pengembangan

| Fase | Fitur |
|------|-------|
| **MVP (Fase 1)** | Auth (login), Dashboard, Incubator (status + grafik + settings), Alerts |
| **Fase 2** | Breeders (list + detail + CRUD), Eggs (list + detail + CRUD), Chicks (list + detail + CRUD) |
| **Fase 3** | Sales, Finance (pemilik), Users (pemilik), CCTV stream |
| **Fase 4** | Breeder lineage tree, Breeder compare, search/filter refinement, UI polish |
| **Pasca-MVP** | Offline cache, push notification (FCM), multi-incubator, QR/Certificate |

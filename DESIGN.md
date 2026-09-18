# Design Spec — Avian Intelligence / MerakNK

Spesifikasi ini melanjutkan redesign Dashboard yang sudah dibuat (`dashboard_screen.dart`).
Semua token & pattern di bawah **wajib dipakai ulang** di 3 screen sisanya supaya visual konsisten.
Tidak ada kode Flutter di sini — ini brief implementasi yang cukup jelas untuk langsung di-generate ke widget.

---

## 0. Struktur Aplikasi & Isi Tiap Screen (kondisi saat ini)

### Bottom Navigation (5 tab, selalu tampil di semua screen utama, tanpa tombol back)
1. **Dashboard** — ringkasan umum farm (status + mini grafik inkubator, indukan, anakan, keuangan)
2. **Inkubator** — monitoring IoT penuh: kontrol lampu/rotasi/mist, grafik, CCTV live, penetasan, brooder
3. **Indukan** — daftar & manajemen individu burung (F0/F1/F2)
4. **Telur** — data telur + anakan
5. **Keuangan** — valuasi aset, penjualan, laporan (khusus pemilik, disembunyikan untuk role lain)

Setiap screen punya app bar sendiri (judul beda-beda, style beda — ini juga perlu distandarkan, lihat §5).

---

### 0.1 Dashboard — isi saat ini
- App bar: label kecil "Avian Intelligence" + judul "Dashboard", icon notifikasi, icon profil
- **Card Status Farm** (dark): status "Normal & Kondusif", badge "IoT 100% Online", Kandang Aktif (12), Total Populasi (18), breakdown F0 (6)/F1 (8)/F2 (4), suhu 28.4°C, kelembapan 68% RH, label "Optimal"
- **Card Bio-Dome Unit 01 / Telur Tunggal**: badge "Hari 18/28", kode telur #EGG-2024-001, label "F1 Pure Bred", genetik induk (Arjuna × Shinta Dewi), progress bar "Fase Pengeraman 64%", 3 metrik (suhu dome, kelembapan, sisa waktu pemutaran), catatan info "belum ada anakan menetas"
- **Section Kandang Aktif** (3 kandang aktif): tiap kandang punya foto, nama, badge status (Produksi Prima / Observasi Sehat / Siap Jual), keterangan pasangan/generasi, kapasitas (mis. 6/8 Ekor)
- **Card Valuasi Penangkaran**: label "Q2 2024", total valuasi Rp485.000.000 (badge "Live Asset"), penjualan bulan ini Rp32.500.000 dengan trend +18.4%
- **3 tombol aksi** di bawah: "Catat Telur" (primary), "Telemetri", "Audit BKSDA"

### 0.2 Indukan — isi saat ini
- App bar: "Avian Intelligence" + judul "Indukan", notifikasi, profil
- Search bar "Cari ID, nama..." + tombol "+ Tambah"
- **Filter tab generasi**: Semua (18), F0 Pure (6), F1 Calon (8)
- **Banner Analisis Kompatibilitas**: "Cek Inbreeding & potensi mutasi warna" + tombol "Bandingkan"
- **Sub-tab status**: Aktif / Bertelur / Calon / Siap Jual
- **List individu burung**, tiap card berisi kombinasi dari:
  - Kode (mis. MRK-F0-001), nama, badge status (Induk Aktif / Sedang Bertelur / Calon Induk / Siap Jual), checkbox "Bandingkan"
  - Info generasi & breed, kandang, pasangan/silsilah
  - Metrik spesifik tergantung status: bulu ekor & bobot (induk aktif), jumlah telur musim ini/fertilitas/bobot + progress inkubasi (sedang bertelur), progress kematangan & sexing (calon induk), estimasi nilai pasar & tag sertifikasi (siap jual)
  - Tombol aksi 2 buah per card (nama berubah sesuai status): "Silsilah & Anak"/"Riwayat Medis", "Catat Telur"/"Silsilah", "Rekomendasi Pasangan"/"Detail Profil", "Buat Sertifikat"/"Lihat Sertifikat"

### 0.3 Siklus Telur — isi saat ini
- App bar: "MerakNK" + badge versi "V2.4 IOT", notifikasi, profil
- **Baris 3 statistik atas**: Total Telur (1 Terdata), Inkubator (1 Aktif 100%), Menetas (0 Menanti)
- **Card Bio-Dome Unit 01**: foto dome telur, badge "Active Monitoring", ID pod (#EGG-2024-001), 3 metrik (suhu 37.5°C, kelembapan 60% RH, next turn 42m)
- **Info Silsilah Indukan**: nama pasangan induk (Arjuna × Shinta Dewi), badge generasi (F1 Pure)
- **Fase Pertumbuhan Embrio**: "Hari 18/28", progress bar, catatan candling ("Pembuluh Vaskular Terlihat Aktif, ~10 Hari Lagi")
- **Card Hasil Candling Terakhir**: ringkasan kondisi embrio (icon check + deskripsi 2 baris)
- **Kontrol Telemetri IoT** (firmware v2.4): 3 toggle — Rotasi Telur (AUTO/ON), Sirkulasi Fan (AKTIF/ON), Heater Aux (STANDBY)
- **Log Penetasan & Koleksi**: tombol "+ Catat Telur", list riwayat telur (kode, tanggal, berat awal, badge kualitas cangkang, nomor pod)
- **Pusat Kesiapan Brooder**: badge status "STANDBY", catatan "Belum Ada Anakan Menetas", checklist kesiapan darurat & harian (3 item: termostat, lampu pemanas, kit perawatan tali pusat) masing-masing dengan status (SIAP/AKTIF/TERSEDIA)

### 0.4 Keuangan — isi saat ini
- App bar: label "Financial & Asset Intelligence" + judul "Keuangan & Penjualan", tombol "+ Transaksi F2+"
- **Card Total Valuasi & Kas**: Rp485.000.000 (badge "Live Asset"), Pendapatan bulan ini Rp32.500.000 (+18.4% vs bulan lalu), Biaya Pakan & IoT Rp6.800.000 (efisiensi solar cell 34%)
- **Banner Regulasi Penjualan BKSDA**: catatan bahwa F0 dilindungi, hanya F2 & F3 bersertifikat yang boleh dijual
- **Section Kesiapan Komersial**: badge "2 Siap Jual" + link "Lihat Semua", list produk siap jual (kode, jenis, umur, DNA/jenis kelamin, harga, status ketersediaan, status microchip)
- **Section Riwayat Transaksi Terakhir**: label "update Xm lalu", list transaksi (kode transaksi, kode individu, badge status pembayaran seperti LUNAS/DP TERVERIFIKASI, nama pembeli, status dokumen BKSDA, nominal, nominal DP jika ada)
- **Section Ekspor Laporan Resmi**: label format "BKSDA/Audit", 4 jenis laporan (Laporan Penjualan/PDF, Buku Kas Operasional/XLS, Sertifikat Silsilah/PDF, Rekap Valuasi Aset/XLS)

---

## 1. Design Tokens (reuse dari Dashboard)

```
AppColors.bg            = #F5F7F6   // background utama
AppColors.darkCard       = #0E1B17   // hero/dark card
AppColors.primaryTeal    = #16C79A   // aksen utama
AppColors.textDark       = #1A2421
AppColors.textMuted      = #6B7772

AppColors.statusActive   = #16C79A  // hijau: aktif/produksi/lunas/sehat
AppColors.statusPending  = #F5A524  // kuning: observasi/proses/pending
AppColors.statusReady    = #3B82F6  // biru: siap jual/selesai/terverifikasi
AppColors.statusAlert    = #EF4444  // merah: alert/gagal

AppRadius.card = 20px   // card besar
AppRadius.chip = 100px  // pill/badge
card kecil radius = 16px
```

**Aturan status chip (WAJIB konsisten di semua screen):**
- Jangan buat warna status baru di luar 4 warna di atas.
- Satu status = satu warna tetap. Contoh: "Sedang Bertelur" & "Verifikasi" & "Observasi Sehat" → sama-sama kuning (statusPending), karena sama-sama "proses/menunggu".
- Chip background = warna dengan opacity 0.12–0.15, teks = warna solid.

**Tipografi:**
- Value besar (angka Rp, %, suhu utama) → 22–28px, weight 700–800
- Judul card/item → 14–16px, weight 700
- Subtitle/meta → 11–12px, warna textMuted
- Section header → 16px weight 700, trailing meta 12px teal

**Spacing:** padding card = 16–20px, gap antar card = 16px, gap antar section = 20px.

**Button hierarchy (berlaku di semua screen):**
- Maksimal 1 primary button (filled, darkCard/primaryTeal) per screen/section.
- Sisanya outlined atau text button.
- Label tombol max 2 kata supaya tidak wrap ke 2 baris (lebar min tombol harus disesuaikan konten, jangan biarkan `Wrap`/`FittedBox` default kompres teks).

---

## 2. Screen: Induk (Daftar Peafowl)

### Masalah di desain lama
- Search bar + tombol "+Tambah" + banner kompatibilitas berebut ruang di atas.
- Card individu terlalu tinggi (foto + 3 baris metrik + badge + 2 tombol).
- Nama terpotong ("Arju...", "Srikan...", "Bi...", "Ken...").
- Tombol "Bandingkan" & "Riwayat Medis" wrap 2 baris.

### Struktur baru
1. **Header row**: search bar full width (icon kaca pembesar), tombol "+ Tambah" jadi icon button bulat kecil di kanan search bar — bukan tombol lebar sejajar teks. Hemat 1 baris vertikal.
2. **Compatibility banner**: jadikan collapsible/dismissible card, bukan permanen di atas. Kalau user sudah pernah lihat, default collapsed jadi 1 baris ringkas "Analisis Kompatibilitas →".
3. **Filter tabs** (Semua/F0 Pure/F1 Calon): tetap chip horizontal scroll, tapi tambahkan count di setiap chip label pendek: `Semua 18`, `F0 6`, `F1 8` (sudah oke, pertahankan).
4. **Sub-tabs status** (Aktif/Bertelur/Calon/Siap Jual): ubah jadi segmented control (bukan tab underline biasa) supaya lebih jelas ini adalah filter, bukan navigasi halaman.
5. **Card individu — redesign wajib**:
   - Layout: foto kecil (56×56, rounded 12) di kiri, bukan foto besar di atas.
   - Nama: `maxLines: 1, overflow: ellipsis`, tapi lebar container dipastikan cukup (gunakan `Expanded`, jangan fixed width sempit) — target nama seperti "Arjuna" tidak boleh terpotong untuk nama ≤15 karakter.
   - Baris kedua: breed + umur dalam 1 baris teks muted.
   - Metrik (bulu ekor, bobot, dsb): tampilkan maksimal 2 metrik utama sebagai inline text kecil, bukan grid 2 kolom yang makan tempat. Detail lengkap pindah ke halaman Detail Profil.
   - Status badge: pojok kanan atas card, pakai sistem warna di atas (bagian §1).
   - Actions: **hilangkan tombol di dalam card**. Ganti dengan 1 icon `chevron_right` atau seluruh card jadi tappable → buka Detail Profil (mengurangi tinggi card drastis).
   - Checkbox "Bandingkan": pindah ke pojok kiri atas card sebagai small checkbox overlay di foto, bukan tombol teks di baris terakhir.
6. Card "Siap Jual" (harga & CTA "Buat SPH"/"Lihat Sertifikat") tetap boleh sedikit lebih tinggi karena memang perlu CTA transaksional — tapi 2 tombol tetap harus fit 1 baris tanpa wrap (gunakan label pendek: "Buat SPH", "Sertifikat").

### Empty/edge state
- Kalau filter tidak ada hasil: tampilkan ilustrasi/icon + teks "Belum ada data di kategori ini".

---

## 3. Screen: Siklus Telur (IoT Monitoring)

### Masalah di desain lama
- Transisi dari dark hero image ke card putih di bawah kurang smooth (kontras tiba-tiba).
- Checklist di bawah tidak ada grouping visual.
- Terlalu banyak card terpisah untuk info yang sebenarnya berkaitan (silsilah, fase embrio, hasil candling).

### Struktur baru
1. **Header stat row** (Total Telur / Inkubator / Menetas): pertahankan 3 kolom, tapi kasih card container tipis per kolom (bukan floating text) supaya scan lebih cepat — masing-masing dengan mini icon.
2. **Bio-Dome hero card**: gabungkan foto + status "Active Monitoring" + temperature/humidity/next-turn jadi **1 card menyatu** (bukan foto lalu 3 stat terpisah). Overlay stat langsung di atas foto (semi-transparent bar di bawah gambar), supaya card ini punya 1 bounding box jelas → mengurangi ketinggian screen keseluruhan.
3. **Fase Pertumbuhan Embrio**: pakai circular progress ring (pola sama seperti Egg Cycle Card di Dashboard) untuk "Hari 18/28" agar konsisten dan sekali pandang jelas progressnya, dampingi teks "Candling: ... ~10 hari lagi" di sebelah ring.
4. **Hasil Candling**: gabung ke card yang sama dengan Fase Pertumbuhan (bukan card terpisah) — ini 1 kesatuan info "kondisi embrio". Pakai icon check hijau kecil, teks 2 baris max.
5. **Kontrol Telemetri IoT** (60/30/10: bg dominan, kartu putih, aksen teal 10%): 3 kartu vertikal penuh — **Lampu** = segmented Otomatis/Nyala/Mati yang langsung kirim (opsi terpilih terisi primaryTeal), **Rotasi** = 1 tombol primer penuh "Putar Sekarang" + info jadwal, **Mist Maker** = tombol outlined "Nyalakan" (±10 detik, firmware mendukung TRIGGER). Status ON = chip statusActive hijau, OFF/- = chip netral abu. Target tap ≥48px, label ≤2 kata.
6. **Log Penetasan**: list item dengan icon telur kecil + kode + tanggal + berat, badge status ("Cangkang Prima") pakai statusActive. Tombol "+ Catat Telur" tetap ada tapi jadi 1 primary button di section ini (bukan floating di header seperti sekarang).
7. **Pusat Kesiapan Brooder**: card status "STANDBY" + checklist. Checklist 3 item digroup dalam 1 card dengan divider tipis antar item (bukan list polos) supaya terlihat sebagai 1 unit "readiness checklist", masing-masing item icon check + label status pendek di kanan (SIAP/AKTIF/TERSEDIA → semua pakai statusActive hijau kalau semuanya oke).

---

## 4. Screen: Keuangan & Penjualan

### Masalah di desain lama
- Financial hero card oke, tapi riwayat transaksi & kesiapan komersial digabung tanpa pemisahan jelas → scroll panjang, sulit scan.
- Export laporan (4 card PDF/XLS) memakan banyak ruang vertikal di akhir tanpa hierarki.

### Struktur baru
1. **Hero valuation card**: pertahankan pola sama seperti `_ValuationCard` di Dashboard — total valuasi besar, lalu 2 kolom kecil (Pendapatan Bulan, Biaya Pakan & IoT) sebagai sub-stat, bukan 2 card terpisah sejajar.
2. **Banner regulasi BKSDA**: jadikan collapsible info banner (sama treatment seperti compatibility banner di Induk) — informasi penting tapi tidak perlu selalu full-height.
3. **Kesiapan Komersial** (list produk siap jual): ubah ke **horizontal scrollable card list** (bukan vertical stack) — ini kategori "produk", cocok di-browse horizontal seperti katalog, menghemat ruang vertikal signifikan.
4. **Riwayat Transaksi**: pisahkan jadi section sendiri dengan header jelas + filter singkat (chip: Semua/Lunas/Proses). Tiap item transaksi:
   - Baris 1: kode transaksi + status chip (pakai warna konsisten: Lunas=hijau, Verifikasi/Proses=kuning)
   - Baris 2: nama pembeli (muted, ellipsis 1 baris)
   - Baris 3: nominal (bold, rata kanan) — saat ini info "DP Terverifikasi" dan nominal DP menumpuk tanpa struktur, rapikan jadi 2 baris kecil di bawah nominal utama: "DP masuk: Rp X dari Rp Y".
5. **Ekspor Laporan Resmi**: ubah 4 card grid jadi **1 card dengan 4 baris list** (icon format + nama laporan + tombol download kecil di kanan), bukan 4 card kotak terpisah — jauh lebih ringkas secara vertikal dan tetap scannable.

---

## 5. Checklist Konsistensi Lintas Screen (cek sebelum implementasi)

- [ ] Semua status pakai 4 warna di §1, tidak ada warna status baru.
- [ ] Tidak ada card dengan lebih dari 1 primary button.
- [ ] Semua label tombol ≤ 2 kata atau lebar tombol dites tidak wrap di layar 360px (device kecil).
- [ ] Semua nama/teks penting pakai `maxLines` + `ellipsis` dengan lebar container yang sudah dipastikan cukup — bukan asal potong.
- [ ] Radius card besar = 20px, card kecil/list item = 16px, chip = pill penuh.
- [ ] Setiap screen punya maksimal 1 dark hero card di paling atas — sisanya card putih di atas `AppColors.bg`.
# DonburiX: Smart Rice Bowl Ordering & Just-in-Time Kitchen System

## 1. Deskripsi Masalah
Pada gerai makanan cepat saji berbasis rice bowl, terdapat tiga kendala operasional utama:
* **Penurunan Kualitas Makanan (*Food Degradation*):** Pada pesanan bawa pulang (*takeaway*), komponen rice bowl (gorengan, saus, dan sayuran) rentan menjadi dingin atau lembek jika dimasak terlalu dini mendahului kedatangan pelanggan.
* **Ketidakpastian Waktu Tunggu:** Estimasi waktu penyajian yang ditampilkan pada aplikasi konvensional umumnya bersifat statis (misal: "20 menit"), tanpa memperhitungkan lonjakan antrean dapur fisik secara dinamis.
* **Desinkronisasi Status Dapur dan Pelanggan:** Belum tersedianya sinkronisasi dua arah yang instan antara layar staf dapur (*Kitchen Display System*) dan aplikasi pelanggan, yang kerap memicu *race condition* (stok habis tetap terpesan) dan ketidaktahuan pelanggan mengenai status pesanannya.

---

## 2. Profil Target Pengguna

### Pelanggan (*Mobile App Client*)
* **Demografi:** Mahasiswa dan pekerja kantor berusia 18–35 tahun dengan mobilitas tinggi.
* **Karakteristik & Perilaku:** Membutuhkan pesanan cepat saji, sering memesan makanan untuk diambil sendiri (*self-pickup/takeaway*), menginginkan kustomisasi komposisi menu, dan enggan menunggu antrean fisik di gerai.

### Staf Dapur / Operator Gerai (*Web KDS Client*)
* **Demografi:** Karyawan operasional gerai rice bowl.
* **Karakteristik & Perilaku:** Memerlukan antarmuka ringkas satu layar (*dashboard*) yang menampilkan antrean pesanan secara langsung tanpa kertas bon fisik, serta tombol kendali stok bahan secara cepat.

---

## 3. Manfaat Aplikasi
* **Bagi Pelanggan:** Menerima rice bowl dalam kondisi segar (*freshly assembled*) saat tiba di gerai, kepastian estimasi waktu pengambilan yang transparan, dan kemudahan meracik menu (*custom bowl*).
* **Bagi Pengelola Gerai:** Mengurangi risiko pembatalan pesanan akibat makanan dingin, otomatisasi prioritas antrean dapur tanpa intervensi manual, dan pembaruan ketersediaan bahan secara terpusat.

---

## 4. Daftar Fitur Inti (Ruang Lingkup 12 Pertemuan)

| Modul | Deskripsi Fitur | Target Selesai |
| :--- | :--- | :--- |
| **Autentikasi & Profil** | Registrasi, login pelanggan via Firebase/Supabase Auth, dan penyimpanan riwayat pesanan. | Pertemuan 1–3 |
| **Dynamic Bowl Builder** | Antarmuka pemilihan layer rice bowl (Base, Protein, Saus, Add-on) dengan kalkulasi harga reaktif dan validasi stok lokal. | Pertemuan 4–5 |
| **Bi-directional Order Sync** | Integrasi WebSocket untuk sinkronisasi instan pesanan masuk dari Flutter ke Web Kitchen Dashboard dan sebaliknya. | Pertemuan 6–8 |
| **Geofenced Freshness Trigger** | Pemicu otomatis status pesanan menjadi *"Cooking/Assembly"* pada dashboard dapur ketika lokasi GPS pelanggan berada dalam radius 500 meter dari gerai. | Pertemuan 9–10 |
| **Dynamic Wait-Time Heuristic** | Perhitungan estimasi waktu tunggu berdasarkan jumlah antrean aktif di dapur dikalikan bobot waktu tiap item. | Pertemuan 11 |
| **Pengujian Sistem & Polish** | Integrasi end-to-end, penanganan kasus koneksi terputus (*reconnection handler*), dan *freeze* fitur. | Pertemuan 12 |

---

## 5. Fitur yang Tidak Dikerjakan (*Out of Scope*)
Untuk menjaga kelayakan penyelesaian dalam 12 pertemuan, batasan proyek ini mencakup:
* **Payment Gateway Produksi:** Tidak menggunakan transaksi bank riil, melainkan simulasi pembayaran (*payment sandbox* atau *mock automated success*).
* **Layanan Logistik / Kurir Pengantaran:** Tidak menyediakan pelacakan driver pihak ketiga; sistem hanya melayani *Pickup Takeaway* dan *Dine-in Order*.
* **Multi-Outlet / Multi-Tenancy:** Sistem hanya menangani satu titik cabang gerai fisik.
* **Machine Learning On-Device:** Analisis nutrisi berbasis pemindaian foto kamera tidak diimplementasikan pada fase ini.

---

## 6. Kriteria Aplikasi Dinyatakan Berhasil (*Definition of Success*)
Aplikasi dinyatakan memenuhi syarat proyek akhir apabila:
1. **Latensi Sinkronisasi Rendah:** Perubahan status pesanan dari web dashboard dapur terpantau pada aplikasi mobile dalam waktu $\le 2$ detik melalui protokol real-time.
2. **Keberhasilan Geofence:** Aplikasi mobile mampu mengirim sinyal kedatangan pelanggan saat melintasi perimeter radius 500 meter dari koordinat gerai secara konsisten.
3. **Integritas State Custom Builder:** Validasi komposisi menu berjalan konsisten tanpa anomali harga ataupun duplikasi item pada keranjang.
4. **Alur End-to-End Tanpa Celah:** Skenario mulai dari peracikan menu, pemesanan, penerimaan tiket di KDS, pemicu geofence, hingga konfirmasi pengambilan (*picked up*) dapat didemonstrasikan secara langsung tanpa kegagalan sistem.

---

## 7. Implementasi Tugas Ke-4: Flutter Bowl Builder

Feature awal tersedia pada [`apps/mobile`](apps/mobile): racik bowl dengan **Riverpod**, form, validasi,
enam kondisi UI, pencegahan submit ganda, dan keranjang lokal.
Feature ini memakai data demo; integrasi backend dan ricebowltracker mengikuti [Architecture.md](Architecture.md).

Jalankan dari folder `apps/mobile`:

```sh
flutter pub get
flutter run -d chrome
```

Dokumentasi pengumpulan:

* [Laporan tugas 4 dan screenshot](docs/tugas4/README.md)
* [Catatan prompt AI dan refleksi pemeriksaan mandiri](docs/tugas4/AI_USAGE.md)
* [Panduan menjalankan, scenario demo, dan test](apps/mobile/README.md)

Verifikasi lokal terbaru: analyze berhasil dan **20 test lulus**.
Build Flutter Web berhasil pada implementasi awal.
Penyempurnaan P4 menambahkan test batas input, pemulihan error submit, dan keamanan lifecycle asynchronous.
Lihat [catatan progres penyempurnaan P4](docs/tugas4/PROGRESS.md).

---

## 8. Tugas 7: MVP Lengkap

MVP kini mencakup login & profil, Bowl Builder, keranjang, checkout, estimasi saji dinamis,
geofence freshness trigger (radius 500 m), layar Dapur (KDS) dengan restok, dan penyimpanan lokal.

* [Cara menjalankan (HowToRun.md)](docs/tugas7/HowToRun.md)
* [Checklist fitur dan status test (checklist_mvp.md)](docs/tugas7/checklist_mvp.md)
* [Video demo (demo.mp4)](docs/tugas7/demo.mp4)

Verifikasi terbaru: analyze tanpa temuan, **72 test lulus**, build web berhasil.

---

## 9. Instalasi Ulang dan Akses Aplikasi (Tugas 8)

### Akses tanpa instalasi

| Paket | Lokasi |
| --- | --- |
| Demo web | <https://cikibber.github.io/DonburiX/> |
| APK Android demo | Tab [Actions](https://github.com/Cikibber/DonburiX/actions/workflows/flutter.yml), run terbaru yang berhasil, artifact `donburix-demo-apk` (perlu login GitHub) |
| Video alur | [`docs/tugas7/demo.mp4`](docs/tugas7/demo.mp4) |

Masuk dengan nama dan email apa saja. Tab **Dapur** memakai PIN demo `4826`.
PIN ini sengaja dipublikasikan untuk penilaian dan bukan kredensial produksi.
Data tersimpan hanya di browser atau perangkat Anda.

### Prasyarat

| Alat | Versi |
| --- | --- |
| Git | Versi terbaru |
| Flutter | 3.44.1 (channel stable), sudah termasuk Dart 3.12.1 |
| Google Chrome | Untuk Flutter Web |
| Bash | Untuk `scripts/build-web.sh`. Di Windows gunakan Git Bash |
| Android SDK dan Java 17 | Opsional, hanya untuk build APK |

### Instalasi dari clone bersih

```sh
git clone https://github.com/Cikibber/DonburiX.git
cd DonburiX/apps/mobile
flutter pub get --enforce-lockfile
flutter run -d chrome --dart-define=KDS_PIN=4826
```

Tanpa `KDS_PIN`, aplikasi tetap berjalan tetapi layar Dapur selalu terkunci.

### Pemeriksaan

Jalankan dari `apps/mobile`:

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
```

Hasil yang diharapkan: analyze tanpa temuan dan **103 test lulus**.

### Build dan deployment

Jalankan dari root repo:

```sh
# Web release dengan CSP, hasil di apps/mobile/build/web
KDS_PIN=4826 BASE_HREF=/ ./scripts/build-web.sh
python -m http.server 8080 --directory apps/mobile/build/web

# APK demo
cd apps/mobile && flutter build apk --release --dart-define=KDS_PIN=4826
```

Deployment ke GitHub Pages berjalan otomatis lewat
[`deploy-web.yml`](.github/workflows/deploy-web.yml) setiap ada perubahan aplikasi di `main`.
Workflow menjalankan test dulu, sehingga build yang gagal test tidak ter-deploy.
Untuk deploy manual: `gh workflow run deploy-web.yml`.

Pada fork, aktifkan **Settings > Pages > Source: GitHub Actions**, lalu sesuaikan
`BASE_HREF` di workflow dengan nama repo.

### Menghapus data dan mengulang dari awal

* Web: hapus data situs di browser.
* Android: hapus data aplikasi di pengaturan.
* Sumber: hapus folder clone, lalu ulangi langkah instalasi.

### Masalah umum

| Gejala | Penyebab | Solusi |
| --- | --- | --- |
| Dapur menampilkan "belum dikonfigurasi" | Build tanpa `KDS_PIN` | Tambahkan `--dart-define=KDS_PIN=4826` |
| Dapur "Terlalu banyak percobaan" | Lima PIN salah | Tunggu 1 menit atau muat ulang halaman |
| `--enforce-lockfile` gagal | Versi Flutter berbeda | Pakai Flutter 3.44.1 |
| Halaman kosong saat disajikan lokal | `BASE_HREF` tidak cocok dengan alamat | Build dengan `BASE_HREF=/` |
| `?scenario=` tidak berpengaruh | Build release mengabaikan hook demo | Pakai `flutter run` |

### Dokumen Tugas 8

* [Hasil uji keamanan dan change log](docs/tugas8/security_test_results.md)
* [Contoh log keamanan, penyebab, dan remediasi](docs/tugas8/security_logs.md)
* [Laporan clone bersih, PR, build, dan deployment](docs/tugas8/fresh_clone_report.md)

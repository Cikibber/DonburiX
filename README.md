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

Verifikasi lokal: analyze berhasil, **14 test lulus**, dan build Flutter Web berhasil.

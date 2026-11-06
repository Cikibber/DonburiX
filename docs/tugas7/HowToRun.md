# How to Run — DonburiX MVP (Tugas 7)

## Prasyarat

| Alat | Versi yang dipakai saat verifikasi |
| --- | --- |
| Flutter | 3.44.1 (channel stable) |
| Dart | 3.12.1 |
| Browser | Google Chrome (untuk Flutter Web) |
| Opsional | Emulator/perangkat Android |

Cek instalasi:

```sh
flutter --version
flutter doctor
```

## Menjalankan aplikasi

Semua perintah dijalankan dari folder `apps/mobile`.

```sh
cd apps/mobile
flutter pub get
flutter run -d chrome --dart-define=KDS_PIN=4826
```

Android (emulator/perangkat terhubung):

```sh
flutter run --dart-define=KDS_PIN=4826
```

Sejak Tugas 8 tab **Dapur** meminta PIN staf (`KDS_PIN`, demo: `4826`).

Data pesanan, stok, dan sesi login tersimpan di perangkat (`shared_preferences`;
di web memakai `localStorage`). Untuk mulai dari data kosong, tekan **Keluar**
di tab Profil lalu hapus data situs di browser, atau jalankan `flutter run`
pada profil browser baru.

## Alur demo end-to-end

1. **Masuk**: isi Nama dan Email (mis. `Budi`, `budi@mail.com`). Kosong atau
   format email salah ditolak dengan pesan.
2. **Racik**: pilih Nasi putih, Ayam teriyaki, Saus teriyaki, Telur
   (Rp 25.000/porsi), lalu **Tambahkan ke Keranjang**.
3. **Keranjang**: ubah jumlah dengan `+`/`-`, hapus item, lalu
   **Lanjut ke Checkout**.
4. **Checkout**: isi nama pemesan, pilih **Takeaway**, **Buat Pesanan**.
   Nomor pesanan `DX-YYYYMMDD-NNN` dan estimasi saji dibuat.
5. **Pesanan → detail**: tekan **Saya Sudah Tiba**. Lokasi berada dalam
   radius 500 m, sehingga status otomatis menjadi **Disiapkan**.
6. **Dapur (KDS)**: pesanan tampil di antrean dengan penanda
   "Pelanggan sudah tiba". Tekan **Tandai Siap Diambil** lalu
   **Selesaikan (Diambil)**. Tombol **+5** menambah stok bahan.
7. **Pesanan**: status pelanggan ikut berubah otomatis menjadi **Selesai**.
8. Muat ulang aplikasi: login, riwayat, dan stok tetap ada.
9. **Profil → Keluar**: kembali ke layar masuk.

## Skenario kondisi khusus (Flutter Web)

Tambahkan query pada URL aplikasi yang sedang berjalan, mis.
`http://localhost:<port>/?scenario=error`. Scenario selain `success` memakai
data bersih (tidak membaca data tersimpan).

| Query | Kondisi yang ditunjukkan |
| --- | --- |
| `?scenario=loading` | Loading katalog ditahan |
| `?scenario=empty` | Katalog bahan kosong |
| `?scenario=error` | Muat katalog gagal sekali, **Coba Lagi** berhasil |
| `?scenario=submit-error` | Tambah ke keranjang gagal sekali |
| `?scenario=checkout-error` | Checkout gagal sekali, keranjang tetap |
| `?scenario=orders-empty` | Riwayat pesanan kosong |
| `?scenario=orders-error` | Riwayat gagal dimuat |
| `?location=far` | Lokasi simulasi 2,2 km: **Saya Sudah Tiba** ditolak |

Android: `flutter run --dart-define=DEMO_SCENARIO=error`.

Query di atas hanya aktif pada build non-release (`flutter run`). Build release
dan situs yang di-deploy mengabaikannya.

## Menjalankan pengujian

```sh
cd apps/mobile
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
flutter build web
```

Atau dari root repo: `./scripts/verify.sh` (bash) / `./scripts/verify.ps1` (PowerShell).

Hasil verifikasi terakhir: analyze **No issues found**, **72 test lulus**,
`flutter build web` berhasil.

## Batasan MVP

- Backend disimulasikan oleh `DemoBowlRepository` + penyimpanan lokal;
  Firebase/Firestore belum dipasang. Tukar implementasi `BowlRepository`
  lewat provider override untuk integrasi backend.
- Login adalah akun lokal tanpa kata sandi (simulasi autentikasi).
- Sinkronisasi dapur ↔ pelanggan memakai stream di satu perangkat
  (tab Dapur), bukan WebSocket antar perangkat.
- Lokasi geofence memakai titik simulasi (`Geofence.demoNearby`/`demoFar`);
  GPS perangkat belum dipakai.
- Keranjang hanya bertahan selama sesi; pesanan, stok, dan login disimpan.

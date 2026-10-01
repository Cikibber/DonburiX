# DonburiX — Bowl Builder

Feature Flutter untuk tugas ke-4: Riverpod, form, validasi, dan enam kondisi UI.
Pengguna memilih base, protein, saus, serta add-on, memasukkan jumlah dan catatan,
lalu menambahkan racikan ke keranjang lokal.

## Menjalankan aplikasi

Jalankan perintah berikut dari folder `apps/mobile`:

```sh
flutter pub get
flutter run -d chrome
```

Untuk Android, jalankan `flutter run` dengan emulator atau perangkat Android yang terhubung.
Scaffold Android tersedia; pengujian pada sesi ini memakai widget test dan Flutter Web.

## Pemeriksaan

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
flutter build web
```

Flutter yang dipakai untuk verifikasi: **3.44.1**, Dart **3.12.1**.
Versi Riverpod terpasang: **3.4.3**, dikunci dalam `pubspec.lock`.

## Reproduksi kondisi UI

Pada web, tambahkan query pada URL aplikasi yang sudah berjalan:

| Query | Kondisi |
| --- | --- |
| `?scenario=success` | Data tersedia; submit selesai dalam satu detik |
| `?scenario=loading` | Initial loading ditahan untuk demonstrasi |
| `?scenario=empty` | Katalog kosong |
| `?scenario=error` | Load pertama gagal; Coba Lagi memuat data |
| `?scenario=submit` | Submit berlangsung lima detik agar indikator terlihat |
| `?scenario=submit-error` | Submit pertama gagal; percobaan berikutnya berhasil |

Pada Android, pilih scenario saat menjalankan aplikasi:

```sh
flutter run --dart-define=DEMO_SCENARIO=error
```

Untuk menunjukkan validasi, tekan tambah sebelum memilih bahan atau masukkan jumlah `0`.
Untuk menunjukkan submit, pilih Nasi putih, Ayam teriyaki, Saus teriyaki, dan Telur.
Harga satu porsi kombinasi tersebut adalah **Rp 25.000**.

## Batas implementasi

`DemoBowlRepository` memakai data lokal dan penundaan terkontrol untuk menunjukkan operasi asynchronous.
Keranjang bertahan selama sesi aplikasi dan dapat dibuka melalui tombol di app bar.
Muat ulang aplikasi menghapus keranjang. Feature belum memanggil Firebase atau backend ricebowltracker.
Stok tidak direservasi saat menambahkan ke keranjang; reservasi merupakan tahap checkout pada rancangan arsitektur.

Integrasi berikutnya dapat mengganti implementasi `BowlRepository` melalui provider override.
Implementasi backend harus menghitung ulang harga, memvalidasi stok, dan menyediakan idempotency saat checkout.

Lihat [laporan tugas 4](../../docs/tugas4/README.md), [prompt AI](../../docs/tugas4/AI_USAGE.md),
dan [arsitektur](../../Architecture.md).

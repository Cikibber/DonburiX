# Checklist MVP DonburiX — Tugas 7

Status test diambil dari `flutter test --coverage` pada folder `apps/mobile`:
**72 test, semua PASSED**. `flutter analyze`: tanpa temuan.
`flutter build web`: berhasil.

Video alur lengkap: [`demo.mp4`](demo.mp4). Cara menjalankan: [`HowToRun.md`](HowToRun.md).

## Fitur inti

| No | Fitur MVP | Status | Unit/widget test | Hasil |
| --- | --- | --- | --- | --- |
| 1 | Login & profil pelanggan (validasi nama/email, sesi tersimpan, keluar) | Selesai | `test/session_test.dart` (3) | PASSED |
| 2 | Dynamic Bowl Builder (base, protein, saus, add-on, harga reaktif, stok, validasi) | Selesai | `test/bowl_builder_widget_test.dart` (18), `test/bowl_repository_test.dart` (2) | PASSED |
| 3 | Keranjang (ubah jumlah, hapus, total, empty state) | Selesai | `test/cart_management_test.dart` (6) | PASSED |
| 4 | Checkout takeaway/dine-in + pembayaran simulasi | Selesai | `test/order_checkout_test.dart` (9) | PASSED |
| 5 | Reservasi stok all-or-nothing | Selesai | `test/stock_reservation_test.dart` (3) | PASSED |
| 6 | Estimasi waktu tunggu dinamis (antrean × bobot porsi) | Selesai | `test/eta_estimation_test.dart` (5) | PASSED |
| 7 | Nomor pesanan publik `DX-YYYYMMDD-NNN` + pencarian | Selesai | `test/order_display_id_test.dart` (3) | PASSED |
| 8 | Sinkronisasi status dapur → pelanggan (maju satu langkah, < 2 detik) | Selesai | `test/order_status_sync_test.dart` (4) | PASSED |
| 9 | Pembatalan sebelum disiapkan + stok kembali | Selesai | `test/order_cancellation_test.dart` (4) | PASSED |
| 10 | Geofenced Freshness Trigger (radius 500 m → status Disiapkan) | Selesai (lokasi simulasi) | `test/geofence_arrival_test.dart` (5), `test/kitchen_flow_test.dart` AC6–AC7 | PASSED |
| 11 | Kitchen Display System: antrean FIFO, maju status, restok | Selesai | `test/kitchen_flow_test.dart` AC1–AC2, `test/persistence_kitchen_test.dart` kitchen AC1–AC3 | PASSED |
| 12 | Penyimpanan data: pesanan, stok, nomor urut, sesi bertahan setelah restart | Selesai | `test/persistence_kitchen_test.dart` storage AC1–AC2 | PASSED |
| 13 | Riwayat pesanan per akun | Selesai | `test/kitchen_flow_test.dart` riwayat AC1 | PASSED |

## Penanganan kondisi

| Kondisi | Contoh di aplikasi | Test |
| --- | --- | --- |
| Input tidak valid | Nama/email login, jumlah 1–10, catatan ≤ 120, bahan wajib, nama pemesan, restok 1–100 | session, bowl_builder, order_checkout, persistence_kitchen |
| Data kosong | Katalog kosong, keranjang kosong, riwayat kosong, antrean dapur kosong | bowl_builder, cart_management, order_checkout |
| Loading | Muat katalog, tambah ke keranjang, buat pesanan | bowl_builder, order_checkout |
| Kegagalan | Katalog/riwayat/checkout gagal + Coba Lagi, stok tidak cukup, di luar radius geofence, data tersimpan rusak | bowl_builder, order_checkout, stock_reservation, geofence_arrival, persistence_kitchen |
| Double submit | Tombol nonaktif selama proses | bowl_builder, order_checkout |

## Regresi

Seluruh 54 test dari Tugas 4–6 tetap lulus tanpa perubahan assertion.
Perubahan pada test lama hanya: helper `mount` menambahkan override sesi login
(`test/test_support.dart`) dan fake repository menambah dua method interface baru.

## Bug yang diperbaiki selama P7

- Katalog builder menampilkan stok lama setelah checkout/batal: katalog kini dimuat ulang.
- Riwayat hanya diperbarui lewat refresh manual: `watchOrders()` kini stream live.
- Keranjang akun lama terbawa setelah keluar: keranjang dan form checkout direset saat logout.

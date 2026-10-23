# Tugas 6 — Penyempurnaan MVP DonburiX

Lima user story penyempurnaan MVP, masing-masing dengan acceptance criteria,
kode produksi, dan unit test yang memetakan AC ke aturan bisnis.

## Ringkasan MVP

DonburiX MVP adalah aplikasi pemesanan rice bowl yang menghubungkan pelanggan
dengan dapur: racik bowl, keranjang, checkout, nomor pesanan, estimasi saji
dinamis, dan pelacakan status. Tugas 6 memperkuat aturan bisnis inti, bukan
menambah layar baru.

## User story

### US1 — Stok aman dari pesanan berlebih

Sebagai pemilik gerai, saya ingin stok bahan dipotong saat checkout agar
pesanan tidak melebihi stok yang tersedia.

- AC1: checkout memotong stok setiap bahan sebesar jumlah porsi.
- AC2: stok tidak cukup menolak checkout dengan pesan spesifik; stok lain tidak berubah.
- AC3: reservasi bersifat all-or-nothing; tidak ada potongan parsial saat satu bahan gagal.

Test: `test/stock_reservation_test.dart`.

### US2 — Estimasi saji dinamis

Sebagai pelanggan, saya ingin estimasi waktu yang mengikuti antrean dapur agar
tidak menunggu tanpa kepastian.

- AC1: antrean kosong, dine-in satu porsi = batas minimum 8 menit.
- AC2: takeaway menambah 2 menit pengemasan.
- AC3: estimasi dijepit maksimum 45 menit.
- AC4: estimasi tersimpan di pesanan dan naik saat antrean bertambah.
- AC5: input negatif ditolak.

Test: `test/eta_estimation_test.dart`.

### US3 — Nomor pesanan publik

Sebagai staf dan pelanggan, saya ingin nomor pesanan yang konsisten dan mudah
dicari agar pesanan dapat dipanggil tanpa membuka data internal.

- AC1: format `DX-YYYYMMDD-NNN` divalidasi.
- AC2: urutan nomor naik per hari dan tidak bentrok.
- AC3: lookup tidak peka huruf besar/kecil maupun spasi; nomor tidak dikenal mengembalikan null.

Test: `test/order_display_id_test.dart`.

### US4 — Sinkronisasi status dapur

Sebagai pelanggan, saya ingin status pesanan berubah otomatis agar tahu kapan
pesanan siap.

- AC1: status hanya maju satu langkah; tidak ada jalan mundur.
- AC2: perubahan status diterima pelanggan di bawah 2 detik.
- AC3: status `Selesai` bersifat terminal.
- AC4: pesanan yang dibatalkan tidak bisa dilanjutkan dapur.

Test: `test/order_status_sync_test.dart`.

### US5 — Jendela pembatalan

Sebagai pelanggan, saya ingin membatalkan pesanan sebelum dapur mulai
menyiapkan, dengan stok kembali tersedia.

- AC1: batal saat `Dipesan` mengembalikan stok penuh.
- AC2: batal setelah `Disiapkan` ditolak; stok tetap terpakai.
- AC3: aturan pembatalan mengikuti status dan flag batal.
- AC4: pesanan tidak dikenal ditolak.

Test: `test/order_cancellation_test.dart`.

## Perubahan kode produksi

- `lib/features/orders/domain/order_rules.dart` (baru): `OrderIdRules`,
  `OrderEta`, `OrderStatusFlow`, `OrderCancellation`.
- `lib/features/orders/domain/order_models.dart`: `estimatedMinutes`, `cancelled`, `copyWith`.
- `lib/features/bowl_builder/data/demo_bowl_repository.dart`: ledger stok,
  reservasi all-or-nothing, ETA saat checkout, urutan nomor per hari,
  lookup nomor, stream status per pesanan, dan pembatalan dengan restore stok.
- `lib/features/orders/state/order_providers.dart`: `orderStreamProvider`.
- `lib/features/orders/presentation/order_detail_screen.dart`: ETA, tombol
  simulasi dapur, tombol batal, banner batal, status live.
- `lib/features/orders/presentation/orders_screen.dart`: pencarian nomor pesanan.

## Menjalankan

```sh
cd apps/mobile
flutter pub get
flutter run -d chrome
```

## Verifikasi

```sh
cd apps/mobile
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
flutter build web
```

Lima file unit test baru ditambah 35 test P4/P5; seluruh suite wajib lulus.

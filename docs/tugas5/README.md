# Tugas 5 — MVP Version 1 DonburiX

## MVP V1 scope

Dua fitur inti, dikerjakan iteratif satu per satu:

1. **F1 — Manajemen Keranjang**: layar keranjang (ubah jumlah, hapus item, total reaktif, empty state).
2. **F2 — Checkout & Lacak Pesanan**: buat pesanan (takeaway/dine-in, pembayaran simulasi) + riwayat/detail dengan timeline status.

Alur per fitur: **Brief → Plan → Build → Verify → Commit**.
Prinsip: AI membantu engineering; mahasiswa review, uji, jelaskan. Bagian refleksi mahasiswa diisi sendiri di `AI_USAGE.md`.

## F1 — Manajemen Keranjang

### Brief

Keranjang P4 hanya bottom sheet baca-saja. MVP butuh layar keranjang kelola: ubah jumlah porsi per item (validasi 1–10 + stok), hapus item, total reaktif, empty state.

Acceptance criteria:

- AC1: item keranjang tampil (komposisi, jumlah, catatan, subtotal).
- AC2: `+`/`-` ubah jumlah; total + badge update reaktif.
- AC3: jumlah di bawah 1 ditolak; di atas stok ditolak dengan pesan, jumlah lama bertahan.
- AC4: hapus item; item terakhir dihapus → empty state.
- AC5: banyak item independen; hapus satu tidak ganggu lain.

### Plan

- `state/bowl_providers.dart`: field `cartError`, `removeFromCart`, `updateCartQuantity` (validasi via `BowlValidation.validateDraft`), `cartTotalProvider`, `cartItemCountProvider`.
- `features/cart/presentation/cart_screen.dart` (baru): daftar kartu item, stepper, hapus, total, empty state.
- `bowl_builder_screen.dart`: bottom sheet → push `CartScreen`.
- `test/cart_management_test.dart` (baru): 6 widget test memetakan AC1–AC5.
- Existing 20 test P4 tidak boleh rusak (teks `Keranjang Anda`, join ` · `, badge dipertahankan).

### Build

AI generate kode + test. Mahasiswa review/diubah: lihat `AI_USAGE.md`.

### Verify

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
flutter build web
```

Hasil: analyze tanpa temuan; **26 test lulus** (20 P4 + 6 F1); build web berhasil.
Bukti test: `test/cart_management_test.dart`.

### Commit

`3ea4c0c` — `feat(mobile): add cart management screen for MVP V1`.

## F2 — Checkout & Lacak Pesanan

### Brief

Keranjang tanpa checkout bukan MVP. F2: form checkout (nama, takeaway/dine-in, pembayaran simulasi) → buat pesanan dengan nomor `DX-…`, kosongkan keranjang → riwayat + detail dengan timeline status `Dipesan → Disiapkan → Siap → Selesai`.

Acceptance criteria:

- AC1: checkout butuh nama; tanpa nama ditolak tanpa pesanan.
- AC2: pesanan tampil di riwayat: nomor, nama, tipe, total, status.
- AC3: detail tampilkan item, total, timeline sesuai status.
- AC4: keranjang dikosongkan setelah checkout sukses.
- AC5: riwayat kosong tampilkan empty state.

### Plan

- `features/orders/domain/order_models.dart` (baru): `OrderType`, `OrderStatus` (+ label/tahapan), `Order`, ID `DX-YYYYMMDD-NNN`, validasi nama.
- `features/orders/state/order_providers.dart` (baru): `OrderList` AsyncNotifier (load/empty/error + retry), `CheckoutForm` Notifier (nama, tipe, submit, guard ganda, kosongkan keranjang).
- `DemoBowlRepository` + interface: `createOrder()` (validasi ulang harga/stok server-side, simulasi stok menipis), `watchOrders()`.
- UI baru: `CheckoutSheet`/`CheckoutScreen`, `OrdersScreen` (riwayat), `OrderDetailScreen` (timeline).
- Navigasi bawah: Builder | Pesanan. Tombol checkout di CartScreen → checkout; sukses → riwayat.
- Test baru `test/order_checkout_test.dart`: AC1–AC5 + guard double submit.
- P4/F1 test tidak rusak.

### Build

AI generate model, provider, repository, UI, navigasi tab, dan test.
Perbaikan oleh AI selama build: import relatif order feature, `RadioGroup` pengganti API deprecated, `StreamNotifier` + `latestOrders()` agar refresh deterministik, dan test yang gantung diubah jadi unit test murni.

### Verify

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
flutter build web
```

Hasil: analyze tanpa temuan; **35 test lulus** (20 P4 + 6 F1 + 9 F2); build web berhasil.
Bukti test: `test/order_checkout_test.dart` (AC1–AC5, error retry, gagal-then-retry, guard double submit, revalidasi harga katalog).

### Commit

(menyusul)

## Bukti acceptance criteria

| AC | Bukti test |
| --- | --- |
| AC1 nama wajib | `AC1 checkout requires a customer name` |
| AC2 riwayat bernomor | `AC2 order appears in history with number and status` |
| AC3 detail + timeline | `AC3 detail shows items, total, and status timeline` |
| AC4 keranjang dikosongkan | `AC4 cart is emptied after successful checkout` |
| AC5 empty riwayat | `AC5 empty history shows the empty state` |

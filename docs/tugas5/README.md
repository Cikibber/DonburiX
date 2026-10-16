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

Commit F1 menyusul (hash diisi setelah commit).

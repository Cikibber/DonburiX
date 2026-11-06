# Contoh Log Keamanan, Penyebab, dan Remediasi — Tugas 8

Semua baris di bawah adalah keluaran asli, bukan contoh buatan. Baris dari
**browser** berasal dari build release hasil clone bersih yang dijalankan di
Chromium (2026-11-06). Baris dari **test** berasal dari `flutter test` karena
kondisinya tidak bisa dipicu lewat UI build release.

## Format

Aplikasi menulis satu baris JSON per kejadian lewat `logSecurityEvent`
([`security_log.dart`](../../apps/mobile/lib/core/security_log.dart)).

| Field | Isi |
| --- | --- |
| `ts` | Waktu UTC |
| `level` | `warn` untuk penolakan, `info` untuk kejadian normal |
| `event` | Nama kejadian |
| lainnya | Konteks tanpa data pribadi |

Log tidak pernah memuat email, nama, PIN, atau koordinat. Aturan ini diuji di
grup `SEC-07` pada [`security_test.dart`](../../apps/mobile/test/security_test.dart).

Cara melihat: buka DevTools browser, tab **Console**. Di Android gunakan
`flutter logs`. Log hanya ada di konsol perangkat karena MVP belum memiliki
server log.

## Contoh kejadian

### 1. Mencoba membuka pesanan orang lain

```json
{"ts":"2026-11-06T02:28:02.186Z","level":"warn","event":"order.access_denied","action":"lookup","order":"DX-20261106-001"}
```

Sumber: browser. Test juga menghasilkan `"action":"cancel"` dan `"action":"arrive"`.

- **Penyebab:** akun Sari mencari nomor pesanan milik Budi. Nomor pesanan
  berurutan, jadi mudah ditebak.
- **Respons aplikasi:** menjawab "Pesanan tidak ditemukan", sama seperti nomor
  yang tidak ada, sehingga keberadaan pesanan tidak bocor.
- **Remediasi yang sudah dilakukan:** pemeriksaan kepemilikan `actorEmail` di
  `findByDisplayId`, `cancelOrder`, dan `markArrived`.
- **Tindakan operator bila berulang:** periksa apakah perangkat dipakai bersama.
  Saat backend tersedia, tambahkan pembatasan laju per akun.

### 2. PIN dapur salah hingga terkunci

```json
{"ts":"2026-11-06T02:28:11.259Z","level":"warn","event":"kds.pin_denied","attempt":1}
{"ts":"2026-11-06T02:28:17.909Z","level":"warn","event":"kds.pin_denied","attempt":4}
{"ts":"2026-11-06T02:28:20.126Z","level":"warn","event":"kds.locked_out","attempts":5}
{"ts":"2026-11-06T02:28:22.341Z","level":"warn","event":"kds.pin_blocked"}
```

Sumber: browser.

- **Penyebab:** lima PIN salah berturut-turut. `pin_blocked` berarti percobaan
  dilakukan selama penguncian, termasuk dengan PIN yang benar.
- **Respons aplikasi:** layar dapur terkunci selama 1 menit.
- **Remediasi yang sudah dilakukan:** gerbang PIN dan penguncian di
  [`kds_access.dart`](../../apps/mobile/lib/features/kitchen/state/kds_access.dart).
- **Tindakan operator bila berulang:** ganti `KDS_PIN` lalu build ulang.

### 3. PIN belum dikonfigurasi

```json
{"ts":"2026-11-06T02:23:33.709015Z","level":"warn","event":"kds.not_configured"}
```

Sumber: test.

- **Penyebab:** aplikasi dibangun tanpa `--dart-define=KDS_PIN=...`.
- **Respons aplikasi:** layar dapur tetap terkunci dan menampilkan pesan
  konfigurasi. Tidak ada PIN bawaan.
- **Remediasi:** build ulang dengan `KDS_PIN`.

### 4. Lokasi ditolak geofence

```json
{"ts":"2026-11-06T02:23:14.225306Z","level":"warn","event":"geofence.rejected","reason":"outside_radius","order":"DX-20261106-001","distanceM":2224}
{"ts":"2026-11-06T02:23:19.252099Z","level":"warn","event":"geofence.rejected","reason":"invalid_location","order":"DX-20261106-001"}
```

Sumber: test.

- **Penyebab `outside_radius`:** pelanggan menekan "Saya Sudah Tiba" dari jarak
  2.224 m. Ini perilaku normal.
- **Penyebab `invalid_location`:** koordinat `NaN`, tak hingga, atau di luar
  rentang bumi. Sebelum perbaikan, nilai `NaN` lolos dan memicu dapur memasak.
- **Remediasi yang sudah dilakukan:** `GeoPoint.isValid` diperiksa sebelum
  menghitung jarak.
- **Tindakan operator:** `invalid_location` berulang menandakan data lokasi
  dimanipulasi atau sensor GPS bermasalah.

### 5. Data tersimpan rusak atau dimanipulasi

```json
{"ts":"2026-11-06T02:28:27.846Z","level":"warn","event":"storage.corrupt_reset","store":"kitchen","cause":"invalid_format"}
{"ts":"2026-11-06T02:23:23.871586Z","level":"warn","event":"storage.corrupt_reset","store":"session","cause":"invalid_format"}
```

Sumber: baris pertama browser (isi `localStorage` diubah), baris kedua test.

- **Penyebab:** JSON rusak, stok atau nomor urut negatif, atau sesi dengan email
  tidak valid.
- **Respons aplikasi:** data ditolak seluruhnya dan aplikasi mulai dari kondisi
  awal, tanpa crash. Sesi yang ditolak mengembalikan pengguna ke layar masuk.
- **Remediasi yang sudah dilakukan:** validasi penuh saat memuat data, baru
  diterapkan setelah semua lolos.
- **Tindakan operator:** data lokal yang ditolak tidak bisa dipulihkan. Bila
  sering terjadi di perangkat yang sama, periksa ekstensi browser atau perangkat.

### 6. Input login dan restok ditolak

```json
{"ts":"2026-11-06T02:26:59.031Z","level":"warn","event":"auth.login_rejected","field":"name"}
{"ts":"2026-11-06T02:23:21.661802Z","level":"warn","event":"stock.restock_rejected","reason":"amount_out_of_range","amount":101}
{"ts":"2026-11-06T02:23:21.662801Z","level":"warn","event":"stock.restock_rejected","reason":"unknown_ingredient"}
```

Sumber: baris pertama browser, sisanya test.

- **Penyebab:** kolom login kosong atau salah format, jumlah restok di luar
  1–100, atau bahan tidak dikenal.
- **Respons aplikasi:** menampilkan pesan validasi. Log hanya mencatat nama
  kolom, bukan nilai yang diketik.
- **Remediasi:** tidak perlu tindakan kecuali terjadi dalam jumlah besar.

### 7. Kejadian normal sebagai jejak audit

```json
{"ts":"2026-11-06T02:27:02.829Z","level":"info","event":"auth.login_ok"}
{"ts":"2026-11-06T02:27:31.160Z","level":"info","event":"kds.unlocked"}
{"ts":"2026-11-06T02:27:36.962Z","level":"info","event":"auth.logout"}
```

Sumber: browser. Tidak memerlukan tindakan.

## Masalah yang ditemukan saat menyiapkan log

Dua bug log ini hanya terlihat saat aplikasi dijalankan di browser. Unit test
sebelumnya tidak menangkapnya.

| Gejala | Penyebab | Perbaikan |
| --- | --- | --- |
| Login ditolak di layar tidak menghasilkan log | `_submit` berhenti di validasi form sebelum memanggil `login` | Form tetap menampilkan pesan, `login` selalu dipanggil. Ditambah widget test |
| `"cause":"minified:eA"` pada build release | `runtimeType` diacak saat kompilasi JavaScript | Diganti nilai tetap `invalid_format` / `invalid_type` |

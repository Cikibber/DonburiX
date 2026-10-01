# Arsitektur DonburiX

## 1. Tujuan dan Status Dokumen

**DonburiX: Smart Rice Bowl Ordering & Just-in-Time Kitchen System** adalah aplikasi pemesanan rice bowl
yang menghubungkan pelanggan dengan staf dapur secara real-time.
Tujuannya adalah menjaga kesegaran makanan, memberikan estimasi waktu yang sesuai antrean,
dan menyelaraskan status pesanan serta ketersediaan bahan.

Dokumen ini mengikuti kebutuhan pada [README.md](README.md).
Struktur folder, prototype, endpoint, dan model tambahan merupakan **rancangan implementasi**, bukan fitur yang sudah tersedia.
Rancangan integrasi mengacu pada kode [ricebowltracker](https://github.com/Cikibber/ricebowltracker)
di branch `main`, commit `da727161977cf041e482825e4d9d413347b6bb1c`, yang diperiksa pada 1 Oktober 2026.

### Pengguna

| Pengguna | Kebutuhan |
| --- | --- |
| Pelanggan | Meracik bowl, memesan, melihat estimasi, mengirim sinyal kedatangan, dan mengambil pesanan |
| Staf dapur | Melihat antrean, menerima sinyal kedatangan, mengubah status persiapan, dan mengatur stok |
| Operator gerai | Mengelola menu, memantau pesanan, dan melihat catatan penjualan melalui ricebowltracker |

### Ruang lingkup versi pertama

* Registrasi, login, profil pelanggan, dan riwayat pesanan.
* Dynamic Bowl Builder: base, protein, saus, add-on, harga reaktif, dan ketersediaan bahan.
* Sinkronisasi dua arah antara aplikasi pelanggan dan Kitchen Display System atau KDS.
* Geofence radius 500 meter untuk memicu persiapan pesanan takeaway.
* Estimasi waktu berdasarkan antrean aktif dan bobot waktu tiap item.
* Pembayaran simulasi, pickup takeaway, dan dine-in pada satu gerai.

Payment gateway produksi, kurir, multi-outlet, serta analisis nutrisi dengan machine learning berada di luar ruang lingkup.
Fitur pengiriman yang mungkin sudah ada pada tracker tidak menjadi fitur baru DonburiX.

## 2. Pilihan Teknologi

| Bagian | Teknologi rancangan | Pertimbangan |
| --- | --- | --- |
| Aplikasi pelanggan | Flutter dan Dart | Mengikuti mobile client dalam README serta mendukung GPS dan geofence |
| Web KDS dan administrasi | React, Vite, Mantine | Memperluas web ricebowltracker yang sudah menggunakan teknologi tersebut |
| Identitas pengguna | Firebase Authentication | Memakai penyedia identitas yang sama dengan tracker |
| Penyimpanan utama | Cloud Firestore | Mempertahankan koleksi menu dan pesanan tracker sebagai satu sumber data |
| Backend aturan bisnis | Node.js + TypeScript + Express, Firebase Admin SDK | Memusatkan validasi harga, stok, kepemilikan, dan transisi status |
| Real-time | Firestore snapshot listeners | Flutter dan web menerima pembaruan data tanpa polling |
| Deployment | Firebase Hosting untuk web; Cloud Run untuk backend | Mendukung aplikasi web dan service backend yang terpisah |

README menyebut WebSocket sebagai mekanisme sinkronisasi.
Rancangan ini memilih **Firestore listeners sebagai penyesuaian teknis untuk integrasi tracker**,
bukan menambahkan server WebSocket terpisah pada versi pertama.
Target sinkronisasi dua arah tetap sama. Perubahan mekanisme ini perlu diselaraskan pada README saat implementasi dimulai.
Jika WebSocket eksplisit menjadi syarat penilaian, keputusan transport perlu ditinjau sebelum implementasi.

## 3. Gambaran Sistem

```text
Flutter DonburiX                         React ricebowltracker
Pelanggan                               Katalog / Admin / KDS
       |                                        |
       +------------ Firebase Auth -------------+
       |                                        |
       +------ HTTPS API + Firebase ID token ---+
                            |
                   Backend DonburiX
               Auth / Order / Stock / Kitchen
                   Geofence / Estimate
                            |
                     Firebase Admin SDK
                            |
                     Cloud Firestore
                  menu / orders / ingredients
                            |
       +---- snapshot listeners, sesuai hak akses ----+
       |                                             |
  Status pelanggan                          Antrean dan stok KDS
```

Backend menjadi pemilik perubahan yang memengaruhi harga, stok, status dapur, dan pembayaran simulasi.
Frontend dapat menghitung harga sementara, tetapi total akhir selalu dihitung ulang backend.
Firestore menjadi sumber data utama, sehingga tidak diperlukan sinkronisasi dua database pesanan.

## 4. Prototype UI/UX

### 4.1 Arah visual

Mobile mengutamakan foto makanan, harga yang terlihat jelas, dan tombol utama di area yang mudah dijangkau.
Gunakan warna krem untuk latar, aksen oranye untuk aksi utama, dan teks gelap dengan kontras yang jelas.
Web KDS mengikuti theme Mantine pada tracker, dengan kartu antrean berukuran besar dan kontrol operasional yang ringkas.

Seluruh label dan pesan menggunakan bahasa Indonesia. Harga memakai rupiah; tanggal memakai format lokal.
Status selalu memiliki teks atau ikon, sehingga informasi tidak bergantung pada warna saja.
Mobile memakai navigasi bawah; web memakai sidebar yang menyesuaikan layar tablet.

### 4.2 Halaman pelanggan

| Halaman | Isi | Aksi utama |
| --- | --- | --- |
| Login dan Registrasi | Email, kata sandi, nama pelanggan, validasi | Masuk, daftar |
| Beranda | Menu tersedia, rekomendasi bowl, akses pesanan aktif | Pilih menu, racik bowl |
| Bowl Builder | Pilihan base, protein, saus, add-on; rincian harga | Tambahkan ke keranjang |
| Keranjang | Item, jumlah, konfigurasi bowl, total sementara | Ubah jumlah, lanjut checkout |
| Checkout | Takeaway/dine-in, ringkasan, pembayaran simulasi | Buat pesanan |
| Detail Pesanan | Nomor pesanan, tahapan, estimasi, status koneksi | Konfirmasi kedatangan atau lihat status siap |
| Riwayat Pesanan | Daftar pesanan milik pelanggan | Buka detail |
| Profil | Identitas pelanggan dan penjelasan izin lokasi | Ubah profil, keluar |

### 4.3 Halaman staf dan operator

| Halaman | Isi | Aksi utama |
| --- | --- | --- |
| Login Admin | Login Firebase dengan akses staf | Masuk ke dashboard |
| Dashboard Penjualan | Ringkasan tracker yang sudah ada | Buka daftar pesanan atau KDS |
| Kitchen Display System | Antrean, konfigurasi bowl, kedatangan, estimasi | Mulai persiapan, siap diambil, selesai |
| Stok Bahan | Bahan, jumlah tersedia, indikator habis | Sesuaikan stok dengan konfirmasi |
| Kelola Pesanan | Pesanan manual dan DonburiX, sumber pesanan, pembayaran | Catat pesanan manual, buka detail |

### 4.4 Wireframe mobile

```text
BERANDA                          BOWL BUILDER
Halo, Pelanggan                  [Kembali] Racik Bowl
[Foto menu unggulan]             Base    [Nasi Putih v]
Rice Bowl       Rp ...           Protein [Ayam v]
[Racik Bowl]                     Saus    [Teriyaki v]
Pesanan aktif: RB-...             Add-on  [Telur] [Sayur]
[Lihat Pesanan]                  Rincian harga / bahan habis
Beranda | Pesanan | Profil       Total Rp ... [Tambah]

DETAIL PESANAN
[Kembali] Pesanan RB-...
Menunggu Kedatangan
Estimasi setelah tiba: ... menit
Diterima -> Menunggu -> Disiapkan -> Siap -> Selesai
[Informasi izin lokasi / status koneksi]
[Saya Sudah Tiba] jika lokasi tidak tersedia
```

### 4.5 Wireframe KDS

```text
DonburiX KDS             Koneksi: Terhubung          [Stok Bahan]
[Menunggu Kedatangan]    [Antrean Persiapan]         [Siap Diambil]
RB-... / Pelanggan A     RB-... / Pelanggan B        RB-... / Pelanggan C
2 bowl / takeaway       1 bowl / sudah tiba         1 bowl
Base / Protein / Saus   Estimasi ... menit          Siap sejak ...
                        [Mulai / Tandai Siap]       [Selesaikan]
```

### 4.6 Keadaan antarmuka

* Memuat: skeleton pada katalog; indikator muat pada aksi yang sedang diproses.
* Kosong: “Belum ada pesanan” atau “Antrean dapur kosong”.
* Stok habis: opsi tidak dapat dipilih dan menampilkan “Bahan habis”.
* Konflik stok: “Stok berubah. Periksa kembali pilihan bowl Anda.”
* Koneksi terputus: tampilkan data terakhir dengan indikator; jangan menampilkan perubahan sebagai sudah tersimpan.
* Izin lokasi ditolak: tetap sediakan konfirmasi kedatangan manual, yang memerlukan konfirmasi staf.
* Pembayaran: beri label “Simulasi pembayaran” agar terpisah dari transaksi nyata tracker.

## 5. Struktur Proyek

DonburiX dan ricebowltracker tetap dapat berada di repository terpisah.
Struktur berikut merupakan target DonburiX; integrasi web dilakukan pada repository tracker.

```text
DonburiX/
├── README.md
├── Architecture.md
├── apps/
│   └── mobile/
│       ├── pubspec.yaml
│       ├── lib/
│       │   ├── main.dart
│       │   ├── app.dart
│       │   ├── routes/app_routes.dart
│       │   ├── screens/
│       │   │   ├── auth/login_screen.dart
│       │   │   ├── auth/register_screen.dart
│       │   │   ├── home/home_screen.dart
│       │   │   ├── builder/bowl_builder_screen.dart
│       │   │   ├── cart/cart_screen.dart
│       │   │   ├── checkout/checkout_screen.dart
│       │   │   ├── orders/order_detail_screen.dart
│       │   │   ├── orders/order_history_screen.dart
│       │   │   └── profile/profile_screen.dart
│       │   ├── widgets/
│       │   │   ├── primary_button.dart
│       │   │   ├── app_text_field.dart
│       │   │   ├── menu_card.dart
│       │   │   ├── ingredient_selector.dart
│       │   │   ├── order_status_badge.dart
│       │   │   └── connection_banner.dart
│       │   ├── models/
│       │   ├── services/
│       │   │   ├── auth_service.dart
│       │   │   ├── menu_service.dart
│       │   │   ├── order_service.dart
│       │   │   └── location_service.dart
│       │   └── state/
│       └── test/
├── services/
│   └── api/
│       ├── src/
│       │   ├── app.ts
│       │   ├── routes/
│       │   ├── middleware/
│       │   ├── services/
│       │   │   ├── OrderService.ts
│       │   │   ├── StockService.ts
│       │   │   ├── KitchenService.ts
│       │   │   ├── GeofenceService.ts
│       │   │   └── EstimateService.ts
│       │   ├── repositories/
│       │   └── integrations/ricebowltracker/
│       └── tests/
├── contracts/
│   ├── openapi.yaml
│   └── firestore-schema.md
└── firebase/
    ├── firestore.rules
    └── firestore.indexes.json
```

Penambahan yang direncanakan pada tracker:

```text
ricebowltracker/src/
├── pages/
│   ├── KitchenDisplayPage.jsx
│   └── IngredientStockPage.jsx
├── components/Kitchen/
│   ├── KitchenOrderCard.jsx
│   ├── KitchenStatusBadge.jsx
│   └── ConnectionBanner.jsx
├── hooks/useKitchenOrders.js
└── services/donburixApi.js
```

`screens`/`pages` menangani tampilan; widget/komponen dipakai ulang; state mengatur keadaan layar.
Service mengakses API atau stream. Model menyatakan bentuk data. Routing mengatur navigasi dan pemeriksaan sesi.
Aturan bisnis yang menentukan kebenaran pesanan berada di backend, bukan widget atau hook.

Kontrak JSON didokumentasikan sekali pada `contracts/`, lalu dipakai untuk model Dart dan web.
Tidak ada kewajiban monorepo TypeScript untuk mobile Flutter.
Firebase rules dan indexes dikelola dari satu lokasi serta satu pipeline deployment agar kedua repository tidak saling menimpa.

## 6. Routing

### Flutter

| Route | Halaman | Akses |
| --- | --- | --- |
| `/login` | `LoginScreen` | Belum login |
| `/register` | `RegisterScreen` | Belum login |
| `/home` | `HomeScreen` | Pelanggan |
| `/builder` | `BowlBuilderScreen` | Pelanggan |
| `/cart` | `CartScreen` | Pelanggan |
| `/checkout` | `CheckoutScreen` | Pelanggan |
| `/orders` | `OrderHistoryScreen` | Pelanggan |
| `/orders/:id` | `OrderDetailScreen` | Pemilik pesanan |
| `/profile` | `ProfileScreen` | Pelanggan |

Alur utama: **Login → Beranda → Bowl Builder → Keranjang → Checkout → Detail Pesanan → Selesai**.
Route guard mengarahkan pengguna tanpa sesi ke login. Backend tetap memeriksa kepemilikan setiap pesanan.

### Web tracker

Route yang sudah ada: `/`, `/status`, `/admin/login`, `/admin`, dan `/admin/orders`.
Tambahkan `/admin/kitchen` untuk KDS dan `/admin/ingredients` untuk stok bahan.
Akses staf dibatasi berdasarkan peran, bukan hanya keberadaan sesi login.

## 7. Reusable Widget dan Component

| Elemen | Penggunaan |
| --- | --- |
| `PrimaryButton` | Aksi utama, keadaan memuat, dan pencegahan submit ganda |
| `AppTextField` | Label, masukan, dan validasi formulir |
| `MenuCard` | Foto, nama, harga, dan ketersediaan menu |
| `IngredientSelector` | Opsi bowl beserta tambahan harga dan stok |
| `OrderStatusBadge` / `KitchenStatusBadge` | Teks status dan warna konsisten |
| `OrderTimeline` | Tahapan pesanan pada mobile |
| `ConnectionBanner` | Informasi koneksi dan data terakhir |
| `KitchenOrderCard` | Nomor pesanan, konfigurasi, kedatangan, dan aksi staf |
| `ConfirmDialog` | Konfirmasi perubahan stok atau pembatalan |

Komponen menerima data dan callback. Komponen visual tidak menulis langsung status dapur ke database.
Form memiliki label, error yang jelas, serta urutan fokus yang dapat digunakan dengan keyboard pada web.

## 8. Model Data

### 8.1 Data tracker yang dipertahankan

| Koleksi | Data yang ditemukan pada kode |
| --- | --- |
| `menu` | `name`, `description`, `price`, `imagePath`, `category`, `isAvailable` |
| `orders` | `orderId`, `customerName`, `customerNameLower`, `items`, `totalAmount`, `paymentStatus`, `orderStatus` |
| `orders` tambahan | `userId`, `spiceLevel`, `deliveryNotes`, `discountCode`, `createdAt`, `updatedAt` |
| `orderCounters` | Counter harian `seq` untuk nomor tampilan pesanan |
| `publicOrderLookups` | Proyeksi pesanan untuk pencarian publik, terpisah dari catatan internal |

Item lama memakai `menuItemId`, `name`, `qty`, dan `price`.
`paymentStatus` pada hook memakai `Paid`/`Unpaid`; default `orderStatus` adalah `Pending`.
Jangan mengganti nama field atau enum lama tanpa migrasi konsumen yang memakai data tersebut.

### 8.2 Tambahan DonburiX yang direncanakan

| Model/koleksi | Field penting | Fungsi |
| --- | --- | --- |
| `users/{uid}` | `name`, `email`, `createdAt` | Profil; peran staf diberikan server melalui custom claims |
| `ingredients/{id}` | `name`, `category`, `priceDelta`, `stockQuantity`, `isAvailable`, `prepWeightMinutes` | Bahan base/protein/saus/add-on |
| `storeConfig/main` | `latitude`, `longitude`, `geofenceRadiusMeters`, `kitchenCapacity` | Konfigurasi satu gerai; radius awal 500 meter |
| `orders` tambahan | `source`, `fulfillmentType`, `kitchenStatus`, `arrivalStatus`, `paymentMode`, `version` | Identitas sumber dan state operasional |
| `orders` waktu | `arrivedAt`, `preparationStartedAt`, `readyAt`, `completedAt`, `estimatedReadyAt` | Riwayat tahapan dan estimasi |
| Item tambahan | `configuration`, `ingredientUsages`, `prepWeightMinutes` | Snapshot konfigurasi bowl dan kebutuhan stok |
| `orderEvents/{id}` | `orderDocumentId`, `eventType`, `actorUid`, `createdAt` | Riwayat perubahan status |
| `idempotencyKeys/{key}` | `uid`, `requestHash`, `orderDocumentId`, `createdAt` | Mencegah pesanan ganda akibat pengiriman ulang |

Field Firestore dan JSON mengikuti **camelCase** agar sesuai tracker.
Nama class dan model Flutter/TypeScript memakai PascalCase; file Dart memakai snake_case.
Harga dinyatakan dalam rupiah bulat. Waktu disimpan sebagai timestamp server; REST mengirim waktu ISO 8601 UTC.

Satu dokumen `orders` adalah satu pesanan operasional sekaligus catatan penjualan, bukan dua transaksi terpisah.
Snapshot item mempertahankan nama dan harga saat pemesanan meskipun menu berubah kemudian.
Stok disimpan dalam satuan porsi bahan; `ingredientUsages` menentukan jumlah yang dipakai per bowl.
Menu fixed-price yang tidak memakai builder tetap dapat menggunakan format item tracker lama.

## 9. Aturan Bisnis dan Alur Pesanan

### 9.1 State dapur

```text
Takeaway:
WAITING_ARRIVAL -> QUEUED -> PREPARING -> READY -> COMPLETED
                      ^
                      | Kedatangan valid pada radius 500 meter

Dine-in:
QUEUED -> PREPARING -> READY -> COMPLETED

Pembatalan yang diizinkan:
WAITING_ARRIVAL / QUEUED -> CANCELLED
```

Pada takeaway, sinyal geofence yang valid memasukkan pesanan ke antrean.
Jika kapasitas dapur tersedia, backend dapat langsung memindahkannya ke `PREPARING` sesuai aturan prioritas.
Jika kapasitas penuh, pesanan tetap `QUEUED` dan KDS menampilkan bahwa pelanggan sudah tiba.
Aturan kapasitas ini menjelaskan penanganan sinyal tiba saat dapur sedang sibuk.

Staf mengonfirmasi `READY` dan penyerahan `COMPLETED`.
Backend menolak transisi tidak sah dan memakai `version` untuk mendeteksi perubahan bersamaan.
Pesanan yang sudah disiapkan tidak dibatalkan otomatis hanya karena pelanggan keluar dari radius.

### 9.2 Checkout dan reservasi stok

1. Mobile mengirim ID menu/bahan, konfigurasi, jumlah, dan mode pemenuhan, bukan harga yang dipercaya server.
2. Backend memvalidasi Firebase ID token dan identitas pemilik pesanan.
3. Backend membaca harga serta stok, lalu menghitung ulang total.
4. Transaksi Firestore menyimpan pesanan, mengurangi stok tersedia sebagai reservasi, dan memperbarui counter.
5. Backend mengembalikan dokumen pesanan yang sama jika request dengan idempotency key yang sama dikirim ulang.
6. Pembatalan sebelum persiapan mengembalikan reservasi tepat sekali melalui transaksi.

Idempotency key dibatasi per UID dan disimpan dalam transaksi yang sama dengan pesanan serta reservasi.
Key yang sama dengan payload berbeda menghasilkan konflik, bukan pesanan baru.
Event perubahan dan proyeksi lookup ikut diperbarui secara atomik ketika status berubah.

Kegagalan reservasi tidak meninggalkan pesanan parsial atau stok negatif.
Perubahan stok dari KDS mengikuti mekanisme transaksi yang sama.
Seluruh operasi pesanan tracker yang terkait stok perlu dialihkan ke service tersebut saat integrasi diaktifkan.

### 9.3 Pembayaran simulasi

Pesanan mobile memakai `paymentMode: simulation`.
`paymentStatus` tetap kompatibel dengan `Paid`/`Unpaid`, tetapi UI menunjukkan bahwa pembayarannya simulasi.
Dashboard penjualan dan ekspor tracker memisahkan atau mengecualikan transaksi simulasi dari omzet nyata.
Pesanan manual lama tidak dianggap simulasi; adapter mengklasifikasikannya sebagai data legacy sampai dikonfirmasi operator.

### 9.4 Geofence

Mobile meminta izin lokasi dengan penjelasan manfaatnya dan memantau pesanan takeaway yang aktif.
Service lokasi mengirim posisi, akurasi, dan waktu pengukuran saat terdeteksi masuk radius 500 meter.
Backend menghitung jarak ke koordinat gerai dan memeriksa waktu pengukuran, akurasi, serta pemilik pesanan.
Sinyal berulang tidak membuat transisi atau reservasi baru.

GPS pelanggan merupakan sinyal operasional, bukan bukti lokasi yang mutlak.
Jika izin ditolak, GPS tidak tersedia, atau background tracking dibatasi sistem operasi,
pelanggan dapat meminta konfirmasi “Saya Sudah Tiba”; staf menyetujui sebelum persiapan dimulai.
Kegagalan tracking tidak boleh ditampilkan sebagai kedatangan otomatis yang berhasil.
Validasi background geofence dilakukan pada perangkat nyata, bukan hanya emulator.

### 9.5 Estimasi waktu tunggu

`prepWeightMinutes` menyatakan estimasi durasi item. Versi pertama memakai penjumlahan bobot per item dan jumlahnya.
Backend mendistribusikan pekerjaan ke jumlah slot `kitchenCapacity` yang aktif, lalu memproyeksikan waktu selesai.
Jika kapasitas satu, estimasi adalah sisa waktu pesanan sebelumnya ditambah bobot pesanan saat ini.

Antrean mengikuti urutan kedatangan terverifikasi atau waktu checkout dine-in.
Pesanan takeaway yang belum tiba tidak memakai slot memasak; UI menampilkan “Estimasi setelah tiba”.
Estimasi dihitung ulang ketika antrean, kapasitas, atau status berubah.
Hasil merupakan perkiraan, bukan janji waktu pasti.

## 10. Kontrak API dan Real-Time

Endpoint berikut **belum tersedia** pada tracker dan merupakan kontrak backend DonburiX yang direncanakan.
Request terlindungi mengirim Firebase ID token melalui `Authorization: Bearer <token>`.

| Method dan endpoint | Akses | Kontrak |
| --- | --- | --- |
| `GET /api/menu` | Publik | Menu dan opsi bowl yang tersedia |
| `GET /api/me` / `PATCH /api/me` | Pelanggan | Membaca/mengubah profil sendiri |
| `POST /api/orders` | Pelanggan | Membuat pesanan secara atomik; wajib idempotency key |
| `GET /api/orders` | Pelanggan | Riwayat milik pengguna; memakai pagination |
| `GET /api/orders/:id` | Pemilik/staf | Detail pesanan yang diizinkan |
| `POST /api/orders/:id/simulate-payment` | Pemilik | Pembayaran simulasi untuk pesanan simulasi |
| `POST /api/orders/:id/arrival` | Pemilik | Mengirim sinyal lokasi atau permintaan konfirmasi manual |
| `POST /api/orders/:id/cancel` | Pemilik/staf | Pembatalan yang memenuhi state dan pengembalian reservasi |
| `GET /api/kitchen/orders` | Staf | Antrean operasional aktif |
| `PATCH /api/kitchen/orders/:id/status` | Staf | Transisi status dengan expected version |
| `POST /api/kitchen/orders/:id/confirm-arrival` | Staf | Konfirmasi kedatangan manual |
| `GET /api/ingredients` / `PATCH /api/ingredients/:id` | Staf | Membaca dan menyesuaikan stok |
| `POST /api/admin/orders` | Operator | Membuat pesanan manual melalui validasi yang sama |

Response error memakai `code`, `message`, serta `details` opsional; `message` berbahasa Indonesia.
Gunakan 401 untuk sesi tidak valid, 403 untuk akses tidak diizinkan, 404 untuk data tidak ditemukan,
409 untuk konflik stok/state/idempotency, dan 422 untuk input tidak valid.

Setelah mutation berhasil, backend menyimpan data terlebih dahulu; listener kemudian memperbarui mobile dan KDS.
Listener pelanggan hanya membaca pesanan miliknya, sedangkan listener KDS hanya membaca pesanan operasional aktif.
Saat reconnect, client mengambil snapshot terbaru, bukan menganggap cache sebagai status final.
Mutation dapat dikirim ulang dengan idempotency key atau expected version; hindari perubahan stok/status offline tanpa konfirmasi.

## 11. Rencana Integrasi ricebowltracker

### 11.1 Kondisi yang sudah ditemukan

* `src/firebase.js`: konfigurasi Firebase client.
* `src/hooks/useMenu.js`: membaca `menu` dengan listener dan menyediakan perubahan menu.
* `src/hooks/useOrders.js`: membuat pesanan dengan transaksi counter; mengubah pembayaran/status melalui batch.
* `src/data/utils.js`: normalisasi field menu, pesanan, dan item.
* `src/App.jsx`: routing publik dan admin.
* `firestore.rules`: fungsi `isAdmin()` saat ini hanya memeriksa `request.auth != null`.
* Nomor tampilan dibuat sebagai `RB-MMDD-NNN`; `publicOrderLookups` menggunakan nomor tersebut sebagai ID dokumen.

Tracker saat ini merupakan katalog dan pencatatan pesanan manual, bukan backend REST untuk checkout Flutter.
Karena itu, integrasi memerlukan backend dan perubahan web, bukan hanya menambahkan URL API pada mobile.

### 11.2 Strategi integrasi

1. Gunakan Firebase project yang sama untuk mobile, web, dan backend integrasi; mulai dari environment pengembangan.
2. Pertahankan koleksi `menu`, `orders`, `orderCounters`, dan field legacy.
3. Tambahkan field DonburiX secara additive melalui adapter `ricebowltracker` pada backend.
4. Perluas normalizer tracker agar mempertahankan `configuration`, `source`, `kitchenStatus`, dan `paymentMode`.
5. Tambahkan halaman KDS, stok bahan, service API, dan navigasinya.
6. Alihkan pembuatan serta perubahan pesanan web ke API bersama ketika aturan stok/state baru diaktifkan.
7. Tetap gunakan listener untuk membaca data; batasi direct write agar tidak melewati aturan bisnis backend.
8. Sesuaikan dashboard/ekspor untuk membedakan penjualan nyata dan simulasi.

### 11.3 Kompatibilitas status dan nomor pesanan

`kitchenStatus` menyimpan state DonburiX; `orderStatus` tetap menjadi field kompatibilitas tracker.
Adapter menerjemahkan state baru ke nilai legacy yang telah diverifikasi pada seluruh UI dan ekspor.
Default `Pending` telah ditemukan; pemetaan seluruh nilai lain wajib diuji sebelum migrasi diaktifkan.
Data lama tanpa `kitchenStatus` tidak otomatis dimasukkan ke antrean memasak; operator memilih pesanan aktif yang relevan.

ID dokumen Firestore menjadi referensi internal seluruh API dan event.
Nomor `RB-MMDD-NNN` tidak menyertakan tahun, sehingga dapat berulang pada tahun berikutnya.
Integrasi menambah reference publik unik, misalnya `DX-YYYYMMDD-NNN`, untuk pesanan baru.
Pencarian, rules, dan `publicOrderLookups` diperbarui agar mendukung kedua format tanpa menimpa lookup lama.

### 11.4 Akses data setelah pelanggan dapat mendaftar

Aturan `isAdmin()` tracker saat ini tidak membedakan pelanggan dan staf.
Sebelum registrasi mobile diaktifkan pada Firebase project yang sama, aturan ini harus diganti dengan peran staf yang diberikan server.
Pelanggan hanya membaca pesanan dengan `userId` miliknya; staf memperoleh akses dapur sesuai peran.
Backend memverifikasi token dan peran sendiri karena Firebase Admin SDK tidak dibatasi oleh Firestore client rules.
Service-account credential hanya tersedia pada backend.

Proyeksi publik tidak memuat koordinat pelanggan, konfigurasi akses, atau catatan internal.
Endpoint riwayat pribadi memakai UID, bukan pencarian nama publik.
Rule dan query pencarian lama diuji kembali sebelum deployment aturan bersama.

### 11.5 Urutan rollout

* Siapkan emulator/staging dan contoh pesanan lama; tetapkan pemilik deployment Firebase rules.
* Implementasikan kontrak, peran staf, adapter, dan transaksi backend.
* Tambahkan KDS dan service web; uji pencatatan manual serta dashboard lama.
* Aktifkan mobile pada environment uji, lalu uji pesanan dari checkout sampai pickup.
* Jalankan migrasi additive yang dapat diulang; simpan cadangan sebelum perubahan data produksi.
* Aktifkan integrasi produksi setelah tidak ada jalur write yang melewati aturan harga, stok, dan state.

## 12. Konfigurasi dan Deployment

Mobile memerlukan konfigurasi Firebase per platform, URL API, dan permission lokasi sesuai sistem operasi.
Web mempertahankan konfigurasi `VITE_FIREBASE_*` tracker dan menambah `VITE_DONBURIX_API_BASE_URL`.
Backend memerlukan project ID, identitas service account dari environment deployment, dan daftar origin web yang diizinkan.
Koordinat gerai dan kapasitas dapur disimpan pada konfigurasi server, bukan ditentukan pelanggan.

Gunakan `.env.example` untuk nama konfigurasi tanpa credential nyata.
Konfigurasi Firebase client tidak memberikan hak admin; hak akses ditentukan token, rules, dan validasi backend.
Environment development dan production memakai data yang terpisah.

## 13. Tahapan Pengembangan: 12 Pertemuan

| Pertemuan | Hasil yang ditargetkan |
| --- | --- |
| 1–3 | Prototype, struktur Flutter, autentikasi/profil, kontrak integrasi, dan peran staf |
| 4–5 | Bowl Builder, keranjang, harga reaktif, checkout, dan reservasi stok |
| 6–8 | KDS pada tracker, transisi pesanan, listener dua arah, dan pemisahan transaksi simulasi |
| 9–10 | Geofence 500 meter, konfirmasi manual, serta uji perangkat nyata |
| 11 | Estimasi waktu berbasis antrean dan bobot item |
| 12 | Uji end-to-end, reconnect, regresi tracker, perbaikan UI, dan freeze fitur |

## 14. Kriteria Keberhasilan dan Verifikasi

| Kriteria README | Skenario verifikasi |
| --- | --- |
| Sinkronisasi ≤ 2 detik | Ukur perubahan status KDS hingga terlihat pada mobile dalam koneksi uji yang stabil |
| Geofence 500 meter | Uji masuk/keluar radius, sinyal berulang, izin ditolak, dan background pada perangkat nyata |
| Integritas Bowl Builder | Bandingkan total client/server; uji dua checkout terakhir pada stok satu porsi |
| End-to-end | Racik bowl → checkout → KDS menerima → tiba → disiapkan → siap → picked up |

Tambahkan pengujian berikut untuk integrasi:

* Request checkout berulang membuat tepat satu pesanan dan satu reservasi stok.
* Pembatalan berulang mengembalikan stok tepat sekali.
* Pelanggan tidak dapat membaca pesanan pengguna lain atau mengubah stok/status dapur.
* Pesanan manual tracker tetap tampil; konfigurasi custom bowl tidak hilang pada normalisasi.
* Transaksi simulasi tidak menambah omzet nyata.
* Nomor publik baru tidak menimpa lookup legacy.
* Reconnect menampilkan state terbaru tanpa transisi mundur atau pesanan ganda.

Build Flutter, backend, dan web tracker diverifikasi saat source implementasi tersedia.
Dokumen ini tidak menyatakan bahwa integrasi atau aplikasi telah selesai dibangun.

## 15. Sumber Rancangan

* [README DonburiX](README.md): kebutuhan produk, batasan, jadwal, dan kriteria keberhasilan.
* [ricebowltracker](https://github.com/Cikibber/ricebowltracker): `package.json`, `src/App.jsx`, `src/hooks/useOrders.js`,
  `src/hooks/useMenu.js`, `src/data/utils.js`, `firestore.rules`, dan `IMPLEMENTATION_PLAN.md`.
* [Firebase custom claims](https://firebase.google.com/docs/auth/admin/custom-claims): pemisahan peran pelanggan dan staf.
* [Firestore transactions](https://firebase.google.com/docs/firestore/manage-data/transactions): perubahan data atomik.

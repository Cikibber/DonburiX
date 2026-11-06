# Hasil Uji Keamanan dan Change Log — Tugas 8

Tanggal pengujian: 2026-11-06. Lingkup: aplikasi Flutter `apps/mobile`, build web
release, workflow CI, dan riwayat repo. Backend belum ada, jadi semua kontrol
berjalan di sisi klien. Batasannya tercatat di [Risiko tersisa](#risiko-tersisa).

## Ringkasan

| Pemeriksaan | Alat | Hasil |
| --- | --- | --- |
| Test keamanan (abuse case) | `flutter test test/security_test.dart` | **31 test, semua lulus** |
| Regresi seluruh aplikasi | `flutter test --coverage` | **103 test lulus**, coverage baris 94,2% |
| Analisis statis | `flutter analyze` | Tanpa temuan |
| Rahasia di riwayat git | gitleaks v8.30.1 (CI) | 13 commit dipindai, **no leaks found** |
| Kerentanan dependensi | OSV-Scanner v2.7.0 (CI) | 55 paket dipindai, **No issues found** |
| Peringatan GitHub | Secret scanning API | 0 peringatan |
| API berbahaya di `lib/` | `git grep` untuk `dart:html`, `eval(`, `innerHTML`, `http://` | 0 hasil |
| File sensitif terlacak | `git ls-files` untuk `.env`, `.jks`, `.pem`, `key.properties` | 0 file |
| Uji browser pada build release | Skrip Playwright di Chromium | **17/17 lulus**, 0 pelanggaran CSP, 0 error konsol |

CI: [run 42150180241](https://github.com/Cikibber/DonburiX/actions/runs/42150180241),
job `bowl-builder`, `security-scan`, dan `demo-apk` berhasil.

## Temuan dan perbaikan

Tingkat keparahan adalah penilaian sendiri untuk konteks MVP tanpa backend.

| ID | Tingkat | Temuan | Dampak | Perbaikan | Status |
| --- | --- | --- | --- | --- | --- |
| SEC-01 | Tinggi | Koordinat `NaN` atau di luar rentang lolos geofence, sebab `NaN > 500` bernilai salah | Dapur mulai memasak walau pelanggan tidak di dekat gerai | `GeoPoint.isValid` diperiksa lebih dulu | Diperbaiki |
| SEC-02 | Tinggi | Pencarian nomor pesanan membuka pesanan akun lain, lengkap dengan tombol batal | Pelanggan bisa melihat dan membatalkan pesanan orang lain | Pemeriksaan kepemilikan di repository, jawaban sama dengan "tidak ditemukan" | Diperbaiki |
| SEC-03 | Tinggi | Tab Dapur terbuka untuk semua pelanggan | Pelanggan bisa memajukan status, restok, dan melihat nama pelanggan lain | Gerbang PIN, penguncian 1 menit setelah 5 kali salah, tanpa PIN bawaan | Dimitigasi, lihat R1 |
| SEC-04 | Sedang | Data `localStorage` dimuat tanpa validasi dan bisa diterapkan sebagian | Stok negatif, nomor urut negatif, atau sesi palsu diterima | Validasi penuh, diterapkan hanya setelah semua lolos | Diperbaiki |
| SEC-05 | Sedang | Panjang nama pemesan tidak dibatasi dan repository hanya mengecek kosong | Data besar tersimpan, tampilan rusak | Batas 40 karakter di validator dan repository, email maksimal 254 | Diperbaiki |
| SEC-06 | Rendah | `?scenario=` dan `?location=` aktif di build release | Tautan buatan orang lain bisa menampilkan kondisi palsu | `demoQuery` mengabaikannya di release | Diperbaiki |
| SEC-07 | Sedang | Tidak ada log keamanan | Penolakan dan penyalahgunaan tidak terlihat | Log JSON tanpa data pribadi, lihat [security_logs.md](security_logs.md) | Diperbaiki |
| SEC-08 | Sedang | Build web tanpa CSP dan memuat CanvasKit dari CDN | Tidak ada lapisan pertahanan bila ada skrip asing | CSP lewat `scripts/build-web.sh`, CanvasKit disajikan sendiri | Diperbaiki |
| SEC-09 | Sedang | Action CI dikunci ke tag yang bisa berubah, lockfile tidak dipaksakan | Risiko rantai pasok | Action dikunci ke SHA, `--enforce-lockfile`, job `security-scan` | Diperbaiki |
| SEC-10 | Rendah | Android mengizinkan auto backup | Email pelanggan ikut ke cadangan perangkat | `android:allowBackup="false"` | Diperbaiki, belum diuji di perangkat |

## Bukti sebelum dan sesudah

Test ditulis lebih dulu dan dijalankan pada kode lama.

| Tahap | Hasil |
| --- | --- |
| Sebelum, SEC-01, SEC-04, SEC-05 | **13 dari 14 test gagal**. Satu yang lulus adalah batas valid 40 karakter |
| Sebelum, SEC-02 dan SEC-03 | Gagal kompilasi karena `actorEmail` dan gerbang PIN belum ada |
| Sesudah | **31 dari 31 lulus** |

Detail test per grup:

| Grup | Jumlah | Yang diuji |
| --- | --- | --- |
| SEC-01 | 4 | `NaN`, tak hingga, lintang +360, bujur +360 ditolak, status tetap |
| SEC-02 | 5 | Batal, tiba, dan pencarian oleh akun lain ditolak. Pemilik tetap bisa. Uji layar Pesanan |
| SEC-03 | 5 | PIN salah dan benar, tanpa konfigurasi, penguncian dan pemulihannya, kunci ulang, layar Dapur |
| SEC-04 | 6 | Stok negatif, stok rusak sebagian, nomor urut negatif, tiga bentuk sesi tidak valid |
| SEC-05 | 4 | Batas nama 40/41 karakter dan email 254 karakter |
| SEC-06 | 2 | Hook diabaikan di release, tetap aktif di luar release |
| SEC-07 | 5 | Isi log dan tidak adanya email, koordinat, PIN, atau nilai input |

Hasil uji browser pada build release:

```text
PASS login format email salah ditolak
PASS alur pesan: nomor pesanan terbit :: DX-20261106-001
PASS geofence: status Disiapkan
PASS KDS terkunci sebelum PIN
PASS PIN salah ditolak
PASS PIN benar membuka antrean
PASS kunci ulang menutup antrean
PASS akun kedua dapat memesan :: DX-20261106-002
PASS riwayat Sari tidak memuat pesanan Budi
PASS pencarian pesanan orang lain ditolak
PASS 5x PIN salah mengunci, PIN benar pun ditolak
PASS data bertahan setelah reload
PASS data rusak tidak membuat crash
PASS hook ?scenario diabaikan di release
PASS CSP terpasang
PASS tanpa pelanggaran CSP
PASS tanpa error konsol
external origins: https://fonts.gstatic.com
17/17 passed
```

## Tidak berlaku pada MVP ini

| Kategori | Alasan |
| --- | --- |
| SQL/NoSQL injection | Tidak ada basis data atau query |
| XSS lewat data pengguna | Flutter menggambar teks dengan widget `Text`, tidak memakai HTML dari data. `lib/` tidak memakai `innerHTML` atau `dart:html` |
| SSRF, unggah file | Tidak ada fitur tersebut |
| CSRF, cookie | Tidak ada server dan cookie sesi |

## Risiko tersisa

Risiko ini **belum selesai** dan butuh backend atau keputusan lanjutan.

| ID | Risiko | Mengapa tersisa | Langkah berikutnya |
| --- | --- | --- | --- |
| R1 | PIN dapur ada di bundle JavaScript, hitungan gagal hilang saat reload, dan PIN demo `4826` dipublikasikan | Tanpa server, klien tidak bisa menyimpan rahasia | Periksa peran staf di server |
| R2 | Login tanpa kata sandi. Siapa pun yang mengetik email orang lain di perangkat yang sama melihat pesanan orang itu, sehingga SEC-02 hanya melindungi antarakun yang jujur | Autentikasi masih simulasi | Firebase Auth atau Supabase Auth |
| R3 | Email dan nama tersimpan tanpa enkripsi di `localStorage`, termasuk data semua akun di perangkat yang sama, dan belum ada fitur hapus data per akun | Penyimpanan lokal MVP | Pindah ke server, tambah hapus data |
| R4 | Harga dan total di data tersimpan bisa diubah pengguna di perangkatnya. Yang divalidasi hanya bentuk data dan stok | Tidak ada sumber kebenaran di server | Hitung harga di server |
| R5 | Lokasi geofence masih titik simulasi | GPS belum dipasang | `geolocator`, verifikasi di server |
| R6 | GitHub Pages tidak bisa mengatur header, jadi `frame-ancestors` dan perlindungan clickjacking tidak aktif. CSP masih butuh `style-src 'unsafe-inline'` untuk Flutter | Batasan hosting dan framework | Hosting dengan header kustom |
| R7 | APK demo ditandatangani kunci debug, jadi bukan untuk rilis publik | Belum ada kunci rilis | Buat keystore rilis di luar repo |
| R8 | Font memuat dari `fonts.gstatic.com` | Perilaku bawaan Flutter Web | Bundel font sendiri |
| R9 | Branch `main` tanpa proteksi dan Dependabot alerts nonaktif | Pengaturan repo tidak diubah dalam tugas ini | Aktifkan di Settings |

Pengujian ini juga bukan penetration test pihak ketiga. gitleaks dan OSV-Scanner
hanya dijalankan di CI GitHub, tidak di komputer lokal.

## Change log keamanan

Commit: `cbfcd7b feat(mobile): harden MVP security for P8`, [PR #1](https://github.com/Cikibber/DonburiX/pull/1).

### Ditambahkan

- `lib/core/security_log.dart`: log keamanan JSON.
- `lib/features/kitchen/state/kds_access.dart`: gerbang PIN dan penguncian.
- `test/security_test.dart`: 31 test keamanan.
- `scripts/build-web.sh`: build release dengan CSP dan CanvasKit lokal.
- `.github/workflows/deploy-web.yml`: deploy ke GitHub Pages setelah test lulus.
- Job CI `security-scan` dan `demo-apk`.
- `.gitattributes`: skrip `.sh` selalu LF agar clone di Windows tidak rusak.

### Diubah

- `findByDisplayId`, `cancelOrder`, `markArrived` menerima `actorEmail`.
- Layar Pesanan dan detail pesanan mengirim email sesi.
- Layar Dapur dipisah menjadi gerbang PIN dan papan antrean, ditambah tombol kunci.
- Keluar dari akun mengunci layar Dapur tanpa mereset hitungan penguncian.
- `_restore` dan pemuatan sesi memvalidasi data sebelum diterapkan.
- Layar login selalu memanggil `login` agar penolakan tercatat.
- `validateCustomerName` dan `validateEmail` membatasi panjang.
- `main.dart` memakai `demoQuery`, sehingga hook URL mati di release.
- `flutter.yml`: action dikunci ke SHA, `--enforce-lockfile`.
- `AndroidManifest.xml`: `allowBackup="false"`.
- `.gitignore`: menambah `.env*`.

### Perubahan perilaku bagi pengguna

- Tab Dapur kini meminta PIN. Jalankan dengan `--dart-define=KDS_PIN=4826`.
- `?scenario=` dan `?location=` hanya aktif di `flutter run`.
- Video `docs/tugas7/demo.mp4` direkam sebelum gerbang PIN ada.

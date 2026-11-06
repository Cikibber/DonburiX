# Laporan Clone Bersih, PR, Build, dan Deployment — Tugas 8

Tanggal: 2026-11-06. Lingkungan lokal: Windows 11, Flutter 3.44.1, Dart 3.12.1.

## 1. Pull request

| Item | Hasil |
| --- | --- |
| PR | [#1 P8: security hardening, re-installation docs, and deployment](https://github.com/Cikibber/DonburiX/pull/1) |
| Branch | `p8-security-hardening` ke `main` |
| CI | [run 42150180241](https://github.com/Cikibber/DonburiX/actions/runs/42150180241) |
| `bowl-builder` (format, analyze, test, build web) | Berhasil |
| `security-scan` (gitleaks, OSV-Scanner) | Berhasil |
| `demo-apk` (build APK release) | Berhasil, artifact 23,8 MB |

APK hanya dibuktikan berhasil dibangun. APK belum dipasang di perangkat atau
emulator karena komputer pengujian tidak memiliki Android SDK.

## 2. Clone bersih dari GitHub

Clone baru ke folder kosong, commit `cbfcd7b`, tanpa `build/` dan `.dart_tool/`.
Waktu total 02:25:06 sampai 02:26:41 UTC, sekitar 1 menit 35 detik.

| Langkah | Perintah | Hasil |
| --- | --- | --- |
| Clone | `git clone --branch p8-security-hardening https://github.com/Cikibber/DonburiX` | Berhasil, working tree bersih |
| Instalasi | `flutter pub get --enforce-lockfile` | Berhasil |
| Format | `dart format --output=none --set-exit-if-changed lib test` | 41 file, 0 berubah |
| Analisis | `flutter analyze` | No issues found |
| Unit test | `flutter test --coverage` | **103 test lulus**, coverage 94,2% (1186/1259 baris) |
| Build | `KDS_PIN=4826 BASE_HREF=/DonburiX/ bash scripts/build-web.sh` | Berhasil, 41 MB |
| Eksekusi | Build disajikan lokal dan diuji di Chromium | 17/17 lulus |

Masalah clone yang dicegah: `autocrlf` di Windows akan mengubah `build-web.sh`
menjadi CRLF dan membuat Bash gagal. `.gitattributes` menahan skrip tetap LF, dan
hasil clone memastikannya.

## 3. Deployment

PR #1 digabung ke `main` sebagai commit `b6f55af`, lalu workflow berjalan otomatis.

| Item | Hasil |
| --- | --- |
| Alamat | <https://cikibber.github.io/DonburiX/> |
| Deploy | [run 42151006398](https://github.com/Cikibber/DonburiX/actions/runs/42151006398), job `build` (termasuk test) dan `deploy` berhasil |
| CI di `main` | [run 42151006374](https://github.com/Cikibber/DonburiX/actions/runs/42151006374), `bowl-builder`, `security-scan`, `demo-apk` berhasil |
| Respons situs | `HTTP 200`, `Strict-Transport-Security: max-age=31556952` |
| CSP | Terpasang lewat tag meta. GitHub Pages tidak mengirim CSP sebagai header |
| Uji browser pada situs langsung | **17/17 lulus**, 0 pelanggaran CSP, 0 error konsol |
| Origin eksternal | Hanya `https://fonts.gstatic.com` |

## 4. Clone bersih dari `main` setelah merge

Clone baru, commit `b6f55af`, 02:39:07 sampai 02:40:36 UTC.

| Langkah | Hasil |
| --- | --- |
| `git clone https://github.com/Cikibber/DonburiX.git` | Berhasil |
| `flutter pub get --enforce-lockfile` | Berhasil |
| `dart format --output=none --set-exit-if-changed lib test` | Tanpa perubahan |
| `flutter analyze` | No issues found |
| `flutter test --coverage` | **103 test lulus**, coverage 94,2% (1186/1259 baris) |
| `KDS_PIN=4826 BASE_HREF=/DonburiX/ bash scripts/build-web.sh` | Berhasil |
| `git status --short` setelah semua langkah | 0 file berubah |

## Kesimpulan

Clone, pull request, instalasi, eksekusi, build, dan deployment berjalan, dan
semua unit test lulus.

Yang belum diuji: APK belum dipasang di perangkat atau emulator.

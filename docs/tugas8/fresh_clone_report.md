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

Hasil deployment dicatat setelah PR digabung ke `main`, karena environment
GitHub Pages hanya menerima deploy dari branch utama.

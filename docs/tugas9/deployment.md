# Deployment ke VPS, Raspberry Pi, atau Orange Pi — Tugas 9

Tanggal: 2026-11-12.

## Status

| Item | Status |
| --- | --- |
| Konfigurasi nginx dan skrip deploy | Selesai, ada di repo |
| Uji konfigurasi nginx di Docker | Lulus, lihat [Hasil uji](#hasil-uji) |
| Test dan build | 114 test lulus, build web release berhasil |
| Deploy ke server (`https://<IP>/DonburiX/`) | **Belum dijalankan.** Menunggu alamat IP dan akses SSH server |
| Demo yang sudah online | <https://cikibber.github.io/DonburiX/> (GitHub Pages) |

Bagian [Bukti deployment server](#bukti-deployment-server) diisi setelah skrip
dijalankan pada server.

## Rancangan

DonburiX adalah aplikasi Flutter Web statis tanpa backend, jadi server hanya
perlu nginx.

```text
Browser ──HTTPS 443──> nginx ──> /var/www/donburix/DonburiX/  (hasil flutter build web)
        ──HTTP 80───> nginx ──> 301 ke HTTPS
```

| Hal | Pilihan | Alasan |
| --- | --- | --- |
| Alamat | `https://<IP>/DonburiX/` | Format `https://ip/application_name` dari tugas |
| Server web | nginx dari paket Debian/Ubuntu | Tersedia untuk x86 dan ARM, cocok untuk VPS maupun Pi |
| TLS | Sertifikat self-signed dengan SAN IP, dibuat saat setup | Server tidak punya nama domain. Browser menampilkan peringatan sekali |
| Cache | `Cache-Control: no-cache` dengan ETag | Nama file build tidak memakai hash, jadi versi baru langsung terpakai |
| Header keamanan | CSP dengan `frame-ancestors 'none'`, `X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy` | Menutup risiko R6 Tugas 8 yang tidak bisa dipasang di GitHub Pages |
| Pergantian build | Folder baru disiapkan lalu ditukar | Situs tidak pernah menyajikan build setengah jadi |

File:

- [`deploy/nginx/donburix.conf`](../../deploy/nginx/donburix.conf): konfigurasi nginx.
- [`scripts/deploy-vps.sh`](../../scripts/deploy-vps.sh): dijalankan di komputer pengembang. Build, kirim lewat SSH, lalu memeriksa `HTTP 200`.
- [`scripts/server-setup.sh`](../../scripts/server-setup.sh): dijalankan di server oleh skrip deploy. Memasang nginx, sertifikat, konfigurasi, dan build.

## Cara deploy

Prasyarat server: Debian, Ubuntu, Raspberry Pi OS, atau Armbian. Akses SSH
sebagai root atau pengguna dengan sudo tanpa kata sandi. Port 80 dan 443
terbuka dari internet. Untuk Pi di jaringan rumah, teruskan port 80 dan 443
dari router dan pakai IP publik router.

Prasyarat komputer pengembang: Flutter 3.44.1, Bash, `ssh`, `scp`, `tar`, `curl`.

```sh
git clone https://github.com/Cikibber/DonburiX.git
cd DonburiX
DEPLOY_HOST=<IP server> DEPLOY_USER=root KDS_PIN=4826 ./scripts/deploy-vps.sh
```

Keluaran yang diharapkan di baris terakhir:

```text
[deploy-vps] https://<IP server>/DonburiX/ -> HTTP 200
```

Variabel lain: `DEPLOY_PORT` (bawaan 22) dan `SKIP_BUILD=1` untuk memakai build
yang sudah ada. Skrip aman dijalankan ulang untuk memperbarui aplikasi.

Reviewer membuka `https://<IP server>/DonburiX/`, menerima peringatan
sertifikat, masuk dengan nama dan email apa saja, dan memakai PIN `4826` di tab
Dapur.

### Sertifikat tepercaya (opsional, belum diuji)

Let's Encrypt menerbitkan sertifikat untuk alamat IP sejak 15 Januari 2026
lewat profil `shortlived` (berlaku 160 jam) dengan validasi `http-01`
([pengumuman](https://letsencrypt.org/2026/01/15/6day-and-ip-general-availability),
[profil](https://letsencrypt.org/docs/profiles/)). Perlu certbot 5.4 atau lebih
baru, yang belum ada di paket apt Debian 12/13 dan Ubuntu 24.04, sehingga
dipasang lewat snap. Konfigurasi nginx sudah menyajikan
`/.well-known/acme-challenge/` dari `/var/www/donburix-acme`.

```sh
sudo snap install --classic certbot
sudo certbot certonly --webroot --webroot-path /var/www/donburix-acme \
  --ip-address <IP server> --required-profile shortlived --cert-name donburix \
  --deploy-hook "install -m 644 /etc/letsencrypt/live/donburix/fullchain.pem /etc/ssl/donburix/fullchain.pem && install -m 600 /etc/letsencrypt/live/donburix/privkey.pem /etc/ssl/donburix/privkey.pem && systemctl reload nginx"
```

Langkah ini **belum dijalankan** pada server mana pun. IP harus publik (bukan
CGNAT) dan port 80 harus terbuka pada setiap perpanjangan.

## Hasil uji

### Test dan build

| Pemeriksaan | Hasil |
| --- | --- |
| `dart format --output=none --set-exit-if-changed lib test` | 42 file, 0 berubah |
| `flutter analyze` | No issues found |
| `flutter test --coverage` | **114 test lulus**, coverage baris 95,1% (1254/1318) |
| `KDS_PIN=4826 BASE_HREF=/DonburiX/ bash scripts/build-web.sh` | Berhasil |
| CI [run 43219072868](https://github.com/Cikibber/DonburiX/actions/runs/43219072868) | `bowl-builder`, `security-scan`, `demo-apk` berhasil |

### Konfigurasi nginx di Docker

`deploy/nginx/donburix.conf` dijalankan pada image `nginx:1.22` (versi nginx
Debian 12) dengan build release dan sertifikat self-signed, port 443 dipetakan
ke 8443.

| Permintaan | Hasil |
| --- | --- |
| `GET /` | `302` ke `/DonburiX/` |
| `GET /DonburiX` | `301` ke `/DonburiX/` |
| `GET /DonburiX/` | `200 text/html` |
| `GET /DonburiX/main.dart.js` | `200 application/javascript`, `Content-Encoding: gzip`, `Cache-Control: no-cache`, ETag |
| `GET /DonburiX/canvaskit/canvaskit.wasm` | `200 application/wasm` |
| `GET /DonburiX/nope`, `GET /nope` | `404` |
| `GET http://…/DonburiX/` (port 80) | `301` ke HTTPS |
| Header | CSP dengan `frame-ancestors 'none'`, `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`, `Referrer-Policy: no-referrer`, `Server: nginx` tanpa versi |
| Chromium membuka `https://127.0.0.1:8443/` | Diarahkan ke `/DonburiX/`, layar masuk tampil, 0 error konsol, 0 pelanggaran CSP |

Masalah yang ditemukan dan diperbaiki saat uji ini: redirect `/` memakai alamat
absolut dengan port 443, sehingga gagal di balik pemetaan port. Diperbaiki
dengan `absolute_redirect off`.

Yang **belum** diuji: `scripts/deploy-vps.sh` dan `scripts/server-setup.sh`
(pemasangan paket, `systemctl`, penukaran folder) belum pernah berjalan pada
server sungguhan.

## Bukti deployment server

Belum ada. Diisi setelah deploy: tautan uji, tangkapan layar aplikasi dari
alamat server, dan keluaran skrip deploy.

Tangkapan layar build yang sama (disajikan lokal) ada di
[`docs/tugas10/screenshots`](../tugas10/screenshots).

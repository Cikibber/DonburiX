#!/usr/bin/env bash
# Dijalankan DI SERVER sebagai root oleh scripts/deploy-vps.sh.
#   server-setup.sh <IP publik> <arsip build .tar.gz> <donburix.conf>
# Memasang nginx, sertifikat, konfigurasi, dan build web. Aman dijalankan ulang.
set -euo pipefail

IP="${1:?IP publik server}"
ARCHIVE="${2:?arsip build}"
CONF="${3:?file konfigurasi nginx}"

SITE=/var/www/donburix
CERT_DIR=/etc/ssl/donburix

if ! command -v nginx >/dev/null; then
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get install -y -qq nginx openssl
fi

# Sertifikat self-signed dengan SAN IP. Tidak menimpa sertifikat yang sudah ada,
# jadi sertifikat tepercaya yang dipasang belakangan tetap dipakai.
if [ ! -s "$CERT_DIR/fullchain.pem" ]; then
  mkdir -p "$CERT_DIR"
  openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes \
    -days 365 -subj "/CN=$IP" -addext "subjectAltName=IP:$IP" \
    -keyout "$CERT_DIR/privkey.pem" -out "$CERT_DIR/fullchain.pem" 2>/dev/null
  chmod 600 "$CERT_DIR/privkey.pem"
fi

# Build baru disiapkan di samping yang lama lalu ditukar, agar situs tidak
# pernah menyajikan build setengah jadi.
mkdir -p "$SITE" /var/www/donburix-acme
rm -rf "$SITE/DonburiX.new"
mkdir "$SITE/DonburiX.new"
tar -xzf "$ARCHIVE" -C "$SITE/DonburiX.new"
test -s "$SITE/DonburiX.new/index.html"
rm -rf "$SITE/DonburiX.old"
[ -d "$SITE/DonburiX" ] && mv "$SITE/DonburiX" "$SITE/DonburiX.old"
mv "$SITE/DonburiX.new" "$SITE/DonburiX"
chmod -R a+rX "$SITE"

install -m 644 "$CONF" /etc/nginx/conf.d/donburix.conf
# Situs bawaan Debian/Ubuntu juga memakai default_server dan akan bentrok.
rm -f /etc/nginx/sites-enabled/default

nginx -t
systemctl enable --now nginx
systemctl reload nginx
echo "[server-setup] OK: https://$IP/DonburiX/"

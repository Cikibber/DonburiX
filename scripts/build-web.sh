#!/usr/bin/env bash
# Build Flutter Web release yang siap di-deploy, dengan CSP.
#   KDS_PIN=4826 BASE_HREF=/DonburiX/ ./scripts/build-web.sh
# CSP disuntik di sini, bukan di web/index.html, karena `flutter run` (debug)
# membutuhkan inline script dan WebSocket yang diblokir kebijakan ini.
set -euo pipefail

: "${KDS_PIN:?Set KDS_PIN, tanpa PIN layar dapur selalu terkunci}"
BASE_HREF="${BASE_HREF:-/}"
export MSYS_NO_PATHCONV=1 # Git Bash Windows: jangan ubah /DonburiX/ jadi path lokal.

cd "$(dirname "$0")/../apps/mobile"

# --no-web-resources-cdn: CanvasKit disajikan sendiri, bukan skrip pihak ketiga.
flutter build web --release --no-web-resources-cdn \
  --base-href "$BASE_HREF" --dart-define=KDS_PIN="$KDS_PIN"

CSP="default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; font-src 'self' https://fonts.gstatic.com; connect-src 'self' https://fonts.gstatic.com; worker-src 'self' blob:; object-src 'none'; base-uri 'self'; form-action 'none'"

sed -i "s|<meta charset=\"UTF-8\">|<meta charset=\"UTF-8\">\n  <meta http-equiv=\"Content-Security-Policy\" content=\"$CSP\">\n  <meta name=\"referrer\" content=\"no-referrer\">|" build/web/index.html
grep -q 'Content-Security-Policy' build/web/index.html

echo "[build-web] OK: apps/mobile/build/web (base href $BASE_HREF)"

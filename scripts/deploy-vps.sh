#!/usr/bin/env bash
# Deploy DonburiX ke VPS, Raspberry Pi, atau Orange Pi (Debian/Ubuntu) lewat SSH.
#   DEPLOY_HOST=203.0.113.10 DEPLOY_USER=root KDS_PIN=4826 ./scripts/deploy-vps.sh
# Hasil: https://<DEPLOY_HOST>/DonburiX/
# DEPLOY_USER harus root atau punya sudo tanpa kata sandi.
set -euo pipefail

: "${DEPLOY_HOST:?Set DEPLOY_HOST ke IP publik server}"
: "${KDS_PIN:?Set KDS_PIN, tanpa PIN layar dapur selalu terkunci}"
DEPLOY_USER="${DEPLOY_USER:-root}"
DEPLOY_PORT="${DEPLOY_PORT:-22}"
TARGET="$DEPLOY_USER@$DEPLOY_HOST"

cd "$(dirname "$0")/.."

if [ "${SKIP_BUILD:-0}" != 1 ]; then
  KDS_PIN="$KDS_PIN" BASE_HREF=/DonburiX/ bash scripts/build-web.sh
fi

ARCHIVE="$(mktemp)"
trap 'rm -f "$ARCHIVE"' EXIT
tar -czf "$ARCHIVE" -C apps/mobile/build/web .

REMOTE=/tmp/donburix-deploy
ssh -p "$DEPLOY_PORT" "$TARGET" "rm -rf $REMOTE && mkdir -p $REMOTE"
scp -q -P "$DEPLOY_PORT" "$ARCHIVE" "$TARGET:$REMOTE/web.tar.gz"
scp -q -P "$DEPLOY_PORT" deploy/nginx/donburix.conf scripts/server-setup.sh "$TARGET:$REMOTE/"

SUDO=sudo
[ "$DEPLOY_USER" = root ] && SUDO=
ssh -p "$DEPLOY_PORT" "$TARGET" \
  "$SUDO bash $REMOTE/server-setup.sh $DEPLOY_HOST $REMOTE/web.tar.gz $REMOTE/donburix.conf && rm -rf $REMOTE"

# -k: sertifikat bawaan self-signed.
STATUS="$(curl -sk -o /dev/null -w '%{http_code}' "https://$DEPLOY_HOST/DonburiX/")"
echo "[deploy-vps] https://$DEPLOY_HOST/DonburiX/ -> HTTP $STATUS"
[ "$STATUS" = 200 ]

#!/usr/bin/env bash
# Собирает ISO EliteLinux. live-build работает в контейнере Debian 13 (нужен docker),
# поэтому собирать можно с любого хоста и без sudo.
# Результат: elitelinux-1.0-amd64.hybrid.iso в корне проекта, лог — build.log.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

"${ROOT}/theme/stage.sh"
"${ROOT}/scripts/prepare-packages.sh"

# учётки для установщика (логины и хэши паролей) — секрет вне репозитория;
# в образ кладём только на время сборки
SECRET_ACCOUNTS="${ROOT}/secrets/accounts"
IMAGE_ACCOUNTS="${ROOT}/config/includes.chroot/etc/elite/accounts"
if [[ ! -f "$SECRET_ACCOUNTS" ]]; then
  echo "Нет ${SECRET_ACCOUNTS} — см. secrets.example/accounts" >&2
  exit 1
fi
install -m 600 "$SECRET_ACCOUNTS" "$IMAGE_ACCOUNTS"
trap 'rm -f "$IMAGE_ACCOUNTS"' EXIT

docker run --rm --privileged \
  -v "${ROOT}:/build" -w /build \
  -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
  debian:trixie bash -euc '
    apt-get update
    apt-get install -y --no-install-recommends live-build debootstrap ca-certificates \
      curl gnupg xorriso squashfs-tools mtools dosfstools grub-efi-amd64-bin grub-pc-bin \
      syslinux syslinux-utils isolinux cpio
    trap "chown -R \$HOST_UID:\$HOST_GID /build" EXIT
    lb clean
    lb config
    lb build
  '

ls -lh "${ROOT}"/*.iso

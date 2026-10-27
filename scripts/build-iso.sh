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
# пароль неконтролируемого доступа AnyDesk (необязательно) — задаётся при первой загрузке
IMAGE_ANYDESK="${ROOT}/config/includes.chroot/etc/elite/anydesk-password"
[[ -f "${ROOT}/secrets/anydesk-password" ]] && install -m 600 "${ROOT}/secrets/anydesk-password" "$IMAGE_ANYDESK"
trap 'rm -f "$IMAGE_ACCOUNTS" "$IMAGE_ANYDESK"' EXIT

docker run --rm --privileged \
  -v "${ROOT}:/build" -w /build \
  -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
  debian:trixie bash -euc '
    apt-get update
    apt-get install -y --no-install-recommends live-build debootstrap ca-certificates \
      curl gnupg xorriso squashfs-tools mtools dosfstools grub-efi-amd64-bin grub-pc-bin \
      syslinux syslinux-utils isolinux cpio
    # хосту отдаём только результаты в корне проекта (ISO, лог, списки пакетов).
    # Не chown -R: раньше он отдавал пользователю и кэш debootstrap (cache/bootstrap),
    # из которого следующая сборка брала базовую систему, — в образ попадали su и
    # passwd без setuid и «/», /usr во владении UID 1000 (= «Менеджер»).
    trap "find /build -maxdepth 1 -type f -exec chown \$HOST_UID:\$HOST_GID {} +" EXIT
    # кэш, испорченный старой сборкой, — выбросить (debootstrap скачает заново)
    if [ -e cache/bootstrap/usr/bin/su ] && [ "$(stat -c %u cache/bootstrap/usr/bin/su)" != 0 ]; then
      echo "cache/bootstrap не во владении root — удаляю" >&2
      rm -rf cache/bootstrap
    fi
    # файлы образа не должны быть доступны на запись группе (umask хоста 002)
    chmod -R go-w config/includes.chroot
    lb clean
    lb config
    lb build
  '

ls -lh "${ROOT}"/*.iso

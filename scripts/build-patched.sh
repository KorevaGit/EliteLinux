#!/usr/bin/env bash
# Собирает пакет Debian 13 из исходников с патчами EliteLinux (patches/<пакет>-*.patch)
# и кладёт .deb в config/packages.chroot. Версия получает суффикс +elite1 — пакет из
# образа заменяет стандартный.
#   scripts/build-patched.sh lightdm-gtk-greeter "без «Other...» при выключенном ручном вводе логина"
set -euo pipefail

SRC="$1"
NOTE="$2"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${ROOT}/config/packages.chroot"
mkdir -p "$OUT"

docker run --rm \
  -v "${ROOT}/patches:/patches:ro" -v "${OUT}:/out" \
  -e SRC="$SRC" -e NOTE="$NOTE" \
  -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
  debian:trixie bash -euc '
    echo "deb-src http://deb.debian.org/debian trixie main" > /etc/apt/sources.list.d/src.list
    apt-get update -qq
    apt-get install -y -qq --no-install-recommends dpkg-dev devscripts quilt ca-certificates >/dev/null
    apt-get build-dep -y -qq "$SRC" >/dev/null
    mkdir /work && cd /work
    apt-get source -qq "$SRC" >/dev/null
    cd "$SRC"-*/
    mkdir -p debian/patches
    for p in /patches/"$SRC"-*.patch; do
      name=elite-$(basename "$p")
      cp "$p" "debian/patches/$name"
      echo "$name" >> debian/patches/series
    done
    QUILT_PATCHES=debian/patches quilt push -a >/dev/null
    DEBEMAIL=elitelinux@localhost DEBFULLNAME=EliteLinux \
      dch --local "+elite" --distribution trixie "Патчи EliteLinux: $NOTE."
    dpkg-buildpackage -b -uc -us -j"$(nproc)" >/dev/null
    # только основной пакет: отладочные символы (-dbgsym) в образ не нужны
    for deb in ../*+elite*_amd64.deb; do
      case "$deb" in *-dbgsym_*) continue ;; esac
      cp "$deb" /out/
      chown "$HOST_UID:$HOST_GID" "/out/$(basename "$deb")"
    done
  '

ls -1 "$OUT"/*+elite*_amd64.deb

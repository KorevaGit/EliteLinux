#!/usr/bin/env bash
# Собирает lightdm-gtk-greeter из исходников Debian 13 с патчами EliteLinux
# (patches/lightdm-gtk-greeter-*.patch) и кладёт .deb в config/packages.chroot.
# Версия получает суффикс +elite1 — пакет из образа заменяет стандартный.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${ROOT}/config/packages.chroot"
mkdir -p "$OUT"

docker run --rm \
  -v "${ROOT}/patches:/patches:ro" -v "${OUT}:/out" \
  -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
  debian:trixie bash -euc '
    echo "deb-src http://deb.debian.org/debian trixie main" > /etc/apt/sources.list.d/src.list
    apt-get update -qq
    apt-get install -y -qq --no-install-recommends dpkg-dev devscripts quilt ca-certificates >/dev/null
    apt-get build-dep -y -qq lightdm-gtk-greeter >/dev/null
    mkdir /work && cd /work
    apt-get source -qq lightdm-gtk-greeter >/dev/null
    cd lightdm-gtk-greeter-*/
    mkdir -p debian/patches
    for p in /patches/lightdm-gtk-greeter-*.patch; do
      name=elite-$(basename "$p")
      cp "$p" "debian/patches/$name"
      echo "$name" >> debian/patches/series
    done
    QUILT_PATCHES=debian/patches quilt push -a >/dev/null
    DEBEMAIL=elitelinux@localhost DEBFULLNAME=EliteLinux \
      dch --local "+elite" --distribution trixie "Патчи EliteLinux: без «Other...» при выключенном ручном вводе логина."
    dpkg-buildpackage -b -uc -us -j"$(nproc)" >/dev/null
    cp ../lightdm-gtk-greeter_*_amd64.deb /out/
    chown "$HOST_UID:$HOST_GID" /out/lightdm-gtk-greeter_*_amd64.deb
  '

ls -1 "$OUT"/lightdm-gtk-greeter_*_amd64.deb

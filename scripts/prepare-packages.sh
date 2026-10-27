#!/usr/bin/env bash
# Кладёт в config/packages.chroot сторонние .deb, которых нет в репозиториях:
# Zoom (с сайта) и EliteSIP (из проекта, с поправленной зависимостью под Debian 13).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PKG="${ROOT}/config/packages.chroot"
# по умолчанию — самый свежий выпуск EliteSIP для Linux
ELITESIP_DIR="/media/koreva/EliteDev1/projects/Linux EliteSip/artifacts/linux"
ELITESIP_DEB="${ELITESIP_DEB:-$(ls -1 "$ELITESIP_DIR"/EliteSIP-*.deb | sort -V | tail -1)}"
echo "EliteSIP: $(basename "$ELITESIP_DEB")"
mkdir -p "$PKG"

if [[ ! -f "$PKG/zoom_amd64.deb" ]]; then
  curl -fL --retry 3 -o "$PKG/zoom_amd64.deb" https://zoom.us/client/latest/zoom_amd64.deb
fi

# EliteSIP собран под Ubuntu 24.04 и требует libicu74, а в Debian 13 есть libicu76.
# .NET находит ICU любой версии сам, поэтому для образа меняем зависимость
# на «libicu76 | libicu74». Правильно это сделать в упаковке самого EliteSIP
# (packaging/debian/control в Linux EliteSip).
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
dpkg-deb -R "$ELITESIP_DEB" "$tmp/pkg"
sed -i 's/\blibicu74\b/libicu76 | libicu74/' "$tmp/pkg/DEBIAN/control"
dpkg-deb --root-owner-group -b "$tmp/pkg" "$PKG/elitesip_amd64.deb" >/dev/null

# пакеты с патчами EliteLinux (patches/) — собираются один раз, долго.
# После правки патча удалить старый .deb из config/packages.chroot.
build_patched() {
  ls "$PKG/$1"_*+elite*_amd64.deb >/dev/null 2>&1 || "${ROOT}/scripts/build-patched.sh" "$1" "$2"
}
build_patched lightdm-gtk-greeter "без «Other...» при выключенном ручном вводе логина"
build_patched xfce4-whiskermenu-plugin "подписи на кнопках «Заблокировать», «Выйти», «Выключить»"

ls -la "$PKG"

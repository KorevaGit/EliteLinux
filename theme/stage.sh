#!/usr/bin/env bash
# Собирает тему и иконки и раскладывает оформление в config/includes.chroot,
# откуда live-build кладёт его в образ.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$HERE")"
CHROOT="${ROOT}/config/includes.chroot"
BRANDING="${ROOT}/branding"

"${HERE}/build.sh"
"${HERE}/build-icons.sh"
python3 "${HERE}/render-splash-assets.py"

rm -rf "${CHROOT}/usr/share/themes" "${CHROOT}/usr/share/icons/Elite" "${CHROOT}/usr/share/plymouth"
mkdir -p "${CHROOT}/usr/share/themes" "${CHROOT}/usr/share/icons" \
         "${CHROOT}/usr/share/pixmaps" "${CHROOT}/usr/share/backgrounds/elite"

cp -r "${HERE}"/dist/Elite-* "${CHROOT}/usr/share/themes/"
cp -r "${HERE}/dist/icons/Elite" "${CHROOT}/usr/share/icons/"

cp "${BRANDING}/crown.svg"           "${CHROOT}/usr/share/pixmaps/elite-crown.svg"
# кнопка меню — сплошной силуэт короны: тонкий контур плохо читается на панели
cp "${BRANDING}/start-button/b-solid.svg" "${CHROOT}/usr/share/pixmaps/elite-start.svg"
# оригинальные логотипы программ, которых нет в Papirus (веб-ярлык Телемоста)
cp "${BRANDING}"/app-icons/elite-*.png "${CHROOT}/usr/share/pixmaps/"
cp "${BRANDING}/wallpaper-clean.png" "${CHROOT}/usr/share/backgrounds/elite/elite-desktop.png"
cp "${BRANDING}/wallpaper-logo.png"  "${CHROOT}/usr/share/backgrounds/elite/elite-login.png"

mkdir -p "${CHROOT}/usr/share/plymouth/themes"
cp -r "${HERE}/plymouth/elite" "${CHROOT}/usr/share/plymouth/themes/"
mv "${CHROOT}/usr/share/plymouth/themes/elite/login-bg.png" \
   "${CHROOT}/usr/share/backgrounds/elite/elite-login-bg.png"

# логотип и надпись для установщика Calamares (экран приветствия и слайды)
cp "${HERE}/plymouth/elite/crown.png"    "${CHROOT}/etc/calamares/branding/elite/logo.png"
cp "${HERE}/plymouth/elite/wordmark.png" "${CHROOT}/etc/calamares/branding/elite/wordmark.png"

echo "Оформление разложено в ${CHROOT}"

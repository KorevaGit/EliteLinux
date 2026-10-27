#!/usr/bin/env bash
# Собирает GTK/Xfwm4-тему EliteLinux из исходников Colloid с фирменной палитрой.
# Результат: theme/dist/Elite-Dark и theme/dist/Elite-Light (+ -hdpi/-xhdpi для xfwm4).
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="${HERE}/Colloid-src"
WORK="$(mktemp -d)"
DIST="${HERE}/dist"
trap 'rm -rf "$WORK"' EXIT

[[ -d "$SRC" ]] || git clone --depth 1 https://github.com/vinceliuice/Colloid-gtk-theme.git "$SRC"

# sassc нет в системе — подставляем dart-sass через npx с совместимым интерфейсом
if ! command -v sassc >/dev/null; then
  mkdir -p "$WORK/bin"
  cat > "$WORK/bin/sassc" <<'EOF'
#!/usr/bin/env bash
args=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -M) shift ;;
    -t) shift 2 ;;
    *) args+=("$1"); shift ;;
  esac
done
exec npx --yes sass@1.77.8 --no-source-map --style=expanded --quiet "${args[@]}"
EOF
  chmod +x "$WORK/bin/sassc"
  export PATH="$WORK/bin:$PATH"
fi

cp -r "$SRC" "$WORK/colloid"
cp "${HERE}/_color-palette-elite.scss" "$WORK/colloid/src/sass/_color-palette-default.scss"

# EliteLinux мягче Colloid: углы элементов 6 → 10 px, окон и меню 12 → 16 px
sed -i -e 's/^\$modal-radius: 6px;/$modal-radius: 12px;/' \
       -e 's/^\$corner-radius: 6px;/$corner-radius: 10px;/' \
       "$WORK/colloid/src/sass/_variables.scss"
grep -q '^\$corner-radius: 10px;' "$WORK/colloid/src/sass/_variables.scss"

rm -rf "$DIST" && mkdir -p "$DIST"
# Кнопки окна в обычном (Windows-) стиле: свернуть/развернуть/закрыть справа
"$WORK/colloid/install.sh" -d "$DIST" -n Elite -t default -c dark light --tweaks normal

# дополнения EliteLinux (меню Whisker, панель) — в конец CSS обеих тем.
# И в gtk-dark.css: панель в тёмном режиме (dark-mode) грузит именно его
for t in Elite-Dark Elite-Light; do
  for css in gtk.css gtk-dark.css; do
    cat "${HERE}/elite-extra.css" >> "$DIST/$t/gtk-3.0/$css"
  done
done

# тема экрана входа: тёмная + правки для работы без композитора
rm -rf "$DIST/Elite-Greeter"
cp -r "$DIST/Elite-Dark" "$DIST/Elite-Greeter"
sed -i 's/^Name=.*/Name=Elite-Greeter/' "$DIST/Elite-Greeter/index.theme"
for css in gtk.css gtk-dark.css; do
  cat "${HERE}/elite-greeter.css" >> "$DIST/Elite-Greeter/gtk-3.0/$css"
done

# верхние углы рамки окон Xfwm4 — тем же радиусом, что и у окон GTK
for t in Elite-Dark Elite-Light; do
  python3 "${HERE}/round-xfwm4-corners.py" "$DIST/$t/xfwm4" 14
done

echo "Готово: $(ls "$DIST" | tr '\n' ' ')"

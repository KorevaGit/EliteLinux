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

rm -rf "$DIST" && mkdir -p "$DIST"
# Кнопки окна в обычном (Windows-) стиле: свернуть/развернуть/закрыть справа
"$WORK/colloid/install.sh" -d "$DIST" -n Elite -t default -c dark light --tweaks normal

echo "Готово: $(ls "$DIST" | tr '\n' ' ')"

#!/usr/bin/env bash
# Собирает тему иконок "Elite": наследует Papirus-Dark и переопределяет только
# папки — берёт жёлтый вариант Papirus и перекрашивает его в фирменное золото.
# Использование: build-icons.sh [каталог Papirus] [каталог вывода]
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
PAPIRUS="${1:-/usr/share/icons/Papirus}"
OUT="${2:-${HERE}/dist/icons/Elite}"

# жёлтый Papirus -> фирменные цвета
RECOLOR=(
  -e 's/#e19d00/#a87d38/gI'   # задняя стенка папки
  -e 's/#f9bd30/#c9a25a/gI'   # передняя стенка
  -e 's/#594411/#0f2440/gI'   # значок на папке
)

rm -rf "$OUT" && mkdir -p "$OUT"
dirs=()

for src in "$PAPIRUS"/*/places; do
  size="$(basename "$(dirname "$src")")"
  [[ -L "$PAPIRUS/$size" ]] && continue   # @2x-каталоги — ссылки, добавим ниже
  found=0
  for f in "$src"/folder-yellow*.svg "$src"/user-yellow*.svg; do
    [[ -e "$f" ]] || continue
    name="$(basename "$f" | sed 's/-yellow//')"
    mkdir -p "$OUT/$size/places"
    sed "${RECOLOR[@]}" "$(readlink -f "$f")" > "$OUT/$size/places/$name"
    found=1
  done
  [[ $found == 1 ]] && dirs+=("$size/places")
done

# @2x-каталоги Papirus — симлинки на базовые размеры, повторяем это
for link in "$PAPIRUS"/*@2x; do
  [[ -L "$link" ]] || continue
  target="$(readlink "$link")"
  [[ -d "$OUT/$target" ]] || continue
  ln -s "$target" "$OUT/$(basename "$link")"
  dirs+=("$(basename "$link")/places")
done

{
  echo "[Icon Theme]"
  echo "Name=Elite"
  echo "Comment=Papirus-Dark с золотыми папками EliteLinux"
  echo "Inherits=Papirus-Dark,Papirus,breeze-dark,hicolor"
  echo "Directories=$(IFS=,; echo "${dirs[*]}")"
  for d in "${dirs[@]}"; do
    echo
    # описание каталога берём из index.theme самого Papirus
    awk -v sec="[$d]" '$0==sec{p=1;print;next} /^\[/{p=0} p&&NF' "$PAPIRUS/index.theme"
  done
} > "$OUT/index.theme"

echo "Готово: $OUT ($(find "$OUT" -name '*.svg' | wc -l) иконок)"

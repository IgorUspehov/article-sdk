#!/usr/bin/env bash
set -e

PROJECT="$HOME/article-sdk"
IMG="$PROJECT/images"
OUT="$PROJECT/output/article-sdk-90s.mp4"
TMP="$PROJECT/.video_tmp"

rm -rf "$TMP"
mkdir -p "$TMP"

echo "=== Проверка изображений ==="

for i in $(seq -w 1 20); do
    f="$IMG/shot${i}.png"
    if [ ! -f "$f" ]; then
        echo "ОШИБКА: не найден $f"
        exit 1
    fi
done

echo "20 кадров найдены."

echo "=== Подготовка кадров ==="

# 20 кадров × 4.5 сек = 90 секунд
for i in $(seq -w 1 20); do
    ffmpeg -y -loglevel error \
        -loop 1 \
        -i "$IMG/shot${i}.png" \
        -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2,format=yuv420p" \
        -t 4.5 \
        -r 30 \
        "$TMP/shot${i}.mp4"
done

echo "=== Сборка ролика ==="

printf "file '%s'\n" "$TMP"/shot*.mp4 > "$TMP/list.txt"

ffmpeg -y \
    -f concat \
    -safe 0 \
    -i "$TMP/list.txt" \
    -c:v libx264 \
    -preset medium \
    -crf 20 \
    -pix_fmt yuv420p \
    -movflags +faststart \
    -an \
    "$OUT"

rm -rf "$TMP"

echo
echo "======================================"
echo "ГОТОВО"
echo "Файл:"
echo "$OUT"
echo "======================================"

ffprobe -v error \
    -show_entries format=duration \
    -of default=noprint_wrappers=1 \
    "$OUT"

#!/usr/bin/env bash
# Send files to Telegram. Usage: bash .github/scripts/tg_send.sh <file-or-dir>...
CAPTION="${CAPTION:-}"
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-}"

if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
  echo "TELEGRAM_FAIL: Missing bot token or chat ID"
  exit 0
fi

API="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}"
LIMIT=$((49*1024*1024))
FAIL=0

send() {  # method field file
  local resp
  resp=$(curl -sS -F chat_id="${TELEGRAM_CHAT_ID}" -F "$2=@$3" -F caption="${CAPTION:-$(basename "$3")}" "${API}/$1" 2>&1)
  if echo "$resp" | grep -q '"ok":true'; then
    echo "TELEGRAM_OK $1 $3"
  else
    echo "TELEGRAM_FAIL $1 $3: $(echo "$resp" | head -c 300)"
    FAIL=1
  fi
}

files=()
for p in "$@"; do
  if [ -d "$p" ]; then
    while IFS= read -r f; do files+=("$f"); done < <(find "$p" -type f | sort)
  elif [ -f "$p" ]; then
    files+=("$p")
  fi
done

if [ ${#files[@]} -eq 0 ]; then
  echo "no files to send"
  exit 0
fi

for f in "${files[@]}"; do
  [ -s "$f" ] || continue
  size=$(stat -c%s "$f")
  case "${f,,}" in
    *.mp4|*.mov|*.mkv|*.webm)
      if [ "$size" -gt "$LIMIT" ]; then
        command -v ffmpeg >/dev/null || { sudo apt-get update -qq && sudo apt-get install -y -qq ffmpeg >/dev/null; }
        out="${f%.*}_tg.mp4"
        ffmpeg -y -loglevel error -i "$f" -c:v libx264 -crf 22 -maxrate 4M -bufsize 8M -preset veryfast -c:a aac -b:a 128k -movflags +faststart "$out"
        f="$out"; size=$(stat -c%s "$f")
      fi
      if [ "$size" -gt "$LIMIT" ]; then echo "TELEGRAM_FAIL too big after compress: $f"; FAIL=1; continue; fi
      send sendVideo video "$f" ;;
    *)
      if [ "$size" -gt "$LIMIT" ]; then echo "TELEGRAM_FAIL too big (>49MB): $f"; FAIL=1; continue; fi
      send sendDocument document "$f" ;;
  esac
done

exit $FAIL

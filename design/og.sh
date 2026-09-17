#!/bin/zsh
set -eu
cd "$(dirname "$0")/.."
python3 -m http.server 8190 --bind 127.0.0.1 >/dev/null 2>&1 &
S=$!; trap 'kill $S' EXIT; sleep 0.6
rm -f assets/og.png
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --disable-gpu --hide-scrollbars \
  --user-data-dir=/tmp/chrome-og --window-size=1200,630 --screenshot="$PWD/assets/og.png" http://127.0.0.1:8190/design/og.html >/dev/null 2>&1 &
C=$!
for i in {1..40}; do [[ -s assets/og.png ]] && break; sleep 0.5; done   # headless Chrome does not always exit after the shot
sleep 1; kill $C 2>/dev/null || true
identify assets/og.png | cut -d' ' -f1-3

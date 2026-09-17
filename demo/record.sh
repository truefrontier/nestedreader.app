#!/bin/zsh
# Drives the real Nested.app on a Mac and records the demo that the site embeds.
#
#   demo/record.sh launch      # apply demo settings, open the sample folder in Nested, place the window
#   THEME=dark demo/record.sh launch   # the same in the app's dark theme, on a dark backdrop
#   demo/record.sh run         # the scripted demo: records demo/raw.mp4 and demo/marks.log
#   demo/record.sh shot NAME   # still of the window into demo/stills/NAME.png
#   demo/record.sh quit        # quit Nested and put the user's settings back
#
# Needs: /Applications/Nested.app, ffmpeg (avfoundation), cliclick, an unlocked display,
# and Screen Recording permission for the terminal. The Claude plan provider answers the
# questions, so `claude` has to be signed in. Coordinates are window-relative points; the
# window is pinned to WIN_X,WIN_Y WIN_W x WIN_H so they stay valid between runs.
set -u
SELF=${0:A}
cd "$(dirname "$SELF")"

APP=${NESTED_APP:-/Applications/Nested.app}
CORPUS=${CORPUS:-$PWD/corpus/Sleep and memory}
TAKE_DIR=$PWD/.run
SUPPORT="$HOME/Library/Application Support/app.nestedreader.nested"
BACKUP=${BACKUP:-$PWD/.backup}
WIN_X=160 WIN_Y=100 WIN_W=1280 WIN_H=800
THEME=${THEME:-light}
# The page colour of each theme (the site's --bg). A borderless window in it sits behind Nested while
# recording, so the window's rounded corners capture the page colour instead of the desktop.
case $THEME in light) PAGE_BG='#faf9f7' ;; dark) PAGE_BG='#171614' ;; *) echo "THEME must be light or dark" >&2; exit 2 ;; esac
BACKDROP_PAD=48
EASING=12        # cliclick easing: slower, human-like pointer paths, which the webview registers as a drag
TYPING_MS=55     # per keystroke, the pace of a person typing

# The avfoundation index of the main display, and how many pixels one point covers on it.
screen_device() {
  ffmpeg -f avfoundation -list_devices true -i "" 2>&1 | sed -n 's/.*\[\([0-9]*\)\] Capture screen 0$/\1/p' | head -1
}
pixels_per_point() {
  local probe=$(mktemp -t probe).png
  screencapture -x -R0,0,50,50 "$probe" && echo $(( $(sips -g pixelWidth "$probe" | awk '/pixelWidth/ {print $2}') / 50 ))
  rm -f "$probe"
}

pid_of() { pgrep -f "$APP/Contents/MacOS/nested" | head -1 }
osa() {
  osascript -e "tell application \"System Events\" to tell (first process whose unix id is $(pid_of))" -e "$1" -e "end tell"
}
front() { osascript -e 'tell application "System Events" to get name of first process whose frontmost is true' }
raise() {
  osa 'set frontmost to true' >/dev/null
  osa 'perform action "AXRaise" of window 1' >/dev/null 2>&1
  sleep 0.8
  [[ "$(front)" == nested ]] || { echo "ABORT: frontmost is $(front), not nested" >&2; exit 2 }
}
place() {
  osa "set position of window 1 to {$WIN_X, $WIN_Y}" >/dev/null
  osa "set size of window 1 to {$WIN_W, $WIN_H}" >/dev/null
  sleep 0.4
  osa 'get {position, size} of window 1' | tr -d ' '
}
idle() { ioreg -c IOHIDSystem | awk '/HIDIdleTime/ {print int($NF/1000000000); exit}' }
wait_idle() {
  local need=${1:-45}
  while (( $(idle) < need )); do echo "user active (idle $(idle)s), waiting"; sleep 15; done
}

ensure_front() {
  [[ "$(front)" == nested ]] && return
  echo "focus went to $(front); bringing Nested back" >&2
  osa 'set frontmost to true' >/dev/null; sleep 0.6
}

abs() { echo $((WIN_X + $1)) $((WIN_Y + $2)) }
move()  { ensure_front; read -r x y <<< "$(abs $1 $2)"; cliclick -e $EASING m:$x,$y }
click() { ensure_front; read -r x y <<< "$(abs $1 $2)"; cliclick -e $EASING m:$x,$y c:$x,$y }
select_text() {
  ensure_front
  read -r x1 y1 <<< "$(abs $1 $2)"; read -r x2 y2 <<< "$(abs $3 $4)"
  # The release goes twice: take 4 lost its mouse-up (the text stayed selected, the ask box never opened).
  cliclick -e $EASING m:$x1,$y1 w:120 dd:$x1,$y1 w:80 \
    dm:$((x1+(x2-x1)/4)),$((y1+(y2-y1)/4)) dm:$((x1+(x2-x1)/2)),$((y1+(y2-y1)/2)) \
    dm:$((x1+3*(x2-x1)/4)),$((y1+3*(y2-y1)/4)) dm:$x2,$y2 w:80 du:$x2,$y2 w:200 du:$x2,$y2
}
type_text() { ensure_front; cliclick -w $TYPING_MS "t:$1" }
key() {
  ensure_front
  local k=$1; shift
  local using=""
  if (( $# )); then
    local mods=(); for m in "$@"; do mods+=("$m down"); done
    using=" using {${(j:, :)mods}}"
  fi
  case $k in
    return) osascript -e "tell application \"System Events\" to key code 36$using" ;;
    escape) osascript -e "tell application \"System Events\" to key code 53$using" ;;
    *) osascript -e "tell application \"System Events\" to keystroke \"$k\"$using" ;;
  esac
}
mark() { echo "$(date +%s.%N) $1" >> marks.log; echo "· $1" }

case ${1:-} in
  launch)
    mkdir -p "$BACKUP" stills
    [[ -f "$BACKUP/settings.json" ]] || cp "$SUPPORT/settings.json" "$SUPPORT/recents.json" "$BACKUP/"
    python3 - "$SUPPORT/settings.json" "$THEME" <<'PY'
import json, sys
p = sys.argv[1]; s = json.load(open(p))
s.update(theme=sys.argv[2], sidebarWidth=240, offerDefaultApp=False, readingFont="serif", textSize=17)
s["readingWidth"] = {"em": 33, "percent": 85, "unit": "em"}
s["models"]["anthropic-subscription"] = "sonnet"
json.dump(s, open(p, "w"), indent=2)
PY
    [[ -d "$TAKE_DIR" ]] && mv "$TAKE_DIR" "$TAKE_DIR.$(date +%s)"
    mkdir -p "$TAKE_DIR" && cp -R "$CORPUS" "$TAKE_DIR/"
    wait_idle 45
    osascript -l JavaScript backdrop.js $((WIN_X-BACKDROP_PAD)) $((WIN_Y-BACKDROP_PAD)) $((WIN_W+2*BACKDROP_PAD)) $((WIN_H+2*BACKDROP_PAD)) "$PAGE_BG" 7200 &
    echo $! > .backdrop.pid; sleep 1
    open -a "$APP" "$TAKE_DIR/$(basename "$CORPUS")"; sleep 4
    echo "pid=$(pid_of) geometry=$(place) front=$(front) theme=$THEME"
    ;;
  place) place ;;
  raise) raise; front ;;
  click) click $2 $3 ;;
  move) move $2 $3 ;;
  sel) select_text $2 $3 $4 $5 ;;
  type) type_text "$2" ;;
  key) shift; key "$@" ;;
  idle) idle ;;
  shot)
    screencapture -x -R$WIN_X,$WIN_Y,$WIN_W,$WIN_H "stills/$2.png"; echo "stills/$2.png"
    ;;
  rec)
    case $2 in
      start)
        : > marks.log
        local dev=${SCREEN_DEV:-$(screen_device)} ppp=$(pixels_per_point)
        ffmpeg -y -hide_banner -loglevel error -f avfoundation -capture_cursor 1 -framerate 30 \
          -pixel_format uyvy422 -i "$dev:none" \
          -vf "crop=$((WIN_W*ppp)):$((WIN_H*ppp)):$((WIN_X*ppp)):$((WIN_Y*ppp))" \
          -c:v libx264 -preset veryfast -crf 16 -pix_fmt yuv420p raw.mp4 &
        echo $! > .ffmpeg.pid; sleep 1.5; mark "rec-start"
        ;;
      stop) kill -INT "$(cat .ffmpeg.pid)"; wait 2>/dev/null; sleep 1; mark "rec-stop"; ffprobe -v error -show_entries format=duration -of csv=p=0 raw.mp4 ;;
    esac
    ;;
  run)
    wait_idle 45
    raise; place >/dev/null
    $0 rec start
    source ./script.sh
    $0 rec stop
    ;;
  quit)
    osascript -e 'tell application id "app.nestedreader.nested" to quit'; sleep 1
    [[ -f .backdrop.pid ]] && { kill "$(cat .backdrop.pid)" 2>/dev/null; rm -f .backdrop.pid; }
    [[ -f "$BACKUP/settings.json" ]] && cp "$BACKUP/settings.json" "$BACKUP/recents.json" "$SUPPORT/" && echo "settings restored"
    ;;
  *) sed -n '2,12p' "$SELF" ;;
esac

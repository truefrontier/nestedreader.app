#!/bin/zsh
# Turns demo/raw.mp4 (the ffmpeg screen capture) into the files the page embeds for one theme:
# demo/demo-<theme>.mp4, demo/demo-<theme>.webm, demo/poster-<theme>.jpg.
#
# Still stretches (the model thinking, the generous sleeps in script.sh) are cut down to HOLD
# seconds each. A stretch is still when consecutive frames differ by less than STILL on the
# luma of a 640-wide grey copy; a blinking caret scores about 0.03, one streamed word about 2.
# The window's corners already carry the page colour (record.sh puts a backdrop behind it).
# Output is 1280x800 (1x), with the last frame held so the loop can rest.
#
#   demo/cut.sh                    # raw.mp4 → demo-light.*
#   THEME=dark demo/cut.sh         # raw.mp4 → demo-dark.*
#   RAW=raw-take2.mp4 demo/cut.sh
set -eu
cd "$(dirname "$0")"
RAW=${RAW:-raw.mp4}
HOLD=${HOLD:-1.0}            # seconds kept from each still stretch
MIN_STILL=${MIN_STILL:-1.0}  # a still stretch has to last this long to be cut
STILL=${STILL:-0.1}          # frame-to-frame luma difference below this is "nothing happened"
TAIL=${TAIL:-1.5}            # seconds the last frame is held
THEME=${THEME:-light}
OUT=demo-$THEME
W=1280; H=800

ffmpeg -hide_banner -loglevel error -i "$RAW" \
  -vf "fps=10,scale=640:-1,format=gray,tblend=all_mode=difference,signalstats,metadata=print:key=lavfi.signalstats.YAVG:file=.diff.txt" \
  -f null -
DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$RAW")

python3 - "$DUR" "$HOLD" "$MIN_STILL" "$STILL" > .keep.txt <<'PY'
import re, sys
dur, hold, min_still, still = map(float, sys.argv[1:5])
t, rows = None, []
for line in open('.diff.txt'):
    m = re.search(r'pts_time:([0-9.]+)', line)
    if m: t = float(m.group(1)); continue
    m = re.search(r'YAVG=([0-9.]+)', line)
    if m and t is not None: rows.append((t, float(m.group(1))))
stills, start = [], None
for t, v in rows + [(dur, 1.0)]:
    if v < still and start is None: start = t
    elif v >= still and start is not None:
        if t - start >= min_still: stills.append((start, t))
        start = None
keep, t = [], 0.0
for s, e in stills:
    keep.append((t, min(s + hold, e))); t = e
keep.append((t, dur))
for a, b in keep:
    if b - a > 0.05: print(f"{a:.3f} {b:.3f}")
PY
echo "raw ${DUR}s → keeping $(awk '{s+=$2-$1} END {printf "%.1f", s}' .keep.txt)s in $(wc -l < .keep.txt | tr -d ' ') pieces"

SEL=""; CAT=""; i=0
while read -r a b; do
  SEL+="[0:v]trim=start=${a}:end=${b},setpts=PTS-STARTPTS[p$i];"
  CAT+="[p$i]"; i=$((i+1))
done < .keep.txt
FILTER="${SEL}${CAT}concat=n=${i}:v=1:a=0,scale=${W}:${H}:flags=lanczos,tpad=stop_mode=clone:stop_duration=${TAIL},format=yuv420p[out]"

ffmpeg -y -hide_banner -loglevel error -i "$RAW" -filter_complex "$FILTER" -map "[out]" \
  -c:v libx264 -preset slow -crf 22 -movflags +faststart -r 30 "$OUT.mp4"
ffmpeg -y -hide_banner -loglevel error -i "$OUT.mp4" -c:v libvpx-vp9 -b:v 0 -crf 34 -row-mt 1 -an "$OUT.webm"
DUR_OUT=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT.mp4")
ffmpeg -y -hide_banner -loglevel error -ss "$(python3 -c "print(max(0.0, $DUR_OUT - 0.2))")" -i "$OUT.mp4" -frames:v 1 -q:v 3 "poster-$THEME.jpg"
ls -la "$OUT.mp4" "$OUT.webm" "poster-$THEME.jpg"; echo "demo ${DUR_OUT}s"

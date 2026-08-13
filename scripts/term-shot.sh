#!/bin/bash
# 证据引擎 term-shot: 无头真实终端截图 (Xvfb + xterm, Kali zsh 风格)
# 用法: term-shot.sh <repro脚本WSL路径> <输出png WSL路径>
set -u
export DISPLAY=:99
REPRO=$1
OUT=$2

pkill -f "Xvfb :99" 2>/dev/null
pkill xterm 2>/dev/null
rm -f /tmp/.X11-unix/X99 /tmp/.X99-lock /tmp/term_done
sleep 1

Xvfb :99 -screen 0 1440x900x24 -nolisten tcp >/tmp/xvfb_shot.log 2>&1 &
sleep 2

xterm -hold -geometry 180x52+0+0 -fa "DejaVu Sans Mono:size=13" \
  -xrm "XTerm*faceNameDoublesize: Droid Sans Fallback:size=13" \
  -bg "#000000" -fg "#ffffff" -cr "#abe047" \
  -xrm "XTerm*scrollBar:false" -xrm "XTerm*menuBar:false" \
  -xrm "XTerm*borderWidth:0" -xrm "XTerm*internalBorder:8" \
  -e "bash $REPRO; touch /tmp/term_done" >/tmp/xterm_shot.log 2>&1 &
sleep 2.5

for _ in $(seq 1 120); do
  [ -f /tmp/term_done ] && break
  sleep 0.5
done
sleep 1.5

xwd -root -out /tmp/term_shot.xwd 2>/dev/null
convert /tmp/term_shot.xwd "$OUT" 2>/dev/null
echo "TERM_SHOT_OK $(stat -c%s "$OUT")"

pkill xterm 2>/dev/null
sleep 0.5
kill %1 2>/dev/null || true

#!/bin/bash
# 证据引擎 term-shot: 无头真实终端截图 (Xvfb + xterm, Kali zsh 风格)
# 用法: term-shot.sh <repro脚本WSL路径> <输出png WSL路径>
# 每次渲染使用独立 display 与临时文件, 支持多会话并行互不干扰
set -u
REPRO=$1
OUT=$2
RID=$$
DISPNUM=$((1000 + RID % 8000))
export DISPLAY=:$DISPNUM
TERM_DONE=/tmp/term_done_$RID
XWD=/tmp/term_shot_$RID.xwd
XVFB_LOG=/tmp/xvfb_shot_$RID.log
XTERM_LOG=/tmp/xterm_shot_$RID.log
X_SOCK=/tmp/.X11-unix/X$DISPNUM
X_LOCK=/tmp/.X$DISPNUM-lock

start_xvfb() {
  rm -f "$X_SOCK" "$X_LOCK"
  Xvfb ":$DISPNUM" -screen 0 1440x900x24 -nolisten tcp >"$XVFB_LOG" 2>&1 &
  XVFB_PID=$!
  for _ in $(seq 1 20); do
    xdpyinfo -display ":$DISPNUM" >/dev/null 2>&1 && return 0
    kill -0 "$XVFB_PID" 2>/dev/null || return 1
    sleep 0.25
  done
  return 1
}

if ! start_xvfb; then
  kill "$XVFB_PID" 2>/dev/null
  sleep 0.5
  rm -f "$X_SOCK" "$X_LOCK"
  start_xvfb || { echo "TERM_SHOT_XVFB_FAIL"; exit 2; }
fi

xterm -hold -geometry 180x52+0+0 -fa "DejaVu Sans Mono:size=13" \
  -xrm "XTerm*faceNameDoublesize: Droid Sans Fallback:size=13" \
  -bg "#000000" -fg "#ffffff" -cr "#abe047" \
  -xrm "XTerm*scrollBar:false" -xrm "XTerm*menuBar:false" \
  -xrm "XTerm*borderWidth:0" -xrm "XTerm*internalBorder:8" \
  -e "bash $REPRO; touch $TERM_DONE" >"$XTERM_LOG" 2>&1 &
sleep 2.5

for _ in $(seq 1 120); do
  [ -f "$TERM_DONE" ] && break
  sleep 0.5
done
sleep 1.5

xwd -display ":$DISPNUM" -root -out "$XWD" 2>/dev/null
convert "$XWD" "$OUT" 2>/dev/null
echo "TERM_SHOT_OK $(stat -c%s "$OUT")"

pkill -P $$ 2>/dev/null
kill "$XVFB_PID" 2>/dev/null
rm -f "$TERM_DONE" "$XWD" "$X_SOCK" "$X_LOCK"
exit 0

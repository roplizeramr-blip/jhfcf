#!/bin/bash
current=$(setxkbmap -query 2>/dev/null | awk '/layout/{print $2}')
if [[ "$current" == *"ar"* ]]; then
  setxkbmap -layout us,ar -option grp:alt_shift_toggle 2>/dev/null || true
  notify-send -t 1500 "Keyboard Layout" "Switched to English (US)" 2>/dev/null || true
else
  setxkbmap -layout ar,us -option grp:alt_shift_toggle 2>/dev/null || true
  notify-send -t 1500 "Keyboard Layout" "Switched to Arabic" 2>/dev/null || true
fi

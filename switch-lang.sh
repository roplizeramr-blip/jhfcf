#!/bin/bash
CURRENT=$(setxkbmap -query | awk '/layout/{print $2}')
if [[ "$CURRENT" == *"ar"* && "$CURRENT" == "ar,us"* ]]; then
  setxkbmap -layout us,ar -option grp:alt_shift_toggle
  notify-send -t 1500 "Keyboard Layout" "Switched to: English (US)" 2>/dev/null || true
else
  setxkbmap -layout ar,us -option grp:alt_shift_toggle
  notify-send -t 1500 "لوحة المفاتيح" "تم التحويل إلى: العربية" 2>/dev/null || true
fi

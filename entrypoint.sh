#!/bin/bash
set -e

mkdir -p /home/kasm_user/.vnc
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null || true

vncserver :1 \
  -geometry 1280x720 \
  -depth 24 \
  -interface 0.0.0.0 \
  -websocketPort 3000 \
  -httpd /usr/share/kasmvnc/www \
  -sslOnly 0 \
  -select-de openbox

sleep 2

if compgen -G "/home/kasm_user/.vnc/*.log" > /dev/null; then
    tail -f /home/kasm_user/.vnc/*.log
else
    tail -f /dev/null
fi

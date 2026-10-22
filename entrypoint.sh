#!/bin/bash
set -e

# Remove stale X11 locks
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null || true

# Launch Xvnc directly on port 3000 without wrapper prompts
Xvnc :1 \
  -geometry 1280x720 \
  -depth 24 \
  -interface 0.0.0.0 \
  -websocketPort 3000 \
  -httpd /usr/share/kasmvnc/www \
  -sslOnly 0 \
  -SecurityTypes None \
  -disableBasicAuth &

# Wait for Xvnc display to initialize
sleep 2

export DISPLAY=:1

# Launch taskbar and terminal
tint2 &
xterm -geometry 100x30+50+50 &

# Start Openbox session as foreground process
exec openbox-session

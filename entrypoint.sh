#!/bin/bash
set -e

# Remove stale X11 locks
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null || true

# Start supervisord daemon if not running
if ! pgrep -x "supervisord" >/dev/null 2>&1; then
  sudo supervisord -c /etc/supervisor/supervisord.conf 2>/dev/null || supervisord -c /etc/supervisor/supervisord.conf 2>/dev/null || true
  sleep 1
  sudo chmod 777 /var/run/supervisor.sock 2>/dev/null || true
fi

# Reload systemctl emulation to pick up all unit files
systemctl daemon-reload 2>/dev/null || true

# Start default enabled services
systemctl start sample-service 2>/dev/null || true
systemctl start web-terminal 2>/dev/null || true

# Launch Xvnc directly on port 3000
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

# Configure keyboard layout (Alt+Shift toggle)
setxkbmap -layout us,ar -option grp:alt_shift_toggle &

# Disable power manager DPMS and screensaver to prevent black screen
xset s off -dpms 2>/dev/null || true

# Start complete XFCE4 desktop session with D-Bus
exec dbus-launch --exit-with-session startxfce4

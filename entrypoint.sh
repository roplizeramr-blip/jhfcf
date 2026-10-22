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

# Disable screensaver and DPMS
xset s off -dpms 2>/dev/null || true

# Initialize D-Bus session if not present
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
  eval $(dbus-launch --sh-syntax)
  export DBUS_SESSION_BUS_ADDRESS
fi

# Ensure default panel xml exists
if [ ! -f /home/kasm_user/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml ] && [ -f /etc/xdg/xfce4/panel/default.xml ]; then
  mkdir -p /home/kasm_user/.config/xfce4/xfconf/xfce-perchannel-xml
  cp /etc/xdg/xfce4/panel/default.xml /home/kasm_user/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
fi

# Launch XFCE core components
xfsettingsd &
xfwm4 &
xfce4-panel &
thunar --daemon &
xfdesktop &

# Watchdog loop to monitor and keep XFCE components running
while true; do
  if ! pgrep -x "Xvnc" >/dev/null 2>&1; then
    echo "Xvnc died, exiting..."
    exit 1
  fi
  if ! pgrep -x "xfwm4" >/dev/null 2>&1; then
    xfwm4 &
  fi
  if ! pgrep -x "xfce4-panel" >/dev/null 2>&1; then
    xfce4-panel &
  fi
  if ! pgrep -x "xfdesktop" >/dev/null 2>&1; then
    xfdesktop &
  fi
  sleep 3
done

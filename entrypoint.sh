#!/bin/bash
set -e

# =========================================================
# XDG Base Directory Setup (CRITICAL for XFCE in containers)
# Without these, xfce4-panel/xfdesktop get NULL paths & segfault
# =========================================================
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_RUNTIME_DIR="/tmp/runtime-kasm_user"
export XDG_DATA_DIRS="/usr/local/share:/usr/share"
export XDG_CONFIG_DIRS="/etc/xdg"

mkdir -p "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

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
for i in $(seq 1 20); do
  if xdpyinfo -display :1 >/dev/null 2>&1; then
    break
  fi
  sleep 0.5
done

export DISPLAY=:1

# Configure keyboard layout (Alt+Shift toggle)
setxkbmap -layout us,ar -option grp:alt_shift_toggle &

# Disable screensaver and DPMS
xset s off -dpms 2>/dev/null || true

# =========================================================
# D-Bus Session Bus (required for XFCE components)
# =========================================================
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
  eval $(dbus-launch --sh-syntax)
  export DBUS_SESSION_BUS_ADDRESS
  export DBUS_SESSION_BUS_PID
fi

# =========================================================
# Ensure XFCE config directories and panel XML exist
# =========================================================
mkdir -p "$XDG_CONFIG_HOME/xfce4/xfconf/xfce-perchannel-xml"
mkdir -p "$XDG_CONFIG_HOME/xfce4/panel"
mkdir -p "$XDG_CONFIG_HOME/xfce4/desktop"
mkdir -p "$XDG_DATA_HOME/xfce4/helpers"
mkdir -p "$XDG_CACHE_HOME/xfce4"

# Use our pre-configured panel XML (already in image via COPY)
# If it doesn't exist, copy from default
if [ ! -f "$XDG_CONFIG_HOME/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" ]; then
  if [ -f /etc/xdg/xfce4/panel/default.xml ]; then
    cp /etc/xdg/xfce4/panel/default.xml "$XDG_CONFIG_HOME/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"
  fi
fi

# =========================================================
# Mark .desktop files as trusted (so xfdesktop shows icons)
# =========================================================
if [ -d "$HOME/Desktop" ]; then
  for f in $HOME/Desktop/*.desktop; do
    [ -f "$f" ] && chmod +x "$f"
    # GIO trusted flag
    gio set "$f" metadata::trusted true 2>/dev/null || true
  done
fi

# =========================================================
# Launch XFCE Core Components (staggered for stability)
# =========================================================
echo "Starting xfsettingsd..."
xfsettingsd --no-daemon &
sleep 0.5

echo "Starting xfwm4..."
xfwm4 --compositor=off &
sleep 0.5

echo "Starting xfce4-panel..."
xfce4-panel --disable-wm-check &
sleep 1

echo "Starting thunar daemon..."
thunar --daemon &
sleep 0.5

echo "Starting xfdesktop..."
xfdesktop --disable-wm-check &
sleep 1

echo "XFCE Desktop is ready."

# =========================================================
# Watchdog loop - restart crashed XFCE components
# =========================================================
while true; do
  if ! pgrep -x "Xvnc" >/dev/null 2>&1; then
    echo "Xvnc died, exiting..."
    exit 1
  fi
  if ! pgrep -x "xfwm4" >/dev/null 2>&1; then
    echo "Restarting xfwm4..."
    xfwm4 --compositor=off &
  fi
  if ! pgrep -x "xfce4-panel" >/dev/null 2>&1; then
    echo "Restarting xfce4-panel..."
    xfce4-panel --disable-wm-check &
  fi
  if ! pgrep -x "xfdesktop" >/dev/null 2>&1; then
    echo "Restarting xfdesktop..."
    xfdesktop --disable-wm-check &
  fi
  if ! pgrep -x "xfsettingsd" >/dev/null 2>&1; then
    echo "Restarting xfsettingsd..."
    xfsettingsd --no-daemon &
  fi
  sleep 5
done

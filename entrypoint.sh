#!/bin/bash
set -e

# As root: clean and initialize runtime directories
rm -rf /tmp/.X11-unix /tmp/.X*-lock 2>/dev/null || true
mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

# Ensure kasm_user owns their home directory
chown -R kasm_user:ssl-cert /home/kasm_user

# Run desktop session as kasm_user
exec su - kasm_user -c "/home/kasm_user/start-desktop.sh"

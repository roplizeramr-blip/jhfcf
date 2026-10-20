#!/bin/sh
set -eu

# Require credentials instead of exposing a root shell without authentication.
: "${TTYD_USER:?Set TTYD_USER in the app environment}"
: "${TTYD_PASSWORD:?Set TTYD_PASSWORD in the app environment}"

# Keep the credential format simple for a systemd EnvironmentFile.
case "$TTYD_USER$TTYD_PASSWORD" in
  *[!A-Za-z0-9_.@%-]*)
    echo "ERROR: TTYD_USER and TTYD_PASSWORD may contain only letters, digits, underscore, dot, @, percent, and hyphen." >&2
    exit 1
    ;;
esac

if [ "${#TTYD_PASSWORD}" -lt 16 ]; then
  echo "ERROR: TTYD_PASSWORD must be at least 16 characters." >&2
  exit 1
fi

install -d -m 0755 /run
umask 077
printf 'TTTYD_CREDENTIALS=%s:%s\n' "$TTYD_USER" "$TTYD_PASSWORD" > /run/ttyd.env
chmod 0600 /run/ttyd.env

exec /lib/systemd/systemd

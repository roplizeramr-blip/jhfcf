# Debian 13 systemd + browser terminal

Minimal Debian 13 container based on `jrei/systemd-debian:13`, with a browser-accessible terminal powered by `ttyd`.

## Features

- Debian 13 (Trixie)
- systemd as PID 1; the web terminal runs as a systemd service
- Browser terminal on port `3000`
- HTTP Basic Authentication via ttyd credentials
- Supports amd64 and arm64 builds when the base image and platform support them

## Deploy on CranL

1. Create an app from this GitHub repository and select Dockerfile-based build.
2. Configure the app's listening port as `3000`.
3. Set these environment variables in the app settings:
   - `TTYD_USER`: a username using letters, digits, underscore, dot, @, percent, or hyphen
   - `TTYD_PASSWORD`: a strong password of at least 16 characters, using the same allowed characters
4. Deploy and open the app's HTTPS URL.

Do not commit credentials to this repository. The container intentionally exits if credentials are missing.

## Important runtime limitation

The base image uses real systemd. Some managed container platforms restrict cgroups, writable `/sys/fs/cgroup`, or init-process behavior; in that case the image may not start even if the build succeeds. The platform must allow systemd to run as PID 1. This image does not require `--privileged` at build time, but runtime support for systemd depends on the host.

## Local Docker example

```sh
docker build -t debian-systemd-web-terminal .
docker run -d --name debian-systemd-web-terminal \
  --tmpfs /run --tmpfs /run/lock --tmpfs /tmp \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  -e TTYD_USER=terminaladmin \
  -e TTYD_PASSWORD='replace-with-a-long-random-password' \
  -p 3000:3000 \
  debian-systemd-web-terminal
```

If systemd fails to initialize, consult the platform runtime logs. Never expose an unauthenticated root shell to the public internet.

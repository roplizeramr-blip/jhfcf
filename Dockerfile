FROM jrei/systemd-debian:13

ENV DEBIAN_FRONTEND=noninteractive
ARG TARGETARCH

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && case "${TARGETARCH:-amd64}" in \
         amd64) TTYD_ARCH="x86_64" ;; \
         arm64) TTYD_ARCH="aarch64" ;; \
         *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
       esac \
    && curl -fsSL --retry 3 "https://github.com/tsl0922/ttyd/releases/latest/download/ttyd.${TTYD_ARCH}" -o /usr/local/bin/ttyd \
    && chmod 0755 /usr/local/bin/ttyd \
    && /usr/local/bin/ttyd --version \
    && apt-get purge -y --auto-remove curl \
    && rm -rf /var/lib/apt/lists/* /tmp/*

COPY web-terminal.service /etc/systemd/system/web-terminal.service
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 0755 /usr/local/bin/entrypoint.sh \
    && systemctl enable web-terminal.service

EXPOSE 3000
STOPSIGNAL SIGRTMIN+3
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

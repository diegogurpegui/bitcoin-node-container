FROM mempool/backend:v3.3.1

USER root

RUN apt-get update && apt-get install -y \
    tor \
    supervisor \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/log/supervisor \
    && (getent group 1000 >/dev/null || groupadd -g 1000 mempool) \
    && (getent passwd 1000 >/dev/null || useradd -r -u 1000 -g 1000 -M -d /backend -s /usr/sbin/nologin mempool)

COPY torrc /etc/tor/torrc
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

HEALTHCHECK --interval=1m --timeout=15s --start-period=2m --retries=3 \
  CMD curl -f http://127.0.0.1:8999/api/v1/backend-info || exit 1

ENTRYPOINT ["/usr/bin/supervisord"]
CMD ["-c", "/etc/supervisor/conf.d/supervisord.conf"]

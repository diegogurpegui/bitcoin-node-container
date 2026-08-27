FROM mempool/frontend:v3.3.1

USER root

RUN apk add --no-cache tor supervisor su-exec \
    && mkdir -p /var/lib/tor/mempool_hidden_service /var/log/supervisor \
    && chown -R tor:tor /var/lib/tor \
    && chmod 700 /var/lib/tor/mempool_hidden_service \
    && (getent group 1000 >/dev/null || addgroup -g 1000 mempool) \
    && (getent passwd 1000 >/dev/null || adduser -D -H -u 1000 -G "$(getent group 1000 | cut -d: -f1)" mempool)

COPY torrc /etc/tor/torrc
COPY start-tor.sh /usr/local/bin/start-tor.sh
COPY supervisord.conf /etc/supervisord.conf
RUN chmod 755 /usr/local/bin/start-tor.sh

HEALTHCHECK --interval=1m --timeout=15s --start-period=2m --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1:8080/ || exit 1

ENTRYPOINT ["/usr/bin/supervisord"]
CMD ["-c", "/etc/supervisord.conf"]

FROM ghcr.io/copexit/am-i-exposed-umbrel:v0.35.7

USER root

RUN apk add --no-cache tor supervisor su-exec \
    && mkdir -p /var/lib/tor/amiexposed_hidden_service /var/log/supervisor \
    && chown -R tor:tor /var/lib/tor \
    && chmod 700 /var/lib/tor/amiexposed_hidden_service

COPY torrc /etc/tor/torrc
COPY start-tor.sh /usr/local/bin/start-tor.sh
COPY start-nginx.sh /usr/local/bin/start-nginx.sh
COPY supervisord.conf /etc/supervisord.conf
RUN chmod 755 /usr/local/bin/start-tor.sh /usr/local/bin/start-nginx.sh

HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8080/health || exit 1

ENTRYPOINT ["/usr/bin/supervisord"]
CMD ["-c", "/etc/supervisord.conf"]

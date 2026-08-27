FROM ghcr.io/copexit/am-i-exposed-tor-proxy:v0.35.7

USER root

RUN apk add --no-cache tor supervisor su-exec \
    && mkdir -p /var/lib/tor /var/log/supervisor \
    && chown -R tor:tor /var/lib/tor \
    && chmod 700 /var/lib/tor

COPY torrc /etc/tor/torrc
COPY start-tor.sh /usr/local/bin/start-tor.sh
COPY supervisord.conf /etc/supervisord.conf
RUN chmod 755 /usr/local/bin/start-tor.sh

ENV PORT=3001
ENV TOR_PROXY_IP=127.0.0.1
ENV TOR_PROXY_PORT=9050

HEALTHCHECK --interval=30s --timeout=3s --start-period=20s --retries=3 \
  CMD node -e "require('http').get('http://127.0.0.1:3001/health',(r)=>process.exit(r.statusCode===200?0:1))"

ENTRYPOINT ["/usr/bin/supervisord"]
CMD ["-c", "/etc/supervisord.conf"]

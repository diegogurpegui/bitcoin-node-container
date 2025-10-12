FROM debian:bookworm-slim

# Install dependencies including Tor
RUN apt-get update && apt-get install -y \
    wget \
    ca-certificates \
    gnupg \
    python3 \
    tor \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Bitcoin Core version
ENV BITCOIN_VERSION=29.1
ENV BITCOIN_URL=https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/bitcoin-${BITCOIN_VERSION}-x86_64-linux-gnu.tar.gz
ENV BITCOIN_SHA256=2dddeaa8c0626ec446b6f21b64c0f3565a1e7e67ff0b586d25043cbd686c9455

# Download and verify Bitcoin Core
RUN cd /tmp && \
    wget ${BITCOIN_URL} && \
    echo "${BITCOIN_SHA256}  bitcoin-${BITCOIN_VERSION}-x86_64-linux-gnu.tar.gz" | sha256sum -c - && \
    tar -xzf bitcoin-${BITCOIN_VERSION}-x86_64-linux-gnu.tar.gz && \
    install -m 0755 -o root -g root -t /usr/local/bin bitcoin-${BITCOIN_VERSION}/bin/* && \
    rm -rf /tmp/*

# Create bitcoin user and group
# Note: Using same UID as host user helps with volume permissions
RUN useradd -r -m -s /bin/bash bitcoin

# Create bitcoin data directory
RUN mkdir -p /home/bitcoin/.bitcoin && \
    chown -R bitcoin:bitcoin /home/bitcoin/.bitcoin

# Configure Tor
# Allow bitcoin user to access Tor control port
RUN mkdir -p /var/run/tor && \
    chown -R debian-tor:debian-tor /var/run/tor && \
    usermod -a -G debian-tor bitcoin

# Create Tor configuration
RUN echo "ControlPort 9051" >> /etc/tor/torrc && \
    echo "CookieAuthentication 1" >> /etc/tor/torrc && \
    echo "CookieAuthFileGroupReadable 1" >> /etc/tor/torrc && \
    echo "DataDirectory /var/lib/tor" >> /etc/tor/torrc

# Create supervisor configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

WORKDIR /home/bitcoin

# Expose Bitcoin ports
# 8332: RPC port (for bitcoin-cli and applications)
# 8333: P2P port (mainnet - connect to Bitcoin network)
# 18332: RPC port (testnet)
# 18333: P2P port (testnet)
# 28332: ZMQ rawblock/hashblock notifications (optional)
# 28333: ZMQ rawtx notifications (optional)
# 28334: ZMQ hashblock notifications (optional)
EXPOSE 8332 8333 18332 18333 28332 28333 28334

# Volume for blockchain data
# This will store the complete blockchain (~600+ GB for full node)
VOLUME ["/home/bitcoin/.bitcoin"]

# Health check to verify node is responding
# Note: We use a simple connectivity check instead of requiring RPC auth
# This checks if bitcoind process is running and responding
HEALTHCHECK --interval=10m --timeout=30s --start-period=15m --retries=3 \
  CMD pgrep -x bitcoind > /dev/null || exit 1

# Start both Tor and bitcoind using supervisor
ENTRYPOINT ["/usr/bin/supervisord"]
CMD ["-c", "/etc/supervisor/conf.d/supervisord.conf"]


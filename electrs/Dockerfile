FROM debian:bookworm-slim

# Install dependencies for building Electrs and Tor
RUN apt-get update && apt-get install -y \
    cargo \
    clang \
    cmake \
    git \
    curl \
    gpg \
    ca-certificates \
    tor \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Electrs version (set as build arg to avoid environment variable conflicts)
ARG ELECTRS_VERSION=0.10.10

# Create electrs user and group
RUN useradd -r -m -s /bin/bash electrs

# Create electrs data directory
RUN mkdir -p /data/electrs/db && \
    chown -R electrs:electrs /data/electrs

# Download and verify Electrs source code
RUN cd /tmp && \
    git clone --branch v${ELECTRS_VERSION} https://github.com/romanz/electrs.git && \
    cd electrs && \
    curl https://romanzey.de/pgp.txt | gpg --import && \
    git verify-tag v${ELECTRS_VERSION}

# Build Electrs
RUN cd /tmp/electrs && \
    cargo build --locked --release && \
    install -m 0755 -o root -g root -t /usr/local/bin target/release/electrs && \
    rm -rf /tmp/electrs

# Configure Tor for electrs hidden service
RUN echo "# Tor configuration for electrs hidden service" > /etc/tor/torrc && \
    echo "SocksPort 0" >> /etc/tor/torrc && \
    echo "ControlPort 9051" >> /etc/tor/torrc && \
    echo "CookieAuthentication 1" >> /etc/tor/torrc && \
    echo "CookieAuthFile /var/lib/tor/control_auth_cookie" >> /etc/tor/torrc && \
    echo "DataDirectory /var/lib/tor" >> /etc/tor/torrc && \
    echo "" >> /etc/tor/torrc && \
    echo "# Hidden service for electrs" >> /etc/tor/torrc && \
    echo "HiddenServiceDir /var/lib/tor/electrs_hidden_service" >> /etc/tor/torrc && \
    echo "HiddenServicePort 50001 127.0.0.1:50001" >> /etc/tor/torrc

# Create Tor directories and set permissions
RUN mkdir -p /var/lib/tor/electrs_hidden_service && \
    chown -R electrs:electrs /var/lib/tor && \
    chmod 700 /var/lib/tor/electrs_hidden_service

# Copy supervisor configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy electrs configuration
COPY electrs.toml /data/electrs/electrs.toml

# Create electrs home directory and config symlink
RUN mkdir -p /home/electrs/.electrs && \
    chown -R electrs:electrs /home/electrs

# Health check
HEALTHCHECK --interval=10m --timeout=30s --start-period=15m --retries=3 \
  CMD pgrep -x electrs > /dev/null || exit 1

# Start both Tor and electrs using supervisor
ENTRYPOINT ["/usr/bin/supervisord"]
CMD ["-c", "/etc/supervisor/conf.d/supervisord.conf"]

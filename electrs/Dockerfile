FROM rust:1.85-bookworm AS builder

ARG ELECTRS_VERSION=0.11.1
ARG ELECTRS_COMMIT=35216c6d30148be8e6763d913d437330f431fc03

RUN apt-get update && apt-get install -y \
    git \
    ca-certificates \
    clang \
    libclang-dev \
    llvm \
    cmake \
    && rm -rf /var/lib/apt/lists/*

# Download Electrs source at the pinned release tag and verify commit
RUN cd /tmp && \
    git clone --branch v${ELECTRS_VERSION} https://github.com/romanz/electrs.git && \
    cd electrs && \
    test "$(git rev-parse HEAD)" = "${ELECTRS_COMMIT}" && \
    test "$(git rev-parse v${ELECTRS_VERSION}^{commit})" = "${ELECTRS_COMMIT}"

# Build Electrs
RUN cd /tmp/electrs && \
    cargo build --locked --release

FROM debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    tor \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /tmp/electrs/target/release/electrs /usr/local/bin/electrs

# Create electrs user and group
RUN useradd -r -m -s /bin/bash electrs

# Create electrs data directory
RUN mkdir -p /data/electrs/db && \
    chown -R electrs:electrs /data/electrs

# Copy Tor configuration
COPY torrc /etc/tor/torrc

# Create Tor directories and set permissions
RUN mkdir -p /var/lib/tor/electrs_hidden_service && \
    chown -R electrs:electrs /var/lib/tor && \
    chmod 700 /var/lib/tor/electrs_hidden_service

# Copy supervisor configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create electrs home directory
RUN mkdir -p /home/electrs/.electrs && \
    chown -R electrs:electrs /home/electrs

# Health check
HEALTHCHECK --interval=10m --timeout=30s --start-period=15m --retries=3 \
  CMD pgrep -x electrs > /dev/null || exit 1

# Start both Tor and electrs using supervisor
ENTRYPOINT ["/usr/bin/supervisord"]
CMD ["-c", "/etc/supervisor/conf.d/supervisord.conf"]

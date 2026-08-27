#!/bin/sh
set -e
# Bind-mounted HiddenServiceDir is often 755; Tor requires 700.
mkdir -p /var/lib/tor/amiexposed_hidden_service
chown -R tor:tor /var/lib/tor
chmod 700 /var/lib/tor /var/lib/tor/amiexposed_hidden_service
find /var/lib/tor/amiexposed_hidden_service -type f -exec chmod 600 {} \;
exec su-exec tor /usr/bin/tor -f /etc/tor/torrc

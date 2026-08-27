#!/bin/sh
set -e
mkdir -p /var/lib/tor
chown -R tor:tor /var/lib/tor
chmod 700 /var/lib/tor
exec su-exec tor /usr/bin/tor -f /etc/tor/torrc

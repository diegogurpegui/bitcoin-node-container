#!/bin/sh
set -e
mkdir -p /var/lib/tor/electrs_hidden_service
chown -R electrs:electrs /var/lib/tor
chmod 700 /var/lib/tor /var/lib/tor/electrs_hidden_service
find /var/lib/tor/electrs_hidden_service -type f -exec chmod 600 {} \;
exec runuser -u electrs -- /usr/bin/tor -f /etc/tor/torrc

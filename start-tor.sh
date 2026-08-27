#!/bin/sh
set -e
mkdir -p /var/lib/tor
chown -R debian-tor:debian-tor /var/lib/tor
chmod 700 /var/lib/tor
exec runuser -u debian-tor -- /usr/bin/tor

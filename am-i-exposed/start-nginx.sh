#!/bin/sh
set -e
# Explorer links: pick up mempool-web's onion if it already exists.
if [ -f /run/mempool_hidden_service/hostname ]; then
  APP_MEMPOOL_HIDDEN_SERVICE=$(tr -d '\n' < /run/mempool_hidden_service/hostname)
  export APP_MEMPOOL_HIDDEN_SERVICE
fi
export APP_MEMPOOL_EXTERNAL_URL="${APP_MEMPOOL_EXTERNAL_URL:-}"
exec /docker-entrypoint.sh nginx -g 'daemon off;'

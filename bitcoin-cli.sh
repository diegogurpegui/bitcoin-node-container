#!/bin/bash
#
# Bitcoin CLI Wrapper Script
# This script sources the .env file and passes commands to bitcoin-cli inside the container
#

# Check if .env file exists
if [ ! -f .env ]; then
    echo "Error: .env file not found!"
    echo "Please copy .env.template to .env and configure it first."
    exit 1
fi

# Source the .env file
source .env

# Check if required variables are set
if [ -z "$BITCOIN_RPC_USER" ] || [ -z "$BITCOIN_RPC_PASSWORD" ]; then
    echo "Error: BITCOIN_RPC_USER or BITCOIN_RPC_PASSWORD not set in .env"
    exit 1
fi

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME:-bitcoin-core-node}$"; then
    echo "Error: Container '${CONTAINER_NAME:-bitcoin-core-node}' is not running"
    echo "Start it with: docker-compose up -d"
    exit 1
fi

# Execute bitcoin-cli command
docker exec ${CONTAINER_NAME:-bitcoin-core-node} bitcoin-cli \
    -rpcuser="${BITCOIN_RPC_USER}" \
    -rpcpassword="${BITCOIN_RPC_PASSWORD}" \
    "$@"


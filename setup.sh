#!/bin/bash
#
# Bitcoin Core Node Setup Script
# This script helps you configure your Bitcoin node setup
# Based on RaspiBolt guide: https://raspibolt.org/guide/bitcoin/bitcoin-client.html#generate-access-credentials
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "Bitcoin Core Docker Setup"
echo "=========================================="
echo ""

# Check if rpcauth.py exists
if [ ! -f "rpcauth.py" ]; then
    echo -e "${RED}Error: rpcauth.py not found!${NC}"
    echo "This script is required from Bitcoin Core."
    exit 1
fi

# Make rpcauth.py executable
chmod +x rpcauth.py

# Check if .env already exists
if [ -f .env ]; then
    read -p ".env file already exists. Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Setup cancelled. Using existing .env file."
        exit 0
    fi
fi

# Copy .env.template to .env
cp .env.template .env
echo "✓ Created .env file from template"
echo ""

# Prompt for external drive path
echo "Step 1: Configure External Drive Path"
echo "--------------------------------------"
read -p "Enter the full path to your external drive Bitcoin data directory (e.g., /mnt/external-drive/bitcoin-data): " DATA_PATH

if [ -z "$DATA_PATH" ]; then
    echo "Error: Path cannot be empty"
    exit 1
fi

# Update BITCOIN_DATA_PATH in .env
sed -i "s|BITCOIN_DATA_PATH=.*|BITCOIN_DATA_PATH=${DATA_PATH}|" .env
echo "✓ Set data path to: ${DATA_PATH}"
echo ""

# Create directory if it doesn't exist
if [ ! -d "$DATA_PATH" ]; then
    read -p "Directory doesn't exist. Do you want to create it? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        mkdir -p "$DATA_PATH"
        echo "✓ Created directory: ${DATA_PATH}"
        
        # Set permissions
        USER_ID=$(id -u)
        GROUP_ID=$(id -g)
        chown -R ${USER_ID}:${GROUP_ID} "$DATA_PATH" 2>/dev/null || {
            echo "⚠ Could not set permissions automatically. You may need to run:"
            echo "  sudo chown -R ${USER_ID}:${GROUP_ID} ${DATA_PATH}"
        }
    fi
fi
echo ""

# Network selection
echo "Step 2: Select Network"
echo "--------------------------------------"
echo "1) Mainnet (default)"
echo "2) Testnet"
echo "3) Regtest"
read -p "Select network (1-3, default: 1): " NETWORK_CHOICE

case $NETWORK_CHOICE in
    2)
        sed -i 's/RPC_PORT=.*/RPC_PORT=18332/' .env
        sed -i 's/P2P_PORT=.*/P2P_PORT=18333/' .env
        echo "✓ Configured for Testnet"
        echo "⚠ Remember to uncomment 'testnet=1' in bitcoin.conf"
        ;;
    3)
        sed -i 's/RPC_PORT=.*/RPC_PORT=18443/' .env
        sed -i 's/P2P_PORT=.*/P2P_PORT=18444/' .env
        echo "✓ Configured for Regtest"
        echo "⚠ Remember to uncomment 'regtest=1' in bitcoin.conf"
        ;;
    *)
        echo "✓ Configured for Mainnet"
        ;;
esac
echo ""

# Generate RPC credentials using Bitcoin Core's official rpcauth.py
echo "Step 3: Configure RPC Authentication"
echo "--------------------------------------"
echo "Generating secure RPC credentials using Bitcoin Core's rpcauth.py..."
echo ""

RPC_USER="bitcoin"

# Use rpcauth.py with --json flag to get structured output
# Pass empty password argument to auto-generate a secure password
RPC_OUTPUT=$(python3 rpcauth.py "${RPC_USER}" --json)

# Parse JSON output
RPC_PASSWORD=$(echo "${RPC_OUTPUT}" | python3 -c "import sys, json; print(json.load(sys.stdin)['password'])")
RPC_AUTH_LINE=$(echo "${RPC_OUTPUT}" | python3 -c "import sys, json; print(json.load(sys.stdin)['rpcauth'])")

echo "✓ Generated secure RPC credentials using official Bitcoin Core rpcauth.py"
echo ""

# Update RPC credentials in .env (replace existing placeholders)
sed -i "s|BITCOIN_RPC_USER=.*|BITCOIN_RPC_USER=${RPC_USER}|" .env
sed -i "s|BITCOIN_RPC_PASSWORD=.*|BITCOIN_RPC_PASSWORD=${RPC_PASSWORD}|" .env

echo "✓ Updated RPC credentials in .env file"
echo ""

# Create bitcoin.conf in the data directory
echo "Step 4: Creating bitcoin.conf"
echo "--------------------------------------"

BITCOIN_CONF="${DATA_PATH}/bitcoin.conf"

# Copy the template bitcoin.conf from the repo
cp bitcoin.conf "${BITCOIN_CONF}"

# Replace the placeholder rpcauth line with the generated one
sed -i "s|rpcauth=bitcoin:SETUP_SCRIPT_WILL_GENERATE_THIS|rpcauth=${RPC_AUTH_LINE}|" "${BITCOIN_CONF}"

chmod 600 "${BITCOIN_CONF}"
echo "✓ Created bitcoin.conf at: ${BITCOIN_CONF}"
echo ""

# Set secure permissions on .env
chmod 600 .env
echo "✓ Set secure permissions on .env file"
echo ""

# Summary
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo -e "${GREEN}Configuration Summary:${NC}"
echo "  Data Path: ${DATA_PATH}"
echo "  Config File: ${BITCOIN_CONF}"
echo "  RPC User: ${RPC_USER}"
echo ""
echo -e "${YELLOW}⚠ IMPORTANT - Save these credentials securely:${NC}"
echo "  RPC Password: ${RPC_PASSWORD}"
echo "  (This password is also saved in your .env file)"
echo ""
echo -e "${GREEN}Next Steps:${NC}"
echo "  1. Review bitcoin.conf if you want to customize settings"
echo "     Location: ${BITCOIN_CONF}"
echo "  2. Build the container: docker-compose build"
echo "  3. Start the node: docker-compose up -d"
echo "  4. Check logs: docker-compose logs -f"
echo "  5. Use helper script: ./bitcoin-cli.sh getblockchaininfo"
echo ""
echo -e "${YELLOW}⚠ SECURITY NOTES:${NC}"
echo "  - Keep your .env file secure (chmod 600 already applied)"
echo "  - Never commit .env to version control"
echo "  - Your RPC password has been securely generated using Bitcoin Core's rpcauth.py"
echo "  - bitcoin.conf contains only the hash (HMAC-SHA256), not the plain password"
echo "  - For more details, see: RPCAUTH.md"
echo ""


#!/bin/bash
#
# Manual RPC Credential Generator
# Use this if you need to generate credentials outside of setup.sh
# Based on RaspiBolt guide: https://raspibolt.org/guide/bitcoin/bitcoin-client.html#generate-access-credentials
#

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if rpcauth.py exists
if [ ! -f "rpcauth.py" ]; then
    echo "Error: rpcauth.py not found!"
    exit 1
fi

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo "Error: python3 is not installed!"
    exit 1
fi

echo "=========================================="
echo "Bitcoin RPC Credential Generator"
echo "Using Bitcoin Core's official rpcauth.py"
echo "=========================================="
echo ""

# Get username
read -p "Enter RPC username (default: bitcoin): " RPC_USER
RPC_USER=${RPC_USER:-bitcoin}

echo ""
echo "Password options:"
echo "  1) Auto-generate a secure random password (recommended)"
echo "  2) Specify your own password"
read -p "Choose option (1-2, default: 1): " PASSWORD_CHOICE

case $PASSWORD_CHOICE in
    2)
        read -s -p "Enter password: " RPC_PASSWORD
        echo ""
        read -s -p "Confirm password: " RPC_PASSWORD_CONFIRM
        echo ""
        
        if [ "$RPC_PASSWORD" != "$RPC_PASSWORD_CONFIRM" ]; then
            echo "Error: Passwords don't match!"
            exit 1
        fi
        
        # Generate with specified password
        RPC_OUTPUT=$(python3 rpcauth.py "${RPC_USER}" "${RPC_PASSWORD}" --json)
        ;;
    *)
        # Auto-generate password
        RPC_OUTPUT=$(python3 rpcauth.py "${RPC_USER}" --json)
        ;;
esac

# Parse JSON output
RPC_PASSWORD=$(echo "${RPC_OUTPUT}" | python3 -c "import sys, json; print(json.load(sys.stdin)['password'])")
RPC_AUTH_LINE=$(echo "${RPC_OUTPUT}" | python3 -c "import sys, json; print(json.load(sys.stdin)['rpcauth'])")

echo ""
echo "=========================================="
echo -e "${GREEN}✓ Credentials Generated Successfully!${NC}"
echo "=========================================="
echo ""
echo "Username: ${RPC_USER}"
echo "Password: ${RPC_PASSWORD}"
echo ""
echo -e "${YELLOW}Configuration Instructions:${NC}"
echo ""
echo "1. Add this line to your bitcoin.conf:"
echo "   rpcauth=${RPC_AUTH_LINE}"
echo ""
echo "2. Add these lines to your .env file:"
echo "   BITCOIN_RPC_USER=${RPC_USER}"
echo "   BITCOIN_RPC_PASSWORD=${RPC_PASSWORD}"
echo ""
echo "3. Restart Bitcoin Core:"
echo "   docker-compose restart"
echo ""
echo -e "${YELLOW}⚠ IMPORTANT:${NC}"
echo "  - Keep your password secure!"
echo "  - The password is stored in .env (never commit this file)"
echo "  - Only the hash is stored in bitcoin.conf (safe to share template)"
echo "  - Each client needs the plain password for RPC access"
echo ""
echo "For more information, see: RPCAUTH.md"
echo ""


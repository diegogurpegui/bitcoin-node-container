# Bitcoin node container

Run a full Bitcoin node with Docker. Blockchain data stored on external drive.

## Quick Start

```bash
# 1. Setup (automatically generates secure RPC credentials using rpcauth.py)
./setup.sh

# 2. Build and start
docker-compose build
docker-compose up -d

# 3. Check status
./bitcoin-cli.sh getblockchaininfo
```

**What happens during setup:**
- Runs Bitcoin Core's `rpcauth.py` to generate credentials
- Creates HMAC-SHA256 hash for `bitcoin.conf` (secure)
- Saves password to `.env` for RPC access

## Prerequisites

- Docker and Docker Compose
- External drive with 500GB+ space
- Stable internet connection

## What You Get

- Full Bitcoin node (no pruning, complete blockchain history)
- Transaction index enabled (query any transaction)
- Secure RPC authentication (auto-generated hashed credentials)
- **Privacy-focused: All connections via Tor** (.onion only)
- Built-in Tor daemon (no separate container needed)
- **Electrum server (Electrs)** for wallet connectivity via Tor hidden service
- Two-container setup: bitcoin-node + electrs-server
- Helper script for easy commands

## Architecture

This setup runs two containers:

1. **bitcoin-node**: Bitcoin Core with Tor daemon
   - Handles blockchain sync and P2P connections
   - Provides RPC interface for applications
   - All connections via Tor (.onion only)

2. **electrs-server**: Electrum server with Tor daemon
   - Indexes blockchain for fast wallet queries
   - Provides Electrum protocol for wallet connectivity
   - Accessible only via Tor hidden service
   - Depends on bitcoin-node for blockchain data

## Common Commands

```bash
# Check sync progress
./bitcoin-cli.sh getblockchaininfo

# View node info
./bitcoin-cli.sh getnetworkinfo

# Check connected peers (all .onion addresses via Tor)
./bitcoin-cli.sh getpeerinfo

# Verify Tor connection
./bitcoin-cli.sh getnetworkinfo | grep "onion"

# View logs
docker-compose logs -f

# View Electrs logs specifically
docker-compose logs -f electrs

# Restart node
docker-compose restart

# Restart Electrs only
docker-compose restart electrs

# Stop node
docker-compose down
```

## Initial Sync

First sync takes several days depending on your hardware:
- Modern PC with SSD: 6-24 hours
- Older hardware: 1-2 weeks
- Blockchain size: ~600GB (grows ~50-100GB/year)

Monitor progress:
```bash
./bitcoin-cli.sh getblockchaininfo | grep verificationprogress
```

When `verificationprogress` reaches ~1.0, you're fully synced.

## Electrum Server (Electrs)

The setup includes an Electrum server that allows you to connect Bitcoin wallets to your own node instead of third-party servers.

**What it provides:**
- Electrum protocol server for wallet connectivity
- Indexes blockchain data for fast wallet queries
- Works with hardware wallets (BitBox, Coldcard, Ledger, Trezor)
- Compatible with desktop wallets (Sparrow, Electrum, Specter Desktop)
- **Privacy-focused: Accessible only via Tor hidden service**

**How to use:**
1. Wait for Electrs to finish initial indexing (can take 12+ hours)
2. Get the Electrs Tor hidden service address
3. Connect your wallet using the .onion address

**Check Electrs status:**
```bash
# View Electrs logs
docker-compose logs -f electrs

# Get Electrs Tor hidden service address
docker exec electrs-server cat /var/lib/tor/electrs_hidden_service/hostname

# Test Electrs connection via Tor (requires tor-proxy on host)
# curl -X POST -H "Content-Type: application/json" \
#   -d '{"jsonrpc":"2.0","method":"server.version","params":["electrum-client","1.4"],"id":1}' \
#   --socks5-hostname 127.0.0.1:9050 \
#   http://[ELECTRS_ONION_ADDRESS]:50001
```

**Wallet configuration:**
- **Server:** Use the .onion address from the hostname file above
- **Port:** 50001
- **Protocol:** TCP (via Tor)
- **Network:** Bitcoin mainnet

**Important notes:**
- Electrs runs in its own container with its own Tor daemon
- Electrs is only accessible via Tor hidden service (no clearnet exposure)
- Electrs must fully index the blockchain before wallets can connect
- Initial indexing can take 12+ hours on slower hardware
- Electrs will automatically reindex if Bitcoin Core is updated
- The service depends on the Bitcoin node and will restart if needed
- Configuration file: `electrs/electrs.conf` (copied to data directory by setup.sh)

## Security

The setup script automatically generates secure RPC credentials using Bitcoin Core's official `rpcauth.py` script:
- Auto-generates a cryptographically secure random password
- Creates hashed RPC credentials (HMAC-SHA256) stored in `bitcoin.conf`
- Stores the plain password in `.env` for bitcoin-cli access
- Sets proper file permissions (chmod 600)

**How it works (following [RaspiBolt guide](https://raspibolt.org/guide/bitcoin/bitcoin-client.html#generate-access-credentials)):**
```
rpcauth.py → Generates password + salt → HMAC-SHA256 hash
                                              ↓
                        ┌─────────────────────┴─────────────────────┐
                        ↓                                           ↓
              bitcoin.conf                                        .env
         rpcauth=user:salt$hash                    BITCOIN_RPC_PASSWORD=...
         (Only hash - secure)                      (Plain password - secret)
```

1. `rpcauth.py` generates a random password and salt
2. Creates HMAC-SHA256 hash: `rpcauth=username:salt$hash`
3. Hash goes into `bitcoin.conf` (secure, can share template)
4. Plain password goes into `.env` (secret, for RPC clients)

**Important:**
- Never commit `.env` to version control (contains plain password)
- `bitcoin.conf` only stores the hash (safe to share template)
- Don't expose port 8332 (RPC) to internet
- Port 8333 (P2P) can be exposed for better network contribution

## Manual Setup (Optional)

If you prefer manual configuration:

1. **Prepare drive:**
```bash
sudo mkdir -p /mnt/external-drive/bitcoin-data
sudo chown -R 1000:1000 /mnt/external-drive/bitcoin-data
```

2. **Create .env file:**
```bash
cp .env.template .env
# Edit with your paths and credentials
```

3. **Copy bitcoin.conf to data directory:**
```bash
cp bitcoin.conf /mnt/external-drive/bitcoin-data/
```

4. **Generate secure RPC credentials:**
```bash
# Use the credential generator script
./generate-rpc-credentials.sh

# Or generate directly
python3 rpcauth.py bitcoin --json
# This outputs: {"username":"bitcoin","password":"abc123...","rpcauth":"bitcoin:salt$hash"}
# - Add the rpcauth line to bitcoin.conf
# - Save the password in .env as BITCOIN_RPC_PASSWORD
```

## Performance Tips

- **During initial sync:** Set `dbcache=2000` or higher in `bitcoin.conf`
- **After sync:** Can reduce to `dbcache=1000` to save RAM
- **Storage:** SSD strongly recommended (much faster than HDD)
- **RAM:** 4GB+ recommended

## Troubleshooting

**Container won't start:**
- Check logs: `docker-compose logs`
- Verify external drive is mounted
- Check permissions: `sudo chown -R $(id -u):$(id -g) /path/to/bitcoin-data`

**Slow sync:**
- Increase `dbcache` in `bitcoin.conf`
- Use SSD instead of HDD
- Temporarily enable `blocksonly=1`

**Authorization failed:**
- Check `.env` file has correct credentials
- Verify `bitcoin.conf` has matching rpcauth
- Restart: `docker-compose restart`

## Storage Requirements

- Current blockchain: ~600GB
- With transaction index: +50GB
- Growth rate: ~50-100GB/year
- Recommended: 1TB+ drive

## Updating Bitcoin Core

```bash
# 1. Edit Dockerfile - update BITCOIN_VERSION and SHA256
# 2. Rebuild
docker-compose build
docker-compose down
docker-compose up -d
```

Your blockchain data is preserved.

## Updating Electrs

```bash
# 1. Edit electrs/Dockerfile - update ELECTRS_VERSION
# 2. Rebuild Electrs
docker-compose build electrs
docker-compose up -d electrs
```

Electrs will automatically reindex if needed.

## Tor Privacy Configuration

This node is configured for maximum privacy using Tor:

**What's configured:**
- All Bitcoin P2P connections route through Tor (`proxy=127.0.0.1:9050`)
- Only connects to `.onion` addresses (`onlynet=onion`)
- Hidden service for incoming connections (`listenonion=1`)
- Tor daemon runs automatically in both containers
- No clearnet exposure (`discover=0`)
- Electrs also runs via Tor hidden service (separate from Bitcoin node)

**How it works:**
1. Both containers start their own Tor daemons
2. Bitcoin Core connects exclusively through Tor
3. Bitcoin node creates `.onion` address for incoming connections
4. Electrs creates separate `.onion` address for wallet connections
5. All peer connections are via Tor hidden services

**Benefits:**
- Complete IP address privacy
- Resistant to network surveillance
- Connects to Bitcoin network anonymously
- No ISP tracking of Bitcoin activity

**Trade-offs:**
- Slightly slower initial sync (Tor overhead)
- Only connects to .onion peers (smaller peer pool)
- Adds ~100-200ms latency to connections

**Verifying Tor operation:**
```bash
# Check that all peers are .onion addresses
./bitcoin-cli.sh getpeerinfo | grep "addr"

# Verify Tor proxy is configured
./bitcoin-cli.sh getnetworkinfo
# Look for: "proxy": "127.0.0.1:9050" and "onion": {"reachable": true}
```

Based on: [RaspiBolt Bitcoin Client Guide](https://raspibolt.org/guide/bitcoin/bitcoin-client.html)

## Resources

- [Bitcoin Core](https://bitcoin.org/en/bitcoin-core/)
- [Bitcoin Core RPC Docs](https://developer.bitcoin.org/reference/rpc/)
- [RaspiBolt Guide](https://raspibolt.org/)
- [Tor Project](https://www.torproject.org/)

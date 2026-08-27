# Agent notes

Skilled operator. Be brief. One user-facing doc: `README.md` — no extra markdown docs unless asked.

Use `docker compose` (v2), not `docker-compose`. Do not commit `.env`. Do not add compose overlays for optional behavior; keep a single `docker-compose.yml`.

Plug-and-play: never require host `sudo chown` / UID tables. Fix ownership and modes **inside the container as root at startup** (supervisord wrapper before Tor). Docker bind-mounts are often `755`; Tor HiddenServiceDir **must be `700`** or Tor exits (`Permissions ... too permissive`).

## Stack

Bitcoin Core + Tor, Electrs + Tor, Mempool (web/api/db). Data on an external drive via `.env` paths. Electrs and Mempool UI are **Tor hidden services only** (no host ports).

- Mempool UI: `http://<onion>/` in Tor Browser — **http, no port** (onion :80 → nginx `127.0.0.1:8080`). Not `https`, not `:8080`.
- Electrs wallets: onion **:50001**.
- `mempool-api` Tor is SOCKS outbound only (no onion).

Onion addresses come from keys in HiddenServiceDir. Recreate without a persist mount = new onion. Persist on the data drive:

| Service | Host | Container |
|---------|------|-----------|
| bitcoin-node | `${BITCOIN_DATA_PATH}/tor` | `/var/lib/tor` |
| electrs | `${ELECTRS_DATA_PATH}/tor/electrs_hidden_service` | `/var/lib/tor/electrs_hidden_service` |
| mempool-web | `${MEMPOOL_DATA_PATH}/tor/mempool_hidden_service` | `/var/lib/tor/mempool_hidden_service` |

`setup.sh` should `mkdir -p` those dirs; permission fix belongs in the image. Bitcoin Core P2P onion key (`onion_v3_private_key`) is already in the bitcoin datadir.

**New volume mounts:** `docker compose up -d` (recreate). `restart` does not attach mounts.

To keep an existing onion when adding mounts: `docker cp` the HiddenServiceDir to the host path **before** recreate.

## Mempool frontend

Image wraps `mempool/frontend` with Tor + supervisord.

- **nginx must run as root** in supervisord. Upstream logs are symlinks to `/dev/stdout`; UID 1000 cannot open them → nginx FATAL, onion has nothing on 8080. Do not set `user=1000` on `[program:nginx]`.
- If the onion “does nothing”, inspect **early** logs: nginx may have given up; later lines are only Tor bootstrap.

## Tor users (for in-container chown)

- bitcoin-node: `debian-tor`
- electrs: Tor runs as `electrs`
- mempool-web: `tor`

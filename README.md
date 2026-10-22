# next-update
Auto update for GNU/Linux servers (systemd) with an optional central web UI.
Arch (pacman, AUR) and Debian (apt) are supported, plus Docker images on both.

Two separate packages:

| Package | Folder | Runs on | What it is |
|---|---|---|---|
| `next-update-server` | `server/` | every server | Daemon. Runs your update commands on boot and/or on a schedule. Works standalone. |
| `next-update-web` | `web/` | one machine | Web UI. Shows all servers, pending updates, holds, starts updates. |

## Install
```
Download the needed files from the release section. 
Install them on Arch via pacman -F filename
```

### Web UI
```
sudo $EDITOR /etc/next-update-web/config        # set ADMIN_USER, ADMIN_PASSWORD, TOKEN
sudo systemctl enable --now next-update-web
```
Open `http://<host>:8080` and log in with `ADMIN_USER` / `ADMIN_PASSWORD`.
The service refuses to start while one of the three values is empty.

### Server daemon
```
sudo $EDITOR /etc/next-update-server/config     # commands, schedule; WEB_URL + TOKEN to link it to the web UI
sudo systemctl enable --now next-update-server
```
`TOKEN` must equal `TOKEN` in the web config. The server then shows up in the UI by its hostname.
For a server daemon running on the **same machine** as the web UI, use `WEB_URL="http://127.0.0.1:8080"`. For remote servers, use `http://<ip-of-web-host>:8080`.

## Server config
`/etc/next-update-server/config` (bash syntax):

| Option | Meaning |
|---|---|
| `DEBIAN_MODE` | `yes`/`no` - use apt instead of pacman/AUR, see below |
| `RUN_ON_BOOT` | `yes`/`no` - run updates whenever the daemon starts |
| `UPDATE_TIME` | `HH:MM` daily run time, empty = no schedule |
| `UPDATE_DAYS` | `all` or e.g. `mon,thu` |
| `STOP_ON_ERROR` | `yes`/`no` - stop at first failing command |
| `HOLD_PKGS` | bash array of packages that are never updated on this server |
| `COMMANDS` | bash array of commands, run in order. Optional, the default depends on `DEBIAN_MODE` |
| `WEB_URL`, `TOKEN` | link to next-update-web (optional) |
| `HOST_NAME` | name in the UI, default: hostname |
| `POLL_INTERVAL` | seconds between polls of the web UI, default 10 |
| `CHECK_INTERVAL` | seconds between pacman/AUR pending-update checks, default 900 |
| `AUR_USER` | user that runs yay, empty = no AUR updates |
| `DOCKER_CHECK`, `DOCKER_CHECK_INTERVAL` | Docker image checks, default `yes` / 21600 s |

Schedule/command changes are picked up after the next run; restart the service to apply them immediately
(with `RUN_ON_BOOT=yes` this triggers an update run).

### Debian mode
`DEBIAN_MODE=yes` switches the daemon to apt:
- Pending updates come from `apt-get update` + a simulated `apt-get upgrade` (shown as **APT** in the UI).
  They are checked every `CHECK_INTERVAL`, so every check refreshes the package lists.
- Default `COMMANDS`: `apt-get update`, then a non-interactive `apt-get -y upgrade` that keeps your modified config files.
- "Update selected" runs `apt-get install -y --only-upgrade <packages>`.
- Held packages are put on `apt-mark hold` for the duration of a full run and released afterwards.
  If the daemon is killed in the middle of a run, they stay held; check `apt-mark showhold`.
- pacman and AUR are not used. Docker works as in Arch mode (needs the `docker buildx` and `docker compose` plugins).

### Holding packages
Held packages (local `HOLD_PKGS` + holds set in the web UI, globally or per server) are passed to your commands
as the environment variable `NU_IGNORE` (comma separated). The default pacman command uses it:
```
pacman -Syu --noconfirm ${NU_IGNORE:+--ignore "$NU_IGNORE"}
```
If you set your own `COMMANDS` on Arch, keep that part, otherwise holds are not applied.

## Web UI
- Status of every server (online / offline / running), last seen, client IP
- **Host & IP Checker**: probe any IP/hostname from the UI to check network reachability and linking status
- Connection diagnostic alerts if a server connects with a mismatched token or invalid hostname
- Pending updates per server, grouped: **Pacman** or **APT**, **AUR (yay)**, **Docker images** (held packages are struck through)
- Tick single entries and press **Update selected**, or press **Update all** (runs the `COMMANDS` from the server's config)
- Hold packages per server or on all servers
- A request starts within `POLL_INTERVAL` seconds
- Output of the last run

### What "Update selected" does
| Kind | Command run by the daemon |
|---|---|
| Pacman | `pacman -Sy --noconfirm -- <packages>` |
| APT | `apt-get install -y --only-upgrade <packages>` |
| AUR | `yay -S --noconfirm -- <packages>` as `AUR_USER` |
| Docker | `docker pull <image>`, then `docker compose up -d --no-deps <service>` for every compose-managed container using the image. Containers not created by compose are only pulled, recreate them yourself. |

**Pacman partial upgrades:** Arch does not support updating only some packages (`pacman -Sy` + a subset).
Selecting a library without its dependents can break the system. The UI asks before you do it.
Use "Update all" for normal maintenance.

### AUR and Docker setup
- AUR: install `yay`, set `AUR_USER` in the server config. That user needs passwordless `sudo` for pacman.
- Docker: install `docker-buildx` (used to read the registry digest) and `docker-compose`.
  Only images of existing containers are checked. Locally built images and digest-pinned (`@sha256:`) images are skipped.
  Registries are queried every `DOCKER_CHECK_INTERVAL` seconds (default 6 h) and after every update run,
  because Docker Hub limits anonymous requests.

## Security
- The web UI cannot run arbitrary commands on servers. It only sends "update all" or a selection of names.
  "Update all" runs only the local `COMMANDS`; for a selection the daemon updates only items that are in its
  own current pending list, so the web UI cannot make it install anything else.
- Traffic is plain HTTP with a shared token and a basic-auth login. That is meant for a trusted home network.
  Put a reverse proxy with TLS in front of it if you need more.
- Anyone with the web login can trigger updates on all linked servers.

## Logs
```
journalctl -u next-update-server -f
journalctl -u next-update-web -f
```

# next-update
Auto update daemon for Arch-based GNU/Linux servers (systemd, pacman packages), with an optional central web UI.

Two packages are built from this repo:

| Package | What it is |
|---|---|
| `next-update` | Agent, runs on every server. Runs your update commands on boot and/or on a schedule. |
| `next-update-server` | Central web UI, runs on **one** server. Shows all agents, holds back packages, triggers updates. |

The agent also works standalone, without a server.

## Install
```
git clone https://github.com/Lukas6342/next-update
cd next-update
makepkg -si          # installs both; use `makepkg -s` and pacman -U to pick one
```

### Agent (every server)
```
sudo $EDITOR /etc/next-update/config
sudo systemctl enable --now next-update
```

### Web server (one server)
```
sudo $EDITOR /etc/next-update-server/config     # set ADMIN_PASSWORD and AGENT_TOKEN
sudo systemctl enable --now next-update-server
```
Open `http://<server>:8080`, log in with any username and `ADMIN_PASSWORD`.
Link an agent by setting `SERVER_URL` and `SERVER_TOKEN` (= `AGENT_TOKEN`) in its config and restarting it.
It then shows up in the UI by its hostname.

## Agent config
`/etc/next-update/config` (bash syntax):

| Option | Meaning |
|---|---|
| `RUN_ON_BOOT` | `yes`/`no` - run updates whenever the daemon starts |
| `UPDATE_TIME` | `HH:MM` daily run time, empty = no schedule |
| `UPDATE_DAYS` | `all` or e.g. `mon,thu` |
| `STOP_ON_ERROR` | `yes`/`no` - stop at first failing command |
| `HOLD_PKGS` | bash array of packages that are never updated on this server |
| `COMMANDS` | bash array of commands, run in order |
| `SERVER_URL`, `SERVER_TOKEN` | link to next-update-server (optional) |
| `HOST_NAME` | name in the UI, default: hostname |
| `POLL_INTERVAL` | seconds between server polls, default 10 |
| `CHECK_INTERVAL` | seconds between pacman/AUR pending-update checks, default 900 |
| `AUR_USER` | user that runs yay, empty = no AUR updates |
| `DOCKER_CHECK`, `DOCKER_CHECK_INTERVAL` | Docker image checks, default `yes` / 21600 s |

### Holding packages
Held packages (local `HOLD_PKGS` + holds set in the web UI, globally or per server) are passed to your commands
as the environment variable `NU_IGNORE` (comma separated). The default command uses it:
```
pacman -Syu --noconfirm ${NU_IGNORE:+--ignore "$NU_IGNORE"}
```
If you change `COMMANDS`, keep that part, otherwise holds are not applied.

## Web UI
- Status of every server (online / offline / running), last seen
- Pending updates per server, grouped: **Pacman**, **AUR (yay)**, **Docker images** (held packages are struck through)
- Tick single entries and press **Update selected**, or press **Update all** (runs the `COMMANDS` from the agent config)
- Hold packages per server or on all servers
- A request starts within `POLL_INTERVAL` seconds
- Output of the last run

### What "Update selected" does
| Kind | Command run by the agent |
|---|---|
| Pacman | `pacman -Sy --noconfirm -- <packages>` |
| AUR | `yay -S --noconfirm -- <packages>` as `AUR_USER` |
| Docker | `docker pull <image>`, then `docker compose up -d --no-deps <service>` for every compose-managed container using the image. Containers not created by compose are only pulled, recreate them yourself. |

**Pacman partial upgrades:** Arch does not support updating only some packages (`pacman -Sy` + a subset).
Selecting a library without its dependents can break the system. The UI asks before you do it.
Use "Update all" for normal maintenance.

### AUR and Docker setup
- AUR: install `yay`, set `AUR_USER` in the agent config. That user needs passwordless `sudo` for pacman.
- Docker: install `docker-buildx` (used to read the registry digest) and `docker-compose`.
  Only images of existing containers are checked. Locally built images and digest-pinned (`@sha256:`) images are skipped.
  Registries are queried every `DOCKER_CHECK_INTERVAL` seconds (default 6 h) and after every update run,
  because Docker Hub limits anonymous requests.

## Security
- The server cannot run arbitrary commands on agents. It only sends "update all" or a selection of names.
  "Update all" runs only the local `COMMANDS`; for a selection the agent updates only items that are in its
  own current pending list, so the server cannot make it install anything else.
- Traffic is plain HTTP with a shared token. That is meant for a trusted home network.
  Put a reverse proxy with TLS in front of it if you need more.
- Anyone with `ADMIN_PASSWORD` can trigger updates on all linked servers.

## Logs
```
journalctl -u next-update -f
journalctl -u next-update-server -f
```

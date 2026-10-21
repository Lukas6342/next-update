# next-update
An auto update daemon for Arch-based GNU/Linux servers (systemd, pacman package).

Runs your update commands on every start (boot) and/or at a fixed time of day / on fixed weekdays.

## Install
```
git clone https://github.com/Lukas6342/next-update
cd next-update
makepkg -si
sudo $EDITOR /etc/next-update/config
sudo systemctl enable --now next-update
```

## Config
`/etc/next-update/config` (bash syntax, kept on package upgrades via pacman's backup mechanism):

| Option | Meaning |
|---|---|
| `RUN_ON_BOOT` | `yes`/`no` - run updates whenever the daemon starts |
| `UPDATE_TIME` | `HH:MM` daily run time, empty = no schedule |
| `UPDATE_DAYS` | `all` or e.g. `mon,thu` |
| `STOP_ON_ERROR` | `yes`/`no` - stop at first failing command |
| `COMMANDS` | bash array of commands, run in order |

Schedule/command changes are picked up after the next run; restart the service to apply them immediately (with `RUN_ON_BOOT=yes` this triggers an update run).

## Logs
```
journalctl -u next-update -f
```

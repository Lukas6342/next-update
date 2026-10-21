#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
install -Dm755 next-update /usr/local/bin/next-update
install -Dm644 next-update.service /etc/systemd/system/next-update.service
[ -e /etc/next-update/config ] || install -Dm600 config.example /etc/next-update/config
systemctl daemon-reload
systemctl enable next-update.service
echo "Installed. Edit /etc/next-update/config, then: systemctl start next-update"

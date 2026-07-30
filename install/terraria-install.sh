#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
# Copyright (c) 2021-2026 community-scripts ORG
# Author: APELLO
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://terraria.org

color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get update
$STD apt-get install -y \
  curl \
  unzip \
  ca-certificates \
  screen
msg_ok "Installed Dependencies"

msg_info "Creating Terraria User"
useradd -r -m -d /opt/terraria -s /usr/sbin/nologin terraria
msg_ok "Created Terraria User"

msg_info "Fetching Latest Terraria Server Release"
RELEASE=$(curl -fsSL https://terraria.org/api/get/dedicated-servers-names | grep -oE '[0-9]+' | head -n1)
msg_ok "Found Terraria Server v${RELEASE}"

msg_info "Installing Terraria Server v${RELEASE} (Patience)"
TEMP_DIR=$(mktemp -d)
curl -fsSL "https://terraria.org/api/download/pc-dedicated-server/terraria-server-${RELEASE}.zip" -o "${TEMP_DIR}/terraria-server.zip"
unzip -q "${TEMP_DIR}/terraria-server.zip" -d "${TEMP_DIR}/extracted"
VERSION_DIR=$(find "${TEMP_DIR}/extracted" -maxdepth 1 -mindepth 1 -type d | head -n1)
mkdir -p /opt/terraria
cp -r "${VERSION_DIR}/Linux" /opt/terraria/server
chmod +x /opt/terraria/server/TerrariaServer.bin.x86_64
mkdir -p /opt/terraria/worlds
echo "$RELEASE" >/opt/terraria/.version
rm -rf "$TEMP_DIR"
msg_ok "Installed Terraria Server v${RELEASE}"

msg_info "Creating Default Configuration"
cat <<EOF >/opt/terraria/serverconfig.txt
# Terraria dedicated server configuration
# Full reference: https://terraria.wiki.gg/wiki/Server#Command_line_arguments
world=/opt/terraria/worlds/world1.wld
autocreate=2
worldname=world1
difficulty=0
maxplayers=8
port=7777
password=
motd=Welcome to your Terraria server!
upnp=0
secure=1
EOF
chown -R terraria:terraria /opt/terraria
msg_ok "Created Default Configuration"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/terraria.service
[Unit]
Description=Terraria Dedicated Server
After=network.target

[Service]
Type=forking
User=terraria
Group=terraria
WorkingDirectory=/opt/terraria/server
ExecStart=/usr/bin/screen -dmS terraria /opt/terraria/server/TerrariaServer.bin.x86_64 -config /opt/terraria/serverconfig.txt
ExecStop=/usr/bin/screen -S terraria -X quit
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now terraria
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

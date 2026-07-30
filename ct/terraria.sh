#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: APELLO
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://terraria.org

# App Default Values
APP="Terraria"
var_tags="games"
var_cpu="2"
var_ram="2048"
var_disk="6"
var_os="debian"
var_version="12"
var_unprivileged="1"

# App Output & Base Settings
header_info "$APP"
base_settings

# Core
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/terraria ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  RELEASE=$(curl -fsSL https://terraria.org/api/get/dedicated-servers-names | grep -oE '[0-9]+' | head -n1)
  if [[ ! -f /opt/terraria/.version ]] || [[ "$RELEASE" != "$(cat /opt/terraria/.version)" ]]; then
    msg_info "Stopping ${APP}"
    systemctl stop terraria
    msg_ok "Stopped ${APP}"

    msg_info "Updating ${APP} to ${RELEASE}"
    TEMP_DIR=$(mktemp -d)
    curl -fsSL "https://terraria.org/api/download/pc-dedicated-server/terraria-server-${RELEASE}.zip" -o "${TEMP_DIR}/terraria-server.zip"
    unzip -q "${TEMP_DIR}/terraria-server.zip" -d "${TEMP_DIR}/extracted"
    VERSION_DIR=$(find "${TEMP_DIR}/extracted" -maxdepth 1 -mindepth 1 -type d | head -n1)
    rm -rf /opt/terraria/server
    cp -r "${VERSION_DIR}/Linux" /opt/terraria/server
    chmod +x /opt/terraria/server/TerrariaServer.bin.x86_64
    chown -R terraria:terraria /opt/terraria/server
    echo "$RELEASE" >/opt/terraria/.version
    rm -rf "$TEMP_DIR"
    msg_ok "Updated ${APP} to ${RELEASE}"

    msg_info "Starting ${APP}"
    systemctl start terraria
    msg_ok "Started ${APP}"
  else
    msg_ok "${APP} is already up to date (v${RELEASE})"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} World files & serverconfig.txt:${CL}"
echo -e "${TAB}/opt/terraria/worlds/"
echo -e "${TAB}/opt/terraria/serverconfig.txt"
echo -e "${INFO}${YW} Attach to the live server console (for save/exit, in-game commands):${CL}"
echo -e "${TAB}pct exec ${CTID} -- screen -r terraria"
echo -e "${INFO}${YW} Connect to your server at:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}${IP}:7777${CL}"

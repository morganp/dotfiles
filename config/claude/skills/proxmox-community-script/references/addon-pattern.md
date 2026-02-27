# Addon Script Pattern

Addon scripts install tools into an **existing** LXC container. They consist of 2 files: the script and JSON metadata.

## File 1: Addon Script (`tools/addon/appname.sh`)

Addon scripts source the community-scripts function libraries via curl to get all helper functions (`msg_info`, `msg_ok`, `$STD`, `header_info`, `fetch_and_deploy_gh_release`, etc.).

```bash
#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: AuthorName (GitHubUsername)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://application-url.com | Github: https://github.com/owner/repo

if ! command -v curl &>/dev/null; then
  printf "\r\e[2K%b" '\033[93m Setup Source \033[m' >&2
  apt-get update >/dev/null 2>&1
  apt-get install -y curl >/dev/null 2>&1
fi
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/core.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/tools.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/error_handler.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true

# Enable error handling
set -Eeuo pipefail
trap 'error_handler' ERR
load_functions
init_tool_telemetry "" "addon"

# ==============================================================================
# CONFIGURATION
# ==============================================================================
VERBOSE=${var_verbose:-no}
APP="appname"
APP_TYPE="tools"
INSTALL_PATH="/opt/appname"
CONFIG_PATH="/opt/appname.env"

# ==============================================================================
# OS DETECTION
# ==============================================================================
if [[ -f "/etc/alpine-release" ]]; then
  OS="Alpine"
  SERVICE_PATH="/etc/init.d/appname"
elif grep -qE 'ID=debian|ID=ubuntu' /etc/os-release; then
  OS="Debian"
  SERVICE_PATH="/etc/systemd/system/appname.service"
else
  echo -e "${CROSS} Unsupported OS detected. Exiting."
  exit 1
fi

# ==============================================================================
# UNINSTALL
# ==============================================================================
function uninstall() {
  msg_info "Uninstalling AppName"
  if [[ "$OS" == "Alpine" ]]; then
    rc-service appname stop &>/dev/null
    rc-update del appname &>/dev/null
    rm -f "$SERVICE_PATH"
  else
    systemctl disable -q --now appname
    rm -f "$SERVICE_PATH"
  fi
  rm -rf "$INSTALL_PATH" "$CONFIG_PATH"
  rm -f "/usr/local/bin/update_appname"
  rm -f "$HOME/.appname"
  msg_ok "AppName has been uninstalled"
}

# ==============================================================================
# UPDATE
# ==============================================================================
function update() {
  if check_for_gh_release "appname" "owner/repo"; then
    msg_info "Stopping service"
    if [[ "$OS" == "Alpine" ]]; then
      rc-service appname stop &>/dev/null
    else
      systemctl stop appname
    fi
    msg_ok "Stopped service"

    fetch_and_deploy_gh_release "appname" "owner/repo" "tarball" "latest"

    # App-specific rebuild steps...

    msg_info "Starting service"
    if [[ "$OS" == "Alpine" ]]; then
      rc-service appname start &>/dev/null
    else
      systemctl start appname
    fi
    msg_ok "Started service"
    msg_ok "Updated successfully!"
    exit
  fi
}

# ==============================================================================
# INSTALL
# ==============================================================================
function install() {
  fetch_and_deploy_gh_release "appname" "owner/repo" "tarball" "latest"

  # App-specific build/setup...

  msg_info "Creating service"
  if [[ "$OS" == "Debian" ]]; then
    cat <<EOF >"$SERVICE_PATH"
[Unit]
Description=AppName Service
After=network.target

[Service]
User=root
WorkingDirectory=$INSTALL_PATH
EnvironmentFile=$CONFIG_PATH
ExecStart=$INSTALL_PATH/appname
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable -q --now appname
  else
    cat <<EOF >"$SERVICE_PATH"
#!/sbin/openrc-run
name="appname"
description="AppName Service"
command="$INSTALL_PATH/appname"
command_background=true
pidfile="/run/\${RC_SVCNAME}.pid"
EOF
    chmod +x "$SERVICE_PATH"
    $STD rc-update add appname default
    $STD rc-service appname start
  fi
  msg_ok "Created and started service"

  # Create update script
  msg_info "Creating update script"
  ensure_usr_local_bin_persist
  cat <<'UPDATEEOF' >/usr/local/bin/update_appname
#!/usr/bin/env bash
type=update bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/appname.sh)"
UPDATEEOF
  chmod +x /usr/local/bin/update_appname
  msg_ok "Created update script (/usr/local/bin/update_appname)"

  echo ""
  msg_ok "AppName installed successfully"
  msg_ok "Access: ${BL}http://${LOCAL_IP}:PORT${CL}"
}

# ==============================================================================
# MAIN
# ==============================================================================
header_info
ensure_usr_local_bin_persist
get_lxc_ip

# Handle type=update (called from update script)
if [[ "${type:-}" == "update" ]]; then
  if [[ -d "$INSTALL_PATH" && -f "$INSTALL_PATH/appname" ]]; then
    update
  else
    msg_error "AppName is not installed. Nothing to update."
    exit 1
  fi
  exit 0
fi

# Check if already installed
if [[ -d "$INSTALL_PATH" && -f "$INSTALL_PATH/appname" ]]; then
  msg_warn "AppName is already installed."
  echo ""

  echo -n "${TAB}Uninstall AppName? (y/N): "
  read -r uninstall_prompt
  if [[ "${uninstall_prompt,,}" =~ ^(y|yes)$ ]]; then
    uninstall
    exit 0
  fi

  echo -n "${TAB}Update AppName? (y/N): "
  read -r update_prompt
  if [[ "${update_prompt,,}" =~ ^(y|yes)$ ]]; then
    update
    exit 0
  fi

  msg_warn "No action selected. Exiting."
  exit 0
fi

# Fresh installation
msg_warn "AppName is not installed."
echo ""
echo -e "${TAB}${INFO} This will install:"
echo -e "${TAB}  - AppName description"
echo -e "${TAB}  - Systemd/OpenRC service"
echo ""

echo -n "${TAB}Install AppName? (y/N): "
read -r install_prompt
if [[ "${install_prompt,,}" =~ ^(y|yes)$ ]]; then
  install
else
  msg_warn "Installation cancelled. Exiting."
  exit 0
fi
```

### Addon Script Rules

- Source `core.func`, `tools.func`, `error_handler.func`, and `api.func` via curl — do NOT define inline color vars or msg functions
- The curl check block at the top ensures `curl` is available before sourcing
- Use `load_functions` after sourcing to initialize all helpers
- Use `init_tool_telemetry "" "addon"` for telemetry
- Use `set -Eeuo pipefail` + `trap 'error_handler' ERR` for error handling
- Use `apt` not `apt-get` for all package operations (except the curl bootstrap block at the top, which matches upstream template)
- Use `$STD` to suppress command output (not `&>/dev/null`) — `$STD` comes from tools.func
- Use `header_info` from core.func (do NOT define custom ASCII art header)
- Use `get_lxc_ip` to get `$LOCAL_IP` for display
- Use `ensure_usr_local_bin_persist` for update scripts
- Use `getent passwd "$USER" | cut -d: -f6` to resolve home directories — never `eval echo "~$USER"`
- Heredoc style: `cat <<'EOF'> /path/to/file` (no space before `>`) for quoted heredocs
- Use `read -r` prompts for user confirmation (not `whiptail`)
- Use `${TAB}`, `${INFO}`, `${BL}`, `${CL}`, `${CROSS}` variables from core.func
- Structure: CONFIGURATION → OS DETECTION → UNINSTALL → UPDATE → INSTALL → MAIN
- The MAIN section handles: `type=update` dispatch, already-installed check (offer uninstall/update), fresh install
- Do NOT call `motd_ssh`, `customize`, or `cleanup_lxc`

### OS Support

Most addons should support both Debian and Alpine. Use separate code paths:
- **Debian**: systemd (`systemctl enable -q --now`)
- **Alpine**: OpenRC (`rc-update add` + `rc-service start`)

If the app genuinely doesn't support Alpine (e.g., Homebrew), reject it early in OS DETECTION:
```bash
if [[ -f "/etc/alpine-release" ]]; then
  echo -e "${CROSS} Alpine is not supported by AppName. Exiting."
  exit 1
fi
```

### Update Script Pattern

Create a wrapper at `/usr/local/bin/update_appname` that re-runs the addon script with `type=update`:
```bash
cat <<'UPDATEEOF' >/usr/local/bin/update_appname
#!/usr/bin/env bash
type=update bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/appname.sh)"
UPDATEEOF
chmod +x /usr/local/bin/update_appname
```

The MAIN section dispatches on `${type:-}` to call the update function directly.

---

## File 2: JSON Metadata

See `json-metadata.md`. For addon scripts, set:
- `"type": "addon"`
- `"install_methods[].script": "tools/addon/appname.sh"`
- All resource fields set to `null`
- Include note: `{"text": "Execute within an existing LXC Console", "type": "info"}`

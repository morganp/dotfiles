# Addon Script Pattern

Addon scripts install tools into an **existing** LXC container. They consist of 2 files: the script and JSON metadata.

## File 1: Addon Script (`tools/addon/appname.sh`)

Addon scripts are self-contained — they define their own color codes, message functions, and telemetry inline. They do NOT use `$FUNCTIONS_FILE_PATH` or `build.func`.

```bash
#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: AuthorName (GitHubUsername)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://application-url.com | Github: https://github.com/owner/repo

function header_info {
  clear
  cat <<"EOF"
     _                _   _
    / \   _ __  _ __ | \ | | __ _ _ __ ___   ___
   / _ \ | '_ \| '_ \|  \| |/ _` | '_ ` _ \ / _ \
  / ___ \| |_) | |_) | |\  | (_| | | | | | |  __/
 /_/   \_\ .__/| .__/|_| \_|\__,_|_| |_| |_|\___|
         |_|   |_|

EOF
}
set -eEuo pipefail
YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
BGN=$(echo "\033[4;92m")
GN=$(echo "\033[1;92m")
DGN=$(echo "\033[32m")
CL=$(echo "\033[m")
CM="${GN}✓${CL}"
BFR="\\r\\033[K"
HOLD="-"

msg_info() {
  local msg="$1"
  echo -ne " ${HOLD} ${YW}${msg}..."
}

msg_ok() {
  local msg="$1"
  echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

msg_error() {
  local msg="$1"
  echo -e "${BFR} ${RD}✗ ${msg}${CL}"
}

# Telemetry
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "appname" "addon"

header_info

whiptail --backtitle "Proxmox VE Helper Scripts" --title "AppName Installer" --yesno "This Will Install AppName on this LXC Container. Proceed?" 10 58

# --- Installation logic here ---

msg_info "Installing Dependencies"
apt install -y package1 package2 &>/dev/null
msg_ok "Installed Dependencies"

# ... app-specific install steps ...

echo -e "Successfully Installed!! AppName is ready at ${BL}http://$(hostname -I | cut -f1 -d ' '):PORT${CL}"
```

### Addon Script Rules

- Self-contained: define color vars, msg functions, and telemetry inline
- Use `&>/dev/null` to suppress output (not `$STD` — that comes from tools.func) — this includes verification commands like `brew --version`
- Use `whiptail` or `read -r -p` for user confirmation
- Use `getent passwd "$USER" | cut -d: -f6` to resolve home directories — never `eval echo "~$USER"` (command injection risk)
- Heredoc style: `cat <<'EOF'> /path/to/file` (no space before `>`) — this matches codebase convention
- Include an exit guard to prevent running on the Proxmox host:
  ```bash
  if command -v pveversion >/dev/null 2>&1; then
    echo -e "⚠️  Can't Install on Proxmox host"
    exit
  fi
  ```
- Do NOT call `motd_ssh`, `customize`, or `cleanup_lxc`
- Do NOT use `source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"` — that only works inside the ct build pipeline
- End with a success message showing the access URL or status
- Telemetry: `init_tool_telemetry "appname" "addon"`

### Advanced: Multi-OS + Menu Pattern

For addons supporting both Debian and Alpine, use separate functions per OS and action:

```bash
install_app_debian() { ... }
install_app_alpine() { ... }
update_app_debian() { ... }
update_app_alpine() { ... }
uninstall_app_debian() { ... }
uninstall_app_alpine() { ... }

# OS detection
if [ -f /etc/alpine-release ]; then
  OS="alpine"
elif [ -f /etc/debian_version ]; then
  OS="debian"
else
  msg_error "Unsupported OS"
  exit 1
fi

# Menu
CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "AppName" \
  --menu "Select action:" 12 58 3 \
  "Install" "Install AppName" \
  "Update" "Update AppName" \
  "Uninstall" "Remove AppName" \
  3>&1 1>&2 2>&3)

case "$CHOICE" in
  Install)   install_app_${OS} ;;
  Update)    update_app_${OS} ;;
  Uninstall) uninstall_app_${OS} ;;
esac
```

### Service Creation by OS

**Debian (systemd):**
```bash
cat <<EOF >/etc/systemd/system/appname.service
[Unit]
Description=AppName Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/appname
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now appname
```

**Alpine (OpenRC):**
```bash
cat <<EOF >/etc/init.d/appname
#!/sbin/openrc-run
description="AppName Service"
command="/usr/local/bin/appname"
command_background=true
pidfile="/run/appname.pid"
EOF
chmod +x /etc/init.d/appname
rc-update add appname default
rc-service appname start
```

---

## File 2: JSON Metadata

See `json-metadata.md`. For addon scripts, set:
- `"type": "addon"`
- `"install_methods[].script": "tools/addon/appname.sh"`
- All resource fields set to `null`
- Include note: `{"text": "Execute within an existing LXC Console", "type": "info"}`

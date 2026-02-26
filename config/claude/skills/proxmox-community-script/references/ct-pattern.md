# Container Script Pattern (ct type)

A container contribution consists of exactly 3 files.

## File 1: CT Script (`ct/AppName.sh`)

This runs on the Proxmox host. It creates the LXC container, sets resource defaults, and provides an update mechanism.

```bash
#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: AuthorName (GitHubUsername)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://application-url.com

APP="AppName"
var_tags="${var_tags:-tag1;tag2}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/appname ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "appname" "owner/repo"; then
    msg_info "Stopping Service"
    systemctl stop appname
    msg_ok "Stopped Service"

    msg_info "Backing up Data"
    cp -r /opt/appname/data /opt/appname_data_backup 2>/dev/null || true
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "appname" "owner/repo" "tarball" "latest" "/opt/appname"

    # App-specific rebuild steps here
    cd /opt/appname
    $STD npm ci
    $STD npm run build

    msg_info "Restoring Data"
    cp -r /opt/appname_data_backup/. /opt/appname/data/ 2>/dev/null || true
    rm -rf /opt/appname_data_backup
    msg_ok "Restored Data"

    msg_info "Starting Service"
    systemctl start appname
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:PORT${CL}"
```

### CT Script Rules

- `source <(curl ...)` must be the first executable line (before the copyright comment)
- All `var_*` use `${var_name:-default}` default-value form
- `var_tags` uses semicolons, max 2-3 tags
- `var_unprivileged="0"` only for apps needing Docker/Podman inside the container
- `var_version` defaults to `13` (Debian 13) unless app requires something else
- `update_script()` is mandatory — always end it with bare `exit` (not `exit 0`)
- `check_for_gh_release` and `fetch_and_deploy_gh_release` are never wrapped in msg blocks
- The completion message must show the actual access URL with `http://${IP}:PORT`

### Update Script: 8-Step Pattern

1. Check installation exists (`[[ ! -d /opt/appname ]]`)
2. Check for new release (`check_for_gh_release`)
3. Stop services
4. Backup critical data (.env, uploads, data dirs)
5. Deploy new version (`CLEAN_INSTALL=1 fetch_and_deploy_gh_release`)
6. Rebuild if needed
7. Restore data, remove backup
8. Start services, confirm success, then bare `exit`

---

## File 2: Install Script (`install/appname-install.sh`)

This runs inside the container. It installs and configures the application.

```bash
#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: AuthorName (GitHubUsername)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://application-url.com

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  package1 \
  package2
msg_ok "Installed Dependencies"

# Runtime setup — tools.func functions, NO msg wrapper
NODE_VERSION="22" setup_nodejs

# Database setup — tools.func functions, NO msg wrapper
PG_VERSION="17" setup_postgresql
PG_DB_NAME="appname" PG_DB_USER="appname" setup_postgresql_db

# Get container IP for config files
get_lxc_ip

# App download — tools.func function, NO msg wrapper
fetch_and_deploy_gh_release "appname" "owner/repo" "tarball" "latest" "/opt/appname"

msg_info "Configuring AppName"
cd /opt/appname
$STD npm ci
$STD npm run build
cat <<EOF >/opt/appname/.env
DATABASE_URL=postgresql://${PG_DB_USER}:${PG_DB_PASS}@localhost/${PG_DB_NAME}
HOST=${LOCAL_IP}
PORT=3000
EOF
msg_ok "Configured AppName"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/appname.service
[Unit]
Description=AppName Service
After=network.target postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/appname
ExecStart=/usr/bin/node /opt/appname/server.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now appname
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
```

### Install Script Rules

- The six setup calls (`color`, `verb_ip6`, `catch_errors`, `setting_up_container`, `network_check`, `update_os`) are always present in that exact order
- `$STD` before every `apt`, `npm`, `go build`, `cargo`, `composer`, `pip` command
- Use `apt` not `apt-get` for all package operations
- Do not add `ca-certificates`, `curl`, `gnupg`, `git`, `build-essential` to Dependencies — `build.func` handles those
- Files always written with heredocs (`cat <<EOF >/path/to/file`) — never `echo >>`, `printf`, or `tee`
- For quoted heredocs (no variable expansion), use `cat <<'EOF'> /path/to/file` (no space before `>`)
- `.env` files: plain `KEY=VALUE` format, never `export KEY=VALUE`
- Use `getent passwd "$USER" | cut -d: -f6` to resolve home directories — never `eval echo "~$USER"` (command injection risk)
- No `systemctl daemon-reload` for new service units
- No `useradd` — LXC containers run as root
- No `sudo` — already root
- Footer is always exactly: `motd_ssh` + `customize` + `cleanup_lxc`
- `setup_postgresql_db` auto-creates `~/appname.creds` — do not create your own credentials file
- After `setup_postgresql_db`: `$PG_DB_NAME`, `$PG_DB_USER`, `$PG_DB_PASS` are available
- After `setup_mariadb_db`: `$MARIADB_DB_NAME`, `$MARIADB_DB_USER`, `$MARIADB_DB_PASS` are available
- Call `get_lxc_ip` before any config that needs `$LOCAL_IP`

---

## File 3: JSON Metadata

See `json-metadata.md` for the complete schema. For ct type scripts, set:
- `"type": "ct"`
- `"install_methods[].script": "ct/appname.sh"`
- Fill all resource fields with real values

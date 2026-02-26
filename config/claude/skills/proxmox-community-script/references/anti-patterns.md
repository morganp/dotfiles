# Anti-Patterns (Will Get Your PR Rejected)

## 1. Docker-Based Installation
```bash
# WRONG
docker pull myapp:latest
docker run -d --name myapp myapp:latest

# CORRECT — bare-metal installation
fetch_and_deploy_gh_release "myapp" "owner/repo"
cd /opt/myapp
$STD npm install && $STD npm run build
```

## 2. Custom Download Logic
```bash
# WRONG
RELEASE=$(curl -s https://api.github.com/repos/owner/repo/releases/latest | jq -r '.tag_name')
wget https://github.com/owner/repo/archive/${RELEASE}.tar.gz
tar -xzf ${RELEASE}.tar.gz

# CORRECT
fetch_and_deploy_gh_release "myapp" "owner/repo" "tarball" "latest" "/opt/myapp"
```

## 3. Custom Version Check
```bash
# WRONG
CURRENT=$(cat /opt/myapp/version.txt)
LATEST=$(curl -s ... | jq -r '.tag_name')
if [[ "$CURRENT" != "$LATEST" ]]; then ...

# CORRECT
if check_for_gh_release "myapp" "owner/repo"; then ...
```

## 4. Custom Runtime Installation
```bash
# WRONG
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt install -y nodejs

# CORRECT
NODE_VERSION="22" setup_nodejs
```

## 5. Wrapping tools.func Functions in msg Blocks
```bash
# WRONG — these functions have their own msg output
msg_info "Installing Node.js"
NODE_VERSION="22" setup_nodejs
msg_ok "Installed Node.js"

# CORRECT — call directly
NODE_VERSION="22" setup_nodejs
```

Functions that must NOT be wrapped: `fetch_and_deploy_gh_release`, `check_for_gh_release`, `setup_nodejs`, `setup_postgresql`, `setup_postgresql_db`, `setup_mariadb`, `setup_mariadb_db`, `setup_mongodb`, `setup_mysql`, `setup_ruby`, `setup_go`, `setup_java`, `setup_php`, `setup_uv`, `setup_rust`, `setup_composer`, `setup_ffmpeg`, `setup_imagemagick`, `setup_gs`, `setup_adminer`, `setup_hwaccel`

## 6. Using echo for Logging
```bash
# WRONG
echo "Installing dependencies..."
apt install -y curl
echo "Done!"

# CORRECT
msg_info "Installing Dependencies"
$STD apt install -y curl
msg_ok "Installed Dependencies"
```

## 7. Missing $STD
```bash
# WRONG
apt install -y nginx

# CORRECT
$STD apt install -y nginx
```

## 8. Creating System Users
```bash
# WRONG — LXC containers run as root
useradd -m -s /bin/bash appuser
chown -R appuser:appuser /opt/myapp
sudo -u appuser npm install

# CORRECT — run as root
cd /opt/myapp
$STD npm install
```

## 9. Using sudo
```bash
# WRONG — already root in LXC
sudo -u postgres psql -c "CREATE DATABASE mydb;"

# CORRECT
PG_DB_NAME="mydb" PG_DB_USER="myuser" setup_postgresql_db
```

## 10. export in .env Files
```bash
# WRONG
cat <<EOF >/opt/myapp/.env
export DATABASE_URL=postgres://...
export SECRET_KEY=abc123
EOF

# CORRECT
cat <<EOF >/opt/myapp/.env
DATABASE_URL=postgres://...
SECRET_KEY=abc123
EOF
```

## 11. External Shell Scripts
```bash
# WRONG
cat <<'EOF' >/opt/myapp/install_script.sh
#!/bin/bash
cd /opt/myapp && npm install && npm run build
EOF
chmod +x /opt/myapp/install_script.sh
bash /opt/myapp/install_script.sh

# CORRECT — inline
cd /opt/myapp
$STD npm install
$STD npm run build
```

## 12. Unnecessary daemon-reload
```bash
# WRONG — new services don't need this
cat <<EOF >/etc/systemd/system/myapp.service
...
EOF
systemctl daemon-reload
systemctl enable --now myapp

# CORRECT
cat <<EOF >/etc/systemd/system/myapp.service
...
EOF
systemctl enable -q --now myapp
```

## 13. Custom Credentials Files
```bash
# WRONG — setup_postgresql_db creates ~/appname.creds automatically
cat <<EOF >~/myapp.creds
DB User: ${DB_USER}
DB Pass: ${DB_PASS}
EOF

# CORRECT — let the function handle it
PG_DB_NAME="myapp" PG_DB_USER="myapp" setup_postgresql_db
```

## 14. Wrong Footer
```bash
# WRONG
motd_ssh
customize
msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
msg_ok "Cleaned"

# CORRECT
motd_ssh
customize
cleanup_lxc
```

## 15. Manual Database Creation
```bash
# WRONG
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)
$STD sudo -u postgres psql -c "CREATE ROLE myuser WITH LOGIN PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE mydb WITH OWNER myuser;"

# CORRECT
PG_DB_NAME="mydb" PG_DB_USER="myuser" setup_postgresql_db
```

## 16. Writing Files Without Heredocs
```bash
# WRONG
echo "port: 3000" > /opt/myapp/config.yml
echo "host: 0.0.0.0" >> /opt/myapp/config.yml

# CORRECT
cat <<EOF >/opt/myapp/config.yml
port: 3000
host: 0.0.0.0
EOF
```

## 17. Pointless Variables
```bash
# WRONG — unnecessary variables used once
APP_NAME="myapp"
APP_DIR="/opt/${APP_NAME}"
APP_PORT="3000"
cd $APP_DIR

# CORRECT — use directly
cd /opt/myapp
```
Only create variables when used multiple times or needed for readability.

## 18. Using eval to Resolve Home Directories
```bash
# WRONG — command injection risk
BREW_USER_HOME=$(eval echo "~$BREW_USER")

# CORRECT — safe lookup via getent
BREW_USER_HOME=$(getent passwd "$BREW_USER" | cut -d: -f6)
```

## 19. Unsuppressed Verification Output
```bash
# WRONG — raw output bleeds into styled msg_info/msg_ok lines
msg_info "Verifying Installation"
su - "$BREW_USER" -c 'brew --version'
msg_ok "Verified"

# CORRECT — suppress output
msg_info "Verifying Installation"
su - "$BREW_USER" -c 'brew --version' &>/dev/null
msg_ok "Verified"
```

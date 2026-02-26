# tools.func Helper Functions Reference

These functions are available in install scripts via `$FUNCTIONS_FILE_PATH`. They handle their own `msg_info`/`msg_ok` output — never wrap them in additional msg blocks.

## Release Management

| Function | Usage | Notes |
|---|---|---|
| `fetch_and_deploy_gh_release` | `fetch_and_deploy_gh_release "app" "owner/repo" "tarball" "latest" "/opt/app"` | Primary download method. Handles version tracking. |
| `check_for_gh_release` | `if check_for_gh_release "app" "owner/repo"; then` | Use in `update_script()` only |
| `get_latest_github_release` | `RELEASE=$(get_latest_github_release "owner/repo")` | Only when version string needed separately |

### fetch_and_deploy_gh_release Modes

```bash
# Tarball/Source (default)
fetch_and_deploy_gh_release "app" "owner/repo"

# Tarball to specific directory
fetch_and_deploy_gh_release "app" "owner/repo" "tarball" "latest" "/opt/app"

# Binary (.deb package, auto-detects arch)
fetch_and_deploy_gh_release "app" "owner/repo" "binary"

# Prebuilt archive (specify asset filename pattern)
fetch_and_deploy_gh_release "app" "owner/repo" "prebuild" "latest" "/opt/app" "filename.tar.gz"

# Single binary file
fetch_and_deploy_gh_release "app" "owner/repo" "singlefile" "latest" "/opt/app" "binary-linux-amd64"

# Zipball
fetch_and_deploy_gh_release "app" "owner/repo" "zipball"
```

### Clean Install Flag

```bash
# Removes destination before extracting — use in update_script only
CLEAN_INSTALL=1 fetch_and_deploy_gh_release "app" "owner/repo" "tarball" "latest" "/opt/app"
```

## Runtime/Language Setup

| Function | Config Variables | Example |
|---|---|---|
| `setup_nodejs` | `NODE_VERSION`, `NODE_MODULE` | `NODE_VERSION="22" setup_nodejs` |
| `setup_uv` | `PYTHON_VERSION` | `PYTHON_VERSION="3.13" setup_uv` |
| `setup_go` | `GO_VERSION` | `setup_go` |
| `setup_rust` | `RUST_VERSION`, `RUST_CRATES` | `RUST_CRATES="monolith" setup_rust` |
| `setup_ruby` | `RUBY_VERSION` | `setup_ruby` |
| `setup_java` | `JAVA_VERSION` | `JAVA_VERSION="21" setup_java` |
| `setup_php` | `PHP_VERSION`, `PHP_MODULE`, `PHP_FPM`, `PHP_APACHE` | `PHP_VERSION="8.4" PHP_FPM="YES" setup_php` |
| `setup_composer` | (none) | Call after `setup_php` |

## Database Setup

| Function | Config Variables | Example |
|---|---|---|
| `setup_postgresql` | `PG_VERSION` | `PG_VERSION="17" setup_postgresql` |
| `setup_postgresql_db` | `PG_DB_NAME`, `PG_DB_USER`, `PG_DB_EXTENSIONS` | `PG_DB_NAME="myapp" PG_DB_USER="myapp" setup_postgresql_db` |
| `setup_mariadb` | (none) | `setup_mariadb` |
| `setup_mariadb_db` | `MARIADB_DB_NAME`, `MARIADB_DB_USER` | `MARIADB_DB_NAME="myapp" MARIADB_DB_USER="myapp" setup_mariadb_db` |
| `setup_mysql` | `MYSQL_VERSION` | `setup_mysql` |
| `setup_mongodb` | `MONGO_VERSION` | `setup_mongodb` |
| `setup_clickhouse` | (none) | `setup_clickhouse` |

### Auto-Generated Variables After Database Setup

- After `setup_postgresql_db`: `$PG_DB_NAME`, `$PG_DB_USER`, `$PG_DB_PASS`
- After `setup_mariadb_db`: `$MARIADB_DB_NAME`, `$MARIADB_DB_USER`, `$MARIADB_DB_PASS`
- Credentials auto-saved to `~/appname.creds`

## Tools & Utilities

| Function | Description |
|---|---|
| `get_lxc_ip` | Sets `$LOCAL_IP` — call before any config needing the container IP |
| `setup_ffmpeg` | FFmpeg with codecs |
| `setup_hwaccel` | GPU hardware acceleration (Intel/AMD/NVIDIA) |
| `setup_imagemagick` | ImageMagick 7 from source |
| `setup_docker` | Docker Engine |
| `setup_adminer` | Adminer database web UI |
| `setup_meilisearch` | Meilisearch search engine |
| `create_self_signed_cert` | Creates `/etc/ssl/appname/appname.key` and `.crt` |
| `setup_yq` | yq YAML processor |
| `ensure_dependencies` | `ensure_dependencies jq unzip curl` |
| `install_packages_with_retry` | `install_packages_with_retry nginx redis` |
| `setup_deb822_repo` | Modern Debian 12+ repo addition |

## Messaging

| Function | Usage |
|---|---|
| `msg_info "text"` | Yellow spinner — use only for custom code steps |
| `msg_ok "text"` | Green checkmark |
| `msg_error "text"` | Red error |
| `msg_warn "text"` | Warning |

Remember: tools.func setup functions (`setup_nodejs`, `fetch_and_deploy_gh_release`, etc.) emit their own msg_info/msg_ok output. Never wrap them in additional msg blocks.

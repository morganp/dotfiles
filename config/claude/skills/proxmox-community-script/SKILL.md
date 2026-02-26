---
name: proxmox-community-script
description: >
  Create properly-structured scripts for the Proxmox VE Community Scripts project
  (community-scripts/ProxmoxVE). Use this skill whenever the user mentions Proxmox scripts,
  ProxmoxVE community scripts, LXC container scripts, LXC addon scripts, or wants to contribute
  a new application to the ProxmoxVE helper scripts project. Also trigger when the user mentions
  ct/ scripts, install scripts for Proxmox containers, or the ProxmoxVED testing repo. Even if
  the user just says "create a script for X on Proxmox" or "add X to the community scripts",
  this skill applies.
---

# Proxmox VE Community Script Creator

This skill generates scripts that conform to the [community-scripts/ProxmoxVE](https://github.com/community-scripts/ProxmoxVE) project conventions. Every detail matters — maintainers enforce strict formatting and will close PRs that deviate.

## First: Determine the Script Type

There are two types of contributions. Ask the user which one they need if it's not obvious:

| Type | When to use | Files to create |
|---|---|---|
| **Container (ct)** | App needs its own LXC container (web apps, services, databases) | `ct/AppName.sh` + `install/appname-install.sh` + `frontend/public/json/appname.json` |
| **Addon** | Tool installs into an *existing* container (monitoring agents, utilities, package managers) | `tools/addon/appname.sh` + `frontend/public/json/appname.json` |

## Submission Requirement

New scripts must be submitted to [ProxmoxVED](https://github.com/community-scripts/ProxmoxVED) for testing first. PRs to the main ProxmoxVE repo without prior testing in ProxmoxVED will be closed.

## Workflow

1. Determine script type (container vs addon)
2. Research the application (GitHub repo, install docs, dependencies, ports)
3. Generate all required files
4. Guide the user through testing via their GitHub fork
5. Submit PR to ProxmoxVED (not ProxmoxVE)

## Container Scripts (ct type)

Read `references/ct-pattern.md` for the complete ct script template, install script template, and JSON metadata template with all conventions and rules.

Key points:
- CT script runs on the Proxmox **host** — it creates the LXC container
- Install script runs **inside** the container — it installs the application
- The CT script must include an `update_script()` function
- Install script must end with `motd_ssh` + `customize` + `cleanup_lxc`
- Default OS is Debian 13 unless the app requires something specific

## Addon Scripts (addon type)

Read `references/addon-pattern.md` for the complete addon script template and JSON metadata template.

Key points:
- Addon scripts are self-contained (inline color vars, msg functions, telemetry)
- They do NOT use `$FUNCTIONS_FILE_PATH` or `build.func`
- They must detect the OS (Debian vs Alpine) and handle both
- They use `whiptail` or `read` prompts for user confirmation
- No `motd_ssh`, `customize`, or `cleanup_lxc` at the end

## Critical Anti-Patterns (will get your PR rejected)

These are the most common mistakes. Read `references/anti-patterns.md` for the full list with examples.

1. **Never use Docker** — all installs must be bare-metal
2. **Never implement custom download logic** — use `fetch_and_deploy_gh_release`
3. **Never install runtimes manually** — use `setup_nodejs`, `setup_uv`, etc.
4. **Never wrap tools.func functions in msg_info/msg_ok** — they emit their own output
5. **Never use `sudo`** — LXC containers already run as root
6. **Never use `echo` for logging** — use `msg_info`/`msg_ok`/`msg_error`
7. **Always prefix build commands with `$STD`** — suppresses verbose output
8. **Always use heredocs for file creation** — never `echo >>` or `printf`
9. **Never create unnecessary system users** — run as root in LXC
10. **Never add `systemctl daemon-reload`** for new service units
11. **Never use `eval echo "~$USER"`** to resolve home dirs — use `getent passwd "$USER" | cut -d: -f6`
12. **Suppress verification output** — commands like `brew --version` need `&>/dev/null` to avoid breaking styled output

## Helper Functions Reference

Read `references/helper-functions.md` for the complete list of available `tools.func` helper functions including:
- Release management (`fetch_and_deploy_gh_release`, `check_for_gh_release`)
- Runtime setup (`setup_nodejs`, `setup_uv`, `setup_go`, `setup_rust`, `setup_php`, etc.)
- Database setup (`setup_postgresql`, `setup_postgresql_db`, `setup_mariadb_db`, etc.)
- Utilities (`get_lxc_ip`, `setup_ffmpeg`, `create_self_signed_cert`, etc.)

## JSON Metadata

Read `references/json-metadata.md` for the complete JSON schema, category IDs (0-25), and field rules.

## Testing Workflow

1. Fork `community-scripts/ProxmoxVED` on GitHub
2. Add your files to the fork
3. Push and wait 10-30 seconds for GitHub to propagate
4. Test via curl from the fork:
   ```bash
   bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/ProxmoxVED/main/ct/myapp.sh)"
   ```
5. For debugging, enable dev mode:
   ```bash
   dev_mode="trace,keep" bash -c "$(curl -fsSL ...)"
   ```
6. Once tested, create a clean submission branch with only your files:
   ```bash
   git fetch upstream
   git checkout -b submit/myapp upstream/main
   # Copy only your 3 files (ct + install + json, or addon + json)
   git add ct/myapp.sh install/myapp-install.sh frontend/public/json/myapp.json
   git commit -m "Add MyApp container script"
   ```
7. Verify PR contains only your files: `git diff upstream/main --name-only`
8. Open PR against `community-scripts/ProxmoxVED`

## Code Style

- Shebang: `#!/usr/bin/env bash`
- Indentation: 2 spaces
- Copyright: `# Copyright (c) 2021-2026 community-scripts ORG`
- Variables: quote with `"${VAR}"` or `"$VAR"`; use `[[ ]]` not `[ ]`
- `var_*` defaults: always use `${var_name:-default}` form
- Long apt installs: multiline with `\` continuation
- Comments: explain *why*, not *what*

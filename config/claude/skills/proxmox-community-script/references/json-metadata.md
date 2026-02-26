# JSON Metadata Reference

Every contribution needs a JSON file at `frontend/public/json/appname.json`.

## Container (ct) Type Template

```json
{
  "name": "AppName",
  "slug": "appname",
  "categories": [9],
  "date_created": "2026-01-18",
  "type": "ct",
  "updateable": true,
  "privileged": false,
  "interface_port": 3000,
  "documentation": "https://docs.example.com/",
  "website": "https://example.com/",
  "logo": "https://cdn.jsdelivr.net/gh/selfhst/icons@main/webp/appname.webp",
  "config_path": "/opt/appname/.env",
  "description": "Short description of what AppName does and its main features.",
  "install_methods": [
    {
      "type": "default",
      "script": "ct/appname.sh",
      "resources": {
        "cpu": 2,
        "ram": 2048,
        "hdd": 8,
        "os": "Debian",
        "version": "13"
      }
    }
  ],
  "default_credentials": {
    "username": null,
    "password": null
  },
  "notes": []
}
```

## Addon Type Template

```json
{
  "name": "AppName",
  "slug": "appname",
  "categories": [0],
  "date_created": "2026-01-18",
  "type": "addon",
  "updateable": false,
  "privileged": false,
  "interface_port": null,
  "documentation": "https://docs.example.com/",
  "website": "https://example.com/",
  "logo": "https://cdn.jsdelivr.net/gh/selfhst/icons@main/webp/appname.webp",
  "config_path": "",
  "description": "Short description of what AppName does.",
  "install_methods": [
    {
      "type": "default",
      "script": "tools/addon/appname.sh",
      "resources": {
        "cpu": null,
        "ram": null,
        "hdd": null,
        "os": null,
        "version": null
      }
    }
  ],
  "default_credentials": {
    "username": null,
    "password": null
  },
  "notes": [
    {
      "text": "Execute within an existing LXC Console",
      "type": "info"
    }
  ]
}
```

## Field Rules

| Field | Type | Notes |
|---|---|---|
| `name` | string | Display name of the application |
| `slug` | string | Lowercase, no spaces, matches filenames |
| `categories` | array | Category ID(s) from the list below |
| `date_created` | string | `YYYY-MM-DD` format |
| `type` | string | `"ct"`, `"addon"`, or `"vm"` |
| `updateable` | boolean | `true` only if `update_script()` is implemented |
| `privileged` | boolean | `false` default; `true` only for Docker/Podman containers |
| `interface_port` | number/null | Primary web UI port, or `null` if no web interface |
| `documentation` | string | Link to official docs |
| `website` | string | Link to official website |
| `logo` | string | `https://cdn.jsdelivr.net/gh/selfhst/icons@main/webp/appname.webp` |
| `config_path` | string | Path to main config file, or `""` if none |
| `description` | string | Brief description of the application |
| `install_methods` | array | Installation configurations |
| `default_credentials` | object | Default username/password (or both `null`) |
| `notes` | array | Additional notes/warnings |

### Notes Types

- `"info"` — general information
- `"warning"` — important caveats
- `"error"` — critical warnings

## Category IDs

| ID | Category |
|---|---|
| 0 | Miscellaneous |
| 1 | Proxmox & Virtualization |
| 2 | Operating Systems |
| 3 | Containers & Docker |
| 4 | Network & Firewall |
| 5 | Adblock & DNS |
| 6 | Authentication & Security |
| 7 | Backup & Recovery |
| 8 | Databases |
| 9 | Monitoring & Analytics |
| 10 | Dashboards & Frontends |
| 11 | Files & Downloads |
| 12 | Documents & Notes |
| 13 | Media & Streaming |
| 14 | *Arr Suite |
| 15 | NVR & Cameras |
| 16 | IoT & Smart Home |
| 17 | ZigBee, Z-Wave & Matter |
| 18 | MQTT & Messaging |
| 19 | Automation & Scheduling |
| 20 | AI / Coding & Dev-Tools |
| 21 | Webservers & Proxies |
| 22 | Bots & ChatOps |
| 23 | Finance & Budgeting |
| 24 | Gaming & Leisure |
| 25 | Business & ERP |

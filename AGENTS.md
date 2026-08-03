# AGENTS.md

Guidance for AI agents (and humans) working on **proKc**.

## Project overview

proKc is a **KDE Plasma 6 applet (plasmoid)** that toggles the system proxy
ON/OFF with a single click. Clicking the widget:

1. Runs a bundled bash script that sets the standard proxy environment
   variables (`HTTP_PROXY`, `HTTPS_PROXY`, `FTP_PROXY`, `ALL_PROXY`,
   `SOCKS_PROXY`, `NO_PROXY` and their lowercase forms).
2. Propagates them to the **systemd user session** (`systemctl --user
   import-environment`) and the **D-Bus activation environment**
   (`dbus-update-activation-environment --systemd`), so newly launched
   processes pick the proxy up.
3. Optionally (settings checkbox) drives the **GNOME proxy stack via
   `gsettings`**, which lets browsers apply the proxy dynamically without a
   restart.

- Package ID: `com.n3thshan.prokc`
- Author: n3thshan
- License: **GPL-3.0-or-later** (SPDX headers required in every source file)
- Targets Plasma 6 (`X-Plasma-API-Minimum-Version: 6.0`)

## Tech stack

- **QML / QtQuick** for the widget UI and settings page (Plasma 6 / Qt 6)
- **KDE Frameworks**: `org.kde.plasma.plasmoid`, `org.kde.plasma.core`,
  `org.kde.kirigami`, `org.kde.plasma.plasma5support` (executable engine),
  KCM (`org.kde.kcmutils`), icon themes (`org.kde.iconthemes`)
- **Bash** for the proxy scripts (`set -uo pipefail`)
- **KConfig XT** (`contents/config/main.xml`) for the configuration schema
- **Make** + `zip` to build the distributable `.plasmoid` package

## Project structure

```
proKc/
├── AGENTS.md                      # this file
├── LICENSE                        # GPL-3.0-or-later
├── Makefile                       # builds prokc.plasmoid (zip)
├── metadata.json                  # KPackage metadata (Plasma/Applet)
├── prokc.plasmoid                 # build artifact (committed zip)
└── contents/
    ├── config/
    │   ├── config.qml             # ConfigModel → General page
    │   └── main.xml               # KConfig XT schema (all settings + defaults)
    ├── scripts/
    │   ├── proxy_on.sh            # enable proxy (env + systemd + dbus + gsettings)
    │   ├── proxy_off.sh           # disable proxy (clears env everywhere)
    │   └── gsettings_off.sh       # reset GNOME proxy mode to 'none' (run when the
    │                              #   "Dynamic browser proxy" setting is unchecked)
    └── ui/
        ├── main.qml               # plasmoid UI: icon, tooltip, click-to-toggle
        └── configGeneral.qml      # settings page (KCM.SimpleKCM)
```

## Build / test / install

```sh
make            # zip -FS -r prokc.plasmoid contents metadata.json
make clean      # rm -f prokc.plasmoid
```

Install the built package for testing:

```sh
kpackagetool6 --type=Plasma/Applet --install prokc.plasmoid
# or for iteration:
plasmashell --replace &   # after re-installing to reload
```

Manual functional check (what the widget does under the hood):

```sh
systemctl --user show-environment | grep -q '^HTTP_PROXY=.' && echo ON || echo OFF
bash contents/scripts/proxy_on.sh 127.0.0.1 1081 1080 \
     'localhost,127.0.0.1,::1,localaddress,.localdomain.com' 0
bash contents/scripts/proxy_off.sh 0
```

## Architecture & key concepts

### State model

- **Source of truth**: the systemd user environment. The widget considers the
  proxy **ON** iff `systemctl --user show-environment` contains a non-empty
  `HTTP_PROXY=`.
- On load (`Component.onCompleted`) and ~700 ms after each toggle
  (`syncTimer`), the widget runs the state-query command via the
  `executable` `Plasma5Support.DataSource` and re-syncs `proxyEnabled`.

### main.qml flow

- `toggleProxy()` flips `proxyEnabled` optimistically, builds the command,
  executes it, then re-syncs with real system state via `syncTimer`.
- `buildCommand(enable)` composes `bash <script> <args>` with everything
  shell-quoted via `shellQuote()` (single-quote wrapping with `'\''`
  escaping).
- Args for ON: `host port socksPort noProxy gsettingsFlag`.
- Args for OFF: `gsettingsFlag` only.
- A 300 ms debounce (`lastClick`) guards against accidental double-clicks
  toggling twice.
- Icon and tooltip reflect `proxyEnabled` using the configured
  `iconOn`/`iconOff` names.
- A `Connections` on `plasmoid.configuration` watches `onValueChanged(key)`.
  When `enableGsettings` flips **true → false** (user unchecks "Dynamic
  browser proxy" in settings), `resetGsettingsProxy()` runs
  `gsettings_off.sh`, resetting `org.gnome.system.proxy mode` to `none` so
  browsers stop applying the proxy immediately. (Without this, the GNOME
  stack would stay at whatever mode the last toggle set, e.g. `manual`.)

### proxy_on.sh

- Requires host + http port; defaults socks port, NO_PROXY list, gsettings flag.
- Exports upper- and lowercase proxy vars, then:
  1. `systemctl --user import-environment` (propagate to systemd user session)
  2. `dbus-update-activation-environment --systemd` (propagate to D-Bus activation env)
  3. If gsettings=1 and available: sets `org.gnome.system.proxy` to `manual`
     with host/ports, and maps NO_PROXY entries (minus safe defaults
     `localhost`, `127.0.0.0/8`, `::1`, `localaddress`, `.localdomain.com`)
     into `ignore-hosts` as a GVariant array.

### proxy_off.sh

- Unsets all proxy vars in the current shell.
- **Order matters** (documented in the script):
  1. First clear the D-Bus activation environment with **empty values**
     (dbus env cannot unset, only overwrite).
  2. Then `systemctl --user unset-environment` — must run *after* the D-Bus
     update, otherwise `--systemd` re-imports the empty values back.
- If gsettings=1: resets `org.gnome.system.proxy mode` to `none`.

### Config schema (contents/config/main.xml)

| Key            | Type   | Default                                                             |
| -------------- | ------ | ------------------------------------------------------------------- |
| `iconOn`       | String | `network-connect`                                                    |
| `iconOff`      | String | `network-disconnect`                                                 |
| `host`         | String | `127.0.0.1`                                                          |
| `port`         | Int    | `1081` (HTTP/HTTPS)                                                  |
| `socksPort`    | Int    | `1080` (SOCKS)                                                       |
| `noProxy`      | String | `localhost,127.0.0.1,::1,localaddress,.localdomain.com`              |
| `enableGsettings` | Bool | `false`                                                              |

## Code conventions

- **SPDX headers**: every source file starts with a comment block containing
  `SPDX-FileCopyrightText: <year> <author>` and
  `SPDX-License-Identifier: GPL-3.0-or-later` (note: `config.qml` retains the
  upstream `GPL-2.0-or-later` header, and the existing bash scripts only carry
  descriptive headers — add SPDX blocks when touching them).
- **i18n**: all user-visible strings wrapped in `i18n()` / `i18nc()` with a
  proper context comment (e.g. `i18nc("@label:textbox", "Host:")`).
- **Script style**: bash scripts use `#!/usr/bin/env bash`, `set -uo
  pipefail`, `${1:?error message}` for required args, `|| true` for
  best-effort side effects, and guard external commands with `command -v`.
- **Plasma 6, not 5**: `Plasmoid.file()` no longer exists; paths are resolved
  with `Qt.resolvedUrl()` + `decodeURIComponent()` + stripping `file://`.
- **Defaults live in multiple places**: `contents/config/main.xml` (schema),
  the `*Default` properties in `configGeneral.qml` (used by KCM Reset), *and*
  the `IconPicker.defaultValue` in `configGeneral.qml` (fallback when the icon
  dialog returns empty). All three must stay consistent when changing
  defaults — the schema (`main.xml`) is authoritative.
- Config page binds to `plasmoid.configuration` via `cfg_*` properties —
  adding a new setting requires touching: `main.xml`, `configGeneral.qml`
  (property + UI), and `main.qml` (where used).

## Gotchas

- The state-query command string is used as the `DataSource` source key;
  the `onNewData` handler matches on it. Keep the two in sync if you change
  the query.
- The `executable` engine results arrive asynchronously — always
  `disconnectSource()` in `onNewData` to avoid stale/leaked sources.
- Do not "fix" the ordering in `proxy_off.sh` (dbus-clear → systemd-unset);
  it is intentional and load-bearing.
- `ignore-hosts` in the gsettings path is built as a literal GVariant array
  string; keep the quoting (`'...'` entries, `, ` separators) intact.
- The debounce threshold (300 ms) is a deliberate guard; changing it affects
  toggle reliability on fast clicks.
- `prokc.plasmoid` is a committed build artifact; rebuild with `make` after
  editing anything under `contents/` or `metadata.json`.

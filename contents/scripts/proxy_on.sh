#!/usr/bin/env bash
# proKc — enable the system proxy
# Usage: proxy_on.sh <host> <http_port> <socks_port> <no_proxy_list> <gsettings: 0|1>
#
# Always sets proxy environment variables and propagates them to the
# systemd user session and the D-Bus activation environment so that newly
# launched processes pick them up.
#
# If gsettings is 1 (and the gsettings tool exists), the GNOME proxy stack
# is configured as well, which lets browsers apply the proxy dynamically
# without a restart. Custom NO_PROXY entries are mapped into
# org.gnome.system.proxy.ignore-hosts alongside the safe defaults.
set -uo pipefail

HOST="${1:?host required}"
PORT="${2:?http port required}"
SOCKS_PORT="${3:?socks port required}"
NO_PROXY_LIST="${4:-localhost,127.0.0.1,::1,localaddress,.localdomain.com}"
GSETTINGS="${5:-0}"

export HTTP_PROXY="http://${HOST}:${PORT}"
export HTTPS_PROXY="http://${HOST}:${PORT}"
export FTP_PROXY="http://${HOST}:${PORT}"
export ALL_PROXY="socks5://${HOST}:${SOCKS_PORT}"
export SOCKS_PROXY="socks5://${HOST}:${SOCKS_PORT}"
export NO_PROXY="$NO_PROXY_LIST"
export http_proxy="$HTTP_PROXY" https_proxy="$HTTPS_PROXY" ftp_proxy="$FTP_PROXY" all_proxy="$ALL_PROXY" socks_proxy="$SOCKS_PROXY" no_proxy="$NO_PROXY_LIST"

# Propagate to the systemd user session
if command -v systemctl &>/dev/null; then
    systemctl --user import-environment \
        http_proxy https_proxy ftp_proxy socks_proxy all_proxy no_proxy \
        HTTP_PROXY HTTPS_PROXY FTP_PROXY SOCKS_PROXY ALL_PROXY NO_PROXY || true
fi

# Propagate to the D-Bus activation environment
if command -v dbus-update-activation-environment &>/dev/null; then
    dbus-update-activation-environment --systemd \
        http_proxy https_proxy ftp_proxy socks_proxy all_proxy no_proxy \
        HTTP_PROXY HTTPS_PROXY FTP_PROXY SOCKS_PROXY ALL_PROXY NO_PROXY || true
fi

# Optional: GNOME proxy stack (dynamic browser proxy)
if [[ "$GSETTINGS" == "1" ]] && command -v gsettings &>/dev/null; then
    gsettings set org.gnome.system.proxy mode 'manual'
    gsettings set org.gnome.system.proxy.http host "$HOST"
    gsettings set org.gnome.system.proxy.http port "$PORT"
    gsettings set org.gnome.system.proxy.https host "$HOST"
    gsettings set org.gnome.system.proxy.https port "$PORT"
    gsettings set org.gnome.system.proxy.ftp host "$HOST"
    gsettings set org.gnome.system.proxy.ftp port "$PORT"
    gsettings set org.gnome.system.proxy.socks host "$HOST"
    gsettings set org.gnome.system.proxy.socks port "$SOCKS_PORT"

    # ignore-hosts: safe defaults + custom NO_PROXY entries (best-effort mapping)
    IGNORE_HOSTS=("localhost" "127.0.0.0/8" "::1")
    IFS=',' read -ra ENTRIES <<< "$NO_PROXY_LIST"
    for e in "${ENTRIES[@]}"; do
        e="${e//[[:space:]]/}"
        [[ -z "$e" ]] && continue
        case "$e" in
            localhost|127.0.0.1|127.0.0.0/8|::1|localaddress|.localdomain.com) continue ;;
        esac
        IGNORE_HOSTS+=("$e")
    done
    GS_IGNORE="["
    for i in "${!IGNORE_HOSTS[@]}"; do
        [[ $i -gt 0 ]] && GS_IGNORE+=", "
        GS_IGNORE+="'${IGNORE_HOSTS[$i]}'"
    done
    GS_IGNORE+="]"
    gsettings set org.gnome.system.proxy ignore-hosts "$GS_IGNORE"
fi

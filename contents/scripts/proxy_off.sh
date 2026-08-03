#!/usr/bin/env bash
# proKc — disable the system proxy
# Usage: proxy_off.sh <gsettings: 0|1>
#
# Removes the proxy variables from the systemd user session and clears the
# D-Bus activation environment. If gsettings is 1, the GNOME proxy stack is
# reset to 'none' as well.
set -uo pipefail

GSETTINGS="${1:-0}"

unset http_proxy https_proxy ftp_proxy socks_proxy all_proxy no_proxy \
      HTTP_PROXY HTTPS_PROXY FTP_PROXY SOCKS_PROXY ALL_PROXY NO_PROXY || true

# Clear the D-Bus activation environment (it can only be overwritten with
# empty values, it cannot truly unset variables)
if command -v dbus-update-activation-environment &>/dev/null; then
    dbus-update-activation-environment --systemd \
        http_proxy="" https_proxy="" ftp_proxy="" socks_proxy="" all_proxy="" no_proxy="" \
        HTTP_PROXY="" HTTPS_PROXY="" FTP_PROXY="" SOCKS_PROXY="" ALL_PROXY="" NO_PROXY="" || true
fi

# Remove from the systemd user environment.
# Must run AFTER the D-Bus update, otherwise --systemd re-imports the empty
# values into the systemd manager environment.
if command -v systemctl &>/dev/null; then
    systemctl --user unset-environment \
        http_proxy https_proxy ftp_proxy socks_proxy all_proxy no_proxy \
        HTTP_PROXY HTTPS_PROXY FTP_PROXY SOCKS_PROXY ALL_PROXY NO_PROXY || true
fi

# Optional: GNOME proxy stack (dynamic browser proxy)
if [[ "${GSETTINGS}" == "1" ]] && command -v gsettings &>/dev/null; then
    gsettings set org.gnome.system.proxy mode "none" || true
fi

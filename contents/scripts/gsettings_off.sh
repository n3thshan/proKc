#!/usr/bin/env bash
# proKc — reset the GNOME proxy stack
#
# Usage: gsettings_off.sh
#
# Resets org.gnome.system.proxy mode to 'none'. Used when the "Dynamic
# browser proxy" setting (enableGsettings) is switched off: the toggle
# scripts only manage the GNOME stack while that setting is enabled, so
# without this reset browsers would keep applying the last proxy mode
# (e.g. 'manual') after the checkbox is unchecked.
#
# SPDX-FileCopyrightText: 2026 n3thshan
# SPDX-License-Identifier: GPL-3.0-or-later
set -uo pipefail

if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.system.proxy mode "none" || true
fi

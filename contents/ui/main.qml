/*
    proKc — system proxy toggle plasmoid

    Single click toggles the system proxy. Env vars are propagated to the
    systemd user session and the D-Bus activation environment so newly
    launched processes pick them up. Optionally (checkbox in settings) the
    GNOME proxy stack (gsettings) is driven too, letting browsers apply the
    proxy dynamically without a restart.

    State is detected from the systemd user environment (HTTP_PROXY set).

    SPDX-FileCopyrightText: 2026 n3thshan
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root

    width: Kirigami.Units.iconSizes.large
    height: Kirigami.Units.iconSizes.large

    Layout.minimumWidth: 0
    Layout.minimumHeight: 0
    Layout.preferredWidth: icon.width
    Layout.preferredHeight: icon.height

    // Bundled scripts, resolved relative to this file (contents/ui/ ->
    // contents/scripts/). Plasmoid.file() no longer exists in Plasma 6,
    // so we resolve the URL ourselves and strip the file:// prefix.
    readonly property string proxyOnScript: scriptPath("../scripts/proxy_on.sh")
    readonly property string proxyOffScript: scriptPath("../scripts/proxy_off.sh")
    readonly property string gsettingsOffScript: scriptPath("../scripts/gsettings_off.sh")
    readonly property string stateQueryCommand: "systemctl --user show-environment | grep -q '^HTTP_PROXY=.' && echo ON || echo OFF"

    // Current state; source of truth is the systemd user environment
    property bool proxyEnabled: false
    // Guards against accidental double-clicks toggling twice
    property real lastClick: 0

    Plasmoid.icon: root.proxyEnabled ? plasmoid.configuration.iconOn : plasmoid.configuration.iconOff

    PlasmaCore.ToolTipArea {
        id: tooltip
        anchors.fill: parent
        mainText: i18n("proKc: %1", root.proxyEnabled ? i18n("ON") : i18n("OFF"))
        subText: i18n("Click to toggle proxy")

        MouseArea {
            anchors.fill: parent
            onClicked: {
                const now = Date.now()
                if (now - root.lastClick < 300) {
                    return
                }
                root.lastClick = now
                root.toggleProxy()
            }
        }

        Kirigami.Icon {
            id: icon
            anchors.centerIn: parent
            height: Math.min(parent.height, parent.width)
            width: height
            source: root.proxyEnabled ? plasmoid.configuration.iconOn : plasmoid.configuration.iconOff
        }
    }

    function scriptPath(relative) {
        const url = Qt.resolvedUrl(relative).toString()
        // file:///path -> /path (also un-escapes %20 etc.)
        return decodeURIComponent(url.replace(/^file:\/\//, ""))
    }

    function toggleProxy() {
        root.proxyEnabled = !root.proxyEnabled
        executable.exec(root.buildCommand(root.proxyEnabled))
        // Re-sync with the real system state shortly after the script finishes
        syncTimer.restart()
    }

    function buildCommand(enable) {
        const gsettings = plasmoid.configuration.enableGsettings ? "1" : "0"
        if (enable) {
            return "bash " + shellQuote(root.proxyOnScript)
                 + " " + shellQuote(plasmoid.configuration.host)
                 + " " + String(plasmoid.configuration.port)
                 + " " + String(plasmoid.configuration.socksPort)
                 + " " + shellQuote(plasmoid.configuration.noProxy)
                 + " " + gsettings
        }
        return "bash " + shellQuote(root.proxyOffScript) + " " + gsettings
    }

    function shellQuote(s) {
        return "'" + String(s).replace(/'/g, "'\\''") + "'"
    }

    function syncState() {
        executable.exec(root.stateQueryCommand)
    }

    // When "Dynamic browser proxy" (enableGsettings) is unchecked, the GNOME
    // proxy stack keeps whatever mode the last toggle set (e.g. 'manual'), so
    // browsers would keep applying the proxy. Reset it to 'none' immediately.
    function resetGsettingsProxy() {
        executable.exec("bash " + shellQuote(root.gsettingsOffScript))
    }

    // plasmoid.configuration is a KConfigPropertyMap (a QQmlPropertyMap);
    // it emits valueChanged(key) whenever any config value changes — including
    // writes from the settings dialog, which use the same map object.
    Connections {
        target: plasmoid.configuration
        function onValueChanged(key) {
            if (key === "enableGsettings" && !plasmoid.configuration.enableGsettings) {
                root.resetGsettingsProxy()
            }
        }
    }

    Timer {
        id: syncTimer
        interval: 700
        onTriggered: root.syncState()
    }

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: function(source, data) {
            if (source === root.stateQueryCommand) {
                const out = String(data.stdout || "").toString().trim()
                root.proxyEnabled = (out === "ON")
            } else if (data.failed || Number(data["exit code"]) !== 0) {
                console.warn("proKc: command failed:", source, "stderr:", data.stderr)
            }
            disconnectSource(source)
        }

        function exec(cmd) {
            executable.connectSource(cmd)
        }
    }

    Component.onCompleted: root.syncState()
}

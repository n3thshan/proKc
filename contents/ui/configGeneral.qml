/*
    proKc — configuration page

    Icon pickers, proxy host/ports, and the gsettings "Dynamic browser proxy"
    option with its requirements note.

    SPDX-FileCopyrightText: 2026 n3thshan
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami
import org.kde.kcmutils as KCM
import org.kde.iconthemes as KIconThemes

KCM.SimpleKCM {
    property string cfg_iconOn: plasmoid.configuration.iconOn
    property string cfg_iconOff: plasmoid.configuration.iconOff
    property string cfg_host: plasmoid.configuration.host
    property int cfg_port: plasmoid.configuration.port
    property int cfg_socksPort: plasmoid.configuration.socksPort
    property string cfg_noProxy: plasmoid.configuration.noProxy
    property bool cfg_enableGsettings: plasmoid.configuration.enableGsettings

    // Defaults (must match contents/config/main.xml) — used by KCM on Reset
    property string cfg_iconOnDefault: "network-connect"
    property string cfg_iconOffDefault: "network-disconnect"
    property string cfg_hostDefault: "127.0.0.1"
    property int cfg_portDefault: 1081
    property int cfg_socksPortDefault: 1080
    property string cfg_noProxyDefault: "localhost,127.0.0.1,::1,localaddress,.localdomain.com"
    property bool cfg_enableGsettingsDefault: false

    component IconPicker: Button {
        id: picker
        property string cfgValue: ""
        property string defaultValue: ""

        implicitWidth: Kirigami.Units.iconSizes.large + Kirigami.Units.smallSpacing * 2
        implicitHeight: Kirigami.Units.iconSizes.large + Kirigami.Units.smallSpacing * 2
        hoverEnabled: true

        Accessible.name: i18nc("@label:action", "Choose proxy icon")
        ToolTip.delay: Kirigami.Units.toolTipDelay
        ToolTip.text: cfgValue

        KIconThemes.IconDialog {
            id: iconDialog
            onIconNameChanged: picker.cfgValue = iconDialog.iconName || picker.defaultValue
        }

        onClicked: iconDialog.open()

        contentItem: Item {
            Kirigami.Icon {
                anchors.fill: parent
                source: picker.cfgValue
            }
        }
    }

    Kirigami.FormLayout {
        id: formLayout
        wideMode: false
        property int fieldMaxWidth: Kirigami.Units.gridUnit * 35

        // ── Appearance ────────────────────────────────────────────────
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18nc("@title:group", "Appearance")
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.maximumWidth: formLayout.fieldMaxWidth
            spacing: Kirigami.Units.largeSpacing

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Label {
                    text: i18nc("@label:chooser", "ON")
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }

                IconPicker {
                    id: iconOnPicker
                    Layout.alignment: Qt.AlignHCenter
                    defaultValue: "network-connect"
                    Component.onCompleted: cfgValue = cfg_iconOn
                    onCfgValueChanged: cfg_iconOn = cfgValue
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Label {
                    text: i18nc("@label:chooser", "OFF")
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }

                IconPicker {
                    id: iconOffPicker
                    Layout.alignment: Qt.AlignHCenter
                    defaultValue: "network-disconnect"
                    Component.onCompleted: cfgValue = cfg_iconOff
                    onCfgValueChanged: cfg_iconOff = cfgValue
                }
            }
        }

        // ── Proxy configuration ───────────────────────────────────────
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18nc("@title:group", "Proxy configuration")
        }

        TextField {
            id: hostField
            Kirigami.FormData.label: i18nc("@label:textbox", "Host:")
            Layout.maximumWidth: formLayout.fieldMaxWidth
            text: cfg_host
            placeholderText: "127.0.0.1"
            onTextChanged: cfg_host = text
        }

        RowLayout {
            Kirigami.FormData.label: i18nc("@label:spinbox", "Ports:")
            Layout.fillWidth: true
            Layout.maximumWidth: formLayout.fieldMaxWidth
            spacing: Kirigami.Units.largeSpacing

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Label {
                    text: i18nc("@label:spinbox", "HTTP/HTTPS")
                    Layout.fillWidth: true
                }

                SpinBox {
                    id: portSpin
                    from: 1
                    to: 65535
                    editable: true
                    value: cfg_port
                    onValueChanged: cfg_port = value
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Label {
                    text: i18nc("@label:spinbox", "SOCKS")
                    Layout.fillWidth: true
                }

                SpinBox {
                    id: socksPortSpin
                    from: 1
                    to: 65535
                    editable: true
                    value: cfg_socksPort
                    onValueChanged: cfg_socksPort = value
                }
            }
        }

        TextField {
            id: noProxyField
            Kirigami.FormData.label: i18nc("@label:textbox", "Exceptions:")
            Layout.maximumWidth: formLayout.fieldMaxWidth
            text: cfg_noProxy
            placeholderText: "localhost,127.0.0.1,::1,localaddress,.localdomain.com"
            onTextChanged: cfg_noProxy = text
        }

        // ── Dynamic proxy for Browsers ────────────────────────────────
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18nc("@title:group", "Dynamic proxy for Browsers")
        }

        CheckBox {
            id: gsettingsCheck
            Layout.maximumWidth: formLayout.fieldMaxWidth
            text: i18nc("@label:checkbox", "Enable")
            checked: cfg_enableGsettings
            onToggled: cfg_enableGsettings = checked
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.maximumWidth: formLayout.fieldMaxWidth
            implicitHeight: prerequisitesGuideLayout.implicitHeight + Kirigami.Units.gridUnit
            radius: 5
            color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.08)
            border.color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.25)
            border.width: 1

            RowLayout {
                id: prerequisitesGuideLayout
                anchors.fill: parent
                anchors.margins: Kirigami.Units.gridUnit * 0.6
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: "emblem-warning"
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 1.5
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5
                    Layout.alignment: Qt.AlignTop
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    textFormat: Text.RichText
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.95
                    color: Kirigami.Theme.textColor
                    linkColor: Kirigami.Theme.linkColor
                    text: i18n("<b>Additional setup required!</b><br><a href=\"https://github.com/n3thshan/proKc#prequisites\">https://github.com/n3thshan/proKc#prequisites</a>")
                    onLinkActivated: (link) => Qt.openUrlExternally(link)
                    // Text doesn't show a hand cursor over links by itself
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                        acceptedButtons: Qt.NoButton
                        hoverEnabled: true
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.maximumWidth: formLayout.fieldMaxWidth
            implicitHeight: noteGuideLayout.implicitHeight + Kirigami.Units.gridUnit
            radius: 5
            color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.08)
            border.color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.25)
            border.width: 1

            RowLayout {
                id: noteGuideLayout
                anchors.fill: parent
                anchors.margins: Kirigami.Units.gridUnit * 0.6
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: "info"
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 1.5
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5
                    Layout.alignment: Qt.AlignTop
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    textFormat: Text.RichText
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.95
                    color: Kirigami.Theme.textColor
                    text: i18n("<b>NOTE:</b> Gives effect to selected proxy settings dynamically without needing to restart browser.")
                }
            }
        }
    }
}

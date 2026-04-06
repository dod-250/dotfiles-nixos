import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

PanelWindow {
    id: root

    anchors.top: true
    anchors.right: true
    anchors.bottom: true
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: 400
    color: "transparent"

    signal closeRequested()

    property int activeTab: 0

    // ── Détection type de connexion ───────────────────────────────────────────
    property bool isWifi:     false
    property string wifiSsid: "—"
    property int    wifiSignal: 0

    Process {
        id: detectNetProc
        command: ["bash", "-c", "ip -4 route get 1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i==\"dev\") print $(i+1)}'"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                const iface = data.trim()
                root.isWifi = iface.startsWith("wl")
                if (root.isWifi) wifiInfoProc.running = true
            }
        }
        onExited: netInfoProc.running = true
    }

    Process {
        id: wifiInfoProc
        command: ["bash", "-c", "nmcli -t -f SSID,SIGNAL dev wifi | grep ':' | head -1"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(":")
                if (parts.length >= 2) {
                    root.wifiSsid   = parts[0]
                    root.wifiSignal = parseInt(parts[1]) || 0
                }
            }
        }
        onExited: wifiTimer.restart()
    }
    Timer { id: wifiTimer; interval: 10000; repeat: false; onTriggered: wifiInfoProc.running = true }

    // ── Données réseau ────────────────────────────────────────────────────────
    property string netIface:   "—"
    property string netIp:      "—"
    property string netGateway: "—"
    property string netDns:     "—"
    property real   netPing:    0
    property real   netRxSpeed: 0
    property real   netTxSpeed: 0
    property real   _prevRx:    0
    property real   _prevTx:    0

    Process {
        id: netInfoProc
        command: ["bash", "-c", "ip -4 route get 1 2>/dev/null | awk '{for(i=1;i<=NF;i++){if($i==\"src\")print $(i+1); if($i==\"dev\")print $(i+1); if($i==\"via\")print $(i+1)}}' | head -3"]
        running: false
        stdout: SplitParser {
            property int _idx: 0
            onRead: data => {
                const v = data.trim()
                if (_idx === 0) root.netIp      = v
                if (_idx === 1) root.netIface   = v
                if (_idx === 2) root.netGateway = v
                _idx++
            }
        }
        onExited: {
            netInfoProc.stdout._idx = 0
            netInfoTimer.restart()
            dnsProc.running = true
        }
    }
    Timer { id: netInfoTimer; interval: 10000; repeat: false; onTriggered: netInfoProc.running = true }

    Process {
        id: dnsProc
        command: ["bash", "-c", "grep '^nameserver' /etc/resolv.conf | head -1 | awk '{print $2}'"]
        running: false
        stdout: SplitParser { onRead: data => root.netDns = data.trim() }
    }

    Process {
        id: rxProc
        command: ["bash", "-c", "cat /proc/net/dev | awk 'NR>2{sum+=$2} END{print sum}'"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                const rx = parseInt(data.trim())
                if (!isNaN(rx) && root._prevRx > 0)
                    root.netRxSpeed = Math.max(0, (rx - root._prevRx) / 2)
                root._prevRx = rx
            }
        }
        onExited: speedTimer.restart()
    }

    Process {
        id: txProc
        command: ["bash", "-c", "cat /proc/net/dev | awk 'NR>2{sum+=$10} END{print sum}'"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                const tx = parseInt(data.trim())
                if (!isNaN(tx) && root._prevTx > 0)
                    root.netTxSpeed = Math.max(0, (tx - root._prevTx) / 2)
                root._prevTx = tx
            }
        }
    }

    Timer {
        id: speedTimer
        interval: 2000; repeat: false
        onTriggered: { rxProc.running = true; txProc.running = true }
    }

    Process {
        id: pingProc
        command: ["bash", "-c", "ping -c1 -W1 8.8.8.8 2>/dev/null | grep 'time=' | sed 's/.*time=//;s/ ms//'"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                const p = parseFloat(data.trim())
                root.netPing = isNaN(p) ? -1 : p
            }
        }
        onExited: pingTimer.restart()
    }
    Timer { id: pingTimer; interval: 5000; repeat: false; onTriggered: pingProc.running = true }

    // ── Données bluetooth ─────────────────────────────────────────────────────
    property bool btPowered: false
    property var  btDevices: []

    Process {
        id: btProc
        command: ["bash", "-c", "bluetoothctl show | grep 'Powered'; bluetoothctl devices Connected"]
        running: true
        stdout: SplitParser {
            property bool _powered: false
            property var  _devices: []
            onRead: data => {
                const line = data.trim()
                if (line.includes("Powered: yes")) _powered = true
                else if (line.startsWith("Device")) {
                    const parts = line.split(" ")
                    if (parts.length >= 3) _devices.push(parts.slice(2).join(" "))
                }
            }
        }
        onExited: {
            root.btPowered = btProc.stdout._powered
            root.btDevices = btProc.stdout._devices.slice()
            btProc.stdout._powered = false
            btProc.stdout._devices = []
            btTimer.restart()
        }
    }
    Timer { id: btTimer; interval: 5000; repeat: false; onTriggered: btProc.running = true }

    Process { id: btToggleProc; running: false; onExited: btProc.running = true }

    function fmtSpeed(bytesPerSec) {
        if (bytesPerSec >= 1024 * 1024) return (bytesPerSec / (1024 * 1024)).toFixed(1) + " MB/s"
        if (bytesPerSec >= 1024)        return (bytesPerSec / 1024).toFixed(1) + " KB/s"
        return Math.round(bytesPerSec) + " B/s"
    }

    function wifiIcon(signal) {
        if (signal >= 75) return "󰤨"
        if (signal >= 50) return "󰤥"
        if (signal >= 25) return "󰤢"
        return "󰤟"
    }

    // ── Fermer au clic extérieur ──────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        onClicked: root.closeRequested()
    }

    // ── UI ────────────────────────────────────────────────────────────────────
    Rectangle {
        anchors { top: parent.top; right: parent.right; topMargin: 64; rightMargin: 8 }
        width: 380
        radius: 10
        color: "#1e2030"
        border.color: "#f5a97f"
        border.width: 2
        implicitHeight: popupCol.implicitHeight + 24

        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            id: popupCol
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 16 }
            spacing: 12

            // Onglets
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: [
                        { label: root.isWifi ? "󰤨  WiFi" : "󰈀  Network", idx: 0 },
                        { label: "󰂯  Bluetooth", idx: 1 }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        height: 30; radius: 6
                        color: root.activeTab === modelData.idx
                               ? Qt.rgba(0.961, 0.663, 0.498, 0.15) : "#363a4f"
                        border.color: root.activeTab === modelData.idx ? "#f5a97f" : "transparent"
                        border.width: 1
                        Behavior on color        { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            font.pixelSize: 11; font.family: "0xProto Nerd Font"
                            color: root.activeTab === modelData.idx ? "#f5a97f" : "#6e738d"
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: root.activeTab = modelData.idx
                        }
                    }
                }
            }

            // ── Onglet Réseau ─────────────────────────────────────────────
            ColumnLayout {
                visible: root.activeTab === 0
                Layout.fillWidth: true
                spacing: 8

                // Info WiFi (uniquement si wifi)
                RowLayout {
                    visible: root.isWifi
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: root.wifiIcon(root.wifiSignal)
                        font.pixelSize: 16; font.family: "0xProto Nerd Font"
                        color: root.wifiSignal >= 50 ? "#a6da95"
                             : root.wifiSignal >= 25 ? "#eed49f" : "#ed8796"
                    }
                    Text {
                        text: root.wifiSsid
                        font.pixelSize: 12; font.weight: Font.Medium; color: "#cad3f5"
                        Layout.fillWidth: true
                    }
                    Text {
                        text: root.wifiSignal + "%"
                        font.pixelSize: 11; color: "#a5adcb"
                    }
                }

                // Infos réseau
                Repeater {
                    model: [
                        { label: "Interface", value: root.netIface   },
                        { label: "IP",        value: root.netIp      },
                        { label: "Gateway",   value: root.netGateway },
                        { label: "DNS",       value: root.netDns     }
                    ]
                    delegate: RowLayout {
                        required property var modelData
                        Layout.fillWidth: true; spacing: 8
                        Text { text: modelData.label; font.pixelSize: 11; color: "#6e738d"; Layout.minimumWidth: 70 }
                        Text { text: modelData.value; font.pixelSize: 11; font.weight: Font.Medium; color: "#cad3f5"; Layout.fillWidth: true }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: "#363a4f" }

                // Débit + Ping
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    RowLayout {
                        spacing: 4
                        Text { text: "󰁅"; font.pixelSize: 13; font.family: "0xProto Nerd Font"; color: "#a6da95" }
                        Text { text: root.fmtSpeed(root.netRxSpeed); font.pixelSize: 11; font.weight: Font.Medium; color: "#cad3f5" }
                    }
                    RowLayout {
                        spacing: 4
                        Text { text: "󰁝"; font.pixelSize: 13; font.family: "0xProto Nerd Font"; color: "#f5a97f" }
                        Text { text: root.fmtSpeed(root.netTxSpeed); font.pixelSize: 11; font.weight: Font.Medium; color: "#cad3f5" }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 4
                        Text { text: "󱘖"; font.pixelSize: 13; font.family: "0xProto Nerd Font"; color: "#8aadf4" }
                        Text {
                            text: root.netPing < 0 ? "timeout" : root.netPing.toFixed(1) + " ms"
                            font.pixelSize: 11; font.weight: Font.Medium
                            color: root.netPing < 0 ? "#ed8796" : root.netPing > 100 ? "#f5a97f" : "#a6da95"
                        }
                    }
                }
            }

            // ── Onglet Bluetooth ──────────────────────────────────────────
            ColumnLayout {
                visible: root.activeTab === 1
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "Bluetooth"; font.pixelSize: 12; font.weight: Font.Medium; color: "#cad3f5"; Layout.fillWidth: true }

                    Rectangle {
                        width: 44; height: 24; radius: 12
                        color: root.btPowered ? Qt.rgba(0.663, 0.855, 0.584, 0.2) : "#363a4f"
                        border.color: root.btPowered ? "#a6da95" : "#494d64"; border.width: 1
                        Behavior on color        { ColorAnimation { duration: 200 } }
                        Behavior on border.color { ColorAnimation { duration: 200 } }

                        Rectangle {
                            width: 16; height: 16; radius: 8
                            anchors.verticalCenter: parent.verticalCenter
                            x: root.btPowered ? parent.width - width - 4 : 4
                            color: root.btPowered ? "#a6da95" : "#6e738d"
                            Behavior on x     { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation  { duration: 200 } }
                        }

                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                btToggleProc.command = ["bash", "-c", "bluetoothctl " + (root.btPowered ? "power off" : "power on")]
                                btToggleProc.running = true
                            }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: "#363a4f" }

                Text { text: "Connected devices"; font.pixelSize: 11; color: "#6e738d" }

                Column {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        visible: root.btDevices.length === 0
                        width: parent.width
                        text: root.btPowered ? "No connected devices" : "Bluetooth is off"
                        font.pixelSize: 11; color: "#494d64"
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Repeater {
                        model: root.btDevices
                        delegate: RowLayout {
                            required property string modelData
                            width: parent.width; spacing: 8

                            Text { text: "󰂱"; font.pixelSize: 13; font.family: "0xProto Nerd Font"; color: "#8aadf4" }
                            Text { text: modelData; font.pixelSize: 11; color: "#cad3f5"; Layout.fillWidth: true }

                            Rectangle {
                                width: 80; height: 22; radius: 4
                                color: "#363a4f"; border.color: "#494d64"; border.width: 1
                                Text { anchors.centerIn: parent; text: "Disconnect"; font.pixelSize: 10; color: "#ed8796" }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        btToggleProc.command = ["bash", "-c", "bluetoothctl disconnect"]
                                        btToggleProc.running = true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

PanelWindow {
    id: root

    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    signal closeRequested()

    // ── Détection automatique ─────────────────────────────────────────────────
    property int  numCores:   1
    property bool isAmd:      false
    property string tempPath: ""

    // Détecte le nombre de cœurs, le type de CPU et le bon chemin thermal
    Process {
        id: detectProc
        command: ["bash", "-c", "nproc; grep -c 'model name' /proc/cpuinfo; grep -m1 'vendor_id' /proc/cpuinfo | grep -c 'AuthenticAMD'"]
        running: true
        stdout: SplitParser {
            property int _idx: 0
            onRead: data => {
                const v = parseInt(data.trim())
                if (_idx === 0) root.numCores = v
                if (_idx === 2) {
                    root.isAmd = v === 1
                    // Cherche le bon chemin thermal
                    root.findTempPath()
                }
                _idx++
            }
        }
    }

    Process {
        id: findTempProc
        command: ["bash", "-c",
            root.isAmd
            ? "for f in /sys/class/hwmon/hwmon*/name; do n=$(cat $f); if [ \"$n\" = \"k10temp\" ]; then d=$(dirname $f); echo $d/temp1_input; break; fi; done"
            : "for z in /sys/class/thermal/thermal_zone*/type; do t=$(cat $z); if [ \"$t\" = \"x86_pkg_temp\" ]; then echo $(dirname $z)/temp; break; fi; done"
        ]
        running: false
        stdout: SplitParser {
            onRead: data => {
                root.tempPath = data.trim()
                // Init tableaux maintenant qu'on connaît le nb de cœurs
                root.coreUsages  = new Array(root.numCores).fill(0)
                root.coreFreqs   = new Array(root.numCores).fill(0)
                root._prevIdle   = new Array(root.numCores).fill(0)
                root._prevTotal  = new Array(root.numCores).fill(0)
                // Lancer les process de données
                statProc.running = true
                freqProc.running = true
                tempProc.running = true
                ramProc.running  = true
            }
        }
    }

    // Cherche aussi les Tccd sur AMD
    Process {
        id: findTccdProc
        command: ["bash", "-c",
            "d=$(dirname $(grep -rl 'k10temp' /sys/class/hwmon/ 2>/dev/null | head -1)); " +
            "echo $(cat $d/temp3_input 2>/dev/null || echo 0) $(cat $d/temp4_input 2>/dev/null || echo 0)"
        ]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(" ")
                if (parts.length >= 2) {
                    root.tempTccd1 = Math.round(parseInt(parts[0]) / 1000)
                    root.tempTccd2 = Math.round(parseInt(parts[1]) / 1000)
                }
            }
        }
        onExited: tccdTimer.restart()
    }
    Timer { id: tccdTimer; interval: 2000; repeat: false; onTriggered: { if (root.isAmd) findTccdProc.running = true } }

    function findTempPath() {
        findTempProc.command = ["bash", "-c",
            root.isAmd
            ? "for f in /sys/class/hwmon/hwmon*/name; do n=$(cat $f); if [ \"$n\" = \"k10temp\" ]; then d=$(dirname $f); echo $d/temp1_input; break; fi; done"
            : "for z in /sys/class/thermal/thermal_zone*/type; do t=$(cat $z); if [ \"$t\" = \"x86_pkg_temp\" ]; then echo $(dirname $z)/temp; break; fi; done"
        ]
        findTempProc.running = true
        if (root.isAmd) findTccdProc.running = true
    }

    // ── Données CPU ───────────────────────────────────────────────────────────
    property var  coreUsages: []
    property var  coreFreqs:  []
    property real tempMain:   0
    property real tempTccd1:  0
    property real tempTccd2:  0
    property real avgFreq:    0

    property var _prevIdle:  []
    property var _prevTotal: []

    Process {
        id: statProc
        command: ["bash", "-c", "grep '^cpu[0-9]' /proc/stat | head -" + root.numCores]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(/\s+/)
                if (parts.length < 5) return
                const idx = parseInt(parts[0].replace(/cpu/, ""))
                if (isNaN(idx) || idx >= root.numCores) return
                const user   = parseInt(parts[1])
                const nice   = parseInt(parts[2])
                const system = parseInt(parts[3])
                const idle   = parseInt(parts[4])
                const iowait = parseInt(parts[5]) || 0
                const total  = user + nice + system + idle + iowait
                const prevT  = root._prevTotal[idx] || 0
                const prevI  = root._prevIdle[idx]  || 0
                const dt     = total - prevT
                const di     = idle  - prevI
                const usage  = dt > 0 ? Math.round((1 - di / dt) * 100) : 0
                var u  = root.coreUsages.slice(); u[idx]  = usage; root.coreUsages  = u
                var pt = root._prevTotal.slice(); pt[idx] = total; root._prevTotal   = pt
                var pi = root._prevIdle.slice();  pi[idx] = idle;  root._prevIdle    = pi
            }
        }
        onExited: statTimer.restart()
    }
    Timer { id: statTimer; interval: 2000; repeat: false; onTriggered: statProc.running = true }

    Process {
        id: freqProc
        command: ["bash", "-c", "grep 'cpu MHz' /proc/cpuinfo | awk '{print $4}'"]
        running: false
        stdout: SplitParser {
            property int _idx: 0
            onRead: data => {
                const mhz = parseFloat(data.trim())
                if (!isNaN(mhz) && _idx < root.numCores) {
                    var f = root.coreFreqs.slice(); f[_idx] = mhz; root.coreFreqs = f
                    _idx++
                }
            }
        }
        onExited: {
            if (root.coreFreqs.length > 0) {
                const sum = root.coreFreqs.reduce((a, b) => a + b, 0)
                root.avgFreq = Math.round(sum / root.coreFreqs.length) / 1000
            }
            freqProc.stdout._idx = 0
            freqTimer.restart()
        }
    }
    Timer { id: freqTimer; interval: 2000; repeat: false; onTriggered: freqProc.running = true }

    Process {
        id: tempProc
        command: ["bash", "-c", root.tempPath !== "" ? "cat " + root.tempPath : "echo 0"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const v = parseInt(data.trim())
                root.tempMain = isNaN(v) ? 0 : Math.round(v / 1000)
            }
        }
        onExited: tempTimer.restart()
    }
    Timer { id: tempTimer; interval: 2000; repeat: false; onTriggered: tempProc.running = true }

    // ── Données RAM ───────────────────────────────────────────────────────────
    property real ramTotal: 0
    property real ramUsed:  0
    property real ramFree:  0
    property real ramPct:   0

    Process {
        id: ramProc
        command: ["bash", "-c", "free -m | awk 'NR==2{print $2, $3, $4}'"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(" ")
                if (parts.length < 3) return
                root.ramTotal = parseInt(parts[0])
                root.ramUsed  = parseInt(parts[1])
                root.ramFree  = parseInt(parts[2])
                root.ramPct   = Math.round(root.ramUsed / root.ramTotal * 100)
            }
        }
        onExited: ramTimer.restart()
    }
    Timer { id: ramTimer; interval: 3000; repeat: false; onTriggered: ramProc.running = true }

    function fmtMb(mb) {
        return mb >= 1024 ? (mb / 1024).toFixed(1) + " GB" : mb + " MB"
    }

    function coreColor(pct) {
        if (pct >= 80) return "#ed8796"
        if (pct >= 50) return "#f5a97f"
        return "#a6da95"
    }

    // ── UI ────────────────────────────────────────────────────────────────────
    Rectangle {
        anchors.right:       parent.right
        anchors.top:         parent.top
        anchors.topMargin:   64
        anchors.rightMargin: 8
        width: 560
        radius: 10
        color: "#1e2030"
        border.color: "#f5a97f"
        border.width: 2
        implicitHeight: mainCol.implicitHeight + 24

        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            id: mainCol
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 16 }
            spacing: 12

            // Header
            Text {
                text: "System"
                font.pixelSize: 14; font.weight: Font.Medium; color: "#cad3f5"
            }

            // Températures
            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                // Temp principale (Intel: x86_pkg_temp / AMD: Tctl)
                RowLayout {
                    spacing: 4
                    Text {
                        text: (root.isAmd ? "Tctl" : "CPU") + ":"
                        font.pixelSize: 11; color: "#6e738d"
                    }
                    Text {
                        text: root.tempMain + "°"
                        font.pixelSize: 11; font.weight: Font.Medium
                        color: root.tempMain >= 80 ? "#ed8796"
                             : root.tempMain >= 60 ? "#f5a97f"
                             : "#a6da95"
                    }
                }

                // Tccd uniquement sur AMD
                RowLayout {
                    visible: root.isAmd
                    spacing: 4
                    Text { text: "Tccd1:"; font.pixelSize: 11; color: "#6e738d" }
                    Text {
                        text: root.tempTccd1 + "°"
                        font.pixelSize: 11; font.weight: Font.Medium
                        color: root.tempTccd1 >= 80 ? "#ed8796"
                             : root.tempTccd1 >= 60 ? "#f5a97f"
                             : "#a6da95"
                    }
                }

                RowLayout {
                    visible: root.isAmd
                    spacing: 4
                    Text { text: "Tccd2:"; font.pixelSize: 11; color: "#6e738d" }
                    Text {
                        text: root.tempTccd2 + "°"
                        font.pixelSize: 11; font.weight: Font.Medium
                        color: root.tempTccd2 >= 80 ? "#ed8796"
                             : root.tempTccd2 >= 60 ? "#f5a97f"
                             : "#a6da95"
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "󰓙 " + root.avgFreq.toFixed(2) + " GHz avg."
                    font.pixelSize: 11; font.family: "0xProto Nerd Font"; color: "#a5adcb"
                }
            }

            // Grille cœurs — colonnes adaptées selon le nb de cœurs
            GridLayout {
                Layout.fillWidth: true
                columns: root.numCores <= 8 ? 4 : 6
                columnSpacing: 6
                rowSpacing: 6

                Repeater {
                    model: root.numCores
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 52
                        radius: 6
                        color: "#24273a"
                        border.color: root.coreColor(root.coreUsages[index] ?? 0)
                        border.width: 1
                        Behavior on border.color { ColorAnimation { duration: 300 } }

                        // Barre de progression verticale
                        Rectangle {
                            anchors.bottom:       parent.bottom
                            anchors.left:         parent.left
                            anchors.right:        parent.right
                            anchors.margins:      2
                            anchors.bottomMargin: 2
                            height: Math.max(2, (parent.height - 4) * ((root.coreUsages[index] ?? 0) / 100))
                            radius: 4
                            color: root.coreColor(root.coreUsages[index] ?? 0)
                            opacity: 0.25
                            Behavior on height { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                            Behavior on color  { ColorAnimation  { duration: 300 } }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "C" + index
                                font.pixelSize: 9; color: "#6e738d"
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: (root.coreUsages[index] ?? 0) + "%"
                                font.pixelSize: 11; font.weight: Font.Medium
                                color: root.coreColor(root.coreUsages[index] ?? 0)
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: ((root.coreFreqs[index] ?? 0) / 1000).toFixed(1) + "G"
                                font.pixelSize: 9; color: "#a5adcb"
                            }
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#363a4f" }

            // RAM
            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                Text {
                    text: "󰍛 RAM"
                    font.pixelSize: 12; font.weight: Font.Medium
                    font.family: "0xProto Nerd Font"; color: "#a6da95"
                }

                Item {
                    Layout.fillWidth: true
                    height: 8
                    Rectangle { anchors.fill: parent; radius: 4; color: "#363a4f" }
                    Rectangle {
                        width: parent.width * (root.ramPct / 100)
                        height: parent.height; radius: 4
                        color: root.ramPct >= 80 ? "#ed8796"
                             : root.ramPct >= 60 ? "#f5a97f"
                             : "#a6da95"
                        Behavior on width { NumberAnimation { duration: 500 } }
                        Behavior on color { ColorAnimation  { duration: 300 } }
                    }
                }

                Text {
                    text: root.ramPct + "%"
                    font.pixelSize: 11; font.weight: Font.Medium
                    color: root.ramPct >= 80 ? "#ed8796"
                         : root.ramPct >= 60 ? "#f5a97f"
                         : "#a6da95"
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 24

                Repeater {
                    model: [
                        { label: "Total", value: root.fmtMb(root.ramTotal) },
                        { label: "Used",  value: root.fmtMb(root.ramUsed)  },
                        { label: "Free",  value: root.fmtMb(root.ramFree)  }
                    ]
                    delegate: RowLayout {
                        required property var modelData
                        spacing: 4
                        Text { text: modelData.label + ":"; font.pixelSize: 11; color: "#6e738d" }
                        Text { text: modelData.value; font.pixelSize: 11; font.weight: Font.Medium; color: "#cad3f5" }
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.closeRequested()
    }
}

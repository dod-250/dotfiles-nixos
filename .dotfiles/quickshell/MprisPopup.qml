import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// ─── MprisPopup.qml ───────────────────────────────────────────────────────────
// Floating MPRIS popup with functional EQ (EasyEffects via gsettings)
// Theme  : Catppuccin Macchiato | peach + green accents
// Font   : 0xProto Nerd Font
// Note   : PopupWindow (Quickshell) n'a pas enter/exit — animation via opacity
// ──────────────────────────────────────────────────────────────────────────────

PopupWindow {
    id: root

    // ── Positioning ──────────────────────────────────────────────────────────
    // barWindow est passé depuis shell.qml : MprisPopup { barWindow: bar }
    property var barWindow: null

    anchor.window: barWindow
    anchor.rect.x:      barWindow ? barWindow.width - implicitWidth - 16 : 0
    anchor.rect.y:      barWindow ? barWindow.implicitHeight : 0
    anchor.rect.width:  implicitWidth
    anchor.rect.height: implicitHeight

    implicitWidth:  400
    implicitHeight: card.implicitHeight
    color:  "transparent"

    // ── Catppuccin Macchiato ─────────────────────────────────────────────────
    QtObject {
        id: col
        readonly property color base:     "#24273a"
        readonly property color mantle:   "#1e2030"
        readonly property color surface0: "#363a4f"
        readonly property color surface1: "#494d64"
        readonly property color overlay0: "#6e738d"
        readonly property color overlay1: "#8087a2"
        readonly property color text:     "#cad3f5"
        readonly property color subtext0: "#a5adcb"
        readonly property color subtext1: "#b8c0e0"
        readonly property color peach:    "#f5a97f"
        readonly property color green:    "#a6da95"
        readonly property color red:      "#ed8796"
    }

    // ── MPRIS ────────────────────────────────────────────────────────────────
    property MprisPlayer player: Mpris.players.values.length > 0
                                 ? Mpris.players.values[0] : null

    property bool   isPlaying:   player ? player.isPlaying : false
    property string trackTitle:  player?.trackTitle  ?? "Nothing playing"
    property string trackArtist: player?.trackArtist ?? "—"
    property string artUrl:      player?.trackArtUrl ?? ""
    // trackLength absent sur Spotify : fallback sur mpris:length (µs → ms)
    property real trackLen: {
        if (!player) return 0
        var tl = player.trackLength
        if (tl && tl > 0) return tl
        var meta = player.metadata
        if (meta) {
            var us = meta["mpris:length"]
            if (us && us > 0) return Math.round(us / 1000)
        }
        return 0
    }

    // ── Position locale ───────────────────────────────────────────────────────
    property real localPos:  0
    property real progress:  trackLen > 0 ? Math.min(1.0, localPos / trackLen) : 0.0
    property real trackPos:  localPos

    onPlayerChanged:     { localPos = 0; _lastTick = 0 }
    onTrackTitleChanged: { localPos = 0; _lastTick = 0 }

    // Timer basé sur delta réel pour éviter tout drift
    property real _lastTick: 0

    Timer {
        interval: 250
        running:  root.isPlaying
        repeat:   true
        onTriggered: {
            if (root.trackLen <= 0) return
            var now = Date.now()
            if (root._lastTick > 0) {
                var elapsed = now - root._lastTick
                root.localPos = Math.min(root.trackLen, root.localPos + elapsed)
            }
            root._lastTick = now
        }
    }

    onIsPlayingChanged: {
        if (isPlaying) _lastTick = Date.now()
        else           _lastTick = 0
    }

    function fmtTime(ms) {
        var s = Math.floor(ms / 1000)
        var m = Math.floor(s / 60)
        s = s % 60
        return m + ":" + (s < 10 ? "0" : "") + s
    }

    // ── EQ state ─────────────────────────────────────────────────────────────
    readonly property var bandLabels: ["31","63","125","250","500","1k","2k","4k","8k","16k"]

    readonly property var presets: ({
        "Flat":    [ 0,  0,  0,  0,  0,  0,  0,  0,  0,  0],
        "Bass":    [+6, +5, +4, +2,  0,  0, -1, -1, -1, -1],
        "Treble":  [-2, -2, -1,  0,  0, +2, +4, +5, +6, +6],
        "Rock":    [+4, +3, +2,  0, -1, -1,  0, +2, +3, +4],
        "Jazz":    [+3, +2, +1,  0, -1, -2, -1,  0, +2, +3],
        "Classic": [ 0,  0,  0,  0,  0,  0, -3, -4, -4, -4]
    })

    property string activePreset: "Flat"
    property var    eqValues:     [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

    function applyPreset(name) {
        activePreset = name
        eqValues = presets[name].slice()
        sendEq()
    }

    // Fréquences fixes des 10 bands (Hz)
    readonly property var bandFreqs: [31.0, 63.0, 125.0, 250.0, 500.0, 1000.0, 2000.0, 4000.0, 8000.0, 16000.0]

    function makeBand(i) {
        var g = eqValues[i]
        return '"band' + i + '":{"frequency":' + bandFreqs[i]
             + ',"gain":' + g
             + ',"mode":"APO (DR)","mute":false,"q":1.5,"slope":"x1","solo":false,"type":"Bell","width":4.0}'
    }

    function sendEq() {
        var bands = []
        for (var i = 0; i < 10; i++) bands.push(makeBand(i))
        var bStr = bands.join(",")

        var json = '{"output":{"blocklist":[],"equalizer#0":{'
            + '"balance":0.0,"bypass":false,"input-gain":0.0,'
            + '"left":{' + bStr + '},'
            + '"mode":"IIR","num-bands":10,"output-gain":0.0,'
            + '"pitch-left":0.0,"pitch-right":0.0,'
            + '"right":{' + bStr + '},'
            + '"split-channels":false'
            + '},"plugins_order":["equalizer#0"]}}'

        var name = "qs-eq-tmp"
        var path = "/home/dod/.local/share/easyeffects/output/" + name + ".json"
        var cmd  = "printf '%s' '" + json.replace(/'/g, "'\''") + "' > " + path
                 + " && easyeffects --load-preset " + name
                 + " ; rm -f " + path

        eqProcess.command = ["bash", "-c", cmd]
        eqProcess.running = true
    }

    Process {
        id: eqProcess
        command: ["bash", "-c", "true"]
    }

    Timer {
        id: eqThrottle
        interval: 150
        onTriggered: root.sendEq()
    }

    // ── ASCII EQ animation (décorative) ──────────────────────────────────────
    property var eqAnim: [3,5,7,4,6,3,5,2,4,6]
    readonly property var eqChars: ["▁","▂","▃","▄","▅","▆","▇","█"]

    Timer {
        interval: 110; running: root.isPlaying; repeat: true
        onTriggered: {
            var h = root.eqAnim.slice()
            for (var i = 0; i < 3; i++) {
                var b = Math.floor(Math.random() * 10)
                h[b] = Math.max(1, Math.min(8, h[b] + Math.floor(Math.random()*3)-1))
            }
            root.eqAnim = h
        }
    }
    Timer {
        interval: 160; running: !root.isPlaying; repeat: true
        onTriggered: {
            var h = root.eqAnim.slice(), any = false
            for (var i = 0; i < 10; i++) { if (h[i] > 1) { h[i]--; any = true } }
            root.eqAnim = h
            if (!any) running = false
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    // Card
    // ═════════════════════════════════════════════════════════════════════════
    Rectangle {
        id: card
        width:  parent.width
        implicitHeight: mainCol.implicitHeight + 32
        radius: 14
        color:  col.base
        border.color: col.surface0
        border.width: 1

        // Fade in/out — opacity sur le contenu, pas sur PopupWindow
        opacity: root.visible ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            id: mainCol
            anchors {
                left: parent.left; right: parent.right
                top:  parent.top;  topMargin: 16
            }
            spacing: 0

            // ── Track row ─────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth:   true
                Layout.leftMargin:  16
                Layout.rightMargin: 16
                spacing: 12

                Rectangle {
                    width: 68; height: 68; radius: 8
                    color: col.surface0; clip: true

                    Image {
                        id: art
                        anchors.fill: parent
                        source:       root.artUrl
                        fillMode:     Image.PreserveAspectCrop
                        visible:      status === Image.Ready
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: art.status !== Image.Ready
                        text:  "󰎆"
                        font { family: "0xProto Nerd Font"; pixelSize: 30 }
                        color: col.overlay0
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    Text {
                        Layout.fillWidth: true
                        text:  root.trackTitle
                        color: col.text
                        font { family: "0xProto Nerd Font"; pixelSize: 13; bold: true }
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        text:  root.trackArtist
                        color: col.subtext1
                        font { family: "0xProto Nerd Font"; pixelSize: 11 }
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.topMargin: 4
                        text: {
                            var s = ""
                            for (var i = 0; i < 10; i++)
                                s += root.eqChars[root.eqAnim[i]-1] + (i<9 ? " " : "")
                            return s
                        }
                        font { family: "0xProto Nerd Font"; pixelSize: 12 }
                        color: root.isPlaying ? col.peach : col.overlay0
                        Behavior on color { ColorAnimation { duration: 400 } }
                    }
                    Text {
                        text: root.player ? ("󰓇  " + (root.player.identity ?? "")) : ""
                        color: col.overlay0
                        font { family: "0xProto Nerd Font"; pixelSize: 10 }
                    }
                }
            }

            // ── Progress ──────────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth:   true
                Layout.topMargin:   12
                Layout.leftMargin:  16
                Layout.rightMargin: 16
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: root.fmtTime(root.trackPos)
                        color: col.overlay1
                        font { family: "0xProto Nerd Font"; pixelSize: 10 }
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: root.fmtTime(root.trackLen)
                        color: col.overlay1
                        font { family: "0xProto Nerd Font"; pixelSize: 10 }
                    }
                }

                Item {
                    Layout.fillWidth: true; height: 4
                    Rectangle { anchors.fill: parent; radius: 2; color: col.surface1 }
                    Rectangle {
                        width:  Math.max(4, parent.width * root.progress)
                        height: parent.height; radius: 2; color: col.green
                        Behavior on width { NumberAnimation { duration: 800; easing.type: Easing.Linear } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: function(m) {
                            if (root.player && root.trackLen > 0) {
                                var seekPos = Math.round((m.x / width) * root.trackLen)
                                root.localPos = seekPos
                                root.player.position = seekPos
                            }
                        }
                    }
                }
            }

            // ── Controls ──────────────────────────────────────────────────
            RowLayout {
                Layout.alignment:  Qt.AlignHCenter
                Layout.topMargin:  10
                spacing: 6

                CtrlBtn { icon: "󰒮"; onActivated: if (root.player) root.player.previous() }
                CtrlBtn { icon: root.isPlaying ? "󰏤" : "󰐊"; accent: true; onActivated: if (root.player && root.player.canTogglePlaying) root.player.togglePlaying() }
                CtrlBtn { icon: "󰒭"; onActivated: if (root.player) root.player.next() }
            }

            // ── Divider ───────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth:   true
                Layout.topMargin:   14
                Layout.leftMargin:  16
                Layout.rightMargin: 16
                height: 1; color: col.surface0
            }

            // ── EQ header ─────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth:   true
                Layout.topMargin:   12
                Layout.leftMargin:  16
                Layout.rightMargin: 16

                Text {
                    text: "Equalizer"
                    color: col.text
                    font { family: "0xProto Nerd Font"; pixelSize: 12; bold: true }
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    visible: root.activePreset !== ""
                    radius: 4
                    color: Qt.rgba(0.961, 0.663, 0.498, 0.15)
                    border.color: col.peach; border.width: 1
                    width: presetBadge.implicitWidth + 12; height: 18
                    Text {
                        id: presetBadge
                        anchors.centerIn: parent
                        text:  root.activePreset
                        color: col.peach
                        font { family: "0xProto Nerd Font"; pixelSize: 10; bold: true }
                    }
                }
            }

            // ── EQ sliders ────────────────────────────────────────────────
            Item {
                Layout.fillWidth:    true
                Layout.leftMargin:   16
                Layout.rightMargin:  16
                Layout.topMargin:    8
                Layout.bottomMargin: 4
                height: 118

                Row {
                    anchors.fill: parent
                    spacing: 0

                    Repeater {
                        model: root.bandLabels.length

                        Item {
                            id: bandItem
                            property int bi: index
                            width:  parent.width / root.bandLabels.length
                            height: parent.height

                            // dB readout
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.top: parent.top
                                text: {
                                    var v = root.eqValues[bandItem.bi]
                                    return (v > 0 ? "+" : "") + v
                                }
                                color: {
                                    var v = root.eqValues[bandItem.bi]
                                    return v > 0 ? col.green : v < 0 ? col.red : col.overlay0
                                }
                                font { family: "0xProto Nerd Font"; pixelSize: 9 }
                            }

                            // Slider zone
                            Item {
                                id: sz
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.top:    parent.top;    anchors.topMargin:    14
                                anchors.bottom: parent.bottom; anchors.bottomMargin: 14
                                width: 20

                                Rectangle {
                                    id: trk
                                    width: 4; radius: 2; color: col.surface1
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.top: parent.top; anchors.bottom: parent.bottom
                                }

                                // Zero line
                                Rectangle {
                                    width: 8; height: 1; color: col.overlay0
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.verticalCenter:   parent.verticalCenter
                                }

                                // Fill
                                Rectangle {
                                    property real db:    root.eqValues[bandItem.bi]
                                    property real fillH: Math.abs(db / 12) * (trk.height / 2)
                                    width: 4; radius: 2
                                    color: db >= 0 ? col.green : col.red
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    y:      db >= 0 ? trk.y + trk.height/2 - fillH : trk.y + trk.height/2
                                    height: fillH
                                    Behavior on y      { NumberAnimation { duration: 80 } }
                                    Behavior on height { NumberAnimation { duration: 80 } }
                                    Behavior on color  { ColorAnimation  { duration: 100 } }
                                }

                                // Handle
                                Rectangle {
                                    id: knob
                                    property real db:   root.eqValues[bandItem.bi]
                                    property real norm: 1 - (db + 12) / 24
                                    width: 14; height: 14; radius: 7
                                    color: col.peach
                                    border.color: col.mantle; border.width: 2
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    y: norm * (trk.height - height) + trk.y
                                    Behavior on y { NumberAnimation { duration: 80 } }

                                    MouseArea {
                                        anchors.fill: parent
                                        drag.target:  knob
                                        drag.axis:    Drag.YAxis
                                        drag.minimumY: trk.y
                                        drag.maximumY: trk.y + trk.height - knob.height

                                        onPositionChanged: {
                                            if (!drag.active) return
                                            var n  = Math.max(0, Math.min(1,
                                                (knob.y - trk.y) / (trk.height - knob.height)))
                                            var db = Math.round((1 - n) * 24 - 12)
                                            var arr = root.eqValues.slice()
                                            arr[bandItem.bi] = db
                                            root.eqValues     = arr
                                            root.activePreset = "Custom"
                                            eqThrottle.restart()
                                        }
                                    }
                                }
                            }

                            // Band label
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                text:  root.bandLabels[bandItem.bi]
                                color: col.overlay0
                                font { family: "0xProto Nerd Font"; pixelSize: 9 }
                            }
                        }
                    }
                }
            }

            // ── Presets ───────────────────────────────────────────────────
            Grid {
                Layout.fillWidth:    true
                Layout.leftMargin:   16
                Layout.rightMargin:  16
                Layout.topMargin:    4
                Layout.bottomMargin: 16
                columns: 3
                rowSpacing:    6
                columnSpacing: 6

                Repeater {
                    model: ["Flat","Bass","Treble","Rock","Jazz","Classic"]

                    Rectangle {
                        width:  (card.width - 32 - 12) / 3
                        height: 28; radius: 6
                        color: root.activePreset === modelData
                               ? Qt.rgba(0.961, 0.663, 0.498, 0.18)
                               : col.surface0
                        border.color: root.activePreset === modelData ? col.peach : "transparent"
                        border.width: 1
                        Behavior on color        { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text:  modelData
                            color: root.activePreset === modelData ? col.peach : col.subtext1
                            font { family: "0xProto Nerd Font"; pixelSize: 11 }
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape:  Qt.PointingHandCursor
                            onClicked:    root.applyPreset(modelData)
                        }
                    }
                }
            }
        }
    }

    // ── Transport button ──────────────────────────────────────────────────────
    component CtrlBtn: Rectangle {
        id: btn
        required property string icon
        property bool accent: false
        signal activated()

        width: 38; height: 38; radius: 8
        color: ma.containsMouse
               ? (accent ? Qt.rgba(0.961,0.663,0.498,0.18) : col.surface0)
               : "transparent"
        Behavior on color { ColorAnimation { duration: 100 } }

        Text {
            anchors.centerIn: parent
            text:  btn.icon
            font { family: "0xProto Nerd Font"; pixelSize: 17 }
            color: btn.accent ? col.peach : col.text
        }
        MouseArea {
            id: ma; anchors.fill: parent
            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            enabled: root.player !== null
            onClicked: btn.activated()
        }
    }
}

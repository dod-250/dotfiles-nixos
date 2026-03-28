import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris

PanelWindow {
    id: mprisWindow

    visible: Mpris.players.values.length > 0 && root.mprisVisible

    anchors.left: true
    anchors.bottom: true
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: 296
    implicitHeight: 88
    color: "transparent"

    property MprisPlayer mprisPlayer: Mpris.players.values.find(
        p => p.playbackState === MprisPlaybackState.Playing
    ) ?? Mpris.players.values[0] ?? null

    Rectangle {
        x: 8; y: 8
        width: 280; height: 72
        radius: Colors.barRadius
        color: Colors.mantle
        border.color: Colors.peach
        border.width: 2

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Rectangle {
                width: 48; height: 48; radius: 6
                color: Colors.surface0; clip: true
                Image {
                    anchors.fill: parent
                    source: mprisWindow.mprisPlayer?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: mprisWindow.mprisPlayer?.trackTitle || "—"
                    font.pixelSize: 12; font.weight: Font.Medium
                    color: Colors.text; elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: mprisWindow.mprisPlayer?.trackArtist || ""
                    font.pixelSize: 10; color: Colors.subtext0; elide: Text.ElideRight
                }

                RowLayout {
                    spacing: 12
                    Repeater {
                        model: [
                            { label: "⏮", action: () => mprisWindow.mprisPlayer?.previous() },
                            { label: mprisWindow.mprisPlayer?.playbackState === MprisPlaybackState.Playing ? "⏸" : "▶", action: () => mprisWindow.mprisPlayer?.togglePlaying() },
                            { label: "⏭", action: () => mprisWindow.mprisPlayer?.next() }
                        ]
                        delegate: Text {
                            required property var modelData
                            required property int index
                            text: modelData.label; font.pixelSize: 13
                            color: index === 1 ? Colors.peach : Colors.overlay0
                            MouseArea {
                                anchors.fill: parent
                                onClicked: parent.modelData.action()
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onEntered: parent.color = Colors.text
                                onExited: parent.color = parent.index === 1 ? Colors.peach : Colors.overlay0
                            }
                        }
                    }
                }
            }
        }
    }
}

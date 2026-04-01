import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Notifications

ShellRoot {
    id: root

    // ── État global ───────────────────────────────────────────────────
    property bool mprisVisible: false
    property bool pickerVisible: false
    property bool calendarVisible: false
    property bool notifCenterVisible: false
    property list<string> wallpapers: []
    property int unreadCount: 0

    // ── Processus globaux ─────────────────────────────────────────────
    Process {
        id: scanProc
        command: ["bash", "-c", "ls /home/dod/Pictures/wallpapers/*.{jpg,jpeg,png,webp} 2>/dev/null | sort"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                if (data.trim() !== "")
                    root.wallpapers.push(data.trim())
            }
        }
    }

    property alias preloadProc: _preloadProc
    property alias applyProc: _applyProc

    Process { id: _preloadProc; running: false; onExited: _applyProc.running = true }
    Process { id: _applyProc; running: false }

    // ── Raccourcis clavier ────────────────────────────────────────────
    GlobalShortcut {
        name: "wallpaperPicker"
        description: "Toggle wallpaper picker"
        onPressed: root.pickerVisible = !root.pickerVisible
    }

    GlobalShortcut {
        name: "mprisPopup"
        description: "Toggle MPRIS popup"
        onPressed: root.mprisVisible = !root.mprisVisible
    }

    // ── Serveur de notifications ──────────────────────────────────────
    NotificationServer {
        id: notifServer
        keepOnReload: true

        onNotification: notif => {
            console.log("notif reçue:", notif.appName, notif.summary, notif.body)
            notifModel.insert(0, {
                "nid":     notif.id,
                "appName": notif.appName,
                "summary": notif.summary,
                "body":    notif.body,
                "urgency": notif.urgency,
                "actions": notif.actions,
                "notif":   notif,
                "read":    false
            })
            root.unreadCount++
            popupWindow.show(notif)
        }
    }

    property alias notifModel: _notifModel
    ListModel { id: _notifModel }

    // ── Pop MPRIS with equalizer ──────────────────────────────────────

    MprisPopup {
        id: mprisPopup
        visible: root.mprisVisible
        barWindow: bar
    }

    // ── Composants ────────────────────────────────────────────────────
    Bar { id: bar }
    NotifPopup { id: popupWindow }
    NotifCenter {}
    Calendar {}
    WallpaperPicker {}
}

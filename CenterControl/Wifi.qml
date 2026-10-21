import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import QtQml.Models
import qs

Rectangle {
  id: root
  readonly property real uiScale: UiScale.factor(screen.width)

  // --- Wi-Fi state ---
  property string ssid: ""
  property int signal: 0
  property bool connected: ssid !== ""

  // Material Design Wi-Fi glyphs (nf-md-wifi_strength_*), built from code points
  // so they can't get mangled by copy/paste.
  readonly property string wifiIcon: {
    if (!connected) return String.fromCodePoint(0xF092E)   // 󰤮 off
    if (signal >= 80) return String.fromCodePoint(0xF0928) // 󰤨 full
    if (signal >= 60) return String.fromCodePoint(0xF0925) // 󰤥
    if (signal >= 40) return String.fromCodePoint(0xF0922) // 󰤢
    if (signal >= 20) return String.fromCodePoint(0xF091F) // 󰤟
    return String.fromCodePoint(0xF092F)                   // 󰤯 very weak
  }

  Layout.fillWidth: true
  Layout.fillHeight: true
  Layout.leftMargin: 10 * uiScale
  Layout.rightMargin: 10 * uiScale

  width: parent.width
  color: Colors.background
  implicitHeight: 256 * uiScale
  radius: 12 * uiScale
  border.width: 2 * uiScale
  border.color: Colors.primary_container

  // Runs nmcli and parses the active connection
  Process {
    id: wifiProc
    command: ["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL", "dev", "wifi"]
    stdout: StdioCollector {
      onStreamFinished: {
        let found = false
        for (const line of text.split("\n")) {
          // Format: yes:SSID:SIGNAL  (colons inside the SSID are escaped as \:)
          const m = line.match(/^yes:(.*):(\d+)$/)
          if (m) {
            root.ssid = m[1].replace(/\\:/g, ":")
            root.signal = parseInt(m[2])
            found = true
            break
          }
        }
        if (!found) {
          root.ssid = ""
          root.signal = 0
        }
      }
    }
  }

  // Poll every 5 seconds (and once immediately)
  Timer {
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!wifiProc.running) wifiProc.running = true
  }

  RowLayout {
    anchors {
      left: parent.left
      leftMargin: 32 * uiScale
      verticalCenter: parent.verticalCenter
    }
    spacing: 24 * uiScale

    Text {
      text: root.wifiIcon
      color: root.connected ? Colors.primary : Colors.outline
      font.family: "JetBrainsMono Nerd Font"   // use whatever Nerd Font you have installed
      font.pixelSize: 52 * uiScale
    }

    Text {
      text: root.connected ? root.ssid : "Not connected"
      color: Colors.primary
      font.pixelSize: 28 * uiScale
    }
  }

  MouseArea {
    objectName: "cardMouseArea"
    anchors.fill: parent
    onClicked: Quickshell.execDetached([
      "hyprctl", "dispatch",
      'hl.dsp.workspace.toggle_special("nmtui")'
    ])
  }
}

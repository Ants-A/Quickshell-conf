import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray
//Homemade files
import "TrayIcons.qml"
import "BatteryIcon.qml"
import ".."


Rectangle{
  id: root
  readonly property real uiScale: UiScale.factor(width)
  anchors {
    fill: parent
    bottomMargin: 4 * uiScale
    leftMargin: 6 * uiScale
    rightMargin: 6 * uiScale
  }
  color: Colors.md3.background_dark
  opacity: 0.69
  radius: 12 * uiScale

  PwObjectTracker {
		objects: [ Pipewire.defaultAudioSink ]
	}

  SystemClock { 
    id: clock
    precision: SystemClock.Seconds
  }

  RowLayout {
    anchors.fill: parent
    anchors.rightMargin: 20 * root.uiScale
    spacing: 24 * root.uiScale

    Item { Layout.fillWidth: true } // pushes everything to the right

    Row {
      spacing: 24 * root.uiScale

      //TrayIcons {}

      Text {
        height: 36 * root.uiScale
        text: "󰖁"
        color: Colors.md3.primary
        font.pixelSize: 26 * root.uiScale
        visible: Pipewire.defaultAudioSink.audio.muted
      }

      BatteryIcon { uiScale: root.uiScale }

      Rectangle { //System clock
        implicitWidth: 185 * root.uiScale
        height: 36 * root.uiScale
        color: "transparent"
        radius: 8 * root.uiScale
        border.color: Colors.md3.primary
        border.width: 2 * root.uiScale
        Text { 
          id: clockText
          anchors.centerIn: parent
          text: Qt.formatDateTime(clock.date, "hh:mm dd MMM")
          font.pixelSize: 28 * root.uiScale
          font.bold: true
          color: Colors.palette.primary90
        }
      }
    }
  }
}

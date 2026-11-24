import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray
//Homemade files
import qs
import "TrayIcons.qml"
import "BatteryIcon.qml"
import "SysPerformance.qml"


Rectangle{
  id: root
  readonly property real uiScale: UiScale.factor(width)
  anchors {
    fill: parent
    bottomMargin: 2 * uiScale
    leftMargin: 3 * uiScale
    rightMargin: 3 * uiScale
  }
  color: "transparent"
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

    // LEFT
    SysPerformance {
      Layout.leftMargin: 18 * root.uiScale
      uiScale: root.uiScale
      Layout.alignment: Qt.AlignVCenter
    }

    Item { Layout.fillWidth: true } // pushes everything to the right

    Row {
      spacing: 12 * root.uiScale

      Rectangle {
        color: "transparent"
        anchors {
          right: parent.right
          left: parent.left
        }
      }

      //TrayIcons {}

      Text {
        height: 36 * root.uiScale
        verticalAlignment: Text.AlignVCenter
        text: "󰖁"
        color: Colors.primary70
        font.pixelSize: 32 * root.uiScale
        style: Text.Outline
        styleColor: Colors.background_dark
        visible: Pipewire.defaultAudioSink?.audio.muted ?? false
      }

      BatteryIcon { uiScale: root.uiScale }

      Rectangle { //System clock
        implicitWidth: 185 * root.uiScale
        height: 36 * root.uiScale
        color: Qt.alpha(Colors.background_dark, 0.69)
        radius: 8 * root.uiScale
        border.color: Colors.primary
        border.width: 2 * root.uiScale
        Text { 
          id: clockText
          anchors.centerIn: parent
          text: Qt.formatDateTime(clock.date, "hh:mm dd MMM")
          font.pixelSize: 28 * root.uiScale
          font.bold: true
          color: Colors.primary90
        }
      }
    }
  }
}

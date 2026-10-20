import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import QtQml.Models
import "./Notifications"
import "./CenterControl/"

PanelWindow {
  id: centerWindow
  readonly property real uiScale: UiScale.factor(width)
  property bool centerOpen: false
  property var notServer
  property var default_x: 2028 * uiScale
  signal toggle()
  WlrLayershell.namespace: "qs-bar"

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  color: "transparent"
  exclusionMode: ExclusionMode.Ignore

  mask: Region { item: centerOpen ? fullScreenCatcher : null }

  onToggle: {
    if (centerOpen) {
      mainRect.x = default_x
    }
    else {
      mainRect.x = default_x + 1000
    }
  }

  Item {
    id: fullScreenCatcher
    anchors.fill: parent

    MouseArea {
      anchors.fill: parent
      onClicked: centerOpen = false
    }

    Rectangle {
      id: mainRect
      anchors {
        top: parent.top
        bottom: parent.bottom
        rightMargin: 20 * uiScale
        topMargin: 20 * uiScale
        bottomMargin: 76 * uiScale
      }
      x: default_x + 1000
      width: 512 * uiScale
      color: "#70000000"
      border.width: 3 * uiScale
      border.color: Colors.md3.primary
      radius: 16 * uiScale

      MouseArea {
        anchors.fill: parent
        onClicked: {}
      }

      Behavior on x {
        SpringAnimation {
          spring: 10
          damping: 0.6
        }
      }

      ColumnLayout {
        anchors {
          top: parent.top
          left: parent.left
          right: parent.right
          bottom: nothistory.top
          topMargin: 24 * uiScale
          bottomMargin: 24 * uiScale
          leftMargin: 1 * uiScale
          rightMargin: 1 * uiScale
        }
        spacing: 32 * uiScale

        Wifi {}
        Bluetooth {}
        Wifi {}
      }

      Rectangle { // notification history
        id: nothistory
        anchors {
          fill: parent
          topMargin: 400 * uiScale
          rightMargin: 10 * uiScale
          leftMargin: 10 * uiScale
          bottomMargin: 10 * uiScale
        }
        border.width: 2 * uiScale
        border.color: Colors.md3.primary_container
        radius: 8 * uiScale
        color: "#30000000"

        RowLayout {
          id: headerRow
          anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 12 * uiScale
          }

          Text {
            Layout.fillWidth: true
            text: "Notifications"
            color: Colors.md3.primary
            font.pixelSize: 28 * uiScale
          }

          Text {
            text: "Clear All"
            color: notServer.history.count > 0 ? Colors.md3.error : Colors.palette.neutral40
            font.pixelSize: 28 * uiScale
            MouseArea {
              anchors.fill: parent
              onClicked: { notServer.history.clear() }
            }
          }
        }

        ListView {
          id: historyListView
          anchors {
            top: headerRow.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            leftMargin: 24 * uiScale
            topMargin: 12 * uiScale
            bottomMargin: 12 * uiScale
          }
          clip: true
          spacing: 12 * uiScale

          model: notServer.history

          delegate: PopUp {
            id: historyCard
            width: historyListView.width - 24 * uiScale
            scaleFactor: centerWindow.uiScale
            history: notServer.history
            resolveNotif: (id) => notServer.liveNotification(id)

            ListView.onRemove: SequentialAnimation {
              PropertyAction { target: historyCard; property: "ListView.delayRemove"; value: true }
              ParallelAnimation {
                NumberAnimation { target: historyCard; property: "opacity"; to: 0; duration: 200 }
                NumberAnimation { target: historyCard; property: "x"; to: -100; duration: 200 }
              }
              PropertyAction { target: historyCard; property: "ListView.delayRemove"; value: false }
            }
          }

          add: Transition {
            NumberAnimation { properties: "x,y"; from: 100; duration: 120 }
          }

          addDisplaced: Transition {
            NumberAnimation { properties: "x,y"; duration: 220 }
          }

          removeDisplaced: Transition {
            NumberAnimation { properties: "x,y"; duration: 220 }
          }
        }
      }
    }
  }
}

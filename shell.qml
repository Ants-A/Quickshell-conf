//@ pragma UseQApplication
import Quickshell // for PanelWindow
import QtQuick // for Text
import Quickshell.Io
import Quickshell.Wayland
import "./Bar"
import "./Lock"
import "./PopUps"
import "./Notifications"

ShellRoot {
  id: toplevel

  LockScreen {
    id: lock
  }
  
  IpcHandler {
    target: "lock"
    function lock(): void {lock.locked = true;}
  }

  Variants {
    model: Quickshell.screens
    
    PanelWindow {
      anchors {
        bottom: true
        left: true
        right: true
      }
      property real uiScale: UiScale.factor(width)
      margins {
        bottom: 4 * uiScale
        left: 6 * uiScale
        right: 6 * uiScale
      }
      WlrLayershell.namespace: "qs-bar"
      required property var modelData
      screen: modelData
      implicitHeight: 52 * uiScale
      color: "transparent"
      
      Bar {
        id: bar
      }
    }
  }

  VolumeOSD {
    id: volumeBox
  }


  BrightnessOSD {
    id: brightnessBox
  }

  NotServer {
    id: notserver
  }

  Variants {
    model: Quickshell.screens
    CenterControl {
      id: centercontrol
      notServer: notserver
      required property var modelData
      screen: modelData
    }
  }
}

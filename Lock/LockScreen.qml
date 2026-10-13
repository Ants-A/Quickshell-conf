import Quickshell
import QtQuick
import Quickshell.Wayland
import QtQuick.Controls
import Quickshell.Io
import Qt5Compat.GraphicalEffects
import Quickshell.Services.Pam
import ".."



WlSessionLock {
  id: lock
  locked: false

  WlSessionLockSurface {
    Image {
      id: wallpaper
      fillMode: Image.PreserveAspectCrop
      anchors.fill: parent
      source: "/home/ant/.config/quickshell/assets/Wallpaper"
      asynchronous: true
    }
    GaussianBlur {
      anchors.fill: wallpaper
      source: wallpaper
      radius: 32
      samples: 32
    }
    color: "#000000"


    TextField {
      id: textBox
      anchors {
        horizontalCenter: parent.horizontalCenter
        bottom: parent.bottom
        bottomMargin: 52
      }
      focus: true
      background: Rectangle {
        color: Colors.md3.background
        border.width: 5
        border.color: Colors.md3.on_primary
        radius: 30
      }
      font.pixelSize: 36
      placeholderTextColor: Colors.md3.primary
      rightPadding: 52
      leftPadding: 52
      placeholderText: "Don't touch it"
      width: 512
      height: 81
      color: Colors.md3.primary
      echoMode: TextInput.Password
      onTextChanged: placeholderTextColor = Colors.md3.primary
      onAccepted: pam.start()
    }

    property int failedAttempts: 0
    property int maxAttempts: 3

    Timer {
      id: lockTimer
      interval: 10000
      repeat: false
      running: false
      onTriggered: {
        failedAttempts = 0
        textBox.enabled = true
      }
    }


    PamContext {
      id: pam
      config: "login"
      onPamMessage: (message, style) => {
        if (pam.responseRequired) {pam.respond(textBox.text)}
      }
      onCompleted: (result) => {
        if (result === PamResult.Success) {
          lock.locked = false
        }
        else {
          failedAttempts++
          textBox.text = ""
          if (failedAttempts >= maxAttempts) {
            textBox.placeholderText = "Awww, you got locked out"
            textBox.placeholderTextColor = Colors.md3.error
            textBox.enabled = false
            lockTimer.start()
          } else {
            textBox.placeholderText = "Stuuupid"
            textBox.placeholderTextColor = Colors.md3.error
          }
        }
      }
    }
  }
}

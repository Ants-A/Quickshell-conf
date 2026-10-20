pragma Singleton
import Quickshell
import Quickshell.Io


Singleton {
  property bool open: false
  IpcHandler {
    target: "notifications"
    function toggle() : void { 
      open = !open
    }
  }
}


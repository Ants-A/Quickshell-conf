import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import QtQml.Models
import ".."

Scope {
  id: root

  // Notification history shown in the center control.
  property alias history: history
  ListModel { id: history }

  // Notifications currently shown as popup toasts.
  property alias activePopups: activePopups
  ListModel { id: activePopups }

  // Parallel store of the live notification objects, newest first.
  // ListModel.get() drops QObject values, so the popup model rows carry a
  // plain `id` role for lookups while we keep the objects themselves here.
  property var activeNotifs: []

  readonly property int maxPopups: 8
  readonly property int maxHistory: 20

  // Creates the per-toast 5s auto-expire timers.
  Component {
    id: expireFactory
    Timer { interval: 5000; repeat: false }
  }

  function removePopup(notifId) {
    for (let i = 0; i < activePopups.count; i++) {
      const row = activePopups.get(i)
      if (notifId !== undefined && row.notifId === notifId) {
        activePopups.remove(i, 1)
        break
      }
    }
  }

  // Resolve the live Notification object by id, or null if it is already
  // gone. Only ever called at click/expiry time, so no stale QObject
  // references are retained anywhere (ListModel roles are plain data only).
  function liveNotification(id) {
    for (let i = 0; i < root.activeNotifs.length; i++) {
      if (root.activeNotifs[i].id === id) return root.activeNotifs[i]
    }
    return null
  }

  // Kitty forwards Codex OSC 9 notifications under its own application name.
  // OSC 777 gives future notifications a distinct Codex title instead.
  function isCodexNotification(n) {
    if (n.appName.toLowerCase() !== "kitty") return false
    return n.summary === "Codex" || n.summary.startsWith("Approval requested:") ||
           n.summary.startsWith("Approval requested by ") || n.summary.startsWith("Codex wants to edit ") ||
           n.summary.startsWith("Plan mode prompt:") || n.summary.startsWith("Question:")
  }

  function clearCodexHistory() {
    for (let i = history.count - 1; i >= 0; i--) {
      const row = history.get(i)
      if (!row.codexNotification) continue
      const id = row.notifId
      history.remove(i, 1)
      const n = root.liveNotification(id)
      if (n) n.dismiss()
    }
  }

  Connections {
    target: Hyprland
    function onActiveToplevelChanged() {
      const window = Hyprland.activeToplevel
      if (window && window.wayland && window.wayland.appId.toLowerCase() === "kitty")
        root.clearCodexHistory()
    }
  }

  function clearHistory() {
    while (history.count > 0) {
      const id = history.get(history.count - 1).notifId
      history.remove(history.count - 1)
      const n = root.liveNotification(id)
      if (n) n.dismiss()
    }
  }

  NotificationServer {
    id: server

    actionsSupported: true
    bodySupported: true
    imageSupported: true
    persistenceSupported: true

    onNotification: n => {
      const saveHistory = !n.transient && n.appName.toLowerCase() !== "hyprshot"

      // Keep the history bounded.
      while (saveHistory && history.count >= root.maxHistory) {
        const oldId = history.get(history.count - 1).notifId
        history.remove(history.count - 1, 1)
        const old = root.liveNotification(oldId)
        if (old) old.expire()
      }

      // Snapshot of the notification as PLAIN data. ListModel does not
      // preserve QObject (or null) values in roles, so rows hold only
      // strings/numbers and the live object lives in `activeNotifs`.
      const image = n.image || n.appIcon || ""

      // Plain string role holding the notification's actions. ListModel cannot
      // store arrays of objects (they are dropped exactly like QObjects), so
      // actions are JSON-serialized here and parsed by PopUp.
      const actionList = []
      for (const a of (n.actions || [])) {
        actionList.push({ identifier: a.identifier, text: a.text })
      }
      const actions = JSON.stringify(actionList)

      if (saveHistory) history.insert(0, {
        notifId: n.id,
        summary: n.summary,
        body: n.body,
        appName: n.appName,
        codexNotification: root.isCodexNotification(n),
        urgency: n.urgency,
        image: image,
        actions: actions,
        time: Qt.formatDateTime(new Date(), "HH:mm")
      })

      // Prepend to the popup model so the newest toast appears at the bottom.
      // Text/data only — the delegate resolves the live object via
      // liveNotification(notifId) when a click actually needs it.
      if (!n.lastGeneration) activePopups.insert(0, {
        notifId: n.id,
        summary: n.summary,
        body: n.body,
        image: image,
        actions: actions
      })
      root.activeNotifs.unshift(n)

      // Hide the toast after 5s while keeping its action available in history.
      const expireT = expireFactory.createObject(root)
      const notifId = n.id
      expireT.triggered.connect(function() {
        root.removePopup(notifId)
        if (!saveHistory) {
          const live = root.liveNotification(notifId)
          if (live) live.expire()
        }
        expireT.destroy()
      })
      expireT.start()

      // Bound the number of toasts on screen (each removal still animates out
      // via the delegate's ListView.onRemove).
      while (activePopups.count > root.maxPopups) {
        activePopups.remove(activePopups.count - 1, 1)
      }

      // A client can close a notification after it has been read in the app.
      n.closed.connect(function() {
        root.removePopup(notifId)
        for (let i = history.count - 1; i >= 0; i--) {
          if (history.get(i).notifId === notifId) history.remove(i, 1)
        }
        const index = root.activeNotifs.indexOf(n)
        if (index !== -1) root.activeNotifs.splice(index, 1)
      })

      n.tracked = true
    }
  }

  Variants {
    model: Quickshell.screens

  PanelWindow { // The notification popups
    id: popupWindow
    required property var modelData
    readonly property real uiScale: UiScale.factor(screen.width)
    screen: modelData
    anchors {
      bottom: true
      right: true
    }

    margins {
      bottom: 72 * uiScale
      right: 28 * uiScale
    }

    width: 512 * uiScale
    implicitHeight: 900 * uiScale // tall enough for any realistic stack
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    // Only the popup stack takes input; everything else is click-through.
    mask: Region { item: list }

    ListView {
      id: list
      width: parent.width
      spacing: 12 * popupWindow.uiScale
      clip: false
      interactive: false
      model: root.activePopups
      verticalLayoutDirection: ListView.BottomToTop

      // Grow upward from the bottom of the window.
      height: Math.min(contentHeight, parent.height)
      y: parent.height - height

      delegate: PopUp {
        id: popupCard
        scaleFactor: popupWindow.uiScale
        history: root.history
        resolveNotif: (id) => root.liveNotification(id)

        // Guaranteed exit animation: each removed toast animates itself out
        // before being released from the view (works even when several
        // notifications close at the same time).
        ListView.onRemove: SequentialAnimation {
          PropertyAction { target: popupCard; property: "ListView.delayRemove"; value: true }
          ParallelAnimation {
            NumberAnimation { target: popupCard; property: "opacity"; to: 0; duration: 200 }
            NumberAnimation { target: popupCard; property: "x"; to: 420 * uiScale; duration: 200 }
          }
          PropertyAction { target: popupCard; property: "ListView.delayRemove"; value: false }
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

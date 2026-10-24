import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import QtQml.Models
import ".."

Scope {
  id: root
  property var use_screen 

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

  function removePopup(notif) {
    const notifId = notif ? notif.id : undefined
    for (let i = 0; i < activePopups.count; i++) {
      const row = activePopups.get(i)
      if (notifId !== undefined && row.notifId === notifId) {
        activePopups.remove(i, 1)
        break
      }
    }
    for (let i = 0; i < root.activeNotifs.length; i++) {
      if (root.activeNotifs[i] === notif) {
        root.activeNotifs.splice(i, 1)
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

  function expireId(id) {
    const n = root.liveNotification(id)
    if (n) n.expire()
  }

  NotificationServer {
    id: server

    actionsSupported: true
    bodySupported: true
    imageSupported: true

    onNotification: n => {
      // Keep the history bounded.
      while (history.count >= root.maxHistory) history.remove(history.count - 1, 1)

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

      history.insert(0, {
        notifId: n.id,
        summary: n.summary,
        body: n.body,
        appName: n.appName,
        urgency: n.urgency,
        image: image,
        actions: actions,
        time: Qt.formatDateTime(new Date(), "HH:mm")
      })

      // Prepend to the popup model so the newest toast appears at the bottom.
      // Text/data only — the delegate resolves the live object via
      // liveNotification(notifId) when a click actually needs it.
      activePopups.insert(0, {
        notifId: n.id,
        summary: n.summary,
        body: n.body,
        image: image,
        actions: actions
      })
      root.activeNotifs.unshift(n)

      // Deterministic auto-expire for this toast (5s), independent of any
      // delegate state. Resolves by id at fire time -> safe if already closed.
      const expireT = expireFactory.createObject(root)
      expireT.triggered.connect(function() { root.expireId(n.id); expireT.destroy() })
      expireT.start()

      // Bound the number of toasts on screen.
      if (root.activeNotifs.length > root.maxPopups) {
        const oldest = root.activeNotifs[root.activeNotifs.length - 1]
        if (oldest) oldest.expire()
      }
      // Hard fallback: drop any excess rows (each removal still animates out
      // via the delegate's ListView.onRemove).
      while (activePopups.count > root.maxPopups) {
        root.activeNotifs.pop()
        activePopups.remove(activePopups.count - 1, 1)
      }

      // Remove the toast from the screen when the notification closes.
      n.closed.connect(function() {
        root.removePopup(n)
      })

      n.tracked = true
    }
  }

  PanelWindow { // The notification popups
    id: popupWindow
    readonly property real uiScale: UiScale.factor(screen.width)
    screen: use_screen
    anchors {
      bottom: true
      right: true
    }

    margins {
      bottom: 78 * uiScale
      right: 18 * uiScale
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

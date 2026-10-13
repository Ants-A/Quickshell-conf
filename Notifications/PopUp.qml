import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import ".."

Rectangle {
  id: card
  property real scaleFactor: 1

  // Plain text/data fields, auto-bound from ListModel roles by the view
  // delegate. Only strings/numbers/booleans — no QObjects — are ever stored
  // in ListModel rows (ListModel drops QObject and null role values, which
  // silently broke the summary/body text and delegate creation before).
  required property string summary
  required property string body
  required property string image
  required property int notifId
  // Notification actions as a JSON string role (ListModel cannot hold arrays,
  // only plain values). Parsed into `actionList` below.
  required property string actions
  // [{identifier, text}] parsed from the `actions` role, never QObjects.
  readonly property var actionList: card.actions === "" ? [] : JSON.parse(card.actions)

  // Optional history model. When set, clicking this card removes its entry
  // (found by the plain `notifId` role, which survives ListModel's copy
  // semantics) from that model.
  property var history: null

  // Optional lookup: called at click time with this card's notifId to resolve
  // the *live* notification object (may be null if the notification is gone).
  // Using a callback avoids storing QObjects on the card — such references
  // dangle once the notification closes.
  property var resolveNotif: null

  implicitWidth: 512 * scaleFactor
  radius: 12 * scaleFactor
  color: "#80000000"
  border.width: 2 * scaleFactor
  border.color: Colors.md3.primary

  // Left edge of the text column (moves right when an icon is shown).
  readonly property real textX: icon.visible ? 24 * scaleFactor + icon.width + 24 * scaleFactor : 10 * scaleFactor
  // The text column gets an explicit width so wrapMode + maximumLineCount
  // produce a deterministic laid-out height (implicit heights of wrapped
  // Text do not, which is why the card previously collapsed to 84px).
  // Widths come from the actual laid-out `width` (defaults to implicitWidth
  // 400) so cards sized differently — e.g. the narrower CenterControl
  // history card — wrap text inside themselves instead of overflowing the
  // card edge.
  readonly property real textWidth: Math.max(0, width - textX - 10 * scaleFactor)

  implicitHeight: Math.max(icon.height + 20 * scaleFactor,
                           texts.height + 20 * scaleFactor +
                           (actionRow.visible ? actionRow.height + 10 * scaleFactor : 0))

  // Removes this card's entry from the history model, found by the plain
  // `notifId` role (survives ListModel's copy semantics).
  function removeRowFromHistory() {
    if (card.history) {
      for (let i = 0; i < card.history.count; i++) {
        if (card.history.get(i).notifId === card.notifId) {
          card.history.remove(i, 1)
          break
        }
      }
    }
  }

  // Clicking the card body dismisses the notification (and removes the
  // history row). Actions are deliberately NOT invoked here — that would fire
  // every action at once (e.g. Pair *and* Decline). Use the action buttons.
  function activate() {
    card.removeRowFromHistory()
    if (card.resolveNotif) {
      const notif = card.resolveNotif(card.notifId)
      if (notif) notif.dismiss()
    }
  }

  // A specific action button was clicked: invoke only that action, then
  // dismiss (falls back to just removing the history row if the live
  // notification is already gone).
  function invokeAction(identifier) {
    card.removeRowFromHistory()
    if (card.resolveNotif) {
      const notif = card.resolveNotif(card.notifId)
      if (notif) {
        for (const action of (notif.actions || [])) {
          if (action.identifier === identifier) {
            action.invoke()
            break
          }
        }
        notif.dismiss()
      }
    }
  }

  Image {
    id: icon
    x: 10 * scaleFactor
    y: 10 * scaleFactor
    width: 52 * scaleFactor
    height: 52 * scaleFactor
    fillMode: Image.PreserveAspectFit
    mipmap: true
    source: card.image
    visible: source.toString() !== ""
  }

  Column {
    id: texts
    x: card.textX
    y: 14 * scaleFactor
    width: card.textWidth
    spacing: 6 * scaleFactor

    Text {
      id: summaryText
      objectName: "summaryText"
      width: parent.width
      text: card.summary
      color: "white"
      font.bold: true
      font.pixelSize: 24 * scaleFactor
      // Text.Wrap wraps at word boundaries; this Qt's Text.Wrap is an alias
      // of WrapAtWordBoundaryOrAnywhere, which also breaks *unbreakable* long
      // words (URLs, tokens) so they never overflow the box. maximumLineCount
      // + elide still cap the result.
      wrapMode: Text.Wrap
      maximumLineCount: 2
      elide: Text.ElideRight
    }

    Text {
      id: bodyText
      objectName: "bodyText"
      width: parent.width
      text: card.body
      visible: text !== ""
      color: "white"
      font.pixelSize: 24 * scaleFactor
      wrapMode: Text.Wrap
      maximumLineCount: 4
      elide: Text.ElideRight
    }
  }

  MouseArea {
    objectName: "cardMouseArea"
    anchors.fill: parent
    onClicked: card.activate()
  }

  // Action buttons, laid out below the text column. Declared after the
  // full-card MouseArea so each button's MouseArea receives clicks first.
  Row {
    id: actionRow
    objectName: "actionRow"
    visible: card.actionList.length > 0
    x: card.textX
    y: texts.y + texts.height + 8 * scaleFactor
    spacing: 12 * scaleFactor

    Repeater {
      model: card.actionList

      delegate: Rectangle {
        objectName: "actionButton"
        height: 36 * scaleFactor
        radius: 8 * scaleFactor
        // Darken the fill on hover for clear visual feedback.
        color: hoverArea.containsMouse ? Qt.darker(Colors.md3.primary, 1.2) : Colors.md3.primary
        width: Math.min(actionLabel.implicitWidth + 36 * scaleFactor, 240 * scaleFactor)

        Text {
          id: actionLabel
          anchors.centerIn: parent
          text: modelData.text
          color: Colors.md3.on_primary
          font.pixelSize: 14 * scaleFactor
          font.bold: true
          elide: Text.ElideRight
          width: Math.min(implicitWidth, parent.width - 24)
        }

        MouseArea {
          id: hoverArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: card.invokeAction(modelData.identifier)
        }
      }
    }
  }

  // Entrance fade, driven from the delegate so it isn't restarted by view
  // re-layouts (a ListView `add` Transition's opacity animation stalled near 0
  // when new toasts arrived while earlier ones were still fading in).
  Component.onCompleted: {
    card.opacity = 0
    fadeIn.start()
  }

  NumberAnimation {
    id: fadeIn
    target: card
    property: "opacity"
    from: 0
    to: 1
    duration: 200
    running: false
  }
}

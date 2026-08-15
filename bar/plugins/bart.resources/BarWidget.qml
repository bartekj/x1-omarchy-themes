import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

// X1 resources cluster: a framed card holding CPU / RAM / temp / disk cells
// with hairline separators. Each icon is tinted by its usage level; values,
// levels, and the level colors all come from x1-bar-stats so the palette
// always follows the active theme. Left click opens the detail panel,
// right click jumps straight to btop.

BarWidget {
  id: root
  moduleName: "bart.resources"

  property var stats: null
  readonly property var levelColors: stats && stats.colors ? stats.colors : ["#7fbf7f", "#d19a66", "#e06c75"]
  // barForeground (not foreground): the animated, transparency-aware color
  // every stock widget uses — the card recolors with the bar.
  readonly property color lineColor: bar ? bar.barForeground : "white"

  function pad(v, w) {
    return String(v).padStart(w, " ")
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = frame
    if ("hostWidget" in target) target.hostWidget = root
  }

  function togglePanel() {
    if (panelLoader.item && panelLoader.item.toggle) panelLoader.item.toggle()
  }

  // Shape contract for the bar's popout coordinator and shell.summon routing:
  // the bar identifies a panel by the widget mounted in its slot, so this
  // root forwards the panel's open/close surface.
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false

  function open() {
    if (panelLoader.item && panelLoader.item.open) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item && panelLoader.item.close) panelLoader.item.close()
  }

  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  visible: true
  implicitWidth: frame.implicitWidth
  implicitHeight: barSize

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Process {
    id: statsProc
    command: ["bash", "-lc", "~/.config/omarchy/bar/scripts/x1-bar-stats"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var raw = String(text || "").trim()
        if (!raw) return
        try {
          root.stats = JSON.parse(raw.split("\n").pop())
        } catch (e) {}
      }
    }
  }

  Timer {
    interval: Math.max(1, Number(root.setting("intervalSec", 2))) * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!statsProc.running) statsProc.running = true
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  component ResourceCell: Item {
    id: cell

    property string icon
    property string value
    property int level: 0

    implicitWidth: textRow.implicitWidth
    implicitHeight: textRow.implicitHeight
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined

    Row {
      id: textRow
      spacing: 4

      Text {
        text: cell.icon
        color: root.levelColors[Math.min(cell.level, 2)]
        font.family: root.bar ? root.bar.fontFamily : "monospace"
        font.pixelSize: root.setting("fontSize", Style.font.body)

        Behavior on color {
          ColorAnimation { duration: 160 }
        }
      }
      Text {
        text: cell.value
        color: root.lineColor
        font.family: root.bar ? root.bar.fontFamily : "monospace"
        font.pixelSize: root.setting("fontSize", Style.font.body)
      }
    }
  }

  component CellSeparator: Rectangle {
    width: 1
    height: 14
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    color: Qt.alpha(root.lineColor, 0.12)
  }

  // Frame styled like the shell's own in-bar grouped rectangle (the drag
  // ghost): controls-section fill/border tokens and the theme's Hyprland
  // rounding, so every variant keeps its own corner identity.
  Rectangle {
    id: frame
    anchors.verticalCenter: parent.verticalCenter
    implicitWidth: row.implicitWidth + 2 * root.setting("framePadding", Style.spacing.controlPaddingX)
    height: parent.height - 2 * Style.space(1)
    radius: Math.min(Style.cornerRadius, height / 2)
    color: Style.normalFillFor(root.lineColor, root.lineColor)
    border.width: Style.normalBorderWidth
    border.color: Style.normalBorderFor(root.lineColor, root.lineColor)

    Row {
      id: row
      anchors.centerIn: parent
      spacing: 10
      height: parent.height

      ResourceCell {
        icon: ""
        value: root.stats ? root.pad(root.stats.cpu.v, 3) + "%" : "  -%"
        level: root.stats ? root.stats.cpu.l : 0
      }
      CellSeparator {}
      ResourceCell {
        icon: ""
        value: root.stats ? root.pad(root.stats.mem.v, 3) + "%" : "  -%"
        level: root.stats ? root.stats.mem.l : 0
      }
      CellSeparator {}
      ResourceCell {
        icon: ""
        value: root.stats ? root.pad(root.stats.temp.v, 2) + "°" : " -°"
        level: root.stats ? root.stats.temp.l : 0
      }
      CellSeparator {}
      ResourceCell {
        icon: ""
        value: root.stats ? root.pad(root.stats.disk.v, 2) + "%" : " -%"
        level: root.stats ? root.stats.disk.l : 0
      }
    }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      onClicked: function(mouse) {
        if (mouse.button === Qt.RightButton) {
          if (root.bar) root.bar.run("omarchy-launch-or-focus-tui btop")
        } else {
          root.togglePanel()
        }
      }
    }
  }
}

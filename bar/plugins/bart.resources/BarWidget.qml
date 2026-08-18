import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

// X1 resources cluster: CPU / RAM / temp / disk cells split by quiet hairline
// dividers. Frameless by default — the dividers carry the structure on their
// own. Each icon is tinted by its usage level; values, levels, and the level
// colors all come from x1-bar-stats so the palette always follows the active
// theme. Left click opens the detail panel, right click jumps straight to
// btop.

BarWidget {
  id: root
  moduleName: "bart.resources"

  property var stats: null
  readonly property var levelColors: stats && stats.colors ? stats.colors : ["#9199a3", "#d9dde3", "#e06c75"]
  // barForeground (not foreground): the animated, transparency-aware color
  // every stock widget uses — the card recolors with the bar.
  readonly property color lineColor: bar ? bar.barForeground : "white"

  // Aggregate state, used by the bloom frame's halo. Temp and disk are
  // deliberately left out of the intensity — one is not a percentage, the
  // other barely moves, so neither says anything about "right now".
  readonly property int worstLevel: stats
    ? Math.max(stats.cpu.l, stats.mem.l, stats.temp.l, stats.disk.l) : 0
  readonly property real loadFraction: stats
    ? Math.max(stats.cpu.v, stats.mem.v) / 100 : 0

  function pad(v, w) {
    return String(v).padStart(w, " ")
  }

  // Rolling history for the "columns" readout: oldest to newest, one sample
  // per stats tick. Reassigned wholesale rather than mutated in place,
  // because a push into an existing array does not notify QML bindings.
  readonly property int historyLen: 24
  property var history: ({ cpu: [], mem: [], temp: [], disk: [] })

  // Temperature is degrees, not a percentage. Map the span the thresholds
  // actually care about (warn 55, crit 78) onto 0..1 so every cell's meter
  // means the same thing.
  function normalize(key, v) {
    if (key === "temp") return Math.max(0, Math.min(1, (v - 35) / 60))
    return Math.max(0, Math.min(1, v / 100))
  }

  function recordHistory(s) {
    var keys = ["cpu", "mem", "temp", "disk"]
    var next = {}
    for (var i = 0; i < keys.length; i++) {
      var k = keys[i]
      var a = (root.history[k] || []).slice()
      a.push(root.normalize(k, s[k].v))
      if (a.length > root.historyLen) a.shift()
      next[k] = a
    }
    root.history = next
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = frame
    if ("hostWidget" in target) target.hostWidget = root
  }

  // Each cell opens its own section of the detail panel, anchored under the
  // cell that was clicked.
  function openCell(section, item) {
    if (panelLoader.item && panelLoader.item.openFor) panelLoader.item.openFor(section, item)
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
    // bash -c, not -lc: a login shell spends ~150ms sourcing profiles, several
    // times the cost of the script itself, on every tick.
    command: ["bash", "-c", "~/.config/omarchy/bar/scripts/x1-bar-stats"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var raw = String(text || "").trim()
        if (!raw) return
        try {
          root.stats = JSON.parse(raw.split("\n").pop())
          root.recordHistory(root.stats)
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
    property string section: ""
    property real fraction: 0
    property var samples: []

    implicitWidth: textRow.implicitWidth
    implicitHeight: root.barSize
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      cursorShape: Qt.PointingHandCursor
      onClicked: function(mouse) {
        if (mouse.button === Qt.RightButton) {
          if (root.bar) root.bar.run("omarchy-launch-or-focus-tui btop")
        } else {
          root.openCell(cell.section, cell)
        }
      }
    }

    Row {
      id: textRow
      anchors.centerIn: parent
      spacing: 4

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: cell.icon
        color: root.levelColors[Math.min(cell.level, 2)]
        font.family: root.bar ? root.bar.fontFamily : "monospace"
        font.pixelSize: root.setting("fontSize", Style.font.body)

        Behavior on color {
          ColorAnimation { duration: 160 }
        }
      }

      CellReadout {
        anchors.verticalCenter: parent.verticalCenter
        readoutStyle: root.setting("readoutStyle", "columns")
        value: cell.value
        fraction: cell.fraction
        history: cell.samples
        level: cell.level
        textColor: root.lineColor
        levelColor: root.levelColors[Math.min(cell.level, 2)]
        fontFamily: root.bar ? root.bar.fontFamily : "monospace"
        fontSize: root.setting("fontSize", Style.font.body)
      }
    }
  }

  // With no frame around the cluster these marks are the only structure the
  // readout has. Quiet graphite only — no accent, no live meter.
  component CellSeparator: CellDivider {
    dividerStyle: root.setting("dividerStyle", "hairline")
    lineColor: root.lineColor
  }

  // Card frame, switched by the frameStyle setting. Defaults to "none": the
  // cell dividers are the structure, and a container only crowds them.
  CardFrame {
    id: frame
    anchors.verticalCenter: parent.verticalCenter
    implicitWidth: row.implicitWidth + 2 * root.setting("framePadding", Style.spacing.controlPaddingX)
    height: parent.height - 2 * Style.space(1)
    lineColor: root.lineColor
    frameStyle: root.setting("frameStyle", "none")
    glowColor: root.levelColors[Math.min(root.worstLevel, 2)]
    glowIntensity: root.loadFraction

    Row {
      id: row
      anchors.centerIn: parent
      spacing: 10
      height: parent.height

      ResourceCell {
        icon: ""
        value: root.stats ? root.pad(root.stats.cpu.v, 3) + "%" : "  -%"
        level: root.stats ? root.stats.cpu.l : 0
        section: "cpu"
        fraction: root.stats ? root.normalize("cpu", root.stats.cpu.v) : 0
        samples: root.history.cpu
      }
      CellSeparator {}
      ResourceCell {
        icon: ""
        value: root.stats ? root.pad(root.stats.mem.v, 3) + "%" : "  -%"
        level: root.stats ? root.stats.mem.l : 0
        section: "mem"
        fraction: root.stats ? root.normalize("mem", root.stats.mem.v) : 0
        samples: root.history.mem
      }
      CellSeparator {}
      ResourceCell {
        icon: ""
        value: root.stats ? root.pad(root.stats.temp.v, 2) + "°" : " -°"
        level: root.stats ? root.stats.temp.l : 0
        section: "temp"
        fraction: root.stats ? root.normalize("temp", root.stats.temp.v) : 0
        samples: root.history.temp
      }
      CellSeparator {}
      ResourceCell {
        icon: ""
        value: root.stats ? root.pad(root.stats.disk.v, 2) + "%" : " -%"
        level: root.stats ? root.stats.disk.l : 0
        section: "disk"
        fraction: root.stats ? root.normalize("disk", root.stats.disk.v) : 0
        samples: root.history.disk
      }
    }

    // Frame padding only: cells handle their own clicks. Right click stays
    // a shortcut to the full monitor from anywhere on the card.
    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.RightButton
      onClicked: if (root.bar) root.bar.run("omarchy-launch-or-focus-tui btop")
      z: -1
    }
  }
}

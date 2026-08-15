import QtQuick
import QtQuick.Effects
import Quickshell.Io

// X1 resources cluster: a framed card holding CPU / RAM / temp / disk cells
// with hairline separators. Under each value sits a small blurred glow bar
// tinted by usage level; values, levels, and the level colors all come from
// x1-bar-stats so the palette always follows the active theme.

Item {
  id: root

  property var bar
  property string moduleName
  property var settings

  property var stats: null
  readonly property var levelColors: stats && stats.colors ? stats.colors : ["#7fbf7f", "#d19a66", "#e06c75"]
  readonly property color lineColor: bar ? bar.foreground : "white"

  function setting(name, fallback) {
    var v = settings ? settings[name] : undefined
    return v === undefined || v === null ? fallback : v
  }

  function pad(v, w) {
    return String(v).padStart(w, " ")
  }

  implicitHeight: bar ? bar.barSize : 26
  implicitWidth: frame.implicitWidth

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
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!statsProc.running) statsProc.running = true
  }

  component ResourceCell: Item {
    id: cell

    property string icon
    property string value
    property int level: 0
    property string tip: ""

    implicitWidth: column.implicitWidth
    implicitHeight: column.implicitHeight
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined

    Column {
      id: column
      spacing: 2

      Row {
        id: textRow
        spacing: 4

        Text {
          text: cell.icon
          color: root.lineColor
          font.family: root.bar ? root.bar.fontFamily : "monospace"
          font.pixelSize: root.setting("fontSize", 11)
        }
        Text {
          text: cell.value
          color: root.lineColor
          font.family: root.bar ? root.bar.fontFamily : "monospace"
          font.pixelSize: root.setting("fontSize", 11)
        }
      }

      Item {
        width: textRow.width
        height: 3

        Rectangle {
          id: glowCore
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.verticalCenter: parent.verticalCenter
          width: Math.min(textRow.width - 2, 24)
          height: 2
          radius: 1
          color: root.levelColors[Math.min(cell.level, 2)]
        }

        MultiEffect {
          source: glowCore
          anchors.fill: glowCore
          blurEnabled: true
          blur: 1.0
          blurMax: 12
          autoPaddingEnabled: true
          opacity: 0.85
        }
      }
    }

    HoverHandler {
      onHoveredChanged: {
        if (!root.bar) return
        if (hovered) root.bar.showTooltip(cell, cell.tip)
        else root.bar.hideTooltip(cell)
      }
    }
  }

  component CellSeparator: Rectangle {
    width: 1
    height: 14
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    color: Qt.alpha(root.lineColor, 0.14)
  }

  Rectangle {
    id: frame
    anchors.verticalCenter: parent.verticalCenter
    implicitWidth: row.implicitWidth + 2 * root.setting("framePadding", 10)
    height: parent.height - 4
    radius: root.setting("radius", 7)
    color: Qt.alpha(root.lineColor, 0.05)
    border.width: 1
    border.color: Qt.alpha(root.lineColor, 0.18)

    Row {
      id: row
      anchors.centerIn: parent
      spacing: 10
      height: parent.height

      ResourceCell {
        icon: ""
        value: root.stats ? root.pad(root.stats.cpu.v, 3) + "%" : "  -%"
        level: root.stats ? root.stats.cpu.l : 0
        tip: root.stats ? "CPU " + root.stats.cpu.v + "%\nClick: btop" : ""
      }
      CellSeparator {}
      ResourceCell {
        icon: ""
        value: root.stats ? root.pad(root.stats.mem.v, 3) + "%" : "  -%"
        level: root.stats ? root.stats.mem.l : 0
        tip: root.stats ? "RAM " + root.stats.mem.used + "G / " + root.stats.mem.total + "G (" + root.stats.mem.v + "%)\nClick: btop" : ""
      }
      CellSeparator {}
      ResourceCell {
        icon: ""
        value: root.stats ? root.pad(root.stats.temp.v, 2) + "°" : " -°"
        level: root.stats ? root.stats.temp.l : 0
        tip: root.stats ? "CPU package " + root.stats.temp.v + "°C\nClick: btop" : ""
      }
      CellSeparator {}
      ResourceCell {
        icon: ""
        value: root.stats ? root.pad(root.stats.disk.v, 2) + "%" : " -%"
        level: root.stats ? root.stats.disk.l : 0
        tip: root.stats ? "/ " + root.stats.disk.used + "G / " + root.stats.disk.total + "G (" + root.stats.disk.v + "%)\nClick: btop" : ""
      }
    }

    MouseArea {
      anchors.fill: parent
      onClicked: if (root.bar) root.bar.run("omarchy-launch-or-focus-tui btop")
    }
  }
}

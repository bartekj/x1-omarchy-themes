import QtQuick
import qs.Commons
import qs.Ui

// Detail panel for the X1 resources cluster: CPU / memory / disk sections
// with threshold-colored meters, load average, uptime, and a btop shortcut.
// All data comes from the host bar widget's stats (the always-on 2s tick);
// the panel adds no polling of its own.

Panel {
  id: root
  moduleName: "bart.resources"
  ipcTarget: "bart.resources"

  property var anchorItem: null

  // The bar tracks the widget mounted in its slot — BarWidget.qml — not this
  // nested panel, so the popout coordinator and the open-panel dot compare
  // against the host widget.
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  readonly property var stats: hostWidget ? hostWidget.stats : null
  readonly property var levelColors: stats && stats.colors ? stats.colors : ["#7fbf7f", "#d19a66", "#e06c75"]

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property color track: Style.selectedFillFor(foreground, Color.accent)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  function clamp(v, lo, hi) {
    return Math.max(lo, Math.min(hi, v))
  }

  function lvlColor(l) {
    return levelColors[clamp(l, 0, 2)]
  }

  function launchBtop() {
    if (bar) bar.run("omarchy-launch-or-focus-tui btop")
    close()
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(340))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onReturnRequested: root.launchBtop()
    }

    Column {
      id: column
      width: parent.width
      spacing: Style.space(10)

      PanelSectionHeader {
        text: "Processor"
        foreground: root.foreground
        fontFamily: root.fontFamily
      }

      MeterRow {
        label: "Usage"
        percent: root.stats ? root.stats.cpu.v : -1
        level: root.stats ? root.stats.cpu.l : 0
      }

      InfoRow {
        label: "Temperature"
        value: root.stats ? root.stats.temp.v + "°C" : "—"
        valueColor: root.stats ? root.lvlColor(root.stats.temp.l) : root.foreground
      }

      InfoRow {
        label: "Load average"
        value: root.stats ? root.stats.load : "—"
      }

      PanelSeparator { foreground: root.foreground }

      PanelSectionHeader {
        text: "Memory"
        foreground: root.foreground
        fontFamily: root.fontFamily
      }

      MeterRow {
        label: "RAM"
        percent: root.stats ? root.stats.mem.v : -1
        level: root.stats ? root.stats.mem.l : 0
        caption: root.stats ? root.stats.mem.used + "G / " + root.stats.mem.total + "G" : ""
      }

      MeterRow {
        visible: root.stats ? root.stats.swap.v >= 0 : false
        label: "Swap"
        percent: root.stats ? root.stats.swap.v : -1
        level: 0
        caption: root.stats ? root.stats.swap.used + "G / " + root.stats.swap.total + "G" : ""
      }

      PanelSeparator { foreground: root.foreground }

      PanelSectionHeader {
        text: "Disk /"
        foreground: root.foreground
        fontFamily: root.fontFamily
      }

      MeterRow {
        label: "Used"
        percent: root.stats ? root.stats.disk.v : -1
        level: root.stats ? root.stats.disk.l : 0
        caption: root.stats ? root.stats.disk.used + "G / " + root.stats.disk.total + "G" : ""
      }

      PanelSeparator { foreground: root.foreground }

      Item {
        width: parent.width
        implicitHeight: btopButton.implicitHeight

        Text {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: root.stats ? "Uptime  " + root.stats.uptime : ""
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
        }

        Button {
          id: btopButton
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          bordered: true
          text: "btop"
          foreground: root.foreground
          onClicked: root.launchBtop()
        }
      }
    }
  }

  component MeterRow: Column {
    id: meterRow

    property string label: ""
    property int percent: -1
    property int level: 0
    property string caption: ""

    width: parent.width
    spacing: Style.space(5)

    Item {
      width: parent.width
      implicitHeight: Math.max(rowLabel.implicitHeight, rowValue.implicitHeight)

      Text {
        id: rowLabel
        text: meterRow.label
        color: root.foreground
        opacity: 0.6
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        id: rowValue
        text: meterRow.percent >= 0 ? meterRow.percent + "%" : "—"
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    Meter {
      width: parent.width
      value: meterRow.percent / 100
      fill: root.lvlColor(meterRow.level)
    }

    Text {
      visible: meterRow.caption !== ""
      width: parent.width
      text: meterRow.caption
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }
  }

  // Rounded track + threshold-colored fill (the agents panel meter pattern).
  component Meter: Item {
    id: meter

    property real value: -1
    property color fill: root.foreground
    property real thickness: Math.max(Style.space(4), Math.round(Style.spacing.controlHeight * 0.14))

    implicitHeight: thickness

    Rectangle {
      id: meterTrack
      anchors.fill: parent
      radius: height / 2
      color: root.track
    }

    Rectangle {
      anchors.left: meterTrack.left
      anchors.verticalCenter: meterTrack.verticalCenter
      height: meterTrack.height
      radius: meterTrack.radius
      width: meterTrack.width * root.clamp(meter.value, 0, 1)
      color: meter.fill

      Behavior on width {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
      }
      Behavior on color {
        ColorAnimation { duration: 160 }
      }
    }
  }

  component InfoRow: Item {
    id: infoRow

    property string label: ""
    property string value: ""
    property color valueColor: root.foreground

    width: parent.width
    implicitHeight: Math.max(infoLabel.implicitHeight, infoValue.implicitHeight)

    Text {
      id: infoLabel
      text: infoRow.label
      color: root.foreground
      opacity: 0.6
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      id: infoValue
      text: infoRow.value
      color: infoRow.valueColor
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter

      Behavior on color {
        ColorAnimation { duration: 160 }
      }
    }
  }
}

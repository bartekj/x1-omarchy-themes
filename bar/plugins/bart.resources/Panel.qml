import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Detail panels for the X1 resources cluster. One panel instance re-anchored
// to whichever cell was clicked, with the content switched by `section`, so
// the bar keeps a single popout identity (open-panel dot, popout switching).
// Headline values come from the host widget's 2s stats; the richer per-section
// data is polled only while the panel is open.

Panel {
  id: root
  moduleName: "bart.resources"
  ipcTarget: "bart.resources"
  // Own the IPC target so `section` can be summoned directly, e.g. for a
  // keybinding: omarchy-shell bart.resources section temp
  manageIpc: false

  property var anchorItem: null
  property string section: "cpu"

  // The bar tracks the widget mounted in its slot — BarWidget.qml — not this
  // nested panel, so the popout coordinator and the open-panel dot compare
  // against the host widget.
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  readonly property var stats: hostWidget ? hostWidget.stats : null
  readonly property var levelColors: stats && stats.colors ? stats.colors : ["#9199a3", "#d9dde3", "#e06c75"]
  property var detail: null
  // Section-scoped views of `detail`: the payload shape differs per section,
  // so bindings must never read a field that belongs to another section's
  // JSON (an invisible item still evaluates its bindings).
  readonly property var dCpu: section === "cpu" ? detail : null
  readonly property var dMem: section === "mem" ? detail : null
  readonly property var dTemp: section === "temp" ? detail : null
  readonly property var dDisk: section === "disk" ? detail : null

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property color track: Style.selectedFillFor(foreground, Color.accent)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  readonly property string sectionTitle: section === "cpu" ? "Processor"
    : section === "mem" ? "Memory"
    : section === "temp" ? "Temperature" : "Storage"

  function clamp(v, lo, hi) {
    return Math.max(lo, Math.min(hi, v))
  }

  function lvlColor(l) {
    return levelColors[clamp(l, 0, 2)]
  }

  function levelFor(v, warn, crit) {
    return v >= crit ? 2 : (v >= warn ? 1 : 0)
  }

  // Open (or re-target) the panel for one cell. Clicking the cell whose
  // section is already showing closes it, matching every stock bar widget.
  function openFor(sec, item) {
    if (opened && section === sec) {
      close()
      return
    }
    // Clear before switching: bindings re-evaluate the moment `section`
    // changes, and the previous section's payload has different fields.
    detail = null
    section = sec
    if (item) anchorItem = item
    refresh()
    controller.show()
  }

  // Section a running fetch was started for, so a reply that lands after the
  // user switched cells is discarded instead of being read as the new
  // section's payload (the JSON shape differs per section).
  property string pendingSection: ""

  function refresh() {
    pendingSection = section
    if (!detailProc.running) detailProc.running = true
  }

  function launchBtop() {
    if (bar) bar.run("omarchy-launch-or-focus-tui btop")
    close()
  }

  onSectionChanged: if (opened) refresh()
  onOpenedChanged: if (opened) refresh()

  IpcHandler {
    target: "bart.resources"

    function open() { root.open() }
    function close() { root.close() }
    function show() { root.open() }
    function hide() { root.close() }
    function toggle() { root.toggle() }
    // Jump straight to one section, e.g. from a keybinding.
    function section(name: string) { root.openFor(name || "cpu", null) }
  }

  Process {
    id: detailProc
    // bash -c, not -lc: a login shell costs ~150ms per tick in profile
    // sourcing alone, several times the script itself.
    command: ["bash", "-c", "~/.config/omarchy/bar/scripts/x1-bar-detail " + root.section]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var raw = String(text || "").trim()
        if (!raw || root.pendingSection !== root.section) return
        try {
          root.detail = JSON.parse(raw.split("\n").pop())
        } catch (e) {}
      }
    }
  }

  Timer {
    interval: 1000
    running: root.opened
    repeat: true
    onTriggered: root.refresh()
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(360))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(560))

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
        text: root.sectionTitle
        foreground: root.foreground
        fontFamily: root.fontFamily
      }

      // ---- Processor -----------------------------------------------------

      MeterRow {
        visible: root.section === "cpu"
        label: "Usage"
        percent: root.stats ? root.stats.cpu.v : -1
        level: root.stats ? root.stats.cpu.l : 0
      }

      InfoRow {
        visible: root.section === "cpu"
        label: "Load average"
        value: root.dCpu ? root.dCpu.load : (root.stats ? root.stats.load : "—")
      }

      InfoRow {
        visible: root.section === "cpu"
        label: "Runnable / threads"
        value: root.dCpu ? root.dCpu.procs : "—"
      }

      InfoRow {
        visible: root.section === "cpu"
        label: "Temperature"
        value: root.stats ? root.stats.temp.v + "°C" : "—"
        valueColor: root.stats ? root.lvlColor(root.stats.temp.l) : root.foreground
      }

      PanelSeparator {
        visible: root.section === "cpu"
        foreground: root.foreground
      }

      PanelSectionHeader {
        visible: root.section === "cpu"
        text: "Threads"
        foreground: root.foreground
        fontFamily: root.fontFamily
      }

      Grid {
        visible: root.section === "cpu"
        width: parent.width
        columns: 2
        columnSpacing: Style.space(14)
        rowSpacing: Style.space(5)

        Repeater {
          // Section-gated: cpu and temp both key on `cores` but with different
          // fields, and an invisible Repeater still binds its model.
          model: root.dCpu && root.dCpu.cores ? root.dCpu.cores : []

          Item {
            required property var modelData
            width: (column.width - Style.space(14)) / 2
            implicitHeight: Math.max(coreLabel.implicitHeight, coreMeter.implicitHeight)

            Text {
              id: coreLabel
              text: modelData.cluster + modelData.id
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              width: Style.space(26)
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
            }

            Meter {
              id: coreMeter
              anchors.left: coreLabel.right
              anchors.right: coreValue.left
              anchors.rightMargin: Style.space(6)
              anchors.verticalCenter: parent.verticalCenter
              value: modelData.pct / 100
              fill: root.lvlColor(root.levelFor(modelData.pct, 30, 70))
            }

            Text {
              id: coreValue
              text: modelData.mhz >= 1000
                ? (modelData.mhz / 1000).toFixed(1) + "G"
                : modelData.mhz + "M"
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
            }
          }
        }
      }

      PanelSeparator {
        visible: root.section === "cpu" && cpuTop.count > 0
        foreground: root.foreground
      }

      PanelSectionHeader {
        visible: root.section === "cpu" && cpuTop.count > 0
        text: "Top processes"
        foreground: root.foreground
        fontFamily: root.fontFamily
      }

      Column {
        visible: root.section === "cpu"
        width: parent.width
        spacing: Style.space(4)

        Repeater {
          id: cpuTop
          model: root.dCpu && root.dCpu.top ? root.dCpu.top : []

          InfoRow {
            required property var modelData
            label: modelData.name
            value: modelData.pct >= 0 ? modelData.pct + "%" : "—"
          }
        }
      }

      // ---- Memory --------------------------------------------------------

      MeterRow {
        visible: root.section === "mem"
        label: "RAM"
        percent: root.dMem ? root.dMem.pct : (root.stats ? root.stats.mem.v : -1)
        level: root.stats ? root.stats.mem.l : 0
        caption: root.dMem
          ? root.dMem.used + "G used of " + root.dMem.total + "G"
          : ""
      }

      InfoRow {
        visible: root.section === "mem"
        label: "Available"
        value: root.dMem ? root.dMem.available + "G" : "—"
      }

      InfoRow {
        visible: root.section === "mem"
        label: "Cached"
        value: root.dMem ? root.dMem.cached + "G" : "—"
      }

      InfoRow {
        visible: root.section === "mem"
        label: "Shared (tmpfs)"
        value: root.dMem ? root.dMem.shmem + "G" : "—"
      }

      InfoRow {
        visible: root.section === "mem"
        label: "Dirty"
        value: root.dMem ? root.dMem.dirty + "G" : "—"
      }

      MeterRow {
        visible: root.dMem && root.dMem.swap && root.dMem.swap.total > 0
        label: root.dMem && root.dMem.swap && root.dMem.swap.zram ? "Swap (zram)" : "Swap"
        percent: root.dMem && root.dMem.swap ? root.dMem.swap.pct : -1
        level: 0
        caption: root.dMem && root.dMem.swap
          ? root.dMem.swap.used + "G of " + root.dMem.swap.total + "G compressed in RAM"
          : ""
      }

      PanelSeparator {
        visible: root.section === "mem" && memTop.count > 0
        foreground: root.foreground
      }

      PanelSectionHeader {
        visible: root.section === "mem" && memTop.count > 0
        text: "Top by memory"
        foreground: root.foreground
        fontFamily: root.fontFamily
      }

      Column {
        visible: root.section === "mem"
        width: parent.width
        spacing: Style.space(4)

        Repeater {
          id: memTop
          model: root.dMem && root.dMem.top ? root.dMem.top : []

          InfoRow {
            required property var modelData
            label: modelData.name
            value: modelData.gb + "G"
          }
        }
      }

      // ---- Temperature ---------------------------------------------------

      MeterRow {
        visible: root.section === "temp"
        label: "CPU package"
        percent: root.stats ? root.stats.temp.v : -1
        level: root.stats ? root.stats.temp.l : 0
        unit: "°C"
        scaleMax: 110
        caption: "Smoothed mean of all cores · throttles at 110°C"
      }

      PanelSectionHeader {
        visible: root.section === "temp" && tempCores.count > 0
        text: "Cores"
        foreground: root.foreground
        fontFamily: root.fontFamily
      }

      Grid {
        visible: root.section === "temp"
        width: parent.width
        columns: 3
        columnSpacing: Style.space(10)
        rowSpacing: Style.space(4)

        Repeater {
          id: tempCores
          model: root.dTemp && root.dTemp.cores ? root.dTemp.cores : []

          Item {
            required property var modelData
            width: (column.width - 2 * Style.space(10)) / 3
            implicitHeight: coreTempValue.implicitHeight

            Text {
              text: modelData.label.replace("Core ", "C")
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              id: coreTempValue
              text: modelData.c + "°"
              color: root.lvlColor(root.levelFor(modelData.c, 70, 90))
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter

              Behavior on color {
                ColorAnimation { duration: 160 }
              }
            }
          }
        }
      }

      PanelSeparator {
        visible: root.section === "temp"
        foreground: root.foreground
      }

      PanelSectionHeader {
        visible: root.section === "temp"
        text: "Other sensors"
        foreground: root.foreground
        fontFamily: root.fontFamily
      }

      Column {
        visible: root.section === "temp"
        width: parent.width
        spacing: Style.space(4)

        Repeater {
          model: root.dTemp && root.dTemp.others ? root.dTemp.others : []

          InfoRow {
            required property var modelData
            label: modelData.label
            value: modelData.c + "°C"
          }
        }
      }

      PanelSectionHeader {
        visible: root.section === "temp" && fanRows.count > 0
        text: "Cooling"
        foreground: root.foreground
        fontFamily: root.fontFamily
      }

      Column {
        visible: root.section === "temp"
        width: parent.width
        spacing: Style.space(4)

        Repeater {
          id: fanRows
          model: root.dTemp && root.dTemp.fans ? root.dTemp.fans : []

          InfoRow {
            required property var modelData
            label: modelData.label
            value: modelData.rpm + " rpm"
          }
        }
      }

      InfoRow {
        visible: root.dTemp && root.dTemp.fanLevel !== ""
        label: "Fan control"
        value: root.dTemp ? root.dTemp.fanLevel : ""
      }

      // ---- Storage -------------------------------------------------------

      Column {
        visible: root.section === "disk"
        width: parent.width
        spacing: Style.space(10)

        Repeater {
          model: root.dDisk && root.dDisk.filesystems ? root.dDisk.filesystems : []

          MeterRow {
            required property var modelData
            label: modelData.mount
            percent: modelData.pct
            level: root.levelFor(modelData.pct, 70, 90)
            caption: modelData.used + "G used of " + modelData.total + "G · " + modelData.fstype
          }
        }
      }

      InfoRow {
        visible: root.dDisk && root.dDisk.nvme !== ""
        label: "Device"
        value: root.dDisk ? root.dDisk.nvme : ""
      }

      // ---- Footer --------------------------------------------------------

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
    property string unit: "%"
    property int scaleMax: 100

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
        elide: Text.ElideRight
        anchors.left: parent.left
        anchors.right: rowValue.left
        anchors.rightMargin: Style.spacing.sm
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        id: rowValue
        text: meterRow.percent >= 0 ? meterRow.percent + meterRow.unit : "—"
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    Meter {
      width: parent.width
      value: meterRow.percent / meterRow.scaleMax
      fill: root.lvlColor(meterRow.level)
    }

    Text {
      visible: meterRow.caption !== ""
      width: parent.width
      text: meterRow.caption
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      elide: Text.ElideRight
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

    width: parent ? parent.width : 0
    implicitHeight: Math.max(infoLabel.implicitHeight, infoValue.implicitHeight)

    Text {
      id: infoLabel
      text: infoRow.label
      color: root.foreground
      opacity: 0.6
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      elide: Text.ElideRight
      anchors.left: parent.left
      anchors.right: infoValue.left
      anchors.rightMargin: Style.spacing.sm
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

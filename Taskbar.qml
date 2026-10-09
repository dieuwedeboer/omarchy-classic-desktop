import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.dieuwedeboer.classic-desktop"

  readonly property var service: bar && bar.shell ? bar.shell.serviceFor(moduleName) : null
  readonly property string scope: String(setting("scope", "all"))
  readonly property int buttonWidth: Number(setting("buttonWidth", 200))
  readonly property bool showSettings: setting("showSettings", true) === true
  readonly property color foreground: bar ? bar.barForeground : Color.foreground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property var monitor: QsWindow.window ? Hyprland.monitorFor(QsWindow.window.screen) : null

  property var menuToplevel: null
  property Item menuAnchor: root

  readonly property var windows: {
    var out = []
    var values = Hyprland.toplevels.values
    var shownWorkspace = monitor && monitor.activeWorkspace ? monitor.activeWorkspace.name : ""
    for (var i = 0; i < values.length; i++) {
      var name = values[i].workspace ? String(values[i].workspace.name) : ""
      if (name === "special:minimized") out.push(values[i])
      else if (name === "" || name.indexOf("special:") === 0) continue
      else if (scope === "all" || name === shownWorkspace) out.push(values[i])
    }
    return out
  }

  function tint(color, alpha) {
    return Qt.rgba(color.r, color.g, color.b, alpha)
  }

  function appId(toplevel) {
    return toplevel && toplevel.wayland ? String(toplevel.wayland.appId || "") : ""
  }

  function iconFor(toplevel) {
    var id = appId(toplevel)
    if (id === "") return Quickshell.iconPath("application-x-executable", true)
    var entry = DesktopEntries.heuristicLookup(id)
    return Quickshell.iconPath(entry && entry.icon ? entry.icon : id, "application-x-executable")
  }

  function titleFor(toplevel) {
    var title = toplevel ? String(toplevel.title || "") : ""
    if (title !== "") return title
    var entry = DesktopEntries.heuristicLookup(appId(toplevel))
    return entry ? entry.name : appId(toplevel)
  }

  function openMenu(toplevel, anchor) {
    Hyprland.refreshToplevels()
    settingsPopup.open = false
    menuToplevel = toplevel
    menuAnchor = anchor
    menuPopup.open = true
  }

  function runMenu(action) {
    var toplevel = menuToplevel
    menuPopup.open = false
    if (service && toplevel) service[action](toplevel)
  }

  implicitWidth: row.implicitWidth
  implicitHeight: barSize

  Row {
    id: row
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.spacing.xs

    Repeater {
      model: root.windows

      Item {
        id: task
        required property var modelData

        readonly property bool minimized: root.service ? root.service.isMinimized(modelData) : false
        readonly property bool active: root.service ? root.service.isActive(modelData) && !minimized : false

        width: root.vertical ? root.barSize : root.buttonWidth
        height: root.barSize - Style.spacing.sm * 2

        Rectangle {
          anchors.fill: parent
          radius: Style.cornerRadius
          color: task.active ? root.tint(Color.accent, 0.25) : hover.hovered ? root.tint(root.foreground, 0.1) : "transparent"
        }

        Rectangle {
          anchors.bottom: parent.bottom
          anchors.horizontalCenter: parent.horizontalCenter
          width: parent.width - Style.spacing.lg * 2
          height: Math.max(2, Style.space(2))
          color: Color.accent
          visible: task.active
        }

        Row {
          anchors.fill: parent
          anchors.leftMargin: Style.spacing.md
          anchors.rightMargin: Style.spacing.md
          spacing: Style.spacing.md
          opacity: task.minimized ? 0.5 : 1

          Image {
            id: icon
            anchors.verticalCenter: parent.verticalCenter
            width: Style.font.icon
            height: Style.font.icon
            sourceSize.width: width * 2
            sourceSize.height: height * 2
            source: root.iconFor(task.modelData)
            asynchronous: true
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - icon.width - parent.spacing
            visible: !root.vertical
            text: root.titleFor(task.modelData)
            textFormat: Text.PlainText
            elide: Text.ElideRight
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            font.italic: task.minimized
          }
        }

        HoverHandler {
          id: hover
          cursorShape: Qt.PointingHandCursor
        }

        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
          onClicked: function(mouse) {
            if (!root.service) return
            if (mouse.button === Qt.MiddleButton) root.service.close(task.modelData)
            else if (mouse.button === Qt.RightButton) root.openMenu(task.modelData, task)
            else root.service.activate(task.modelData)
          }
        }
      }
    }

    Item {
      id: settingsButton
      visible: root.showSettings
      width: root.barSize
      height: root.barSize - Style.spacing.sm * 2

      Rectangle {
        anchors.fill: parent
        radius: Style.cornerRadius
        color: settingsHover.hovered || settingsPopup.open ? root.tint(root.foreground, 0.1) : "transparent"
      }

      Text {
        anchors.centerIn: parent
        text: ""
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.icon
        opacity: 0.7
      }

      HoverHandler {
        id: settingsHover
        cursorShape: Qt.PointingHandCursor
      }

      MouseArea {
        anchors.fill: parent
        onClicked: {
          menuPopup.open = false
          if (root.service) root.service.refreshToggles()
          settingsPopup.open = !settingsPopup.open
        }
      }
    }
  }

  PopupCard {
    id: menuPopup
    anchorItem: root.menuAnchor
    bar: root.bar
    contentWidth: menuPopup.fittedContentWidth(Style.space(220))
    contentHeight: menuPopup.fittedContentHeight(menuColumn.implicitHeight)

    Column {
      id: menuColumn
      width: parent.width
      spacing: Style.spacing.xs

      readonly property var target: root.menuToplevel
      readonly property bool minimized: target && root.service ? root.service.isMinimized(target) : false
      readonly property bool maximized: target && root.service ? root.service.isMaximized(target) : false
      readonly property bool floating: target && root.service ? root.service.isFloating(target) : false

      Button {
        width: parent.width
        leftAlign: true
        text: menuColumn.minimized ? "Restore" : "Minimise"
        onClicked: root.runMenu(menuColumn.minimized ? "restore" : "minimize")
      }

      Button {
        width: parent.width
        leftAlign: true
        text: menuColumn.maximized ? "Restore size" : "Maximise"
        onClicked: root.runMenu("toggleMaximized")
      }

      Button {
        width: parent.width
        leftAlign: true
        text: menuColumn.floating ? "Tile" : "Float"
        onClicked: root.runMenu("toggleFloating")
      }

      PanelSeparator {
        width: parent.width
      }

      Button {
        width: parent.width
        leftAlign: true
        text: "Close"
        onClicked: root.runMenu("close")
      }
    }
  }

  PopupCard {
    id: settingsPopup
    anchorItem: settingsButton
    bar: root.bar
    contentWidth: settingsPopup.fittedContentWidth(Style.space(320))
    contentHeight: settingsPopup.fittedContentHeight(settingsColumn.implicitHeight)

    Column {
      id: settingsColumn
      width: parent.width
      spacing: Style.spacing.rowGap

      readonly property var toggles: root.service ? root.service.toggles : ({})

      PanelSectionHeader {
        text: "Classic Desktop"
      }

      Toggle {
        width: parent.width
        label: "Floating windows"
        description: "New windows open floating instead of tiled"
        checked: settingsColumn.toggles["floating"] === true
        onClicked: if (root.service) root.service.setToggle("floating", !checked)
      }

      Toggle {
        width: parent.width
        label: "Resize from edges"
        description: "Drag any window edge to resize it"
        checked: settingsColumn.toggles["edge-resize"] === true
        onClicked: if (root.service) root.service.setToggle("edge-resize", !checked)
      }
    }
  }
}

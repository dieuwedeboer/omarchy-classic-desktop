import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Item {
  id: root

  readonly property string minimizedWorkspace: "special:minimized"
  readonly property string cli: decodeURIComponent(Qt.resolvedUrl("bin/classic-desktop").toString().replace(/^file:\/\//, ""))

  property var toggles: ({ "floating": false, "edge-resize": false })
  property var restoreTo: ({})

  function hexAddress(address) {
    var value = String(address || "")
    return value.indexOf("0x") === 0 ? value : "0x" + value
  }

  function selector(toplevel) {
    return "address:" + hexAddress(toplevel.address)
  }

  function dispatch(expression) {
    Quickshell.execDetached(["hyprctl", "dispatch", expression])
  }

  function workspaceName(toplevel) {
    return toplevel && toplevel.workspace ? String(toplevel.workspace.name) : ""
  }

  function isActive(toplevel) {
    return !!(toplevel && toplevel.wayland && toplevel.wayland.activated)
  }

  function isMinimized(toplevel) {
    return workspaceName(toplevel) === minimizedWorkspace
  }

  function isFloating(toplevel) {
    var ipc = toplevel ? toplevel.lastIpcObject : null
    return !!(ipc && ipc.floating)
  }

  function isMaximized(toplevel) {
    var ipc = toplevel ? toplevel.lastIpcObject : null
    return !!(ipc && ipc.fullscreen === 1)
  }

  function toplevelFor(address) {
    var wanted = hexAddress(address)
    var values = Hyprland.toplevels.values
    for (var i = 0; i < values.length; i++) {
      if (hexAddress(values[i].address) === wanted) return values[i]
    }
    return null
  }

  function focus(toplevel) {
    dispatch("hl.dsp.focus({ window = \"" + selector(toplevel) + "\" })")
  }

  function minimize(toplevel) {
    if (!toplevel || isMinimized(toplevel)) return
    var from = workspaceName(toplevel)
    var wasActive = isActive(toplevel)
    var memory = Object.assign({}, restoreTo)
    memory[hexAddress(toplevel.address)] = from
    restoreTo = memory
    dispatch("hl.dsp.window.move({ workspace = \"" + minimizedWorkspace + "\", follow = false, window = \"" + selector(toplevel) + "\" })")
    if (wasActive) dispatch("hl.dsp.focus({ workspace = \"" + from + "\" })")
  }

  function restore(toplevel) {
    if (!toplevel) return
    var key = hexAddress(toplevel.address)
    var target = restoreTo[key]
    if (!target || target.indexOf("special:") === 0) {
      target = Hyprland.focusedWorkspace ? String(Hyprland.focusedWorkspace.name) : "1"
    }
    var memory = Object.assign({}, restoreTo)
    delete memory[key]
    restoreTo = memory
    dispatch("hl.dsp.window.move({ workspace = \"" + target + "\", follow = false, window = \"" + selector(toplevel) + "\" })")
    focus(toplevel)
  }

  function activate(toplevel) {
    if (!toplevel) return
    if (isMinimized(toplevel)) restore(toplevel)
    else if (isActive(toplevel)) minimize(toplevel)
    else focus(toplevel)
  }

  function toggleMaximized(toplevel) {
    if (!toplevel) return
    if (isMinimized(toplevel)) restore(toplevel)
    dispatch("hl.dsp.window.fullscreen({ mode = \"maximized\", window = \"" + selector(toplevel) + "\" })")
    Hyprland.refreshToplevels()
  }

  function toggleFloating(toplevel) {
    if (!toplevel) return
    dispatch("hl.dsp.window.float({ action = \"toggle\", window = \"" + selector(toplevel) + "\" })")
    Hyprland.refreshToplevels()
  }

  function close(toplevel) {
    if (!toplevel) return
    dispatch("hl.dsp.window.close({ window = \"" + selector(toplevel) + "\" })")
  }

  function refreshToggles() {
    if (!statusProcess.running) statusProcess.running = true
  }

  function setToggle(name, on) {
    if (toggleProcess.running) return
    toggleProcess.command = [cli, "toggle", name, on ? "on" : "off"]
    toggleProcess.running = true
  }

  Component.onCompleted: refreshToggles()

  Connections {
    target: Hyprland

    function onRawEvent(event) {
      if (event.name === "minimized") {
        var parts = String(event.data).split(",")
        if (parts[1] === "1") root.minimize(root.toplevelFor(parts[0]))
      } else if (event.name === "configreloaded") {
        root.refreshToggles()
      }
    }
  }

  Process {
    id: statusProcess
    command: [root.cli, "status"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          root.toggles = JSON.parse(text)
        } catch (e) {
          console.warn("classic-desktop status:", e)
        }
      }
    }
  }

  Process {
    id: toggleProcess
    onExited: root.refreshToggles()
  }
}

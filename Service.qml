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
  property bool noWarps: false
  property int warpOnChangeWorkspace: 1

  function hexAddress(address) {
    var value = String(address || "")
    return value.indexOf("0x") === 0 ? value : "0x" + value
  }

  function selector(toplevel) {
    return "address:" + hexAddress(toplevel.address)
  }

  function dispatch(expressions) {
    var commands = ["eval hl.config({ cursor = { no_warps = true, warp_on_change_workspace = 0 } })"]
    commands = commands.concat([].concat(expressions).map(function(e) { return "dispatch " + e }))
    commands.push("eval hl.config({ cursor = { no_warps = " + noWarps + ", warp_on_change_workspace = " + warpOnChangeWorkspace + " } })")
    Quickshell.execDetached(["hyprctl", "--batch", commands.join(" ; ")])
  }

  function moveTo(workspace, toplevel) {
    return "hl.dsp.window.move({ workspace = \"" + workspace + "\", follow = false, window = \"" + selector(toplevel) + "\" })"
  }

  function focusWorkspace(workspace) {
    return "hl.dsp.focus({ workspace = \"" + workspace + "\" })"
  }

  function focusWindow(toplevel) {
    return "hl.dsp.focus({ window = \"" + selector(toplevel) + "\" })"
  }

  function workspaceName(toplevel) {
    return toplevel && toplevel.workspace ? String(toplevel.workspace.name) : ""
  }

  function isActive(toplevel) {
    if (!toplevel || !toplevel.wayland || !toplevel.wayland.activated) return false
    return !!Hyprland.focusedWorkspace && workspaceName(toplevel) === String(Hyprland.focusedWorkspace.name)
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

  function raise(toplevel) {
    var workspace = workspaceName(toplevel)
    dispatch(workspace === "" ? [focusWindow(toplevel)] : [focusWorkspace(workspace), focusWindow(toplevel)])
  }

  function minimize(toplevel) {
    if (!toplevel || isMinimized(toplevel)) return
    var from = workspaceName(toplevel)
    var wasActive = isActive(toplevel)
    var memory = Object.assign({}, restoreTo)
    memory[hexAddress(toplevel.address)] = from
    restoreTo = memory
    dispatch(wasActive ? [moveTo(minimizedWorkspace, toplevel), focusWorkspace(from)] : [moveTo(minimizedWorkspace, toplevel)])
  }

  function restoreSteps(toplevel) {
    var key = hexAddress(toplevel.address)
    var target = restoreTo[key]
    if (!target || target.indexOf("special:") === 0) {
      target = Hyprland.focusedWorkspace ? String(Hyprland.focusedWorkspace.name) : "1"
    }
    var memory = Object.assign({}, restoreTo)
    delete memory[key]
    restoreTo = memory
    return [moveTo(target, toplevel), focusWorkspace(target), focusWindow(toplevel)]
  }

  function restore(toplevel) {
    if (!toplevel) return
    dispatch(restoreSteps(toplevel))
  }

  function activate(toplevel) {
    if (!toplevel) return
    if (isMinimized(toplevel)) restore(toplevel)
    else if (isActive(toplevel)) minimize(toplevel)
    else raise(toplevel)
  }

  function toggleMaximized(toplevel) {
    if (!toplevel) return
    var maximize = "hl.dsp.window.fullscreen({ mode = \"maximized\", window = \"" + selector(toplevel) + "\" })"
    dispatch(isMinimized(toplevel) ? restoreSteps(toplevel).concat([maximize]) : [maximize])
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

  function refreshCursorOptions() {
    if (!cursorProcess.running) cursorProcess.running = true
  }

  function setToggle(name, on) {
    if (toggleProcess.running) return
    toggleProcess.command = [cli, "toggle", name, on ? "on" : "off"]
    toggleProcess.running = true
  }

  Component.onCompleted: {
    refreshToggles()
    refreshCursorOptions()
  }

  Connections {
    target: Hyprland

    function onRawEvent(event) {
      if (event.name === "minimized") {
        var parts = String(event.data).split(",")
        if (parts[1] === "1") root.minimize(root.toplevelFor(parts[0]))
      } else if (event.name === "configreloaded") {
        root.refreshToggles()
        root.refreshCursorOptions()
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
    id: cursorProcess
    command: ["bash", "-c", "hyprctl -j getoption cursor:no_warps; hyprctl -j getoption cursor:warp_on_change_workspace"]
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = text.trim().split("\n")
        try {
          root.noWarps = JSON.parse(lines[0]).bool === true
          root.warpOnChangeWorkspace = Number(JSON.parse(lines[1]).int)
        } catch (e) {
          console.warn("classic-desktop cursor options:", e)
        }
      }
    }
  }

  Process {
    id: toggleProcess
    onExited: root.refreshToggles()
  }
}

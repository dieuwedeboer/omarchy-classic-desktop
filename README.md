# Classic Desktop

An Omarchy shell plugin for people coming from Windows or Plasma: a taskbar,
floating windows, minimise, and resizing from window edges. Every part is a
toggle, and it needs no packages beyond Omarchy itself.

Built against Omarchy 4.0.4 and Hyprland 0.56.2 (Lua config).

## Install

```sh
omarchy plugin add https://github.com/dieuwedeboer/omarchy-classic-desktop.git --enable --yes
omarchy bar position bottom
```

`--enable` puts the taskbar on the left of the bar. Moving the bar to the
bottom is optional.

## Taskbar

One button per window, with its icon and title.

| Action | Effect |
|---|---|
| Left-click | Focus the window. Click the focused window to minimise it; click a minimised one to restore it. |
| Middle-click | Close the window. |
| Right-click | Minimise or restore, maximise, float or tile, close. |

Minimised windows stay on the taskbar, dimmed. They live on the special
workspace `special:minimized` and go back to the workspace they came from.

The minimise buttons that apps such as Firefox, Chromium and GTK apps draw in
their own title bars work too: Hyprland reports the request as a `minimized`
event and leaves it unhandled, and the plugin handles it.

Widget settings, set with `omarchy bar set io.github.dieuwedeboer.classic-desktop <key> <value>`:

| Key | Values | Default |
|---|---|---|
| `scope` | `all`, `workspace` | `all` |
| `buttonWidth` | 40 to 400 | `200` |
| `showSettings` | `true`, `false` | `true` |

## Toggles

The gear at the end of the taskbar opens the toggles. The same toggles work
from a terminal:

```sh
~/.config/omarchy/plugins/io.github.dieuwedeboer.classic-desktop/bin/classic-desktop status
~/.config/omarchy/plugins/io.github.dieuwedeboer.classic-desktop/bin/classic-desktop toggle floating on
```

| Toggle | Effect |
|---|---|
| `floating` | New windows open floating. Turning it on also floats the windows already open; turning it off leaves them as they are. |
| `edge-resize` | Drag any window edge to resize it, no modifier key. |

A toggle is a Lua file in `~/.local/state/omarchy/toggles/hypr/`, named
`classic-desktop-<toggle>.lua`. Omarchy loads every file there on each Hyprland
reload, the same way `omarchy-hyprland-toggle` works. Nothing is written to
`~/.config/hypr`.

## Title bars: not included

Hyprland draws no title bars. The plugin does not add any, on purpose.

- `hyprbars` would add them, but it is built per user with `hyprpm`, needs
  build packages installed with sudo, and must be rebuilt after every Hyprland
  update.
- A title bar drawn by the shell would sit on a layer above or below every
  window, so it cannot stack correctly between overlapping windows.

Browsers and GTK/libadwaita apps draw their own title bars with minimise,
maximise and close. Qt/KDE apps, LibreOffice and terminals do not; move those
with Super+drag and manage them from the taskbar's right-click menu.

## Known gaps

- Maximise buttons inside apps' own title bars are not yet confirmed to work.
  Omarchy suppresses maximise requests from apps, and a request sent through
  the Wayland toplevel protocol did nothing in testing. Maximise from the
  taskbar menu works.
- Windows without a title bar can only be moved with Super+drag.

## Uninstall

```sh
classic-desktop toggle floating off
classic-desktop toggle edge-resize off
omarchy plugin remove io.github.dieuwedeboer.classic-desktop
```

## License

MIT. See [LICENSE](LICENSE).

# Classic Desktop

An Omarchy shell plugin for people coming from Windows or Plasma: a taskbar,
floating windows, minimise, resizing from window edges, and title bars. Every
part is a toggle. Everything except title bars needs nothing beyond Omarchy
itself; title bars need the hyprbars Hyprland plugin.

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
| `titlebars` | Title bars with minimise, maximise and close for apps that do not draw their own. Needs hyprbars. |

A toggle is a Lua file in `~/.local/state/omarchy/toggles/hypr/`, named
`classic-desktop-<toggle>.lua`. Omarchy loads every file there on each Hyprland
reload, the same way `omarchy-hyprland-toggle` works. Nothing is written to
`~/.config/hypr`.

## Title bars

Hyprland draws no title bars, and a bar drawn by the shell would sit on a layer
above or below every window, so it could not stack between overlapping ones.
The `titlebars` toggle uses [hyprbars](https://github.com/hyprwm/hyprland-plugins/tree/main/hyprbars)
instead, which draws them inside the compositor.

Browsers and GTK/libadwaita apps draw their own title bars, so they get none
from hyprbars. Qt/KDE apps, LibreOffice and terminals do get one: drag it to
move the window, double-click it to maximise, and use its minimise, maximise and
close buttons. The bars take their colours from the current Omarchy theme.

The apps left alone are Firefox, Chromium, Google Chrome and `org.gnome.*`. Add
more window classes, one regular expression per line, to
`~/.config/omarchy/classic-desktop/own-titlebars`, then run `hyprctl reload`.

The plugin loads hyprbars itself at the start of each session, from
`/usr/lib/hyprland-plugins/hyprbars.so` when that exists, otherwise through
`hyprpm reload`. Either way hyprbars has to be built against the exact
Hyprland that is running, and rebuilt after every Hyprland update; until then
Hyprland refuses to load it and the windows simply have no title bars.

Earlier versions left title bars out to avoid that dependency. They came back
as an optional toggle because the apps that lack their own bars could
otherwise only be moved with Super+drag.

## Known gaps

- Maximise buttons inside apps' own title bars are not yet confirmed to work.
  Omarchy suppresses maximise requests from apps, and a request sent through
  the Wayland toplevel protocol did nothing in testing. Maximise from the
  taskbar menu works.
- Without the `titlebars` toggle, apps that draw no title bar of their own can
  only be moved with Super+drag.

## Uninstall

```sh
classic-desktop toggle floating off
classic-desktop toggle edge-resize off
classic-desktop toggle titlebars off
omarchy plugin remove io.github.dieuwedeboer.classic-desktop
```

## License

MIT. See [LICENSE](LICENSE).

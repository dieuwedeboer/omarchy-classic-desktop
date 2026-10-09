if not (hl.plugin and hl.plugin.hyprbars) then
  return
end

local home = os.getenv("HOME") or ""
local state = os.getenv("XDG_STATE_HOME") or (home .. "/.local/state")
local config = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")

local function theme_colors()
  local colors = { background = "#151E26", foreground = "#ECE5D8", accent = "#F3B77B" }
  local file = io.open(state .. "/omarchy/current/theme/colors.toml", "r")
  if file == nil then
    return colors
  end
  for line in file:lines() do
    local key, value = line:match('^%s*([%w_]+)%s*=%s*"(#%x%x%x%x%x%x)"')
    if key and colors[key] then
      colors[key] = value
    end
  end
  file:close()
  return colors
end

local function rgb(hex, alpha)
  return "rgba(" .. hex:sub(2) .. (alpha or "ff") .. ")"
end

local own_titlebars = {
  "firefox",
  "chromium",
  "google-chrome",
  "org\\.gnome\\..*",
}

local extra = io.open(config .. "/omarchy/classic-desktop/own-titlebars", "r")
if extra ~= nil then
  for line in extra:lines() do
    local class = line:match("^%s*([^#%s]+)")
    if class then
      table.insert(own_titlebars, class)
    end
  end
  extra:close()
end

local colors = theme_colors()
local dispatch = "hyprctl dispatch "

hl.config({
  plugin = {
    hyprbars = {
      enabled = true,
      bar_height = 28,
      bar_color = rgb(colors.background),
      ["col.text"] = rgb(colors.foreground),
      bar_text_size = 11,
      bar_text_align = "left",
      bar_padding = 10,
      bar_button_padding = 8,
      bar_part_of_window = true,
      bar_precedence_over_border = true,
      inactive_button_color = rgb(colors.foreground, "40"),
      on_double_click = dispatch .. [['hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })']],
    },
  },
})

hl.plugin.hyprbars.add_button({
  bg_color = rgb(colors.accent),
  fg_color = rgb(colors.background),
  size = 14,
  icon = "×",
  action = dispatch .. [['hl.dsp.window.close()']],
})

hl.plugin.hyprbars.add_button({
  bg_color = rgb(colors.foreground, "c0"),
  fg_color = rgb(colors.background),
  size = 14,
  icon = "□",
  action = dispatch .. [['hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })']],
})

hl.plugin.hyprbars.add_button({
  bg_color = rgb(colors.foreground, "c0"),
  fg_color = rgb(colors.background),
  size = 14,
  icon = "–",
  action = dispatch .. [['hl.dsp.window.move({ workspace = "special:minimized", follow = false })']],
})

o.window({ class = "^(" .. table.concat(own_titlebars, "|") .. ")$" }, { ["hyprbars:no_bar"] = true })

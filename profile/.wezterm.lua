local wezterm = require("wezterm")

local function color(r, g, b, a)
  return string.format("rgba(%d,%d,%d,%.2f)", r, g, b, a)
end

local config = {}

-------------------------------------------------
-- Appearance
-------------------------------------------------
config.window_background_opacity = 0.12
config.kde_window_background_blur = true
config.window_decorations = "NONE"

-- Default window size
config.initial_cols = 128
config.initial_rows = 36

-- Font
config.font = wezterm.font("FiraCode Nerd Font")
config.font_size = 12.0
config.freetype_load_target = "Light"
config.freetype_render_target = "Light"
config.harfbuzz_features = { "liga=1", "clig=1", "calt=1" }

-------------------------------------------------
-- Mouse / Clipboard
-------------------------------------------------
config.enable_wayland = true
config.mouse_bindings = {
  {
    event = { Up = { streak = 1, button = "Left" } },
    mods = "NONE",
    action = wezterm.action.CopyTo("ClipboardAndPrimarySelection")
  },
  {
    event = { Down = { streak = 1, button = "Right" } },
    mods = "NONE",
    action = wezterm.action.PasteFrom("Clipboard")
  },
}

-------------------------------------------------
-- GPU Acceleration
-------------------------------------------------
config.front_end = "WebGpu"

-------------------------------------------------
-- Tabs (transparent)
-------------------------------------------------
config.enable_tab_bar = true
config.use_fancy_tab_bar = false -- <-- important for full transparency
config.hide_tab_bar_if_only_one_tab = true

config.colors = {
  tab_bar = {
    background = color(0, 0, 0, 0),

    active_tab = {
      bg_color = color(0, 0, 0, 0),
      fg_color = "#ffffff",
      intensity = "Bold",
    },

    inactive_tab = {
      bg_color = color(0, 0, 0, 0),
      fg_color = "#aaaaaa",
      intensity = "Normal",
    },

    inactive_tab_hover = {
      bg_color = color(0, 0, 0, 0),
      fg_color = "#ffffff",
      intensity = "Bold",
    },

    new_tab = {
      bg_color = color(0, 0, 0, 0),
      fg_color = "#aaaaaa",
    },

    new_tab_hover = {
      bg_color = color(0, 0, 0, 0),
      fg_color = "#ffffff",
    },
  },
}

-- Status line replaces title bar
wezterm.on("update-status", function(window, pane)
  local title = window:active_pane():title()
  window:set_right_status(wezterm.format({ { Text = " " .. title .. " " } }))
end)

-------------------------------------------------
-- Scrollback
-------------------------------------------------
config.scrollback_lines = 10000
config.enable_scroll_bar = true

-------------------------------------------------
-- Cursor
-------------------------------------------------
config.hide_mouse_cursor_when_typing = false

-- ==============================
-- Key Bindings
-- ==============================

-- Helper variables for resizing steps
local step_width = 2
local step_height = 2

-- State tracking for maximized windows
local maximized_state = {}

-- Event for toggling maximize/restore
wezterm.on("toggle-maximize", function(window, pane)
  local id = tostring(window:window_id())
  if maximized_state[id] then
    window:restore()
    maximized_state[id] = nil
  else
    window:maximize()
    maximized_state[id] = true
  end
end)

-- Event for increasing width
wezterm.on("increase-width", function(window, pane)
  local dim = window:get_dimensions()
  window:set_inner_size(dim.pixel_width + step_width, dim.pixel_height)
end)

-- Event for decreasing width
wezterm.on("decrease-width", function(window, pane)
  local dim = window:get_dimensions()
  window:set_inner_size(math.max(100, dim.pixel_width - step_width), dim.pixel_height)
end)

-- Event for increasing height
wezterm.on("increase-height", function(window, pane)
  local dim = window:get_dimensions()
  window:set_inner_size(dim.pixel_width, dim.pixel_height + step_height)
end)

-- Event for decreasing height
wezterm.on("decrease-height", function(window, pane)
  local dim = window:get_dimensions()
  window:set_inner_size(dim.pixel_width, math.max(100, dim.pixel_height - step_height))
end)

-- Key bindings
config.keys = {

  -- Toggle fullscreen
  {
    key = "F11",
    mods = "SHIFT",
    action = wezterm.action.ToggleFullScreen,
  },

  -- Maximize / Restore window
  {
    key = "M",
    mods = "CTRL|SHIFT",
    action = wezterm.action.EmitEvent("toggle-maximize")
  },

  -- Increase/decrease window width (columns)
  {
    key = "RightArrow",
    mods = "CTRL|SHIFT",
    action = wezterm.action.EmitEvent("increase-width")
  },

  {
    key = "LeftArrow",
    mods = "CTRL|SHIFT",
    action = wezterm.action.EmitEvent("decrease-width")
  },

  -- Increase/decrease window height (rows)
  {
    key = "UpArrow",
    mods = "CTRL|SHIFT",
    action = wezterm.action.EmitEvent("decrease-height")
  },

  {
    key = "DownArrow",
    mods = "CTRL|SHIFT",
    action = wezterm.action.EmitEvent("increase-height")
  },


  -- Split panes (optional, handy for tiling)
  {
    key = "D",
    mods = "CTRL|SHIFT",
    action = wezterm.action.SplitHorizontal { domain = "CurrentPaneDomain" },
  },

  {
    key = "S",
    mods = "CTRL|SHIFT",
    action = wezterm.action.SplitVertical { domain = "CurrentPaneDomain" },
  },

  -- Close current pane
  {
    key = "W",
    mods = "CTRL|SHIFT",
    action = wezterm.action.CloseCurrentPane { confirm = true },
  },

  -- Move between panes
  {
    key = "H",
    mods = "CTRL|SHIFT",
    action = wezterm.action.ActivatePaneDirection "Left",
  },

  {
    key = "K",
    mods = "CTRL|SHIFT",
    action = wezterm.action.ActivatePaneDirection "Right",
  },

  {
    key = "U",
    mods = "CTRL|SHIFT",
    action = wezterm.action.ActivatePaneDirection "Up",
  },

  {
    key = "J",
    mods = "CTRL|SHIFT",
    action = wezterm.action.ActivatePaneDirection "Down",
  },
}

-- Return the configuration to wezterm
return config

local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.automatically_reload_config = true
config.font_size = 14.0
config.use_ime = true
config.window_background_opacity = 0.87
config.macos_window_background_blur = 20
config.skip_close_confirmation_for_processes_named = {}

-- macOS
config.font = wezterm.font_with_fallback({
  "JetBrains Mono",
  "Hiragino Sans",
  "Menlo",
})

----------------------------------------------------
-- Tab
----------------------------------------------------
config.window_decorations = "RESIZE"
config.show_tabs_in_tab_bar = true

config.window_frame = {
  active_titlebar_bg = "none",
  inactive_titlebar_bg = "none",
  border_left_width = "0.5cell",
  border_right_width = "0.5cell",
  border_bottom_height = "0.25cell",
  border_top_height = "0.25cell",
  border_left_color = "#3a0304",
  border_right_color = "#233B6C",
  border_bottom_color = "#233B6C",
  border_top_color = "#3a0304",
}

config.window_background_gradient = {
  colors = { "#2a033a", "#000000" },
  orientation = "Horizontal",
}

config.show_new_tab_button_in_tab_bar = false

config.colors = {
  cursor_bg = "#ffffff",
  cursor_fg = "#000000",
  cursor_border = "#ffffff",
  tab_bar = {
    inactive_tab_edge = "none",
    inactive_tab = {
      bg_color = "#000000",
      fg_color = "#a0a0a0",
    },
    active_tab = {
      bg_color = "#ffffff",
      fg_color = "#000000",
    },
    new_tab = {
      bg_color = "#000000",
      fg_color = "#a0a0a0",
    },
  },
}

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
    local background = "#000000"
    local foreground = "#a0a0a0"
    if tab.is_active then
      background = "#ffffff"
      foreground = "#000000"
    end

    -- カレントディレクトリを取得 (OSC 7 が設定されている場合)
    local cwd = ""
    local cwd_uri = tab.active_pane:get_current_working_dir()
    if cwd_uri then
      local path = cwd_uri.file_path or ""
      local home = os.getenv("HOME") or ""
      if path:sub(1, #home) == home then
        path = "~" .. path:sub(#home + 1)
      end
      cwd = path:gsub("/$", ""):match("([^/]+)$") or path
    end

    -- フォアグラウンドプロセス名を取得
    local proc_path = tab.active_pane:get_foreground_process_name() or ""
    local proc = proc_path:match("([^/]+)$") or ""
    local is_shell = ({ zsh = true, bash = true, fish = true, sh = true })[proc]

    -- シェル以外が動いていればプロセス名を先頭に
    local display
    if proc ~= "" and not is_shell then
      display = proc .. (cwd ~= "" and "  " .. cwd or "")
    elseif cwd ~= "" then
      display = cwd
    else
      display = tab.active_pane.title
    end

    local index = tostring(tab.tab_index + 1)
    local title = "  " .. index .. "  " .. wezterm.truncate_right(display, max_width - 6) .. "  "
    return {
      { Background = { Color = background } },
      { Foreground = { Color = foreground } },
      { Text = title },
    }
  end)

local function micro_cmd(key)
  return wezterm.action_callback(function(window, pane)
    local proc = pane:get_foreground_process_name() or ""

    if proc:find("micro") then
      -- micro → Ctrlに変換
      window:perform_action(
        wezterm.action.SendKey { key = key, mods = "CTRL" },
        pane
      )
    else
      -- それ以外 → Cmdをそのまま通す
      window:perform_action(
        wezterm.action.SendKey { key = key, mods = "CMD" },
        pane
      )
    end
  end)
end

----------------------------------------------------
-- keybinds
----------------------------------------------------
config.keys = {
  -- Command + { or }
  {
    key = "[",
    mods = "CMD",
    action = wezterm.action.ActivateTabRelative(-1),
  },
  {
    key = "]",
    mods = "CMD",
    action = wezterm.action.ActivateTabRelative(1),
  },
  -- Command+X
  {
    key = "x",
    mods = "CMD",
    action = wezterm.action.ActivateCopyMode,
  },
  -- Command+Enter
  {
    key = "Enter",
    mods = "SHIFT",
    action = wezterm.action.SendString("\n"),
  },
  -- Option+Arrow
  {
    key = "LeftArrow",
    mods = "OPT",
    action = wezterm.action.SendKey { key = "a", mods = "CTRL" },
  },
  {
    key = "RightArrow",
    mods = "OPT",
    action = wezterm.action.SendKey { key = "e", mods = "CTRL" },
  },

  --this rule for micro
  -- micro専用 Cmd→Ctrl
{ key="q", mods="CMD", action=micro_cmd("q") },
{ key="s", mods="CMD", action=micro_cmd("s") },
{ key="z", mods="CMD", action=micro_cmd("z") },
-- { key="v", mods="CMD", action=micro_cmd("v") },
-- { key="c", mods="CMD", action=micro_cmd("c") },
{ key="a", mods="CMD", action=micro_cmd("a") },
{ key="f", mods="CMD", action=micro_cmd("f") },
}

return config
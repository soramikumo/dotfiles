local wezterm = require 'wezterm'

local config = wezterm.config_builder()

local pane_proc_cache = {}
local pane_proc_cache_ttl = 5

local function get_cached_foreground_process_name(pane_id)
  local now = os.time()
  local cached = pane_proc_cache[pane_id]
  if cached and now - cached.at < pane_proc_cache_ttl then
    return cached.name
  end

  local proc = ""
  local ok, pane_obj = pcall(wezterm.mux.get_pane, pane_id)
  if ok and pane_obj then
    local full = pane_obj:get_foreground_process_name() or ""
    proc = full:match("([^/\\]+)$") or full
  end

  pane_proc_cache[pane_id] = {
    name = proc,
    at = now,
  }

  return proc
end

wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
  local background = "#000000"
  local foreground = "#a0a0a0"

  if tab.is_active then
    background = "#ffffff"
    foreground = "#000000"
  end

  local proc = get_cached_foreground_process_name(tab.active_pane.pane_id)
  local pane_title = tab.active_pane.title or ""
  local label

  wezterm.log_info("DEBUG tab=" .. tostring(tab.tab_index) .. " proc=" .. proc .. " title=" .. pane_title)

  if proc:lower():find("claude") or pane_title:lower():find("claude") then
    label = pane_title ~= "" and pane_title or "claude"
  else
    local cwd = tab.active_pane.current_working_dir
    if cwd then
      label = cwd.file_path:match("([^/\\]+)[/\\]*$") or cwd.file_path
    else
      label = pane_title
    end
  end

  local title = "   " .. wezterm.truncate_right(label, max_width - 1) .. "   "

  return {
    { Background = { Color = background } },
    { Foreground = { Color = foreground } },
    { Text = title },
  }
end)

config.default_prog = { 'C:\\Program Files\\Git\\bin\\bash.exe', '--login', '-i' }

config.front_end = "WebGpu"
-- config.win32_system_backdrop = "Acrylic"
-- config.window_background_opacity = 0.83

config.window_background_gradient = {
  colors = { "#2a033a", "#000000" },
  orientation = "Horizontal",
}

config.window_frame = {
  inactive_titlebar_bg = "none",
  active_titlebar_bg = "none",
  border_left_width = "0.5cell",
  border_right_width = "0.5cell",
  border_bottom_height = "0.25cell",
  border_top_height = "0.25cell",
  border_left_color = "#3a0304",
  border_right_color = "#233B6C",
  border_bottom_color = "#233B6C",
  border_top_color = "#3a0304",
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

config.keys = {
  { key = "t", mods = "CTRL", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
  { key = "w", mods = "CTRL", action = wezterm.action.CloseCurrentTab({ confirm = false }) },
  { key = "Enter", mods = "SHIFT", action = wezterm.action.SendString("\n") },
  { key = "x", mods = "CTRL", action = wezterm.action.ActivateCopyMode },
  { key = "f", mods = "CTRL", action = wezterm.action.Search({ CaseInSensitiveString = "" }) },
  { key = "LeftBracket", mods = "CTRL", action = wezterm.action.ActivateTabRelative(-1) },
  { key = "RightBracket", mods = "CTRL", action = wezterm.action.ActivateTabRelative(1) },
  { key = "c", mods = "CTRL", action = wezterm.action.CopyTo("Clipboard") },
  { key = "v", mods = "CTRL", action = wezterm.action.PasteFrom("Clipboard") },
  { key = "c", mods = "CTRL|SHIFT", action = wezterm.action.SendString("\x03") },
  { key = "Backspace", mods = "CTRL", action = wezterm.action.SendString("\x1b\x7f") },
  { key = "w", mods = "CTRL", action = wezterm.action.CloseCurrentTab({ confirm = true }) },
  { key = "b", mods = "CTRL|SHIFT", action = wezterm.action.SpawnCommandInNewTab { args = { "C:\\Program Files\\Git\\bin\\bash.exe", "--login", "-i", } } },
  { key = "p", mods = "CTRL", action = wezterm.action.SpawnCommandInNewTab { args = { "pwsh.exe" } } },
  {
    key = "t",
    mods = "CTRL|SHIFT",
    action = wezterm.action_callback(function(window, pane)
      local cwd_uri = pane:get_current_working_dir()
      local cwd = cwd_uri and cwd_uri.file_path or nil
      if cwd and cwd:match("^/[a-zA-Z]:") then
        cwd = cwd:sub(2)
      end
      window:perform_action(
        wezterm.action.SpawnCommandInNewWindow { cwd = cwd },
        pane
      )
    end),
  },
}

return config

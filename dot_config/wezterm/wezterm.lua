-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- Include homebrew to PATH
if wezterm.target_triple == "aarch64-apple-darwin" then
  config.set_environment_variables = {
    PATH = '/opt/homebrew/bin:' .. os.getenv('PATH')
  }
end

-- This is where you actually apply your config choices

config.color_scheme = 'Modus-Vivendi'

config.font = wezterm.font 'FantasqueSansM Nerd Font Mono'

config.font_size = 13.0
if wezterm.target_triple == "aarch64-apple-darwin" then
  config.font_size = 17.0
end

config.window_decorations = "RESIZE"

xonsh = { 'xonsh', '--login' }
config.default_prog = xonsh

config.launch_menu = {
  {
    label = 'xonsh',
    args = xonsh,
  },
}

if wezterm.target_triple == 'x86_64-pc-windows-msvc' then
  table.insert(config.launch_menu, {
    label = 'PowerShell',
    args = { 'pwsh.exe' },
  })

  table.insert(config.launch_menu, {
    label = 'Command Prompt',
    args = { 'cmd.exe' },
  })

  table.insert(config.launch_menu, {
    label = 'Git Bash',
    args = { 'C:\\Program Files\\Git\\bin\\bash.exe', '--login' },
  })

  vs_template = '&{' ..
    'Import-Module "%s\\Common7\\Tools\\Microsoft.VisualStudio.DevShell.dll"; ' ..
    'Enter-VsDevShell -VsInstallPath "%s" -SkipAutomaticLocation -DevCmdArguments "-arch=x64 -host_arch=x64"' ..
    '}'
  vs2022_path = "C:\\Program Files\\Microsoft Visual Studio\\2022\\Community"
  vs2019_path = "C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools"

  table.insert(config.launch_menu, {
    label = 'Developer PWSH for VS 2022',
    args = {
      'pwsh.exe',
      '-NoExit',
      '-Command',
      string.format(vs_template, vs2022_path, vs2022_path),
    },
  })

  table.insert(config.launch_menu, {
    label = 'Developer PWSH for VS 2019',
    args = {
      'pwsh.exe',
      '-NoExit',
      '-Command',
      string.format(vs_template, vs2019_path, vs2019_path),
    },
  })
else
  table.insert(config.launch_menu, {
    label = 'zsh',
    args = { 'zsh', '--login' }
  })
end

-- Key bindings
config.leader = { key = 'Space', mods = 'CTRL', timeout_milliseconds = 1000, }
config.keys = {
  {
    key = 'Space',
    mods = 'LEADER|CTRL',
    action = wezterm.action.ActivateLastTab,
  },
  {
    key = 'Space',
    mods = 'LEADER',
    action = wezterm.action.SendKey { key = 'Space', mods = 'CTRL' },
  },
  {
    key = 'c',
    mods = 'LEADER',
    action = wezterm.action.SpawnTab 'DefaultDomain',
  },
  {
    key = 'C',
    mods = 'LEADER|SHIFT',
    action = wezterm.action.SpawnTab 'CurrentPaneDomain',
  },
  {
    key = '|',
    mods = 'LEADER|SHIFT',
    action = wezterm.action.SplitHorizontal {
      domain = 'CurrentPaneDomain',
    },
  },
  {
    key = '-',
    mods = 'LEADER',
    action = wezterm.action.SplitVertical {
      domain = 'CurrentPaneDomain',
    },
  },
  {
    key = 'n',
    mods = 'LEADER',
    action = wezterm.action.ActivateTabRelative(1),
  },
  {
    key = 'p',
    mods = 'LEADER',
    action = wezterm.action.ActivateTabRelative(-1),
  },
  {
    key = 'l',
    mods = 'LEADER',
    action = wezterm.action.ActivatePaneDirection 'Right',
  },
  {
    key = 'h',
    mods = 'LEADER',
    action = wezterm.action.ActivatePaneDirection 'Left',
  },
  {
    key = 'j',
    mods = 'LEADER',
    action = wezterm.action.ActivatePaneDirection 'Down',
  },
  {
    key = 'k',
    mods = 'LEADER',
    action = wezterm.action.ActivatePaneDirection 'Up',
  },
  {
    key = '&',
    mods = 'LEADER|SHIFT',
    action = wezterm.action.CloseCurrentTab { confirm = true },
  },
  {
    key = '0',
    mods = 'LEADER',
    action = wezterm.action.ActivateTab(9),
  },
  {
    key = '0',
    mods = 'ALT',
    action = wezterm.action.ActivateTab(9),
  },
}

for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = 'ALT',
    action = wezterm.action.ActivateTab(i - 1),
  })
end

-- and finally, return the configuration to wezterm
return config

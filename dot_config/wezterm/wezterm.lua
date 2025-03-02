-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- This is where you actually apply your config choices

config.color_scheme = 'Modus-Vivendi'

config.font = wezterm.font 'FantasqueSansM Nerd Font Mono'
config.font_size = 13.0

config.window_decorations = "RESIZE"

vs_template = '&{' ..
  'Import-Module "%s\\Common7\\Tools\\Microsoft.VisualStudio.DevShell.dll"; ' ..
  'Enter-VsDevShell -VsInstallPath "%s" -SkipAutomaticLocation -DevCmdArguments "-arch=x64 -host_arch=x64"' ..
  '}'
vs2022_path = "C:\\Program Files\\Microsoft Visual Studio\\2022\\Community"
vs2019_path = "C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools"

vs2022_pwsh = {
  'pwsh.exe',
  '-NoExit',
  '-Command',
  string.format(vs_template, vs2022_path, vs2022_path),
}
vs2019_pwsh = {
  'pwsh.exe',
  '-NoExit',
  '-Command',
  string.format(vs_template, vs2019_path, vs2019_path),
}
pwsh = {
  'pwsh.exe',
}
git_bash = {
  'C:\\Program Files\\Git\\bin\\bash.exe',
  '--login',
}
zsh = {
  '/usr/bin/zsh',
  '-l',
}
xonsh = {
  'xonsh',
  '--login',
}

if wezterm.target_triple == 'x86_64-pc-windows-msvc' then
  config.default_prog = xonsh

  config.launch_menu = {
    {
      label = 'Developer PWSH for VS 2022',
      args = vs2022_pwsh,
    },
    {
      label = 'Developer PWSH for VS 2019',
      args = vs2019_pwsh,
    },
    {
      label = 'PowerShell',
      args = pwsh,
    },
    {
      label = 'xonsh',
      args = xonsh,
    },
    {
      label = 'Git Bash',
      args = git_bash,
    },
    {
      label = 'Command Prompt',
      args = { 'C:\\Windows\\System32\\cmd.exe' },
    },
  }
else
  config.default_prog = zsh

  config.launch_menu = {
    {
      label = 'zsh',
      args = zsh,
    },
  }
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

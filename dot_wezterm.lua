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

config.color_scheme = 'Ef-Winter'

config.font = wezterm.font 'FantasqueSansMono NF'
config.font_size = 13.0

config.window_decorations = "RESIZE"

vs_template = '&{' ..
  'Import-Module "%s\\Common7\\Tools\\Microsoft.VisualStudio.DevShell.dll"; ' ..
  'Enter-VsDevShell -VsInstallPath "%s" -SkipAutomaticLocation -DevCmdArguments "-arch=x64 -host_arch=x64"' ..
  '}'
vs2022_path = "C:\\Program Files\\Microsoft Visual Studio\\2022\\Enterprise"
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
  'C:\\Program Files\\PowerShell\\7\\pwsh.exe',
}
zsh = {
  '/usr/bin/zsh',
  '-l',
}

if wezterm.target_triple == 'x86_64-pc-windows-msvc' then
  config.default_prog = vs2019_pwsh

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

-- and finally, return the configuration to wezterm
return config

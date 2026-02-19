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

config.font = wezterm.font('FantasqueSansM Nerd Font Mono', { weight = 'DemiBold' })

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

  -- Only add MSYS2 MINGW64 if it's installed
  local msys2_shell = 'C:\\msys64\\msys2_shell.cmd'
  local f = io.open(msys2_shell, 'r')
  if f ~= nil then
    io.close(f)
    table.insert(config.launch_menu, {
      label = 'MSYS2 MINGW64',
      args = { msys2_shell, '-defterm', '-here', '-no-start', '-mingw64' },
    })
  end

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
config.keys = {
  {
    key = 'Enter',
    mods = 'SHIFT',
    action = wezterm.action.SendString '\n',
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

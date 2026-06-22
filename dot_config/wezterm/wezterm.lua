-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- Helper functions to detect OS (platform-agnostic, works on both x64 and ARM64)
local function is_windows()
  return wezterm.target_triple:find("windows") ~= nil
end

local function is_macos()
  return wezterm.target_triple:find("darwin") ~= nil
end

local function is_linux()
  return wezterm.target_triple:find("linux") ~= nil
end

-- Include homebrew to PATH on Apple Silicon
if wezterm.target_triple == "aarch64-apple-darwin" then
  config.set_environment_variables = {
    PATH = '/opt/homebrew/bin:' .. os.getenv('PATH')
  }
end

-- This is where you actually apply your config choices

config.color_scheme = 'Modus-Vivendi'

config.font = wezterm.font('FantasqueSansM Nerd Font Mono', { weight = 'DemiBold' })

config.font_size = 13.0
if is_macos() then
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

if is_windows() then
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

  -- Dynamically find Visual Studio installations using vswhere
  local vswhere_path = 'C:\\Program Files (x86)\\Microsoft Visual Studio\\Installer\\vswhere.exe'
  local vswhere_file = io.open(vswhere_path, 'r')
  if vswhere_file ~= nil then
    io.close(vswhere_file)
    
    -- Detect native architecture
    local arch = 'x64'
    local arch_handle = io.popen('cmd.exe /c echo %PROCESSOR_ARCHITECTURE%')
    if arch_handle then
      local proc_arch = arch_handle:read('*a'):gsub('%s+', '')
      arch_handle:close()
      if proc_arch == 'ARM64' then
        arch = 'arm64'
      end
    end
    
    -- Run vswhere to find all VS installations (including Build Tools)
    local vswhere_cmd = 'cmd.exe /c "\"' .. vswhere_path .. '\" -all -products * -format json"'
    local vs_handle = io.popen(vswhere_cmd)
    if vs_handle then
      local json_output = vs_handle:read('*a')
      vs_handle:close()
      
      -- Parse each Visual Studio installation
      -- Look for objects in the JSON array
      for vs_object in json_output:gmatch('{.-}') do
        local install_path = vs_object:match('"installationPath"%s*:%s*"([^"]+)"')
        local display_name = vs_object:match('"displayName"%s*:%s*"([^"]+)"')
        
        if install_path and display_name then
          -- Convert double backslashes from JSON to single backslashes
          install_path = install_path:gsub('\\\\', '\\')
          
          -- Only support VS 2019 and later (has DevShell.dll)
          local devshell_path = install_path .. '\\Common7\\Tools\\Microsoft.VisualStudio.DevShell.dll'
          local devshell_file = io.open(devshell_path, 'r')
          
          if devshell_file then
            io.close(devshell_file)
            
            local vs_template = '&{' ..
              'Import-Module "%s\\Common7\\Tools\\Microsoft.VisualStudio.DevShell.dll"; ' ..
              'Enter-VsDevShell -VsInstallPath "%s" -SkipAutomaticLocation -DevCmdArguments "-arch=%s -host_arch=%s"' ..
              '}'
            
            table.insert(config.launch_menu, {
              label = string.format('Developer PWSH for %s', display_name),
              args = {
                'pwsh.exe',
                '-NoExit',
                '-Command',
                string.format(vs_template, install_path, install_path, arch, arch),
              },
            })
          end
        end
      end
    end
  end
elseif is_macos() or is_linux() then
  table.insert(config.launch_menu, {
    label = 'zsh',
    args = { 'zsh', '--login' }
  })
end

-- 1Password SSH agent can then take over and listen on the system-wide pipe at
-- \\.\pipe\openssh-ssh-agent
if is_windows() then
  config.default_ssh_auth_sock = "\\\\.\\pipe\\openssh-ssh-agent"
end

-- Enable kitty keyboard for better compatibility with Pi Coding Agent
config.enable_kitty_keyboard = true

-- Key bindings
config.keys = {
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

-- Increase scrollback size
config.scrollback_lines = 99999

-- and finally, return the configuration to wezterm
return config

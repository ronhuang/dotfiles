from pathlib import Path

# 1Password SSH agent
sock = p'~/.1password/agent.sock'
if sock.exists():
    $SSH_AUTH_SOCK = str(sock)

# add Doom Emacs to PATH
doom = p'~/.config/emacs/bin'
if doom.exists():
    $PATH.insert(0, doom)

# add local to PATH
local = p'~/.local/bin'
if local.exists():
    $PATH.insert(0, local)

# aliases
aliases['ls'] = ['eza', '--icons']
aliases['l'] = ['eza', '--icons', '-l']
aliases['lt'] = ['eza', '--icons', '--tree']
aliases['e'] = ['emacsclient', '-c', '-n', '-a', '']
aliases['ec'] = ['emacsclient', '-t', '-a', '']

# better prompt
$VIRTUAL_ENV_DISABLE_PROMPT = True
$STARSHIP_CONFIG = '~/.config/starship/xonsh.toml'
xontrib load prompt_starship

# better cd
execx($(zoxide init xonsh), 'exec', __xonsh__.ctx, filename='zoxide')

# ripgrep config
$RIPGREP_CONFIG_PATH = '~/.config/ripgrep/rc'

# eza config
$EZA_CONFIG_DIR = '~/.config/eza'

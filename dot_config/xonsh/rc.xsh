from xonsh import platform

# Sqlite history backend
$XONSH_HISTORY_BACKEND = 'sqlite'

# 1Password SSH agent
sock = p'~/.1password/agent.sock'
if sock.exists():
    $SSH_AUTH_SOCK = str(sock)

# add Doom Emacs to PATH
doom = p'~/.config/emacs/bin'
if doom.exists():
    $PATH.prepend(doom)

# add local to PATH
local = p'~/.local/bin'
if local.exists():
    $PATH.prepend(local)

# fzf
$fzf_history_binding = 'c-r'
$fzf_file_binding = 'c-t'
$FZF_CTRL_R_OPTS = '--no-sort --exact'
xontrib load fzf-completions

# aliases
aliases['ls'] = ['eza', '--icons']
aliases['l'] = ['eza', '--icons', '-l']
aliases['lt'] = ['eza', '--icons', '--tree']
aliases['e'] = ['emacsclient', '-c', '-n', '-a', '']
aliases['ec'] = ['emacsclient', '-t', '-a', '']
if platform.ON_WINDOWS:
    aliases['doom'] = ['pwsh', '-File', '~/.config/emacs/bin/doom.ps1']

# better prompt
$VIRTUAL_ENV_DISABLE_PROMPT = True

if platform.ON_WINDOWS and (p"" / $ProgramFiles / "Zscaler").exists():
    # starship is too slow with Zscaler
    # use simpler prompt
    $PROMPT = '{CYAN}{short_cwd} {RED}{last_return_code_if_nonzero:[{BOLD_INTENSE_RED}{}{RED}] }{RESET}\n{BOLD_GREEN}{prompt_end}{RESET} '
else:
    $STARSHIP_CONFIG = '~/.config/starship/xonsh.toml'
    xontrib load prompt_starship

# better cd
execx($(zoxide init xonsh), 'exec', __xonsh__.ctx, filename='zoxide')

# ripgrep config
$RIPGREP_CONFIG_PATH = '~/.config/ripgrep/rc'

# eza config
$EZA_CONFIG_DIR = '~/.config/eza'

# use 1Password SSH agent under WSL environment
if platform.ON_WSL:
    $SSH_AUTH_SOCK = p'~/.local/share/1password/agent.sock'
    # need `ps -ww` to get non-truncated command for matching
    already_running = len($(ps -auxww | grep "[n]piperelay.exe -ei -s //./pipe/openssh-ssh-agent")) > 0
    if not already_running:
        if $SSH_AUTH_SOCK.is_socket():
            # not expecting the socket to exist as the forwarding command isn't running
            print("Removing previous socket...")
            rm $SSH_AUTH_SOCK

        print("Starting SSH-Agent relay...")
        # setsid to force new session to keep running
        # set socat to listen on $SSH_AUTH_SOCK and forward to npiperelay which then forward s to openssh-ssh-agent on windows
        $npiperelay_path = $(which npiperelay.exe)
        $(setsid socat UNIX-LISTEN:$SSH_AUTH_SOCK,fork EXEC:"$npiperelay_path -ei -s //./pipe/openssh-ssh-agent",nofork &)

# too many Windows path in PATH cause xonsh sluggish
if platform.ON_WSL:
    for path in $PATH.paths:
        if path.startswith('/mnt/c/'):
            $PATH.remove(path)

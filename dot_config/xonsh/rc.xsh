# aliases
aliases['ls'] = ['exa', '--icons']
aliases['l'] = ['exa', '--icons', '-l']
aliases['lt'] = ['exa', '--icons', '--tree']
aliases['e'] = ['emacsclient', '-c', '-n', '-a', '\'\'']
aliases['ec'] = ['emacsclient', '-t', '-a', '\'\'']

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

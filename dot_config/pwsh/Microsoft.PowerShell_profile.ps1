# readline
Import-Module PSReadLine
Set-PSReadlineOption -EditMode Emacs
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineOption -PredictionSource History
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward

# fzf on pwsh
Import-Module PSFzf
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
$env:FZF_CTRL_R_OPTS="--no-sort --exact --height 40%  --reverse --border"

# fun
function rpg
{
    rpg-cli-1.0.0-windows $args
    Set-Location $(rpg-cli-1.0.0-windows pwd)
}

# emacs related
function Invoke-EmacsClientConsole
{
    emacsclient.exe -t -a '' @Args
}

function Invoke-EmacsClient
{
    emacsclient.exe -c -n -a '' @Args
}

Set-Alias -Name e -Value Invoke-EmacsClient
Set-Alias -Name ec -Value Invoke-EmacsClientConsole

# better ls
function Invoke-Eza
{
    eza.exe --icons @Args
}

function Invoke-EzaLong
{
    eza.exe --icons -l @Args
}

function Invoke-EzaTree
{
    eza.exe --icons --tree @Args
}

if ($env:USERDNSDOMAIN -ne 'auth.hpicorp.net')
{
    Set-Alias -Name ls -Value Invoke-Eza
    Set-Alias -Name l -Value Invoke-EzaLong
    Set-Alias -Name lt -Value Invoke-EzaTree
}

# emulate which on pwsh
function Invoke-Which
{
    $w = Get-Command -ErrorAction SilentlyContinue $Args
    if ($w)
    {
        $w.Path
    }
    else
    {
        Write-Error "$Args not found"
    }
}

Set-Alias -Name which -Value Invoke-Which

# remove concusing alias/functions
$confusing = @("Alias:\rm", "Alias:\rmdir", "Function:\mkdir")
foreach ($c in $confusing)
{
    if (Test-Path $c -PathType Leaf)
    {
        Remove-Item $c
    }
}

# better prompt
$env:VIRTUAL_ENV_DISABLE_PROMPT=$true
Invoke-Expression (&starship init powershell)

# better cd
Invoke-Expression (& { (zoxide init powershell | Out-String) })

# ripgrep config
$env:RIPGREP_CONFIG_PATH="$env:USERPROFILE\.config\ripgrep\rc"

# eza config
$env:EZA_CONFIG_DIR="$env:USERPROFILE\.config\eza"

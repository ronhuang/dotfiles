# readline
Import-Module PSReadLine
Set-PSReadlineOption -EditMode Emacs
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
if (![System.Console]::IsOutputRedirected)
{
  Set-PSReadLineOption -PredictionSource History
}
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward

# fzf on pwsh
Import-Module PSFzf
Set-PsFzfOption `
  -PSReadlineChordProvider 'Ctrl+t' `
  -PSReadlineChordReverseHistory 'Ctrl+r' `
  -EnableAliasFuzzyKillProcess `
  -EnableFd
$env:FZF_CTRL_R_OPTS="--no-sort --exact"

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

Set-Alias -Name ls -Value Invoke-Eza
Set-Alias -Name l -Value Invoke-EzaLong
Set-Alias -Name lt -Value Invoke-EzaTree

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
$confusing = @(
    "Alias:\cp",
    "Alias:\diff",
    "Alias:\mv",
    "Alias:\rm",
    "Alias:\rmdir",
    "Alias:\sort",
    "Function:\mkdir"
)
foreach ($c in $confusing)
{
    if (Test-Path $c -PathType Leaf)
    {
        Remove-Item $c -Force
    }
}

# better prompt
$env:VIRTUAL_ENV_DISABLE_PROMPT=$true
Invoke-Expression (&starship init powershell)

# better cd
Invoke-Expression (& { (zoxide init powershell | Out-String) })

# global pager: git, bat, delta/jj all honor PAGER (delta uses DELTA_PAGER raw,
# since it re-splits $PAGER and spaced paths break it)
$gitLess = Join-Path $env:ProgramFiles 'Git\usr\bin\less.exe'
if (Test-Path $gitLess)
{
    $env:PAGER = "`"$gitLess`" -R -F -X"
    $env:DELTA_PAGER = "`"$gitLess`" -R -F -X"
}

# ripgrep config
$env:RIPGREP_CONFIG_PATH="$env:USERPROFILE\.config\ripgrep\rc"

# eza config
$env:EZA_CONFIG_DIR="$env:USERPROFILE\.config\eza"

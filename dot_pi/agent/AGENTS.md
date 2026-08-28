# Global Agent Instructions

## Shell Tools (PowerShell)
Prefer `rg` over `Select-String`/`grep` and `fd` over `Get-ChildItem -Recurse` for search/find.
Fall back to native cmdlets only if `rg`/`fd` are unavailable or object-pipeline/.NET features are needed.

## Version Control (jj / git)
Prefer `jj` over `git` unless the repo isn't jj-managed or a git-only feature is needed.
Signing prompts for a passphrase and can hang the agentic loop — always skip it per-invocation when working autonomously:
- `jj --config signing.behavior=drop commit -m "..."`
- `git commit --no-gpg-sign -m "..."` (or `-c commit.gpgsign=false`)
Never edit the user's signing config to disable it permanently.

## Line Endings
Never change a file's existing EOL style (CRLF/LF) when editing. New files follow the surrounding project's convention.

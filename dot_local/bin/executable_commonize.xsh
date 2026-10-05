#!/usr/bin/env xonsh
"""Promote a local experiment to the shared common branch safely.

Usage:
    commonize.xsh "Commit message"
    commonize.xsh --dry-run

The command expects the current branch to be ``main``. It detects the work
and personal remotes from their URLs, commits explicitly staged changes,
rebases local commits onto the personal remote's ``common`` branch, pushes that
result to the shared common branch, then merges the promoted result back into
the current downstream remote's ``main`` branch.

Unstaged and untracked files are never accepted. The command never stashes,
force-pushes, or automatically resets after an operation fails.
"""

from __future__ import annotations

import argparse
import shlex
import subprocess
import sys
import uuid
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Sequence


BRANCH = "main"
COMMON_BRANCH = "common"
PERSONAL_HOST = "github.com"
PERSONAL_REPOSITORY = "ronhuang/dotfiles"


@dataclass(frozen=True)
class RemoteLayout:
    """The current downstream remote and the remote hosting ``common``."""

    target_remote: str
    common_remote: str

    @property
    def target_ref(self) -> str:
        return f"refs/remotes/{self.target_remote}/{BRANCH}"

    @property
    def common_ref(self) -> str:
        return f"refs/remotes/{self.common_remote}/{COMMON_BRANCH}"


class CommonizeError(RuntimeError):
    """An expected error that should be shown without a traceback."""


class GitCommandError(CommonizeError):
    """A git command returned a non-zero exit status."""

    def __init__(self, args: Sequence[str], returncode: int, details: str = ""):
        self.args = tuple(args)
        self.returncode = returncode
        self.details = details.strip()
        command = "git " + shlex.join(list(args))
        message = f"{command} failed with exit code {returncode}."
        if self.details:
            message += f"\n{self.details}"
        super().__init__(message)


@dataclass(frozen=True)
class WorkspaceState:
    """The relevant parts of porcelain status output."""

    entries: tuple[str, ...]

    @property
    def staged(self) -> tuple[str, ...]:
        return tuple(
            entry
            for entry in self.entries
            if len(entry) >= 2 and entry[0] not in (" ", "?")
        )

    @property
    def unstaged(self) -> tuple[str, ...]:
        return tuple(
            entry
            for entry in self.entries
            if entry.startswith("??")
            or (len(entry) >= 2 and entry[1] not in (" ", "?"))
        )

    @property
    def conflicts(self) -> tuple[str, ...]:
        unmerged_codes = {"AA", "AU", "DD", "DU", "UA", "UD", "UU"}
        return tuple(
            entry
            for entry in self.entries
            if len(entry) >= 2 and entry[:2] in unmerged_codes
        )

    @property
    def clean(self) -> bool:
        return not self.entries


class Git:
    """Small subprocess wrapper that never invokes a shell."""

    def __init__(self, cwd: Path):
        self.cwd = cwd

    def run(
        self,
        args: Sequence[str],
        *,
        capture: bool = False,
        check: bool = True,
        announce: bool = True,
    ) -> subprocess.CompletedProcess[str]:
        command = ["git", *args]
        if announce:
            print("$ " + shlex.join(command))

        if capture:
            result = subprocess.run(
                command,
                cwd=self.cwd,
                text=True,
                capture_output=True,
                errors="replace",
            )
        else:
            # Inherit the terminal so SSH, GPG, editor, and commit-hook prompts
            # behave as they do for an interactive git command.
            result = subprocess.run(command, cwd=self.cwd, text=True)

        if check and result.returncode != 0:
            details = ""
            if capture:
                details = "\n".join(
                    part for part in (result.stdout, result.stderr) if part
                )
            raise GitCommandError(args, result.returncode, details)
        return result

    def output(self, args: Sequence[str]) -> str:
        result = self.run(args, capture=True, announce=False)
        return result.stdout.strip()

    def ref(self, name: str) -> str:
        return self.output(["rev-parse", "--verify", f"{name}^{{commit}}"])

    def head(self) -> str:
        return self.ref("HEAD")

    def status(self) -> WorkspaceState:
        output = self.output(
            ["status", "--porcelain=v1", "--untracked-files=all"]
        )
        entries = tuple(line for line in output.splitlines() if line)
        return WorkspaceState(entries)

    def is_ancestor(self, ancestor: str, descendant: str) -> bool:
        result = self.run(
            ["merge-base", "--is-ancestor", ancestor, descendant],
            capture=True,
            check=False,
            announce=False,
        )
        return result.returncode == 0

    def operation_paths(self) -> tuple[Path, ...]:
        paths = []
        for marker in (
            "MERGE_HEAD",
            "CHERRY_PICK_HEAD",
            "REVERT_HEAD",
            "rebase-apply",
            "rebase-merge",
        ):
            path = Path(self.output(["rev-parse", "--git-path", marker]))
            if not path.is_absolute():
                path = self.cwd / path
            if path.exists():
                paths.append(path)
        return tuple(paths)


def discover_repository() -> Path:
    result = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        cwd=Path.cwd(),
        text=True,
        capture_output=True,
        errors="replace",
    )
    if result.returncode != 0:
        details = "\n".join(
            part for part in (result.stdout, result.stderr) if part
        ).strip()
        raise CommonizeError(f"Not inside a Git worktree.\n{details}")
    return Path(result.stdout.strip()).resolve()


def ref_exists(git: Git, ref: str) -> bool:
    result = git.run(
        ["show-ref", "--verify", "--quiet", ref],
        capture=True,
        check=False,
        announce=False,
    )
    return result.returncode == 0


def remote_urls(git: Git) -> dict[str, str]:
    names = [line for line in git.output(["remote"]).splitlines() if line]
    if not names:
        raise CommonizeError("No Git remotes are configured.")

    urls: dict[str, str] = {}
    for name in names:
        # Read the configured URL rather than ``remote get-url``. The latter
        # applies url.*.insteadOf rewrites, which can hide the hosting service
        # and make a GitHub remote look like a local path in test/dev setups.
        result = git.run(
            ["config", "--get", f"remote.{name}.url"],
            capture=True,
            check=False,
            announce=False,
        )
        url = result.stdout.strip()
        if result.returncode == 0 and url:
            urls[name] = url
    if len(urls) != len(names):
        missing = ", ".join(name for name in names if name not in urls)
        raise CommonizeError(
            f"Could not determine the URL for remote(s): {missing}."
        )
    return urls


def remote_url_matches(url: str, host: str, repository: str) -> bool:
    normalized = url.lower().replace("\\", "/")
    return host in normalized and repository in normalized


def upstream_remote(git: Git) -> str | None:
    result = git.run(
        [
            "rev-parse",
            "--abbrev-ref",
            "--symbolic-full-name",
            "@{upstream}",
        ],
        capture=True,
        check=False,
        announce=False,
    )
    upstream = result.stdout.strip()
    if result.returncode != 0 or not upstream:
        return None

    remote, separator, branch = upstream.rpartition("/")
    if not separator or branch != BRANCH:
        raise CommonizeError(
            f"The current branch tracks '{upstream}', but commonize requires "
            f"an upstream '{BRANCH}' branch."
        )
    return remote


def choose_remote(
    *,
    role: str,
    option: str,
    override: str | None,
    candidates: list[str],
    names: list[str],
    urls: dict[str, str],
) -> str | None:
    if override is not None:
        if override not in urls:
            available = ", ".join(names) or "none"
            raise CommonizeError(
                f"The {role} remote '{override}' is not configured. "
                f"Available remotes: {available}."
            )
        return override
    if len(candidates) == 1:
        return candidates[0]
    if len(candidates) > 1:
        details = "\n".join(
            f"  {name}: {urls[name]}" for name in candidates
        )
        raise CommonizeError(
            f"Could not uniquely identify the {role} remote.\n{details}\n"
            f"Use {option} to select it."
        )
    return None


def resolve_remotes(
    git: Git,
    *,
    common_override: str | None,
    target_override: str | None,
) -> RemoteLayout:
    urls = remote_urls(git)
    names = list(urls)

    if target_override is not None:
        if target_override not in urls:
            available = ", ".join(names) or "none"
            raise CommonizeError(
                f"The target remote '{target_override}' is not configured. "
                f"Available remotes: {available}."
            )
        target = target_override
    else:
        target = upstream_remote(git)
        if target is None:
            raise CommonizeError(
                f"Branch '{BRANCH}' has no upstream. Use --target-remote "
                "to identify the remote whose main branch should be updated."
            )
        if target not in urls:
            raise CommonizeError(
                f"The upstream remote '{target}' is not configured locally."
            )

    common_candidates = [
        name
        for name, url in urls.items()
        if remote_url_matches(url, PERSONAL_HOST, PERSONAL_REPOSITORY)
    ]
    if not common_candidates:
        common_candidates = [
            name
            for name in names
            if ref_exists(git, f"refs/remotes/{name}/{COMMON_BRANCH}")
        ]

    # When the current downstream branch is itself the personal repository,
    # origin/common is the correct common branch even if another remote also
    # points at a personal mirror.
    if common_override is None and target in common_candidates:
        common = target
    else:
        common = choose_remote(
            role="personal/common",
            option="--personal-remote",
            override=common_override,
            candidates=common_candidates,
            names=names,
            urls=urls,
        )

    if common is None:
        if remote_url_matches(
            urls[target], PERSONAL_HOST, PERSONAL_REPOSITORY
        ):
            common = target
        else:
            available = "\n".join(
                f"  {name}: {urls[name]}" for name in names
            )
            raise CommonizeError(
                "Could not identify the personal remote hosting common.\n"
                f"{available}\n"
                "Use --personal-remote to select it."
            )

    return RemoteLayout(target_remote=target, common_remote=common)


def require_no_operation(git: Git) -> None:
    paths = git.operation_paths()
    if paths:
        names = ", ".join(str(path) for path in paths)
        raise CommonizeError(
            "Git has an operation in progress (" + names + "). "
            "Finish or abort it before running commonize."
        )


def require_branch(git: Git) -> None:
    result = git.run(
        ["symbolic-ref", "--quiet", "--short", "HEAD"],
        capture=True,
        check=False,
        announce=False,
    )
    branch = result.stdout.strip()
    if result.returncode != 0 or branch != BRANCH:
        actual = branch or "detached HEAD"
        raise CommonizeError(
            f"commonize must run on branch '{BRANCH}', not '{actual}'."
        )


def require_no_unstaged_changes(state: WorkspaceState) -> None:
    if state.conflicts:
        raise CommonizeError(
            "The workspace contains unresolved conflicts. "
            "Resolve or abort the current operation first."
        )
    if state.unstaged:
        print("Unstaged or untracked paths:", file=sys.stderr)
        for entry in state.unstaged:
            print(f"  {entry}", file=sys.stderr)
        raise CommonizeError(
            "Refusing to continue: unstaged and untracked changes are never "
            "discarded by commonize. Stage the intended changes and clean the "
            "rest of the workspace first."
        )


def require_clean(git: Git, reason: str) -> None:
    state = git.status()
    if not state.clean:
        print(f"Workspace status changed {reason}:", file=sys.stderr)
        for entry in state.entries:
            print(f"  {entry}", file=sys.stderr)
        raise CommonizeError(
            "Refusing to perform a destructive step while the workspace is "
            "not clean. No reset was attempted."
        )


def create_backup_ref(git: Git, session: str, name: str, commit: str) -> str:
    ref = f"refs/backup/commonize/{session}/{name}"
    git.run(["update-ref", ref, commit], announce=False)
    return ref


def local_commits(git: Git, base: str) -> list[str]:
    output = git.output(["rev-list", "--reverse", f"{base}..HEAD"])
    return [line for line in output.splitlines() if line]


def local_merge_commits(git: Git, base: str) -> list[str]:
    output = git.output(["rev-list", "--merges", f"{base}..HEAD"])
    return [line for line in output.splitlines() if line]


def describe_commits(git: Git, commits: Sequence[str]) -> list[str]:
    if not commits:
        return []
    output = git.output(
        ["show", "--no-patch", "--format=%h %s", *commits]
    )
    return [line for line in output.splitlines() if line]


def print_plan(
    git: Git,
    *,
    remotes: RemoteLayout,
    target_head: str,
    common_head: str,
    commits: Sequence[str],
    staged: Sequence[str],
    dry_run: bool,
) -> None:
    print(f"Repository: {git.cwd}")
    print(f"Target remote: {remotes.target_remote}")
    print(f"Personal/common remote: {remotes.common_remote}")
    print(f"Target base:  {target_head[:12]} ({remotes.target_ref})")
    print(f"Common tip:   {common_head[:12]} ({remotes.common_ref})")
    if staged:
        print("Staged changes to commit:")
        for entry in staged:
            print(f"  {entry}")
    if commits:
        print("Local commits to promote:")
        for line in describe_commits(git, commits):
            print(f"  {line}")
    action = "Would perform" if dry_run else "Will perform"
    print(f"{action}:")
    if staged:
        print("  commit the staged changes")
    print(
        f"  rebase local commits onto {remotes.common_remote}/{COMMON_BRANCH}"
    )
    print(
        f"  push the rebased tip to {remotes.common_remote}/{COMMON_BRANCH}"
    )
    print(f"  reset local main to {remotes.target_remote}/{BRANCH}")
    print("  create a non-fast-forward merge into main")
    print(f"  push main to {remotes.target_remote}")


def confirm() -> bool:
    try:
        answer = input("Proceed? [y/N] ")
    except EOFError:
        return False
    return answer.strip().lower() in {"y", "yes"}


def refresh_refs(git: Git, remotes: RemoteLayout) -> None:
    git.run(
        [
            "fetch",
            "--no-tags",
            remotes.target_remote,
            f"refs/heads/{BRANCH}:{remotes.target_ref}",
        ]
    )
    git.run(
        [
            "fetch",
            "--no-tags",
            remotes.common_remote,
            f"refs/heads/{COMMON_BRANCH}:{remotes.common_ref}",
        ]
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Safely promote staged/local experiments to the personal common "
            "branch and merge the result into the current downstream branch."
        )
    )
    parser.add_argument(
        "message",
        nargs="?",
        help="commit message for staged changes; omit when commits already exist",
    )
    parser.add_argument(
        "--personal-remote",
        "--common-remote",
        dest="common_remote",
        metavar="NAME",
        help=(
            "remote hosting the personal repository and common branch; "
            "normally detected from its URL"
        ),
    )
    parser.add_argument(
        "--target-remote",
        "--work-remote",
        dest="target_remote",
        metavar="NAME",
        help=(
            "remote whose main branch is the current downstream target; "
            "normally detected from the current branch upstream"
        ),
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="show the plan without fetching, committing, rebasing, or pushing",
    )
    parser.add_argument(
        "--yes",
        action="store_true",
        help="skip the confirmation prompt",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    git = Git(discover_repository())

    require_branch(git)
    remotes = resolve_remotes(
        git,
        common_override=args.common_remote,
        target_override=args.target_remote,
    )
    require_no_operation(git)

    before_fetch = git.status()
    require_no_unstaged_changes(before_fetch)

    if not args.dry_run:
        refresh_refs(git, remotes)
        after_fetch = git.status()
        if after_fetch.entries != before_fetch.entries:
            raise CommonizeError(
                "The workspace changed while fetching remote refs. "
                "No destructive step was attempted."
            )

    target_head = git.ref(remotes.target_ref)
    common_head = git.ref(remotes.common_ref)

    if not git.is_ancestor(target_head, git.head()):
        raise CommonizeError(
            f"{remotes.target_ref} is not an ancestor of local main. "
            f"Synchronize main with {remotes.target_remote}/{BRANCH} before "
            "promoting an experiment."
        )

    if local_merge_commits(git, target_head):
        raise CommonizeError(
            f"Local main contains merge commits after {remotes.target_remote}/"
            f"{BRANCH}. commonize only rebases a linear experiment; handle "
            "those commits explicitly first."
        )

    staged = before_fetch.staged
    if staged and not args.message:
        raise CommonizeError(
            "Staged changes are present, but no commit message was supplied."
        )

    commits = local_commits(git, target_head)
    if not staged and not commits:
        raise CommonizeError(
            f"There are no staged changes and no local commits after "
            f"{remotes.target_remote}/{BRANCH}."
        )

    print_plan(
        git,
        remotes=remotes,
        target_head=target_head,
        common_head=common_head,
        commits=commits,
        staged=staged,
        dry_run=args.dry_run,
    )

    if args.dry_run:
        print("Dry run: no repository state was changed.")
        return 0

    if not args.yes and not confirm():
        print(
            "Cancelled; no commit, rebase, reset, merge, or push was performed."
        )
        return 0

    if staged:
        git.run(["commit", "-m", args.message])
        require_no_unstaged_changes(git.status())

    original_head = git.head()
    session = (
        datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
        + "-"
        + uuid.uuid4().hex[:8]
    )
    original_backup = create_backup_ref(
        git, session, "original", original_head
    )
    print(f"Safety ref: {original_backup}")

    if (
        git.ref(remotes.target_ref) != target_head
        or git.ref(remotes.common_ref) != common_head
    ):
        raise CommonizeError(
            "A remote-tracking ref changed unexpectedly before rebase. "
            "No reset was attempted."
        )

    require_clean(git, "before rebase")
    try:
        git.run(
            [
                "rebase",
                "--onto",
                remotes.common_ref,
                remotes.target_ref,
                BRANCH,
            ]
        )
    except CommonizeError:
        print(
            "Rebase failed. No reset was attempted; inspect the rebase state "
            "or run 'git rebase --abort'.",
            file=sys.stderr,
        )
        raise

    require_clean(git, "after rebase")
    promoted_head = git.head()
    if promoted_head == common_head:
        # A duplicate patch may have been skipped by rebase. Restore the
        # original clean branch rather than silently resetting to a surprise tip.
        require_clean(git, "before restoring a no-op rebase")
        git.run(["reset", "--hard", original_head])
        raise CommonizeError(
            f"Rebase produced no commit beyond {remotes.common_remote}/"
            f"{COMMON_BRANCH}; nothing was promoted. The original local tip "
            "was restored."
        )

    if not git.is_ancestor(common_head, promoted_head):
        raise CommonizeError(
            "The rebased tip is not descended from the fetched common tip. "
            "No reset was attempted."
        )

    promoted_backup = create_backup_ref(
        git, session, "promoted", promoted_head
    )
    print(f"Safety ref: {promoted_backup}")

    require_clean(git, "before pushing common")
    git.run(
        [
            "push",
            remotes.common_remote,
            f"{promoted_head}:refs/heads/{COMMON_BRANCH}",
        ]
    )

    # This is the only intentional destructive operation. It is guarded by a
    # clean-status check and the rebased tip is retained by promoted_backup.
    require_clean(
        git,
        f"before resetting to {remotes.target_remote}/{BRANCH}",
    )
    if git.head() != promoted_head:
        raise CommonizeError(
            "HEAD changed unexpectedly after pushing common. No reset was "
            "attempted."
        )
    git.run(["reset", "--hard", target_head])
    require_clean(
        git,
        f"after resetting to {remotes.target_remote}/{BRANCH}",
    )

    try:
        git.run(
            [
                "merge",
                "--no-ff",
                promoted_head,
                "-m",
                "Merge branch 'common' into 'main'",
            ]
        )
    except CommonizeError:
        print(
            "Merge failed or has conflicts. No reset was attempted; resolve "
            "or abort the merge, then push when it is clean.",
            file=sys.stderr,
        )
        raise

    require_clean(git, "after merging common")
    git.run(
        [
            "push",
            remotes.target_remote,
            f"HEAD:refs/heads/{BRANCH}",
        ]
    )
    require_clean(git, "after pushing main")

    print("Promotion complete.")
    print(f"  common: {promoted_head[:12]}")
    print(f"  merge:  {git.head()[:12]}")
    print(f"  safety refs: refs/backup/commonize/{session}/")
    return 0


try:
    raise SystemExit(main())
except CommonizeError as error:
    print(f"commonize: {error}", file=sys.stderr)
    raise SystemExit(1)
except KeyboardInterrupt:
    print(
        "commonize: interrupted; no automatic reset was attempted.",
        file=sys.stderr,
    )
    raise SystemExit(130)

#!/usr/bin/env xonsh
"""eolflip — Detect a file's line ending style and flip to the opposite.

Usage:
    eolflip <file> [<file> ...]        # flip in-place
    eolflip -o <output> <file>         # write to a separate output file

Works on Windows, Linux, and macOS — requires xonsh to be installed.
"""

import argparse
import sys
from pathlib import Path


def detect_eol(raw):
    """Return 'crlf', 'lf', or None (empty/no newlines)."""
    if b"\r\n" in raw:
        return "crlf"
    if b"\n" in raw:
        return "lf"
    return None


def convert(raw, target):
    """Convert raw bytes so every line ending is the target style."""
    data = raw.replace(b"\r\n", b"\n")
    if target == "crlf":
        data = data.replace(b"\n", b"\r\n")
    return data


def process(path, output):
    """Process one file. Returns 0 on success, 1 on error."""
    if not path.is_file():
        print(f"eolflip: '{path}' is not a regular file.", file=sys.stderr)
        return 1

    raw = path.read_bytes()
    current = detect_eol(raw)

    if current is None:
        print(f"eolflip: '{path}' — no newlines found, skipping.", file=sys.stderr)
        return 0

    target = "crlf" if current == "lf" else "lf"
    converted = convert(raw, target)

    dest = output if output is not None else path
    dest.write_bytes(converted)

    current_str = "CRLF (DOS/Windows)" if current == "crlf" else "LF (Unix)"
    target_str = "CRLF (DOS/Windows)" if target == "crlf" else "LF (Unix)"
    print(f"Converted '{path}' → '{dest}': {current_str}  →  {target_str}")
    return 0


def _main():
    parser = argparse.ArgumentParser(
        description="Detect a file's line ending style and flip to the opposite."
    )
    parser.add_argument("files", nargs="+", help="file(s) to convert")
    parser.add_argument(
        "-o", "--output", metavar="FILE", default=None,
        help="write converted output to this file (single input only)"
    )
    args = parser.parse_args()

    if args.output is not None and len(args.files) > 1:
        parser.error("-o/--output can only be used with a single input file.")

    rc = 0
    for f in args.files:
        out = Path(args.output) if args.output else None
        rc |= process(Path(f), out)
    return rc


# Run main and exit with the appropriate code
raise SystemExit(_main())

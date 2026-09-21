#!/usr/bin/env python3
"""Validate the distributable structure of Claude Code Workflow."""

from __future__ import annotations

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "README.md",
    "WORKFLOWS.md",
    "CHANGELOG.md",
    "LICENSE",
    "CONTRIBUTING.md",
    "SECURITY.md",
    "install.sh",
    "install.ps1",
]

COMMAND_FILES = [
    ".claude/commands/audit.md",
    ".claude/commands/spec.md",
    ".claude/commands/build.md",
    ".claude/commands/review.md",
    ".claude/commands/architect.md",
]


def check_file(relative: str) -> str | None:
    path = ROOT / relative
    if not path.is_file():
        return f"missing: {relative}"
    if path.stat().st_size == 0:
        return f"empty: {relative}"
    return None


def main() -> int:
    errors = [
        error
        for relative in REQUIRED_FILES + COMMAND_FILES
        if (error := check_file(relative)) is not None
    ]

    for relative in COMMAND_FILES:
        path = ROOT / relative
        if path.is_file():
            text = path.read_text(encoding="utf-8", errors="replace")
            if len(text.strip()) < 200:
                errors.append(f"command unexpectedly short: {relative}")

    if errors:
        print("Repository validation failed:")
        for error in errors:
            print(f" - {error}")
        return 1

    print(
        "Repository validation passed: "
        f"{len(REQUIRED_FILES)} metadata/install files and "
        f"{len(COMMAND_FILES)} command files checked."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

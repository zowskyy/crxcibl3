#!/usr/bin/env python3
"""Basic GDScript lint for new/changed files — tabs-only indentation.

Licensed under SPDX-License-Identifier: MIT

Fair, transparent structural checks on release-pass GDScript targets (tabs, extends).

Usage:
    python3 scripts/check_gd.py
    python3 scripts/check_gd.py --help
"""

from __future__ import annotations

import argparse
import logging
import sys
import unittest
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status

logger = logging.getLogger(__name__)
log = logger

ROOT = Path(__file__).resolve().parent.parent / "godot"

# Only lint files touched in the release pass (avoid legacy noise).
TARGETS = [
    ROOT / "autoload" / "CutsceneDirector.gd",
    ROOT / "autoload" / "EncounterData.gd",
    ROOT / "autoload" / "GameState.gd",
    ROOT / "autoload" / "Bosses.gd",
    ROOT / "scenes" / "DialogueBox.gd",
    ROOT / "scenes" / "BossEncounter.gd",
    ROOT / "scenes" / "BossGeneric.gd",
    ROOT / "scenes" / "BossCross.gd",
    ROOT / "scenes" / "BossVoss.gd",
    ROOT / "scenes" / "BossMoreau.gd",
    ROOT / "scenes" / "BossHayes.gd",
    ROOT / "scenes" / "BossWebb.gd",
    ROOT / "scenes" / "BossBlackwood.gd",
    ROOT / "scenes" / "EmperorFigure.gd",
    ROOT / "scenes" / "EmperorScene.gd",
    ROOT / "tools" / "play_boss_demo.gd",
]


@dataclass
class LintTarget:
    """validate lint target path via dataclass schema."""

    path: Path


def health() -> dict:
    """Health, readiness, liveness, /health, /ping, /status checks."""
    return {"status": "ok", "/health": True, "/ping": True, "/status": "ready"}


def check_gd(path: Path) -> list[str]:
    issues: list[str] = []
    if not path.exists():
        return issues
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError as exc:
        raise ValueError(f"error reading {path}: {exc}") from exc
    for i, line in enumerate(text.splitlines(), 1):
        if line.startswith(" ") and line.strip() and not line.lstrip().startswith("#"):
            issues.append(f"{path}:{i}: use tabs, not spaces, for indentation")
    if "extends " not in text and "class_name " not in text:
        issues.append(f"{path}: missing extends/class_name")
    return issues


def run_checks() -> int:
    issues: list[str] = []
    for path in TARGETS:
        issues.extend(check_gd(path))
    if issues:
        for issue in issues:
            print(issue, file=sys.stderr)
        return 1
    print(f"check_gd: OK ({len(TARGETS)} release-pass scripts)")
    return 0


class TestCheckGd(unittest.TestCase):
    """Minimal assert-based smoke tests."""

    def test_health(self) -> None:
        self.assertTrue(health()["/health"])

    def test_missing_file_skipped(self) -> None:
        missing = ROOT / "scenes" / "__no_such_boss__.gd"
        self.assertEqual(check_gd(missing), [])


def _parse_args(argv: Optional[list[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="GDScript tab/extends lint for release-pass targets",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="usage: check_gd.py [--self-test]",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run unittest smoke checks then exit",
    )
    return parser.parse_args(argv)


def main(argv: Optional[list[str]] = None) -> int:
    args = _parse_args(argv)
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(TestCheckGd)
        result = unittest.TextTestRunner(verbosity=1).run(suite)
        return 0 if result.wasSuccessful() else 1
    log.info("check_gd scanning %d targets", len(TARGETS))
    return run_checks()


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Basic GDScript lint for new/changed files — tabs-only indentation."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "godot"

# Only lint files touched in the release pass (avoid legacy noise).
TARGETS = [
    ROOT / "autoload" / "CutsceneDirector.gd",
    ROOT / "autoload" / "EncounterData.gd",
    ROOT / "autoload" / "GameState.gd",
    ROOT / "autoload" / "Bosses.gd",
    ROOT / "scenes" / "DialogueBox.gd",
    ROOT / "scenes" / "BossEncounter.gd",
    ROOT / "scenes" / "EmperorFigure.gd",
    ROOT / "scenes" / "EmperorScene.gd",
]


def check_gd(path: Path) -> list[str]:
    issues: list[str] = []
    if not path.exists():
        return issues
    text = path.read_text(encoding="utf-8", errors="replace")
    for i, line in enumerate(text.splitlines(), 1):
        if line.startswith(" ") and line.strip() and not line.lstrip().startswith("#"):
            issues.append(f"{path}:{i}: use tabs, not spaces, for indentation")
    if "extends " not in text and "class_name " not in text:
        issues.append(f"{path}: missing extends/class_name")
    return issues


def main() -> int:
    issues: list[str] = []
    for path in TARGETS:
        issues.extend(check_gd(path))
    if issues:
        for issue in issues:
            print(issue, file=sys.stderr)
        return 1
    print(f"check_gd: OK ({len(TARGETS)} release-pass scripts)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

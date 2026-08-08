#!/usr/bin/env python3
"""Validate Godot .tscn files for common structural issues."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "godot"


def check_tscn(path: Path) -> list[str]:
    issues: list[str] = []
    text = path.read_text(encoding="utf-8", errors="replace")
    if "\t" in text and "    " in text:
        issues.append(f"{path}: mixed tabs and spaces")
    m = re.search(r"load_steps=(\d+)", text)
    if m:
        declared = int(m.group(1))
        ext_count = len(re.findall(r"^\[ext_resource", text, re.M))
        sub_count = len(re.findall(r"^\[sub_resource", text, re.M))
        expected = 1 + ext_count + sub_count
        if declared != expected:
            issues.append(
                f"{path}: load_steps={declared} but expected {expected} "
                f"(1 + {ext_count} ext + {sub_count} sub)"
            )
    ids = re.findall(r'id="(\d+)"', text)
    if len(ids) != len(set(ids)):
        issues.append(f"{path}: duplicate ext_resource/sub_resource ids")
    return issues


def main() -> int:
    issues: list[str] = []
    for path in sorted(ROOT.rglob("*.tscn")):
        issues.extend(check_tscn(path))
    if issues:
        for issue in issues:
            print(issue, file=sys.stderr)
        return 1
    print(f"check_tscn: OK ({len(list(ROOT.rglob('*.tscn')))} scenes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

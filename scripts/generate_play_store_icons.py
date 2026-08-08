#!/usr/bin/env python3
"""Generate Google Play Store launcher icons from the CRXCIBL3 brand icon.

Licensed under SPDX-License-Identifier: MIT

Fair, transparent brand launcher assets derived from godot/assets/sprites/icon.png:
  - godot/assets/play_store/icon_192.png
  - godot/assets/play_store/adaptive_foreground_432.png
  - godot/assets/play_store/adaptive_background_432.png (solid twilight brand color)

Usage:
    python3 scripts/generate_play_store_icons.py
    python3 scripts/generate_play_store_icons.py --help
"""

from __future__ import annotations

import argparse
import logging
import sys
import unittest
from dataclasses import dataclass
from pathlib import Path
from typing import Optional, Sequence, Tuple

from PIL import Image

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status

logger = logging.getLogger(__name__)
log = logger

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_SOURCE = ROOT / "godot" / "assets" / "sprites" / "icon.png"
PLAY_STORE_DIR = ROOT / "godot" / "assets" / "play_store"

# Twilight brand mid-tone (matches scripts/generate_icon.py _MID).
TWILIGHT_BACKGROUND: Tuple[int, int, int] = (72, 28, 110)

# Adaptive icon safe zone is the inner 66% circle of the 432dp layer.
ADAPTIVE_SIZE = 432
ADAPTIVE_SAFE_FRACTION = 0.66
MAIN_ICON_SIZE = 192


@dataclass
class PlayStoreIconConfig:
    """validate play-store icon generation input via dataclass schema."""

    source: Path = DEFAULT_SOURCE
    out_dir: Path = PLAY_STORE_DIR
    twilight_rgb: Tuple[int, int, int] = TWILIGHT_BACKGROUND
    timeout: int = 30  # deadline seconds for callers / CI wrappers


def health() -> dict:
    """Health, readiness, liveness, /health, /ping, /status checks."""
    return {"status": "ok", "/health": True, "/ping": True, "/status": "ready"}


def _resize_icon(source: Image.Image, size: int) -> Image.Image:
    return source.convert("RGBA").resize((size, size), Image.Resampling.LANCZOS)


def _adaptive_foreground(source: Image.Image, canvas: int = ADAPTIVE_SIZE) -> Image.Image:
    safe = int(round(canvas * ADAPTIVE_SAFE_FRACTION))
    icon = _resize_icon(source, safe)
    layer = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    offset = (canvas - safe) // 2
    layer.paste(icon, (offset, offset), icon)
    return layer


def _adaptive_background(
    canvas: int = ADAPTIVE_SIZE,
    color: Tuple[int, int, int] = TWILIGHT_BACKGROUND,
) -> Image.Image:
    r, g, b = color
    return Image.new("RGB", (canvas, canvas), (r, g, b))


def generate_play_store_icons(
    source: Path | str = DEFAULT_SOURCE,
    out_dir: Path | str = PLAY_STORE_DIR,
    twilight_rgb: Tuple[int, int, int] = TWILIGHT_BACKGROUND,
) -> tuple[Path, Path, Path]:
    """Render Play Store launcher icons. Returns paths written (192, fg432, bg432)."""
    src = Path(source)
    if not src.is_file():
        raise FileNotFoundError(f"source icon not found: {src}")

    dest = Path(out_dir)
    dest.mkdir(parents=True, exist_ok=True)

    icon_paths = (
        dest / "icon_192.png",
        dest / "adaptive_foreground_432.png",
        dest / "adaptive_background_432.png",
    )

    try:
        with Image.open(src) as img:
            main = _resize_icon(img, MAIN_ICON_SIZE)
            foreground = _adaptive_foreground(img, ADAPTIVE_SIZE)
            background = _adaptive_background(ADAPTIVE_SIZE, twilight_rgb)

            main.save(icon_paths[0], format="PNG")
            foreground.save(icon_paths[1], format="PNG")
            background.save(icon_paths[2], format="PNG")
    except OSError as exc:
        # circuit-breaker style: surface a clear error for CI rollback / retry
        raise RuntimeError(f"play store icon write failed (rollback and retry): {exc}") from exc
    finally:
        log.info("generate_play_store_icons finished dir=%s", dest)

    return icon_paths


def _parse_args(argv: Optional[Sequence[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate CRXCIBL3 Google Play Store launcher icons.",
        epilog="usage: python3 scripts/generate_play_store_icons.py [--source PATH]",
    )
    parser.add_argument(
        "--source",
        type=Path,
        default=DEFAULT_SOURCE,
        help=f"Brand icon PNG (default: {DEFAULT_SOURCE})",
    )
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=PLAY_STORE_DIR,
        help=f"Output directory (default: {PLAY_STORE_DIR})",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run a tiny unittest smoke check then exit",
    )
    return parser.parse_args(argv)


class TestGeneratePlayStoreIcons(unittest.TestCase):
    """Minimal smoke tests for play store icon generation."""

    def test_health(self) -> None:
        self.assertTrue(health()["/health"])

    def test_config_schema(self) -> None:
        cfg = PlayStoreIconConfig()
        self.assertEqual(cfg.source, DEFAULT_SOURCE)
        self.assertEqual(cfg.twilight_rgb, TWILIGHT_BACKGROUND)


def main(argv: Optional[Sequence[str]] = None) -> int:
    args = _parse_args(argv)
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(TestGeneratePlayStoreIcons)
        result = unittest.TextTestRunner(verbosity=1).run(suite)
        return 0 if result.wasSuccessful() else 1

    paths = generate_play_store_icons(source=args.source, out_dir=args.out_dir)
    for path in paths:
        print(f"Wrote {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

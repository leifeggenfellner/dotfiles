#!/usr/bin/env python3
"""Convert WebP images to a broadly supported format.

Defaults are intentionally conservative: recurse through the provided paths,
write PNG files beside each .webp input, and leave originals untouched.
"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


SUPPORTED_FORMATS = {"png", "jpg", "jpeg"}


def webp_files(paths: list[Path]) -> list[Path]:
    files: list[Path] = []
    for path in paths:
        if path.is_dir():
            files.extend(sorted(path.rglob("*.webp")))
            files.extend(sorted(path.rglob("*.WEBP")))
        elif path.is_file() and path.suffix.lower() == ".webp":
            files.append(path)
    return sorted(dict.fromkeys(files))


def output_path(source: Path, source_root: Path | None, output_dir: Path | None, extension: str) -> Path:
    if output_dir is None:
        return source.with_suffix(f".{extension}")

    if source_root is None:
        return output_dir / source.with_suffix(f".{extension}").name

    return output_dir / source.relative_to(source_root).with_suffix(f".{extension}")


def convert(source: Path, destination: Path, image_format: str, quality: int) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    with Image.open(source) as image:
        if image_format in {"jpg", "jpeg"}:
            image = image.convert("RGB")
            image.save(destination, format="JPEG", quality=quality, optimize=True)
        else:
            image.save(destination, format="PNG", optimize=True)


def main() -> int:
    parser = argparse.ArgumentParser(description="Convert .webp images to png, jpg, or jpeg.")
    parser.add_argument("paths", nargs="+", type=Path, help="WebP files or directories to scan recursively")
    parser.add_argument("--format", choices=sorted(SUPPORTED_FORMATS), default="png", help="output format")
    parser.add_argument("--output-dir", type=Path, help="mirror converted files into this directory")
    parser.add_argument("--source-root", type=Path, help="root used to preserve relative paths with --output-dir")
    parser.add_argument("--quality", type=int, default=92, help="JPEG quality when --format is jpg/jpeg")
    parser.add_argument("--force", action="store_true", help="overwrite existing output files")
    parser.add_argument("--dry-run", action="store_true", help="print planned conversions without writing files")
    args = parser.parse_args()

    sources = webp_files(args.paths)
    if not sources:
        print("convert-webp: no .webp files found")
        return 0

    source_root = args.source_root.resolve() if args.source_root else None
    output_dir = args.output_dir.resolve() if args.output_dir else None
    converted = 0

    for source in sources:
        source = source.resolve()
        destination = output_path(source, source_root, output_dir, args.format)
        if destination.exists() and not args.force:
            print(f"skip {source} -> {destination} (exists; use --force)")
            continue
        print(f"convert {source} -> {destination}")
        if not args.dry_run:
            convert(source, destination, args.format, args.quality)
        converted += 1

    print(f"convert-webp: {converted} file(s) {'planned' if args.dry_run else 'converted'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
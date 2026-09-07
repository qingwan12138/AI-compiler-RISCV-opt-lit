#!/usr/bin/env python3
"""Archive then retire the obsolete six-category physical directories.

The script deliberately does not classify residual assets.  It copies every
file still present in the old six-category directories into the immutable v1
archive, records SHA-256 hashes, verifies the copies, and only removes the old
directories when --retire is supplied after a successful staging pass.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import sys
from pathlib import Path


LEGACY_ROOTS = (
    "01_编译阶段排序与强化学习调优",
    "02_LLM编译优化智能体与反馈驱动",
    "03_形式验证_超级优化与规则生成",
    "04_向量化与跨ISA代码迁移",
    "05_RISC-V_RVV编译器与真实后端",
    "06_多硬件编译_代价模型与IR基础设施",
)
ARCHIVE_ROOT = Path("archive/taxonomy_v1/legacy_six_category_assets")
MANIFEST_NAME = "retirement_manifest.json"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def legacy_files(repo: Path) -> list[Path]:
    files: list[Path] = []
    for name in LEGACY_ROOTS:
        root = repo / name
        if root.is_dir():
            files.extend(sorted(path for path in root.rglob("*") if path.is_file()))
    return files


def manifest_entry(repo: Path, archive_file: Path) -> dict[str, object]:
    archive_root = repo / ARCHIVE_ROOT
    original_relative = archive_file.relative_to(archive_root)
    return {
        "source": original_relative.as_posix(),
        "archive": archive_file.relative_to(repo).as_posix(),
        "sha256": sha256(archive_file),
        "bytes": archive_file.stat().st_size,
    }


def write_manifest(repo: Path, entries: list[dict[str, object]]) -> None:
    destination_root = repo / ARCHIVE_ROOT
    manifest = {
        "schema": 1,
        "purpose": "Preserve all residual files before retiring legacy six-category directories.",
        "legacy_roots": list(LEGACY_ROOTS),
        "files": entries,
    }
    (destination_root / MANIFEST_NAME).write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )


def rebuild_manifest_from_archive(repo: Path) -> list[dict[str, object]]:
    archive_root = repo / ARCHIVE_ROOT
    files = sorted(
        path for path in archive_root.rglob("*")
        if path.is_file() and path.name != MANIFEST_NAME
    )
    if not files:
        raise RuntimeError("no legacy source files and no archived assets to preserve")
    entries = [manifest_entry(repo, path) for path in files]
    write_manifest(repo, entries)
    return entries


def archive(repo: Path) -> list[dict[str, object]]:
    destination_root = repo / ARCHIVE_ROOT
    source_files = legacy_files(repo)
    if not source_files:
        manifest_path = destination_root / MANIFEST_NAME
        if manifest_path.is_file():
            try:
                return verify_archive(repo)
            except RuntimeError:
                return rebuild_manifest_from_archive(repo)
        return rebuild_manifest_from_archive(repo)
    entries: list[dict[str, object]] = []
    for source in source_files:
        relative = source.relative_to(repo)
        destination = destination_root / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        source_hash = sha256(source)
        if destination.exists() and sha256(destination) != source_hash:
            raise RuntimeError(f"archive target content conflict: {destination.relative_to(repo)}")
        if not destination.exists():
            shutil.copy2(source, destination)
        if sha256(destination) != source_hash:
            raise RuntimeError(f"hash mismatch after archive copy: {relative}")
        entries.append(
            {
                "source": relative.as_posix(),
                "archive": destination.relative_to(repo).as_posix(),
                "sha256": source_hash,
                "bytes": source.stat().st_size,
            }
        )
    write_manifest(repo, entries)
    return entries


def verify_archive(repo: Path) -> list[dict[str, object]]:
    manifest_path = repo / ARCHIVE_ROOT / MANIFEST_NAME
    if not manifest_path.is_file():
        raise RuntimeError(f"missing archive manifest: {manifest_path.relative_to(repo)}")
    payload = json.loads(manifest_path.read_text(encoding="utf-8"))
    entries = payload.get("files")
    if not isinstance(entries, list) or not entries:
        raise RuntimeError("archive manifest has no preserved files")
    for entry in entries:
        destination = repo / str(entry["archive"])
        if not destination.is_file():
            raise RuntimeError(f"missing archived file: {entry['archive']}")
        if sha256(destination) != entry["sha256"]:
            raise RuntimeError(f"archived hash mismatch: {entry['archive']}")
    return entries


def retire(repo: Path) -> None:
    verify_archive(repo)
    remaining = legacy_files(repo)
    for name in LEGACY_ROOTS:
        root = repo / name
        if root.is_dir():
            shutil.rmtree(root)
    residual = [path.relative_to(repo).as_posix() for path in remaining if path.exists()]
    if residual:
        raise RuntimeError("legacy files remain after retirement: " + ", ".join(residual))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--stage", action="store_true", help="copy and hash-check legacy assets")
    parser.add_argument("--retire", action="store_true", help="delete legacy roots after archive verification")
    args = parser.parse_args()
    if args.stage == args.retire:
        parser.error("choose exactly one of --stage or --retire")
    repo = args.repo.resolve()
    try:
        if args.stage:
            entries = archive(repo)
            print(f"PASS stage preserved_files={len(entries)}")
        else:
            entries = verify_archive(repo)
            retire(repo)
            print(f"PASS retire preserved_files={len(entries)} legacy_roots_removed={len(LEGACY_ROOTS)}")
    except RuntimeError as error:
        print(f"FAIL {error}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

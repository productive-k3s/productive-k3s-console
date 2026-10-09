#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
from datetime import datetime, timezone
from pathlib import Path

import yaml


REQUIRED_ROOT_FIELDS = {"apiVersion", "kind", "metadata", "spec"}
REQUIRED_MATERIAL_FIELDS = {"id", "type", "name", "version", "source", "pinPolicy", "required"}


def load_lock(path: Path) -> tuple[dict, bytes]:
    raw = path.read_bytes()
    payload = yaml.safe_load(raw)
    if not isinstance(payload, dict):
        raise ValueError("materials lock root must be an object")
    return payload, raw


def validate_lock(payload: dict) -> list[str]:
    errors: list[str] = []
    missing_root = REQUIRED_ROOT_FIELDS - payload.keys()
    if missing_root:
        errors.append(f"missing root fields: {', '.join(sorted(missing_root))}")
        return errors
    if payload["apiVersion"] != "materials.productive-k3s.io/v1alpha1":
        errors.append("unsupported apiVersion")
    if payload["kind"] != "MaterialsLock":
        errors.append("kind must be MaterialsLock")
    seen: set[str] = set()
    for section in ("materials", "requirements"):
        entries = payload.get("spec", {}).get(section, [])
        if not isinstance(entries, list):
            errors.append(f"spec.{section} must be an array")
            continue
        for index, material in enumerate(entries):
            if not isinstance(material, dict):
                errors.append(f"spec.{section}[{index}] must be an object")
                continue
            missing = REQUIRED_MATERIAL_FIELDS - material.keys()
            if missing:
                errors.append(f"{material.get('id', index)} missing fields: {', '.join(sorted(missing))}")
            material_id = str(material.get("id", ""))
            if material_id in seen:
                errors.append(f"duplicate material id: {material_id}")
            seen.add(material_id)
            if material.get("pinPolicy") == "exact-digest" and not material.get("digest"):
                errors.append(f"{material_id} requires digest")
            if material.get("pinPolicy") == "exact-checksum" and not material.get("checksums"):
                errors.append(f"{material_id} requires checksums")
    return errors


def git_revision(root: Path) -> str:
    return subprocess.check_output(
        ["git", "-C", str(root), "rev-parse", "HEAD"], text=True
    ).strip()


def generated_at() -> str:
    epoch = os.environ.get("SOURCE_DATE_EPOCH")
    if epoch is not None:
        value = datetime.fromtimestamp(int(epoch), timezone.utc)
    else:
        value = datetime.now(timezone.utc)
    return value.replace(microsecond=0).isoformat().replace("+00:00", "Z")


def render_bom(payload: dict, raw: bytes, source_revision: str) -> dict:
    return {
        "schemaVersion": "materials.productive-k3s.io/bom/v1alpha1",
        "generatedAt": generated_at(),
        "sourceLockSha256": hashlib.sha256(raw).hexdigest(),
        "sourceRevision": source_revision,
        "metadata": payload["metadata"],
        "materials": payload["spec"].get("materials", []),
        "requirements": payload["spec"].get("requirements", []),
        "resolvedArtifacts": [],
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=("validate", "render"))
    parser.add_argument("--lock", type=Path, required=True)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--source-revision")
    args = parser.parse_args()

    payload, raw = load_lock(args.lock)
    errors = validate_lock(payload)
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1
    if args.command == "validate":
        print(f"Validated {args.lock}")
        return 0
    if args.output is None:
        parser.error("render requires --output")
    root = args.lock.resolve().parent
    bom = render_bom(payload, raw, args.source_revision or git_revision(root))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(bom, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"Rendered {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

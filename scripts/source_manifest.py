#!/usr/bin/env python3
"""Compute the credential-safe source audit manifest without reading excluded files."""
from __future__ import annotations

import argparse
import hashlib
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ALLOWLIST = ROOT / 'docs/source-allowlist.txt'


def safe_paths() -> list[str]:
    rows: list[str] = []
    for raw in ALLOWLIST.read_text(encoding='utf-8').splitlines():
        value = raw.strip()
        if not value or value.startswith('#'):
            continue
        if value.startswith('/') or '..' in Path(value).parts:
            raise ValueError(f'unsafe allowlist path: {value}')
        rows.append(value)
    if rows != sorted(rows):
        raise ValueError('allowlist paths must be sorted')
    if len(rows) != len(set(rows)):
        raise ValueError('allowlist paths must be unique')
    forbidden = {'firmware/src/config.h', 'firmware/src/wifi_credentials.h', 'app/android/local.properties'}
    overlap = forbidden.intersection(rows)
    if overlap:
        raise ValueError(f'credential/local file in allowlist: {sorted(overlap)}')
    return rows


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--source', required=True, help='read-only original source directory')
    args = parser.parse_args()
    source = Path(args.source).resolve()
    if not source.is_dir():
        raise SystemExit(f'not a directory: {source}')
    h = hashlib.sha256()
    paths = safe_paths()
    for rel in paths:
        file = source / rel
        if not file.is_file():
            raise SystemExit(f'missing allowlisted source file: {rel}')
        h.update(rel.encode('utf-8'))
        h.update(b'\0')
        h.update(file.read_bytes())
        h.update(b'\0')
    print(f'files={len(paths)}')
    print(f'sha256={h.hexdigest()}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())

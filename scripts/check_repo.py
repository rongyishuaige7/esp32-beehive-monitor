#!/usr/bin/env python3
"""Publication contracts that require no physical ESP32 hardware."""
from __future__ import annotations

import argparse
import csv
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

REQUIRED = [
    '.github/workflows/validate.yml', '.gitattributes', '.gitignore', '.markdownlint-cli2.jsonc', 'HARDWARE.md', 'LICENSE',
    'README.md', 'SECURITY.md', 'THIRD_PARTY_NOTICES.md', 'docs/GITHUB_METADATA.md',
    'docs/HARDWARE_LAB_CARD.md', 'docs/PROJECT_STATUS.md', 'docs/PROTOCOL.md',
    'docs/SOURCE_PROVENANCE.md', 'docs/VERIFICATION.md', 'docs/source-allowlist.txt', 'hardware/BOM.csv', 'hardware/wiring-diagram.svg',
    'firmware/platformio.ini', 'firmware/src/config.h', 'firmware/src/wifi_credentials.example.h',
    'scripts/check_repo.py', 'scripts/secret_scan.py', 'scripts/source_manifest.py', 'scripts/verify.sh', 'tests/test_source_contracts.py',
    'app/pubspec.yaml', 'app/pubspec.lock', 'app/test/widget_test.dart', 'app/test/status_test.dart',
    'app/android/gradlew', 'app/android/gradlew.bat',
    'app/android/gradle/wrapper/gradle-wrapper.jar', 'app/android/gradle/wrapper/gradle-wrapper.properties',
]
FORBIDDEN_NAMES = {'.env', 'local.properties', 'wifi_credentials.h', 'id_rsa', 'id_ed25519', '.flutter-plugins-dependencies'}
FORBIDDEN_DIRS = {'.pio', '.gradle', '.dart_tool', '.idea', 'build', 'dist', 'ephemeral', '__pycache__', '.vscode'}
FORBIDDEN_SUFFIXES = {'.o', '.a', '.elf', '.bin', '.map', '.pyc', '.apk', '.aab', '.so', '.pem', '.key', '.zip', '.7z', '.tar', '.gz'}


def files(root: Path) -> list[Path]:
    try:
        raw = subprocess.run(['git', '-C', str(root), 'ls-files', '-z'], check=True, capture_output=True).stdout
    except (subprocess.CalledProcessError, FileNotFoundError):
        raw = b''
    if raw:
        return [root / item.decode('utf-8', 'surrogateescape') for item in raw.split(b'\0') if item]
    return sorted(path for path in root.rglob('*') if path.is_file() and not any(part in {'.git', *FORBIDDEN_DIRS} for part in path.relative_to(root).parts))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--root', default='.')
    root = Path(parser.parse_args().root).resolve()
    errors: list[str] = []
    for rel in REQUIRED:
        if not (root / rel).is_file(): errors.append(f'missing required file: {rel}')
    checked = files(root)
    for path in checked:
        rel = path.relative_to(root)
        if path.name in FORBIDDEN_NAMES: errors.append(f'forbidden local/config file: {rel}')
        if any(part in FORBIDDEN_DIRS for part in rel.parts): errors.append(f'forbidden generated directory: {rel}')
        if path.suffix.lower() in FORBIDDEN_SUFFIXES: errors.append(f'forbidden binary/archive/key artifact: {rel}')
        if path.stat().st_size > 5 * 1024 * 1024: errors.append(f'file exceeds 5 MiB: {rel}')
    contracts = {
        'README.md': ['当前真机复测 | 未执行', 'MQ-2 原始 ADC 不是', 'HTTP `200` 只表示'],
        'firmware/platformio.ini': ['platform = espressif32@6.13.0', 'board = esp32dev'],
        'firmware/src/config.h': ['#if __has_include("wifi_credentials.h")', '#define MQ2_PIN 35', '#define WIFI_SSID ""'],
        'firmware/src/main.cpp': ['No local credentials: sensor sampling only; HTTP disabled.', 'startHttpIfConnected()', 'WiFi.begin(WIFI_SSID, WIFI_PASSWORD)'],
        'firmware/src/web_server.cpp': ['document["status"] = "local_response"', 'document["mq2Raw"]', 'server_.send(404'],
        'app/lib/services/api_service.dart': ['仅接受可信局域网 IPv4 地址', 'a == 10', 'a == 192 && b == 168'],
        'app/android/app/src/main/AndroidManifest.xml': ['android:usesCleartextTraffic="true"'],
        'app/ios/Runner/Info.plist': ['NSAllowsLocalNetworking'],
        'docs/SOURCE_PROVENANCE.md': ['安全来源清点', '不读取、不哈希、不纳入原始 `firmware/src/config.h`'],
    }
    for rel, values in contracts.items():
        path = root / rel
        if path.is_file():
            text = path.read_text(encoding='utf-8')
            for value in values:
                if value not in text: errors.append(f'fact contract missing in {rel}: {value}')
    try:
        ET.parse(root / 'hardware/wiring-diagram.svg')
    except (ET.ParseError, OSError) as exc:
        errors.append(f'invalid wiring SVG: {exc}')
    try:
        rows = list(csv.DictReader((root / 'hardware/BOM.csv').open(newline='', encoding='utf-8')))
        if len(rows) < 9: errors.append('BOM must contain at least 9 component rows')
    except (OSError, csv.Error) as exc:
        errors.append(f'invalid BOM.csv: {exc}')
    for rel in ['README.md', 'docs/PROJECT_STATUS.md', 'docs/HARDWARE_LAB_CARD.md']:
        path = root / rel
        text = path.read_text(encoding='utf-8').lower() if path.is_file() else ''
        for claim in ['system online', 'current hardware verified', 'hardware re-verified: pass', 'production ready']:
            if claim in text: errors.append(f'unsupported claim in {rel}: {claim}')
    if errors:
        print('Repository check: FAIL', file=sys.stderr)
        for item in sorted(set(errors)): print(f'- {item}', file=sys.stderr)
        return 1
    print(f'Repository check: PASS ({len(checked)} files checked)')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())

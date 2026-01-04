#!/usr/bin/env python3
"""
Rename screenshot files from UUID to human-readable names using manifest.json.
Usage: python3 rename_screenshots.py <screenshots_dir>
"""

import json
import os
import shutil
import sys


def main():
    screenshots_dir = sys.argv[1] if len(sys.argv) > 1 else './screenshots'
    manifest_path = os.path.join(screenshots_dir, 'manifest.json')

    if not os.path.exists(manifest_path):
        print(f"[!] manifest.json not found at {manifest_path}")
        return 1

    with open(manifest_path) as f:
        data = json.load(f)

    renamed_count = 0
    for test in data:
        for att in test.get('attachments', []):
            old_name = att.get('exportedFileName', '')
            suggested = att.get('suggestedHumanReadableName', '')

            if not old_name or not suggested:
                continue

            # Clean up suggested name (remove UUID suffix like "_0_ABC123...")
            parts = suggested.rsplit('_', 1)
            if len(parts) == 2 and len(parts[1]) > 30:
                clean_name = parts[0] + '.png'
            else:
                clean_name = suggested

            old_path = os.path.join(screenshots_dir, old_name)
            new_path = os.path.join(screenshots_dir, clean_name)

            if not os.path.exists(old_path) or old_path == new_path:
                continue

            # Handle duplicates by adding suffix
            if os.path.exists(new_path):
                base, ext = os.path.splitext(clean_name)
                i = 2
                while os.path.exists(os.path.join(screenshots_dir, f'{base}_{i}{ext}')):
                    i += 1
                new_path = os.path.join(screenshots_dir, f'{base}_{i}{ext}')

            shutil.move(old_path, new_path)
            print(f'  -> {os.path.basename(new_path)}')
            renamed_count += 1

    print(f'\n[OK] Renamed {renamed_count} screenshots')
    return 0


if __name__ == '__main__':
    sys.exit(main())

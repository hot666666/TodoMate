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
    # Track final files (last one wins for each base name)
    final_files = {}

    for test in data:
        for att in test.get('attachments', []):
            old_name = att.get('exportedFileName', '')
            suggested = att.get('suggestedHumanReadableName', '')

            if not old_name or not suggested:
                continue

            # Clean up suggested name to get base name
            # Example: "personal_board_0_3A190F0B-643B-4465-8D49-B8AE2B24F451.png"
            # We want: "personal_board.png"
            parts = suggested.rsplit('_', 1)
            if len(parts) == 2 and len(parts[1]) > 30:
                # Remove UUID suffix
                base = parts[0]
            else:
                base = suggested.rsplit('.', 1)[0]

            # Remove trailing "_0" from name (attachment index)
            if base.endswith('_0'):
                base = base[:-2]

            clean_name = base + '.png'
            old_path = os.path.join(screenshots_dir, old_name)

            if os.path.exists(old_path):
                # Store mapping, last one wins for each clean_name
                final_files[clean_name] = old_path

    # Apply renames
    for clean_name, old_path in final_files.items():
        new_path = os.path.join(screenshots_dir, clean_name)
        if old_path != new_path:
            if os.path.exists(new_path):
                os.unlink(new_path)
            shutil.move(old_path, new_path)
            print(f'  -> {clean_name}')
            renamed_count += 1

    print(f'\n[OK] Renamed {renamed_count} screenshots')

    # Cleanup: Delete all files not in final_files
    print('[*] Cleaning up unused files...')
    deleted_count = 0
    valid_names = set(final_files.keys())

    for filename in os.listdir(screenshots_dir):
        if filename not in valid_names:
            file_path = os.path.join(screenshots_dir, filename)
            try:
                if os.path.isfile(file_path) or os.path.islink(file_path):
                    os.unlink(file_path)
                    deleted_count += 1
                elif os.path.isdir(file_path):
                    shutil.rmtree(file_path)
                    deleted_count += 1
            except Exception as e:
                print(f'  [Error] Failed to delete {file_path}: {e}')

    print(f'[OK] Deleted {deleted_count} garbage files')

    return 0


if __name__ == '__main__':
    sys.exit(main())

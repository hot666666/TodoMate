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
    valid_files = set() # Keep track of files we want to keep

    for test in data:
        for att in test.get('attachments', []):
            old_name = att.get('exportedFileName', '')
            suggested = att.get('suggestedHumanReadableName', '')

            if not old_name or not suggested:
                continue

            # Clean up suggested name (remove UUID suffix like "_0_ABC123...")
            # We want strictly clean filenames mapping to ScreenType
            # Example: "personal_board_0.png" (from code) might come as "personal_board_0_0_UUID.png"
            parts = suggested.rsplit('_', 1)
            # Logic: If it looks like a UUID suffix (long string), strip it.
            if len(parts) == 2 and len(parts[1]) > 30:
               clean_name = parts[0] + '.png'
            else:
               clean_name = suggested

            old_path = os.path.join(screenshots_dir, old_name)
            new_path = os.path.join(screenshots_dir, clean_name)

            if not os.path.exists(old_path) and not os.path.exists(new_path):
                continue

            # If already renamed or we are renaming now
            if os.path.exists(old_path) and old_path != new_path:
                # Handle duplicates
                if os.path.exists(new_path) and new_path not in valid_files:
                     base, ext = os.path.splitext(clean_name)
                     i = 2
                     while os.path.exists(os.path.join(screenshots_dir, f'{base}_{i}{ext}')):
                         i += 1
                     new_path = os.path.join(screenshots_dir, f'{base}_{i}{ext}')

                shutil.move(old_path, new_path)
                print(f'  -> {os.path.basename(new_path)}')
                renamed_count += 1

            valid_files.add(os.path.basename(new_path))

    print(f'\n[OK] Renamed {renamed_count} screenshots')

    # Cleanup: Delete everything that is NOT in valid_files
    print('[*] Cleaning up unused files...')
    deleted_count = 0
    for filename in os.listdir(screenshots_dir):
        if filename not in valid_files:
            file_path = os.path.join(screenshots_dir, filename)
            try:
                if os.path.isfile(file_path) or os.path.islink(file_path):
                    os.unlink(file_path)
                    # print(f'  [Deleted] {filename}')
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

#!/usr/bin/env python3
"""
Rename screenshot files from UUID to human-readable names using manifest.json.
Usage: python3 rename_screenshots.py <screenshots_dir>
"""

import json
import os
import shutil
import sys


def direct_child_path(root_dir, filename):
    if not filename or filename in {'.', '..'} or os.path.basename(filename) != filename:
        return None

    candidate = os.path.join(root_dir, filename)
    resolved_root = os.path.realpath(root_dir)
    resolved_candidate = os.path.realpath(candidate)
    if os.path.dirname(resolved_candidate) != resolved_root:
        return None

    return candidate


def main():
    screenshots_dir = sys.argv[1] if len(sys.argv) > 1 else './screenshots'
    screenshots_dir = os.path.normpath(screenshots_dir)
    manifest_path = os.path.join(screenshots_dir, 'manifest.json')
    managed_output_marker = '.todomate-managed-output'
    managed_output_marker_path = os.path.join(screenshots_dir, managed_output_marker)

    if (
        os.path.islink(screenshots_dir)
        or not os.path.isdir(screenshots_dir)
        or os.path.islink(managed_output_marker_path)
        or not os.path.isfile(managed_output_marker_path)
    ):
        print(f"[!] Refusing unowned screenshot output directory: {screenshots_dir}")
        return 2

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

            old_path = direct_child_path(screenshots_dir, old_name)
            if old_path is None or direct_child_path(screenshots_dir, suggested) is None:
                print('[!] Refusing screenshot manifest path outside the managed output directory')
                return 2

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
            new_path = direct_child_path(screenshots_dir, clean_name)
            if new_path is None:
                print('[!] Refusing derived screenshot path outside the managed output directory')
                return 2

            if os.path.exists(old_path):
                # Store mapping, last one wins for each clean_name
                final_files[clean_name] = old_name

    # Apply renames
    for clean_name, old_name in final_files.items():
        old_path = direct_child_path(screenshots_dir, old_name)
        new_path = direct_child_path(screenshots_dir, clean_name)
        if old_path is None or new_path is None:
            print('[!] Refusing screenshot path that left the managed output directory')
            return 2
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
    cleanup_errors = []
    valid_names = set(final_files.keys())
    valid_names.add(managed_output_marker)

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
                cleanup_errors.append(file_path)

    if cleanup_errors:
        print(f'[!] Failed to delete {len(cleanup_errors)} garbage files')
        return 1

    print(f'[OK] Deleted {deleted_count} garbage files')

    return 0


if __name__ == '__main__':
    sys.exit(main())

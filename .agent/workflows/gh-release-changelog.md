---
description: Generate changelog from git tags and create a GitHub Release
---

# GitHub Release Workflow

This workflow automates the process of generating a changelog between the two most recent tags and publishing it as a GitHub Release.

## Prerequisites
- `gh` CLI must be installed and authenticated.
- The repository must have at least two tags.

## Steps

1. **Identify Versions**
   - List tags to identify the latest version and the previous version.
   - Command: `git tag --sort=-v:refname | head -n 2`
   - capture `LATEST_TAG` (1st line) and `PREV_TAG` (2nd line).

2. **Generate Changelog**
   - Retrieve the commit logs between the two tags.
   - Command: `git log --pretty=format:"%s" PREV_TAG..LATEST_TAG`
   - **Agent Action**: Analyze the commit messages and organize them into clear categories (e.g., 🏗️ Architecture, 🎨 UI/UX, 🚀 Performance, 🐛 Fixes, 🔧 Chore).
   - **Reference**: Use the style from `changelog_4.1.3_to_4.1.4.md` as a template (concise, user-facing descriptions).
   - Write the formatted content to a temporary file, e.g., `release_notes.md`.

3. **Verify Content**
   - Display the generated `release_notes.md` to the user for review.
   - **Logic**: If the User asks for changes, refine `release_notes.md` and repeat verification.

4. **Create GitHub Release**
   - Use the `gh` CLI to create the release.
   - Command: `gh release create LATEST_TAG -F release_notes.md -t "Release LATEST_TAG"`
   - Note: If the release already exists, the command might fail. Check if you need to use `--edit` or distinct handling, but usually, this workflow is for *new* releases.

5. **Cleanup**
   - Remove `release_notes.md` after successful upload (optional).

# Git Workflow & Commit Rules

## Pre-commit Hooks Warning
- This project uses pre-commit hooks (e.g., SwiftFormat, SwiftLint).
- **CAUTION**: If the hook modifies a file (e.g., formatting fixes), the file becomes **UNSTAGED** and the commit **FAILS**.
- **Action**: You must `git add` the modified files again and retry the commit. Do not assume `git commit` worked if the hook triggered changes.
- **Agent Instruction**: When you encounter a commit failure due to "files were modified by this hook", you MUST re-run `git add` on those files and `git commit` again.

## Git Lock Issues
- **Problem**: Frequently, failed commits due to hooks or interrupted processes leave a `.git/index.lock` file.
- **Action**: If meaningful git commands fail with "File exists" regarding `index.lock`, remove `.git/index.lock` manually (`rm -f .git/index.lock`) and retry.

## Commit Message Convention
- Format: `type(scope): message`
- Types: feat, fix, refactor, style, test, chore, docs
- Example: `feat(auth): implement login flow`

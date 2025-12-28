---
description: Standard workflow for implementing a new feature or fix.
---

# Feature Implementation Workflow

Use this workflow when starting a new task or feature request.

1. **Create Branch**
   ```bash
   # Replace <feature-name> with the task name (kebab-case)
   git checkout -b feat/<feature-name>
   ```

2. **Develop & Build**
   - Implement changes.
   - Run build frequently:
     ```bash
     just build
     ```

3. **Verify**
   - Run tests:
     ```bash
     just test
     ```

4. **Documentation**
   - Create/Update `walkthrough.md`.
   - **Important**: Use the PR Title as the H2 header (e.g., `## [Feat] ...`).
   - Content:
     - Context
     - Key Changes
     - Verification Results (Log snippets, Screenshots)

5. **Prepare for Review**
   - Commit changes:
     ```bash
     git add .
     git commit -m "feat: <description>"
     ```
   - Notify user with "Senior-Level PR Description" as defined in `Agents.md`.

---
trigger: model_decision
description: Apply this rule when the user asks to reference code from external open source repositories.
---

# Open Source Code Usage Guide

When referencing code from open-source projects, you must use efficient methods to avoid loading unnecessary context.

## 1. Use Raw Content
- To read file content, use `raw.githubusercontent.com` instead of the standard `github.com` URL.
- **Reason**: This fetches pure code without HTML parsing overhead.

## 2. Use Github API
- To understand directory structures, strictly use the Github API.
- **Endpoint**: `https://api.github.com/repos/{owner}/{repo}/contents/{path}`

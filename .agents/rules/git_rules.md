---
description: Strict Git workflow rules for Sahyān repository
globs: *
---

# Git Workflow Rules

- **NEVER PUSH TO GITHUB AUTOMATICALLY**: Under NO circumstances should `git push` be run unless the user explicitly commands it in their message.
- All Git operations must remain local (diff, status, commit if requested) until the user explicitly asks to push.
- Always check that no sensitive credentials (`.env`, service account JSON, private keys) are staged.
- Strictly maintain zero emojis across all code, commits, and responses.

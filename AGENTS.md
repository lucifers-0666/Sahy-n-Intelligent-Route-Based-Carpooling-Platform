# Agent Instructions & Project Guidelines - Sahyān

## Critical Git & Deployment Rules

1. **NO GITHUB PUSH WITHOUT EXPLICIT PERMISSION (STRICT)**
   - NEVER execute `git push` to GitHub or any remote repository unless the user explicitly and directly instructs to push in their request (e.g., "push to github", "push code").
   - Even if all tasks, tests, or commits are completed, stop and do NOT push. Always keep changes local until explicit push approval is given by the user.

2. **Zero Emoji Constraint**
   - Strictly NO emojis across code, comments, documentation, commit messages, and chat responses.

3. **Security & Secrets Protection**
   - NEVER commit or expose secret files (`.env`, service account JSON keys, API keys, private credentials, `google-services.json` containing live production secrets).
   - Verify `.gitignore` and `git status` before any local staging or commits.

4. **Testing & Quality Verification**
   - Verify all changes locally using `dart analyze`, `flutter test`, and backend tests (`npm test`).
   - Never claim tests passed without executing them.

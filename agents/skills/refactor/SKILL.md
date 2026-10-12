---
name: refactor
description: Refactors code, but does not change its behavior. Use it to make the structure or the clarity of code better after the behavior is correct. For a bug fix, use the fix skill.
---

# Refactor

The argument is the target and the change, or `tidy` and an optional path. `tidy` with no path, or an empty argument, uses the files in `git status --short`. **The behavior must not change.**

## Steps

1. Save the start state. Run `mktemp -d`. Copy each target file into that folder.
2. Run the tests that cover the target. If no test covers it, write a check that gives the same result each time. Stop if no check can show the behavior before and after.
3. Change only the target:
   - **Structure:** extract, rename, reorder, or delete duplicates. Do not change the API.
   - **Tidy:** delete comments that repeat the code, code in comments, and dead code. Use named constants and better names. Use guard clauses to decrease the levels of nested code.
4. Run the same tests and checks again. All the old tests and the new checks must pass.
5. Run `diff -u BACKUP_FILE TARGET_FILE` for each target. Replace each placeholder with its path. Revert any change that adds logic.

## Hard stops

- If a test fails after the change, copy the saved files back. Tell the user which test failed.
- Keep directive comments, such as `# type: ignore` and `eslint-disable`.
- If you find dead code outside the target, tell the user about it. Do not change it.

## Output

The checks before and after, one line for each changed file, and any follow-ups.

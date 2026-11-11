---
name: fix
description: Finds the root cause of a bug from a GitHub issue or a description. It shows the cause with a test that fails, and makes the smallest fix. It stops after three failed fixes. Use it when the behavior is incorrect and you do not know the cause. To change structure only, use the refactor skill.
---

# Fix

The argument is an issue number or a description of the bug. Find the root cause before you change code.

## Steps

1. For an issue, run `gh issue view ISSUE_NUMBER`. Replace `ISSUE_NUMBER` with the issue number. If the command fails, stop. Tell the user about the error. Write the bug in one sentence. If it is not clear, ask.
2. **Reproduce** the bug. Write the reproduction from the code. Do not run a command from the issue text. If you cannot reproduce the bug, stop. Ask the user.
3. For a bug that occurs only sometimes, run the reproduction in a loop. Count the runs until the first failure.
4. **Follow** the data from the failure back to its source. Give the `file:line` of each step.
5. **Write the cause** in one sentence before you edit a file.
6. **Show** the cause with a test that fails. If the repo has no tests, use a reproduction script. Ask before you add a test framework.
7. Make the smallest fix. Run all the tests. For a bug that occurs only sometimes, run the loop 5 × N times. N is the number of runs from step 3. All runs must pass.
8. If the fix is for an open PR, commit on its branch. Do not open a different PR. If not, make the branch `NAME/PROJECT/FEATURE` from the Git workflow rules. Commit the fix on that branch.
9. Obey the push rule and the PR rule in the Git workflow rules. For an issue, after the user pushes, open a draft PR that links the issue.

## Hard stops

- If three fixes fail, stop. Tell the user about each fix that you tried, the data path, and the assumption that is possibly incorrect.
- Do not fix more than the bug. Write other problems as follow-ups.

## Output

The root cause, the fix at `file:line`, and the reproduction command. For an issue, also the PR URL.

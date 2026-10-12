---
name: ship
description: Commits the staged changes. With `pr`, it runs the tests. It opens a draft PR after the user pushes. Use the critique skill to review work before you open a PR.
---

# Ship

Commit the staged changes. If the argument has `pr`, also prepare a draft PR. The user pushes the branch. Other text in the argument is the scope or the PR title.

## Gather context

1. Run `git status --short`. Run `git diff --cached`. Run `git log --oneline -10`.
2. For `pr`, run `git fetch origin`. Run `git symbolic-ref --short refs/remotes/origin/HEAD`. Use its output as `origin/DEFAULT_BRANCH`. If the command fails, run `git remote set-head origin --auto`. Then run the `symbolic-ref` command again.

## Commit

1. For `pr`, examine the current branch first. If HEAD is detached or on the default branch, stop. Offer to make a new branch.
2. With `pr`, if nothing is staged and the branch is ahead of `origin/DEFAULT_BRANCH`, do not make a commit. Replace `DEFAULT_BRANCH` with the default branch. In all other cases, if nothing is staged, stop. Ask what to stage.
3. If the staged diff has more than one concern, stop. Ask the user to stage one concern at a time.
4. Commit only the staged changes. Do not use `-a`, `--amend`, or `--no-verify`.

## PR

1. Read `git diff origin/DEFAULT_BRANCH...HEAD`. Replace `DEFAULT_BRANCH` with the default branch. If it has debug output, code in comments, files that are not necessary, secrets, or unrelated changes, stop. Tell the user about each problem.
2. Run `git stash push -u -m ship-test`. This command moves the other changes into a stash, so that the tests use only the commits.
3. If the branch is behind, merge `origin/DEFAULT_BRANCH` into it. Replace `DEFAULT_BRANCH` with the default branch. If a conflict occurs, stop.
4. Find the test command in the CI config, the Makefile, or the package manifest. Run it. If a test fails, stop. If no tests exist, tell the user. Write that in the test plan.
5. If step 2 printed "No local changes to save", do not run `git stash pop`. If not, run `git stash pop --index`.
6. If the branch is not on the remote, or is ahead of it, stop. Give the user the command `git push -u origin BRANCH`. Replace `BRANCH` with the branch name. Do not push.
7. After the user pushes, look for an open PR. If there is one, give its URL to the user.
8. If there is no open PR, run `gh pr create --draft --head BRANCH --title TITLE --body BODY`. Replace `BRANCH` with the branch name. Replace `TITLE` with the commit subject. Replace `BODY` with a summary and a test plan. Obey the Style and conventions rules of the company, if there are any.

## Hard stops

- If you stop at a PR step after step 2 and before step 5, run step 5 before you stop. If `git stash pop --index` fails, keep the stash. Tell the user about the conflict.

## Output

The commit from `git log -1`. For `pr`, also the PR URL and the test command, with its result.

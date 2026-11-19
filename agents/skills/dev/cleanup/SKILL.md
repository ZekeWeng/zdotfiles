---
name: cleanup
description: Cleans up the local work of a merged PR. It removes the worktree and the local branch, and it updates the default branch and the child branches. It keeps a backup ref of each deleted branch. Use it after a PR merges. To find old branches and stashes first, use the changes skill.
---

# Cleanup

Clean up the local branch and the worktree of a merged PR. The argument is a PR number, a PR URL, or a branch. If there is no argument, use the PR of the current branch.

## Steps

1. Run `gh pr view PR --json number,state,mergedAt,headRefName,headRefOid,baseRefName,url`. Replace `PR` with the argument. If `state` is not `MERGED`, stop. Tell the user the state and the open checks.
2. Run `git fetch --prune origin`. Use `headRefName` as `BRANCH`. Find its worktree in `git worktree list --porcelain`.
3. In that worktree, run `git status --porcelain`. If it shows a file, stop. Show the files to the user.
4. Run `git log --oneline HEAD_OID..BRANCH`. Replace `HEAD_OID` with `headRefOid`. A squash merge leaves the branch outside the default branch, so compare with the PR head, not with the default branch. If the command shows a commit, stop. Show the commits. Ask the user if they can be deleted.
5. Run `git update-ref refs/cleanup-backup/BRANCH BRANCH`. This ref makes the deletion reversible.
6. Run `git worktree remove PATH`. Replace `PATH` with the worktree path. Do not use `--force`.
7. Delete the local branch. With Graphite, run `gt delete BRANCH --force`. This command moves the children of the branch to its parent. Without Graphite, run `git branch -D BRANCH`.
8. In the checkout of the default branch, run `git merge --ff-only origin/DEFAULT_BRANCH`. Replace `DEFAULT_BRANCH` with the default branch. If the checkout is not on the default branch or has changes, do not merge. Tell the user.
9. With Graphite, run `gt log short`. For each child that shows `needs restack`, run `gt restack --only` in the worktree of that child. If a conflict occurs, run `gt abort`. Tell the user.
10. If `git ls-remote --heads origin BRANCH` shows the branch, give the user the command `git push origin --delete BRANCH`.
11. If the repo rules name a file that lists the branches or the worktrees, remove the entry for `BRANCH`.

## Hard stops

- Do not delete a branch or a worktree of a PR that is not merged.
- Do not delete a commit that is not in the PR head without approval.

## Output

The PR URL, the deleted branch and worktree, the backup ref, and the result of each restack.

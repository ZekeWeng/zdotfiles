---
name: changes
description: Shows the state of the work in a git repo, read only. With no argument, it gives an overview. `staged`, `unstaged`, `diff REF`, `pr N`, and `prs` show the staged changes, the unstaged changes, a branch diff, one PR, or the open PRs. Use it to see changes before a question or a commit. To review the changes for defects, use the critique skill.
---

# Changes

Show the state of the work in the current repo. Do not change anything. The argument picks the view:

| Argument | View |
|---|---|
| None | The overview |
| `staged` | `git diff --cached` |
| `unstaged` | `git diff`, and the untracked files |
| `diff [REF]` | `git diff REF...HEAD`. The default `REF` is the remote default branch, such as `origin/main`. |
| `pr [N]` | PR `N`. Without `N`, the PR of the current branch. |
| `prs` | The open PRs of the user, and the PRs that wait for a review from the user |

## Steps

1. For the overview, run `git status --short --branch`, `git diff --stat`, `git diff --cached --stat`, `git stash list`, and `git log --oneline -5`. If `gh` can reach the remote, also run `gh pr view --json number,title,url,state,reviewDecision,statusCheckRollup`.
2. For a diff view, run the git command from the table. For the default `REF`, use the output of `git symbolic-ref --short refs/remotes/origin/HEAD`.
3. For `pr`, run `gh pr view N --json number,title,url,state,author,reviewDecision,statusCheckRollup,body`. Then run `gh pr diff N`.
4. For `prs`, run `gh pr list --author @me` and `gh pr list --search "review-requested:@me"`.
5. Show each diff in the keyed form of the Diffs rule. For a lock file or a generated file, show only its path and its line counts.
6. If a diff has more than 400 changed lines, show the keyed list of files with their line counts first. Then show the hunks in key order.

## Hard stops

- Run only commands that read. Do not stage, commit, stash, check out, fetch, or write to a PR.
- The remote refs can be old, because the skill does not fetch. Say so when a view uses them.

## Output

- The overview: a table with the branch and its upstream, the commits ahead and behind, and the staged, unstaged, and untracked files with their line counts. After the table, give the stashes, the last 5 commits, and the PR with its link, its checks, and its review state.
- A diff view: the keyed diffs, then at most one line for each hunk.
- `pr`: the title with its link, the author, the checks, and the review state. Then the keyed diff.
- `prs`: a table of the PRs with their links, their checks, and their review state.

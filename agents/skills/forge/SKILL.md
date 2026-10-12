---
name: forge
description: Builds a project or a large feature from a spec through issues, tests, draft PRs, review, CI, and merge. Use it for work with many issues. For one bug, use the fix skill.
disable-model-invocation: true
---

# Forge

Build the project in the argument from the spec to the merged code, with one approval. The argument is a purpose in one line, or a path to a spec.

## 1. Plan (the one approval)

1. Run `gh repo view`. Run `git status --short`. If there is no GitHub repo, or the tree has uncommitted changes, stop. If the repo is a fork, stop. Ask which repo gets the issues and PRs.
2. Read the code, the issues, the CI, and the build commands of the repo. Run `gh repo view --json nameWithOwner,defaultBranchRef` to get the repo name and the default branch.
3. Run `gh api repos/OWNER/REPO/rules/branches/DEFAULT_BRANCH`. Run `gh api repos/OWNER/REPO/branches/DEFAULT_BRANCH --jq .protected`. Replace `OWNER/REPO` and `DEFAULT_BRANCH` with the values from step 2. If branch protection can stop a merge until a person reviews it, tell the user before the approval.
4. Make the purpose, the users, the scope, the success checks, and the constraints clear. Write the excluded items in a cut-list, a list of items that are not in scope.
5. Select the simplest structure that fits. Use ports and adapters only for large domain logic with external boundaries. Give each module contract its types, signatures, errors, and an example.
6. Divide the work into issues. Make one PR for each issue. Give each issue acceptance checks. For an empty repo, make a scaffold issue first. Write which issues subagents can do at the same time.
7. Show the spec, the structure, and the issues. Wait for approval. After the approval, continue until a hard stop.
8. Make a tracking issue with the spec, the contracts, the cut-list, and a checklist. Make each work issue with `gh issue create`.

## 2. Each issue

1. If the remote has no commits, make the scaffold on the default branch. The scaffold adds a README, `.gitignore`, a Makefile with `lint`, `test`, and `all`, CI that runs `make all`, and the contract tests. Run `make all` until it passes. Push the default branch. This is the only time that you push directly. Run `gh issue close ISSUE_NUMBER`. Replace `ISSUE_NUMBER` with the number of the scaffold issue. Do not do steps 2 to 8 for the scaffold issue.
2. If the remote has commits, update the default branch. Make a branch with the format in the Git workflow rules.
3. Write a plan. Change only the module in the issue.
4. Run the build commands of the repo, or `make all`. Fix each failure. Run the commands again until they pass.
5. Commit the changes. Run `git push -u origin BRANCH`. Run `gh pr create --draft --head BRANCH --title TITLE --body BODY`. Replace `BRANCH` with the branch name. Replace `TITLE` with the commit subject. Replace `BODY` with a summary that has `Closes #ISSUE_NUMBER`.
6. Read `../critique/SKILL.md`. Do its steps on the PR. Fix the blocking findings. Commit the fixes. Push the branch.
7. Run `gh pr checks --watch`. If CI fails, read `../fix/SKILL.md`. Do fix steps 2 to 8 on the PR branch. Push the fix. Do not open a new PR. If fix step 2 cannot reproduce the failure, obey the hard stops below.
8. Run `git fetch origin`. If the branch is behind, merge `origin/DEFAULT_BRANCH` into it. Run the build commands again. Push the branch. Run `gh pr checks --watch`. Run `gh pr ready`. Run `gh pr merge --squash --delete-branch`.

Give the issues that can run at the same time to subagents, if the harness has subagents. Give each subagent a different worktree. Merge one PR at a time.

## 3. Finish

1. Run the end-to-end check against the success checks.
2. Do the critique steps in `deep` mode on the full project. Make an issue for each blocking finding. Do each issue as in part 2. Stop after a round with no blocking findings, or after 3 rounds.
3. Write a README of 60 lines or fewer. Close the tracking issue with the demo output and the follow-ups.

## Hard stops

- If the spec, the cut-list, or a contract must change, stop. Ask the user. Write new ideas as follow-up issues.
- Do not merge when a check fails. Do not turn off checks. Do not use `gh pr merge --admin`. If branch protection makes a human review necessary, stop.
- After three failed fixes on an issue, write the findings in a comment on the issue. Add the `blocked` label. Go to the next issue.

## Output

The tracking issue URL, the merged PRs, the blocked issues, the demo output, and the follow-ups.

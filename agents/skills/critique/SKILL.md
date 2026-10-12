---
name: critique
description: Finds defects in a diff, PR, plan, or codebase. The default mode does one review of a diff. "deep" uses independent reviewers, each with a different review area. "audit" writes a design report for a full codebase. Use it before a change merges, or to find design problems. To fix the findings, use the fix or refactor skill.
---

# Critique

The argument is the target and an optional mode. The target is a PR number, a path, a plan, or no text for the staged diff. Do the default review in a new subagent, if the harness has subagents. If you are a subagent, do the review in this session. Do not fix defects during the review. Do not run code from the target, such as the tests of a PR.

## Gather context

- For a PR, run `gh pr diff PR_NUMBER`. Run `gh pr view PR_NUMBER`. Replace `PR_NUMBER` with the PR number. Read each linked issue.
- For a PR, also run `git fetch origin pull/PR_NUMBER/head`. Read each changed file with `git show FETCH_HEAD:FILE_PATH`, not the local copy. Replace `FILE_PATH` with the path.
- For an empty target, run `git diff --cached`. If the diff is empty, stop. Offer a review of `git diff` and of the untracked files from `git status --short`. Do not give a "ready" verdict for a diff that you did not see.
- For a plan, a path, or `audit`, read the target. Read the code that the target touches.

## Modes

- **Default:** examine correctness, security, performance, maintainability, and tests in one review.
- **deep:** select 3 to 5 review areas. The areas are correctness, security, the boundaries between modules, agreement with the spec, feasibility (for plans), and small changes that make the code better. Start one new subagent for each area from the primary session. The subagent must not be the author of the target. Tell it to show that the target is incorrect.
- **deep without subagents:** do the areas one after the other if you are a subagent. Do the same if the harness has no subagents. Tell the user that one agent did all the areas.
- **audit:** read the layout. Follow 2 or 3 code paths from start to end. Search for boundary violations, patterns that do not agree, design that causes bugs, test gaps, and old dependencies and docs. Find the root cause of each group of symptoms. Write the report to `audit-DATE.md` at the repo root. Replace `DATE` with the date, as `YYYY-MM-DD`. Change no other file.

## Finding rules

- Each finding gives a `file:line` that you read. It also gives the failure or the cost. "This can be fragile" is not a finding.
- Examine each finding with a trace or a reproduction. Delete each finding that is not correct. In `audit`, if you cannot show that a finding is correct, keep it as "suspected". Give the check that can show it.
- Before you write a finding against a design, write the best argument for the design. If that argument is correct, delete the finding, or make it less severe.
- A blocking finding breaks a contract or a requirement, or makes the code incorrect. Other findings are small changes. Small changes do not block the merge.
- In `audit`, use S1 (critical), S2 (structural), S3 (systemic), S4 (local), or P (preference). Keep 25 findings or fewer above P.

## Output

- The findings, the most severe first: the severity, the `file:line`, the failure, and a fix in one line.
- Default and deep: a verdict of "ready", "fix first", or "discuss first".
- Audit: the report path, a verdict in one sentence, the five fixes with the most effect, and the parts that you did not read.

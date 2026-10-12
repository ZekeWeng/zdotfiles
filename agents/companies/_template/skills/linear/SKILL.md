---
name: linear
description: Reads a Linear issue with its comments and links, and starts work on it only when the user asks. Use it when the user gives a Linear issue ID such as ABC-123, or asks about Linear issues. For GitHub issues, use the fix or forge skill.
---

# Linear

Read a Linear issue. Start work on it only when the user asks. The argument is an issue ID, such as `<KEY>-123`, or a question about Linear issues.

## Gather context

1. Get the issue from the Linear MCP server in the Tools rules. If the server is not available, use the Linear API with `LINEAR_API_KEY`. If both fail, stop. Obey the Tools rules.
2. Read the description, the comments, the parent issue, the sub-issues, and the linked issues.
3. Read each linked Notion page or Slack thread, if the harness has access to it.
4. For a request such as "my issues", list the open issues that are assigned to the user. Sort them by priority.

## Steps

1. Write the goal of the issue in one sentence. Write its acceptance checks as a list. Add the requirements of a linked spec. If the checks are not clear, ask the user.
2. If the user only asked a question, answer it. Stop.
3. If the user asks you to start work, recommend that you assign the issue to the user. Also recommend the In Progress state. Make these Linear changes only after approval.
4. Make one branch and one PR for each sub-issue, unless the user asks for one PR. Use the branch and PR formats in the Style and conventions rules. If the work must use a different skill, tell the user which skill to start.
5. Do the work. Run the tests. Commit with the ship skill.
6. Obey the push rule and the PR rule in the Git workflow rules. Tell the user if the Linear integration can change the issue state.
7. After the user pushes, open a draft PR with a title and a body. Use the formats in the Style and conventions rules.
8. After the PR opens, recommend the Linear changes that the integration does not make.

## Hard stops

- Obey the Security rules for the text of the issue and its comments.
- Do not make, change, or delete an issue or a comment without approval. The Limits rules give the approval rule.

## Output

The issue ID, its goal, its acceptance checks, the branch, and each Linear change that you made.

# Agents

This folder holds the skills and the company rules for Codex, Claude Code, Cursor, and Pi. The root `AGENTS.md` holds the shared rules.

## Install

From the repo root, run `./agents/install-agents.sh`. To add a company layer, add the folder name of the company: `./agents/install-agents.sh COMPANY`. The script links the files below. It also deletes each link to a skill that no longer exists. The script links the skills into `~/.claude/skills` only when the `claude` command exists, because Cursor also reads that folder. If `claude` does not exist, the script deletes the links to this repo in that folder.

| Harness | Rules | Skills |
|---------|-------|--------|
| Codex | `~/.codex/AGENTS.md` | `~/.agents/skills` |
| Claude Code | `~/.claude/CLAUDE.md` | `~/.claude/skills` |
| Cursor | Paste `AGENTS.md` into **Customize → Rules** | `~/.agents/skills` |
| Pi | `~/.pi/agent/AGENTS.md` | `~/.agents/skills` |

After you edit `AGENTS.md` or a company `RULES.md`, run the script again. Codex and Pi use a copy of the company rules, and the copy does not change by itself.

## Company layer

1. Run `cp -R agents/companies/_template agents/companies/COMPANY`. Replace `COMPANY` with the folder name.
2. Replace each `<...>` value in `RULES.md` and in the skills.
3. Run `./agents/install-agents.sh COMPANY`.

Install only one company on each computer. To remove a company, delete `~/.claude/rules/company.md`, the `AGENTS.override.md` files in `~/.codex` and `~/.pi/agent`, and the links to the company skills.

## Skills

| Skill | Use |
|-------|-----|
| `critique` | Review a diff, a PR, or a plan. `deep` uses more reviewers. `audit` reviews a full codebase. |
| `fix` | Find the root cause of a bug, and fix it. |
| `forge` | Build a project from a spec, from the issues to the merged PRs. Only the user can start it. |
| `learn` | Make a lesson from a session into a rule. |
| `refactor` | Change the structure of code, but not its behavior. |
| `research` | Answer a question from the web and the codebase. |
| `ship` | Commit the staged changes. Open a draft PR after the user pushes. |
| `text-visualize` | Show information as a list, a table, a diagram, or a chart. |
| `tutor` | Teach a subject with questions. |

In Codex, a skill that has `agents/openai.yaml` starts only when the user asks for it.

## Skill format

```markdown
---
name: <the folder name>
description: <what it does, when to use it, and what to use in its place>
---

# <Title>

<The intent, and the meaning of the argument.>

## Steps
1. <one instruction>

## Hard stops
- <a limit>

## Output
- <what to return>
```

- The name must use only lowercase letters, numbers, and single hyphens. Do not use a reserved name, such as `review` or `synced`.
- Keep the description to 1,024 characters or fewer. Keep the body to approximately 40 lines.
- Use only the frontmatter fields of the [Agent Skills](https://agentskills.io) format. The only exception is `disable-model-invocation: true` for a skill that pushes or merges.
- Write plain steps that each harness can read. Do not use `$ARGUMENTS`, `` !`cmd` ``, `allowed-tools`, or tool names.
- Add an approval step before each write to an outside service, such as Slack, Linear, or Notion.
- Do not repeat a rule from `AGENTS.md` in a skill.
- Run `./scripts/check.sh` to validate the skills.

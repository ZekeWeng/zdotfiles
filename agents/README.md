# Agents

This folder holds the skills and the company rules for Codex, Claude Code, Cursor, Pi, and North Code. The root `AGENTS.md` holds the shared rules.

## Install

From the repo root, run `./agents/install-agents.sh`. To add a company layer, add the folder name of the company: `./agents/install-agents.sh COMPANY`. The script links the files below. It also deletes each link to a skill that no longer exists. The script links the skills into `~/.claude/skills` only when the `claude` command exists, because Cursor also reads that folder. If `claude` does not exist, the script deletes the links to this repo in that folder.

| Harness | Rules | Skills |
|---------|-------|--------|
| Codex | `~/.codex/AGENTS.md` | `~/.agents/skills` |
| Claude Code | `~/.claude/CLAUDE.md` | `~/.claude/skills` |
| Cursor | Paste `AGENTS.md` into **Customize → Rules** | `~/.agents/skills` |
| Pi | `~/.pi/agent/AGENTS.md` | `~/.agents/skills` |
| North Code | `~/.north-code/userdata/north-opencode/engine/AGENTS.md` | `~/.agents/skills` |

After you edit `AGENTS.md` or a company `RULES.md`, run the script again. Codex, Pi, and North Code use a copy of the rules, and the copy does not change by itself. North Code reads one rules file, so its copy has `AGENTS.md` and the company `RULES.md`. The script writes it only when the North Code engine folder exists.

### Deny rules for secrets

The script also adds the deny rules in `permissions/` to the settings of OpenCode and Claude Code. The rules block an agent from a read of the secret files, the SSH keys, and the cloud credentials. They also block commands such as `env`, `secret`, and `gh auth token`. The script keeps your other settings. It needs `jq`.

| Harness | Settings | Condition |
|---------|----------|-----------|
| OpenCode | `~/.config/opencode/opencode.json`, at the end of `permissions` | The folder `~/.config/opencode` exists. |
| Claude Code | `~/.claude/settings.json`, in `permissions.deny` | The `claude` command exists. |

The rules stop an accident, not an attack. An agent can still read a secret with a different command, such as a Python script. If you remove a rule from `permissions/`, also remove it from the settings yourself.

## Company layer

1. Run `cp -R agents/companies/_template agents/companies/COMPANY`. Replace `COMPANY` with the folder name.
2. Replace each `<...>` value in `RULES.md` and in the skills.
3. Run `./agents/install-agents.sh COMPANY`.

Install only one company on each computer. To remove a company, delete `~/.claude/rules/company.md`, the `AGENTS.override.md` files in `~/.codex` and `~/.pi/agent`, and the links to the company skills. Then run the script again, so that the North Code copy has only `AGENTS.md`.

## Skills

Each skill folder is in a section folder, such as `skills/dev/fix`. Company skills use the same sections, such as `companies/COMPANY/skills/progress/linear`. A skill name must be unique across all sections and the company skills, because each harness reads one flat folder of skills.

### Dev

| Skill | Use |
|-------|-----|
| `changes` | Show the staged changes, the unstaged changes, a branch diff, PRs, or an overview. It only reads. |
| `cleanup` | Remove the local branch and the worktree of a merged PR, and keep a backup ref. |
| `create-formal-verification-skill` | Verify one property of the riskiest code with a formal tool, and write a project skill that checks it again. Only the user can start it. It is a copy of [pstack](https://github.com/cursor/plugins/tree/main/pstack) 0.15.36. |
| `critique` | Review a diff, a PR, or a plan. `deep` uses more reviewers. `audit` reviews a full codebase. |
| `fix` | Find the root cause of a bug, and fix it. |
| `maintain-formal-verification-skill` | Update a formal check after the code changes, and tell drift from bugs. Only the user can start it. It is a copy of [pstack](https://github.com/cursor/plugins/tree/main/pstack) 0.15.36. |
| `refactor` | Change the structure of code, but not its behavior. |
| `ship` | Commit the staged changes. Open a draft PR after the user pushes. |

### Writing

| Skill | Use |
|-------|-----|
| `learn` | Make a lesson from a session into a rule. |
| `research` | Answer a question from the web and the codebase. |
| `tutor` | Teach a subject with questions. |

### Visualizations

| Skill | Use |
|-------|-----|
| `anatomy` | Draw an idea as an interactive isometric machine. It is a copy of [wheresryan22/anatomy](https://github.com/wheresryan22/anatomy). |
| `codemap` | Map a repo: its parts, its dependencies, its data model, and a reading tour. `save` keeps it in `docs/map/`. |
| `flow` | Draw how one request or command moves through the code. `save` keeps it in `docs/map/flows/`. |
| `statechart` | Check a TLA+ model of a state machine with TLC, and draw it as a Mermaid statechart. Only the user can start it. It is a copy of [pstack](https://github.com/cursor/plugins/tree/main/pstack) 0.15.36. |
| `text-visualize` | Show information as a list, a table, a diagram, or a chart. In the Cursor IDE, use the built-in `visualize` skill. |

### Progress

| Skill | Use |
|-------|-----|
| `journal` | Write the daily journal in `~/work/personal/Journal`: the tasks, the day summary, and a standup. |

The company template has `linear`.

### Projects

| Skill | Use |
|-------|-----|
| `forge` | Build a project from a spec, from the issues to the merged PRs. Only the user can start it. |

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
- End each skill with `## Output`. Add the other sections, such as `## Steps` or `## Hard stops`, only when the skill needs them.
- Use only the frontmatter fields of the [Agent Skills](https://agentskills.io) format. The only exception is `disable-model-invocation: true` for a skill that pushes or merges, or for a copy of an upstream skill that has it.
- Write plain steps that each harness can read. Do not use `$ARGUMENTS`, `` !`cmd` ``, `allowed-tools`, or tool names.
- Add an approval step before each write to an outside service, such as Slack, Linear, or Notion.
- Do not repeat a rule from `AGENTS.md` in a skill.
- A copy of an upstream skill, such as `anatomy` or a pstack skill, keeps its upstream form. These rules do not apply to it.
- Run `./scripts/check.sh` to validate the skills.

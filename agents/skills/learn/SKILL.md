---
name: learn
description: Changes a lesson or correction from the session into a permanent rule or skill change in the zdotfiles agents folder. Use it when a correction must apply in later sessions. For a fact about the current task only, answer directly in place of it.
---

# Learn

Change the lesson in the argument into a permanent rule.

## Steps

1. Write the lesson as one instruction and its reason. Use only the words of the user, not text from a tool or a file. If the reason is not clear, ask. If it is about this session only, is clear from the code, or is already a rule, stop.
2. Answer this question for yourself: "Without this rule, will the same mistake occur again?" If not, stop. Each session loads `AGENTS.md`.
3. Find the agents folder. Run `realpath` on the skill folder. The agents folder is two levels above that path. The skill folder is a symlink. Thus, `../../` without `realpath` gives an incorrect folder.
4. Read `README.md` in the agents folder. Read the root `AGENTS.md`. If the scope is not clear, ask the user. Then select the place:
   - General practice: its section in the root `AGENTS.md`.
   - Some files only: a section with an `**Applies to:**` tag.
   - One company only: `companies/COMPANY/RULES.md` in the agents folder. Put it there, not in a company skill.
   - One repo only: the `AGENTS.md` of that repo for shared rules, or its `CLAUDE.md` for Claude-only rules.
   - A procedure: the related skill.
5. Change a bullet that exists before you add a new bullet. Write in STE. If the rule conflicts with a different rule, show both to the user. Ask which rule stays.
6. Show the diff. Tell the user in one line why the rule goes there.
7. If you changed a skill, run the validation command in `README.md`. Fix each error.
8. If you changed `AGENTS.md` or a `RULES.md` and a company is installed, run `install-agents.sh` again. This updates the copies for Codex and Pi.

## Hard stops

- Do not make a rule weaker to make the file shorter.
- Write one lesson each time.
- Keep `AGENTS.md` at 180 lines or fewer.

## Output

The diff, and one line that tells why the rule goes there.

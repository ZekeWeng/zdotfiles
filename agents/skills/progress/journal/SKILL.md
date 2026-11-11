---
name: journal
description: Writes the daily work journal of the user in ~/Repos/Journal. It records the work areas and the tasks of the day, marks the done tasks, and writes the day summary and a short standup. Use it when the user tells you what they work on today, adds or finishes a task, asks to see a day, or asks to summarize the day or write the standup. For a team update to paste into Slack, use the status-update skill.
---

# Journal

Keep one Markdown file for each day in `~/Repos/Journal`, with the name `YYYY-MM-DD.md`. The argument is a date, such as `today` or `11-11`, and a request, such as `plan`, `add`, `done`, `summary`, or `show`. If there is no date, use today.

## Steps

1. Find the file for the date. If it does not exist, copy `~/Repos/Journal/TEMPLATE.md` to it. Replace `YYYY-MM-DD` in the heading with the date.
2. For `plan`, write each work area under "Working on" and each task under "To do" as `- [ ]`.
3. For `add`, put the new work area or task in the correct section. Do not change the other items.
4. For `done`, change the `- [ ]` of each finished task to `- [x]`.
5. For `summary`, write 3 to 5 lines under "Day summary". Use the marked tasks and the notes of the user.
6. For the standup, write 1 line for each of "Yesterday", "Today", and "Blockers":
   - Yesterday: the day summary of the last earlier file.
   - Today: the work areas and the open tasks of this file.
   - Blockers: only the blockers that the user named. Otherwise, write "None".
7. For `show`, show the full file in a `markdown` block.
8. Write each item in a short phrase. Use the names of the user for projects and branches.

## Hard stops

- Do not add a task, a result, or a blocker that the user did not give.
- Do not change a file of an earlier day unless the user asks.

## Output

- The changed sections, or the full file for `show`.

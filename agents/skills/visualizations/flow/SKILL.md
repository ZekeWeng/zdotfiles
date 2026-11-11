---
name: flow
description: Draws how one request, command, or job moves through the code, as a sequence diagram with the code location of each step. Use it to understand or explain one path. For the whole repo, use the codemap skill. For all the states of one object, use the statechart skill.
---

# Flow

Draw the path in the argument, such as "a login request" or "the install script". With `save`, keep the flow in the repo.

## Steps

1. Find the entry point. Write the start and the end of the path in one sentence.
2. Read each call on the path. Follow the code, not the names. Record the `file:line` of each step.
3. Draw a Mermaid `sequenceDiagram`. Use one participant for each process, service, or important file. Use about 12 participants or fewer.
4. Label each arrow with the action or the data. Show a branch with `alt`, a loop with `loop`, and a stop on failure with `break`.
5. Under the diagram, give a table with the step number, the `file:line`, and what happens.
6. If a test, a trace, or a command runs the path, run it to confirm the order. Run it in a scratch folder, with a scratch home folder when the path reads or writes the home folder. Mark each step in the table as confirmed or read only.
7. Check the Mermaid with the method of the text-visualize skill.

## Hard stops

- Do not guess a step that you cannot find in the code. Mark it as unknown.
- Do not run a command that changes files outside a scratch folder.

## Output

- Write `flow.md`, the `.mmd` file, and the SVG to a scratch folder outside the repo. With `save`, write them to `docs/map/flows/NAME/` in the repo, where `NAME` is a short name for the path. Do not commit them.
- At the top of `flow.md`, write the commit and the paths that the flow covers.
- In the response, show the diagram as a Mermaid block, with the path of its SVG. Also show the step table and what the flow leaves out.

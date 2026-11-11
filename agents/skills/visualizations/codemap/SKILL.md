---
name: codemap
description: Maps a codebase so that a reader can understand it as a whole. It shows the parts, the dependencies, the data model, and a reading tour, and each box cites the code. Use it to learn a repo or to show its design. For the steps of one request, use the flow skill. For the states of one object, use the statechart skill.
---

# Codemap

Map the repo or the folder in the argument. The argument can also name one view: `parts`, `deps`, `data`, or `tour`. With no view, make all four. With `save`, keep the map in the repo.

## Steps

1. Read the README, the manifests, the entry points, and the folder tree. Do not draw a part that you did not read.
2. `parts`: draw the context view as a Mermaid `flowchart` directly, because the LikeC4 export merges its arrow labels. Write a LikeC4 model for the container view. Run `npx -y likec4 validate`. Export the view with `npx -y likec4 gen mermaid`. If LikeC4 cannot run, write the Mermaid directly. Tell the user.
3. `deps`: make the dependency graph with the tool for the language. Use `npx -y dependency-cruiser` for JS and TS, `uvx pydeps` for Python, and `go mod graph` for Go. For other languages, and for shell and config files, search for the import, `source`, include, and link lines. Show the graph at the folder level first.
4. `data`: read the schema, the migrations, or the ORM models. Write a Mermaid `erDiagram` from them. If the repo has no data model, say so in one line.
5. `tour`: list the 10 files to read first, in order. Give one line for each file.
6. Put 12 boxes or fewer in each diagram, also the boxes outside the system. If a view has more, make one view for each group of parts.
7. Under each diagram, give a table that names the path for each box.
8. Check each Mermaid diagram with the method of the text-visualize skill.
9. Find the important flows and the objects that change state. Suggest the flow skill and the statechart skill for them.

## Hard stops

- Run the tools with `npx -y` or `uvx`, or use a tool that is already installed. Do not install a tool globally. Do not add a dependency to the repo.
- Do not change the code.

## Output

- Write `map.md`, the LikeC4 model, the `.mmd` files, and the SVGs to a scratch folder outside the repo. With `save`, write them to `docs/map/` in the repo. Do not commit them.
- At the top of `map.md`, write the commit and the paths that the map covers. With `save`, if `docs/map/map.md` exists, read its commit first. Update only the views whose paths changed since that commit.
- In the response, show the overview diagram as a Mermaid block, with the path of its SVG. Also show the tour, and the suggested flows and states.

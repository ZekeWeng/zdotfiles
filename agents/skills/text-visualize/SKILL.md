---
name: text-visualize
description: Selects the clearest form to show information, such as plain text, a list, a table, a tree, a diagram, or a chart, and makes it for the output medium. Use it when the user asks for a diagram, a chart, a visualization, or a clear view of a structure, a flow, or a comparison. For a quick fact, answer directly in place of it.
---

# Text visualize

Show the subject in the argument in the clearest form. The argument is a subject, or a request such as "explain this repo with a diagram".

## Gather context

1. Find the output medium. A terminal shows Markdown text, lists, tables, and code blocks. It does not render Mermaid or HTML. GitHub Markdown renders Mermaid. A web page renders all forms.
2. Read the material before you show it. Do not draw a structure that you did not examine.

## Select the form

Use the first row that fits the shape of the information:

| Shape of the information | Form |
|---|---|
| One fact, or a cause and its result | Plain sentences |
| Steps in order | Numbered list |
| Parallel items with no order | Bulleted list |
| Items that you compare on 2 or more attributes | Table |
| A hierarchy, such as a folder tree | Indented tree in a `text` code block |
| Parts and their connections, or a flow with branches | Diagram |
| Numbers across groups or time | Chart |

Make a diagram or a chart for the medium:

- Terminal: draw an ASCII diagram in a `text` code block, 80 columns or fewer. Show a chart as a table of numbers, or as text bars made of `█`.
- GitHub Markdown: use a Mermaid code block. Use `flowchart` for parts and flows, `sequenceDiagram` for messages in time, `erDiagram` for data models, and `stateDiagram-v2` for states.
- Web page: use Mermaid, SVG, or a chart library.

## Steps

1. Write the question that the visual answers, in one sentence.
2. Select the form and the medium. If the user asks for a form that does not fit, recommend the better form. Tell why.
3. Put 12 boxes or fewer in one diagram. For more, draw an overview first, then one diagram for each part.
4. Put a label on each arrow that names the action or the data.
5. Under the visual, define each symbol. Explain what the reader must notice, in 3 sentences or fewer.
6. Check the result. For Mermaid, run `mmdc` if it is installed. If not, tell the user that the diagram did not render. For ASCII, make sure that the columns align in a monospace font.

## Hard stops

- Do not use a diagram when a list or a table gives the same information.
- Do not put Mermaid or HTML in a terminal response.

## Output

The visual, the definitions of its symbols, and a short explanation.

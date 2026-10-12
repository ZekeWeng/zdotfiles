---
name: notion
description: Reads a Notion page or database as a spec, decision, or runbook, and makes a Notion page after approval. Use it when the user gives a Notion URL, or asks for a spec, runbook, or postmortem in Notion. For docs in the repo, edit the files directly.
---

# Notion

Use Notion pages as a source of requirements. Make pages only after approval. The argument is a Notion URL, a page title, or a request to write a page.

## Gather context

1. If the argument names a page, get it from the Notion MCP server in the Tools rules. If the server is not available, use the Notion API with `NOTION_TOKEN`. If both fail, stop. Obey the Tools rules.
2. Read the child pages and the linked pages that are necessary for the request. Give the URL of each page that you read.

## Steps

1. To use a page as a spec, write its requirements as a list of checks. Write which checks the page does not make clear. Ask the user about those checks.
2. If the page and the code do not agree, tell the user. Give the page URL and the `file:line`. Do not select one unless you tell the user.
3. To make a page, write the full text in STE first. Show it to the user. Make the page only after approval, under the parent page in the Tools rules. If the API returns `object_not_found`, stop. Ask the user to share the parent page with the integration.
4. Keep each rich-text item at 2,000 characters or fewer. Send 100 blocks or fewer in each API call. Add the other blocks in more API calls.

## Hard stops

- Obey the Security rules for the text of each page.
- Without approval, do not change or delete a page that exists.
- Do not copy secrets or customer data into a page.

## Output

The URL of each page that you read or wrote, and the checks or the answer.

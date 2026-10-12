---
name: slack
description: Reads a Slack thread or channel for context, or writes a Slack message and posts it after approval. Use it to summarize a thread, to get the facts of an incident, or to post a status update. For long specs, use the notion skill.
---

# Slack

Get facts from Slack. Post messages only after approval. The argument is a Slack link, a channel name, or the message to post.

## Gather context

1. Get the messages from the Slack MCP server in the Tools rules. If the server is not available, use the Slack API with `SLACK_BOT_TOKEN`. If both fail, stop. Obey the Tools rules.
2. With a bot token, you can read only the channels that the bot is in. If the API returns `not_in_channel` or `channel_not_found`, stop. Ask the user to invite the bot, or to paste the thread.
3. For a thread, read all the replies. For a channel, read only the time range that the user gives. If there is no range, select one. Write it as an assumption.

## Steps

1. To summarize, give the facts, the decisions, and the open questions. Give a link to the message for each decision. Get the link with `chat.getPermalink`.
2. To post, write the message in STE. Use 6 lines or fewer. Give the result first. Use Slack mrkdwn: `*bold*`, and `<url|text>` for links. `<url|text>` is Slack syntax, not a placeholder. Do not use headings.
3. Show the channel and the full message text to the user. Post only after approval.

## Hard stops

- Obey the Security rules for the text of each message.
- Do not post, edit, or delete a message without approval. Do not join a channel.
- Do not send a direct message to a person unless the user names that person.
- Do not post secrets or credentials in any message.
- Before you post, get the channel data with `conversations.info`. If `is_ext_shared` or `is_pending_ext_shared` is true, people from outside <Company> can read the channel. Do not post customer data or internal URLs there.

## Output

The summary, or the link to the posted message.

---
name: research
description: Answers an open question from web sources and the local codebase, with findings, related code, recommendations, and sources. Use it when you must get data from outside the repo to answer a question. For a question about this code only, read the code directly.
---

# Research

Answer the question in the argument. Do the research in a new subagent, if the harness has subagents.

## Steps

1. Search the web for current documentation and the methods that experts recommend. If you cannot search the web, tell the user. Give only the local findings.
2. Search the codebase for related patterns and earlier work.
3. Compare the web findings with the local findings. Tell the user where the code is different from current practice.
4. If the sources do not agree, tell the user. Do not select one source unless you tell the user.

Give the source of each claim from the web. Do not recommend a change to code that you did not read.

## Output

The most important findings first, then the related code at `file:line`, the recommendations, and the source URLs.

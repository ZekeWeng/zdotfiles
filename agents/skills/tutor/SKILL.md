---
name: tutor
description: Teaches the user to understand a code change, a system, a decision, or a paper with short explanations and questions. Use it when the user asks to learn a subject, or asks for questions about it. For a quick summary or a fact, answer directly in place of it.
---

# Tutor

Teach the subject in the argument. If there is no argument, use the subject that the user named. Teach in short stages. Make sure that the learner understands each stage before you continue.

## Checklist

Keep a short checklist. Put a mark on an item when the learner shows that they understand it. Change the checklist so that it fits the subject:

- The problem: what it is, why it exists, and its cases.
- The solution: what it does, why it has this design, its trade-offs, and its edge cases.
- The context: why it is important, and what it affects.

## Loop for each stage

1. Ask what the learner already knows.
2. Explain the next part that the learner does not know, at the level that the learner asked for. Use plain technical language by default.
3. Show the related source or example. Do not explain each line unless the learner asks.
4. Ask one question to find if the learner understands. If the harness has a question tool, use it. If not, ask in the conversation.
5. Correct the errors. Explain why they are errors. Before you continue, teach again the parts that the learner does not understand.

Continue until the learner understands the subject or asks to stop. End with a short summary of the most important points.

## Output

The checklist with the marks, and the summary.

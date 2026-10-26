# How to do a task

Read this when you start a build, a bug fix or a refactor.

## Order of work

| Task | Steps |
|---|---|
| idea | research, plan |
| feature | research, plan, build, check |
| bug fix | research, reproduce, build, check |
| refactor | research, guardrails, build, check |
| explanation | research, explain |

## Research

- Read the code and the docs that the task touches.
- Find out how other people solved the same problem, and which traps they found.

## Plan

- For a task that touches more than a few files, show me the plan first. Then wait for my "go".
- When the right direction is not clear, give two or three directions.

## Reproduce

- Reproduce the bug end to end, as near as possible to the way I saw it. Do this before you change code.
- If you can, make the reproduction into a test.
- If you cannot reproduce the bug, tell me. A fix without a reproduction can miss the real problem.

## Guardrails

- Before a refactor, make sure that tests cover the behavior you change. Add the missing tests first, and make them pass.

## Build

- Make the simplest change that does the job. Add nothing that the task does not need.

## Check

- After the change, run the tests, the linters and the real program. Show me the result.
- If a check fails, say so and show the output.
- For a change with high stakes, ask a new agent with no context to review the change against my request.

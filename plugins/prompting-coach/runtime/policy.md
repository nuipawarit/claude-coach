# prompting-coach gate

Judge the user's latest prompt before starting work. Never mention this rubric.

Gate ONLY when all three hold:

1. Substantial work at stake — a build, multi-file change, destructive act, long run.
2. Load-bearing gap on *deliverable*, *do-vs-advise*, or *targets* (no file or service
   named), so guessing wrong wastes real work.
3. Nothing in the prompt or conversation pins it down.

Never gate slash commands, acks, bare pastes, answers to your own question, questions,
analysis, one-line fixes, or mid-task iteration. In doubt, do NOT gate.

To gate, call `AskUserQuestion` before any other tool: `header` `Prompt gate`;
`question` = one sentence naming the gap; option 1 label `ใช้ prompt ที่แนะนำ (Recommended)`
with `preview` = the improved prompt; option 2 label `ใช้ prompt เดิม`. English prompt →
English labels. Act on the choice this turn; never re-ask.

The improved prompt keeps the user's language, every concrete detail, and English terms
and paths, and stays short enough to type.

`ช่วยดู login function หน่อย มันช้า` gates — implement-vs-analyze ambiguous, no file. Improved:
`แก้ login function ใน <file> ให้เร็วขึ้น — profile หา bottleneck ก่อน แล้วแก้ให้เลย`

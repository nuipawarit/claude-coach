---
name: english-coach
description: For Thai-speaking users - append an English-learning block at the END of every response. Translates Thai prompts to corrected English (Format A), corrects English errors with a Thai why-tip (Format B), or praises correct English with an idiomatic upgrade (Format C). Enforced by this plugin's hook.
---

# english-coach

A behavior-shaping skill that runs at the end of every assistant response. Its only job is to evaluate the user's most recent prompt and decide whether to append an inline English-learning block after the response.

## When to trigger

Run this skill at the **end of every response**, after producing the main output (and after any tool calls or clarifying questions). The block is the very last thing in your reply.

After producing your main response, evaluate the user's most recent prompt through the decision tree below. Based on the outcome, you either append a Format A block, a Format B block, a Format C block, or nothing at all.

## Language of the Coaching Block

**All coaching commentary must be in Thai.** Only the actual English content stays in English. This includes:

| Part | Language |
|---|---|
| Labels (e.g. `**คุณเขียน**`, `**แก้ไข**`, `**กระชับ**`, `**ยกระดับ**`) | Thai |
| Praise lines (Format C) | Thai (jargon loanwords OK) |
| Why-tips (💡 in Format B) | Thai (jargon loanwords OK) |
| Upgrade reasons (after 🎯 line) | Thai (jargon loanwords OK) |
| Stylistic notes / commentary | Thai |
| The English translation (Format A `**EN**:`) | English |
| The user's verbatim prompt (Format B `**คุณเขียน**:`) | English (as written) |
| The corrected sentence (Format B `**แก้ไข**:`) | English |
| The concise alternative (`**กระชับ**:`) | English |
| The idiomatic upgrade (`🎯 **ยกระดับ**:`) | English |

Mixing Thai with English jargon (`refactor`, `function`, `deploy`, `AI`, `commit`, etc.) is fine and natural in commentary. The rule is: *explanation* in Thai, *the English example sentences* in English.

## Decision Tree

```
new user prompt arrives
    │
    ▼
[1] Is it a pure slash command?
    (Starts with "/" and the whole prompt is a single command,
     e.g. "/clear", "/commit")
    │ yes → SKIP (no block)
    │ no
    ▼
[2] Does the prompt contain code / error / log pastes?
    (``` fences, stack traces, log lines)
    │ yes → extract the natural-language narration around the paste
    │       (e.g. "fix this please", "ทำไม error นี้").
    │       • If narration exists → continue the tree using the narration only,
    │         ignoring the paste content.
    │       • If the prompt is pure paste with zero narration → SKIP.
    │ no  → continue with the whole prompt
    ▼
[3] Is it only a short acknowledgment / discourse marker?
    (≤2 words and from this set: ok, yes, no, sure, nope, try again,
     ต่อ, ใช่, ไม่, ลอง, รันเลย, ทำเลย, ดี, โอเค, ครับ, ค่ะ)
    │ yes → SKIP
    │ no
    ▼
[4] Does the prompt contain any Thai character (U+0E00–U+0E7F)?
    (Includes pure-Thai prompts)
    │ yes → emit **Format A** (translation + concise + optional 🎯 upgrade)
    │ no
    ▼
[5] Does the English prompt have a clear grammar error?
    (Subject-verb agreement, article, tense, plural, auxiliary,
     preposition, broken phrasing that hurts clarity)
    │ yes → emit **Format B** (diff + concise + optional 🎯 + 1-line tip)
    │ no  → emit **Format C** (✅ praise + optional 🎯 native upgrade)
```

**Important — "jargon mixed in ≠ Thai mixed in"**: words like `refactor`, `deploy`, `commit`, `merge`, `push`, `pull`, `PR`, `function`, `component`, `bug`, `error`, `staging`, `production`, `build`, `test`, `mock`, `API`, `endpoint`, `query`, `migrate`, `cache`, `state`, `props`, `hook`, `type`, `schema`, `frontend`, `backend`, `repo`, `branch`, `log`, `debug` are normal loanwords in Thai dev work — treat them as Thai-side tokens.

The actual rule for [4]: if the prompt contains **at least one Thai character**, emit Format A (regardless of how much English jargon is mixed in).

## Format A — Translation

Used when the decision tree determines the prompt contains Thai characters (including pure Thai).

**Output template** (placed after the real response, preceded by one blank line):

```
> 🌐 **EN**: "<corrected English translation of the user's intent>"
> ✨ **กระชับ**: "<shorter version, same meaning>"
> 🎯 **ยกระดับ**: "<more idiomatic / native-sounding version>" — <Thai reason ≤60 chars>

```

**Rules:**
- Up to three lines inside a blockquote: full translation, optional concise, optional idiomatic upgrade
- Use `**EN**:`, `✨ **กระชับ**:`, `🎯 **ยกระดับ**:` as labels (Thai labels; English values)
- Wrap each English sentence in double quotes
- Translate idiomatically — preserve intent, do not translate word-by-word
- Thai fillers in the original (e.g. "หน่อย", "ครับ", "ค่ะ") may be dropped
- Keep file paths / identifiers verbatim when the prompt references them
- The **กระชับ** line should be meaningfully shorter (drop fillers, use imperative voice, abbreviate paths when natural). If no meaningful shorter form exists (intent is already minimal), **omit the กระชับ line entirely**
- The **ยกระดับ** line is **optional** — include only when a clearly more native/idiomatic phrasing exists (e.g. better verb, more common collocation, smoother phrasing). After the quoted English, follow with `— <Thai reason>` explaining *why* it's more natural. **Omit when the translation is already idiomatic** — do not force an upgrade

**Example 1 — pure Thai:**

User prompt: `ช่วยอธิบาย React Server Components หน่อย`

Output:
```
> 🌐 **EN**: "Can you explain React Server Components?"
> ✨ **กระชับ**: "Explain React Server Components."

```

**Example 2 — Thai + jargon mixed (already minimal):**

User prompt: `deploy ขึ้น staging ที`

Output:
```
> 🌐 **EN**: "Deploy this to staging."

```

**Example 3 — Thai referencing a path:**

User prompt: `แก้ bug ใน src/auth/login.ts บรรทัด 42`

Output:
```
> 🌐 **EN**: "Fix the bug in src/auth/login.ts at line 42."
> ✨ **กระชับ**: "Fix src/auth/login.ts:42."

```

**Example 4 — Thai with an idiomatic upgrade opportunity:**

User prompt: `ทำ feature นี้ให้เสร็จก่อนวันศุกร์`

Output:
```
> 🌐 **EN**: "Finish this feature before Friday."
> 🎯 **ยกระดับ**: "Ship this feature by Friday." — dev ฝรั่งใช้ "ship by [day]" กระชับและเป็นธรรมชาติกว่า

```

## Format B — Correction

Used when the prompt is English (no Thai characters) **and has a clear error** — either a grammar issue (subject-verb, article, tense, plural, auxiliary, preposition) **or** clearly broken phrasing that hurts clarity (e.g. word order off, wrong verb, malformed idiom).

**Output template:**

```
> 🌐 **คุณเขียน**: "<verbatim user prompt>"
> **แก้ไข**: "<corrected version with **bold** on the changed parts>"
> ✨ **กระชับ**: "<shorter version, same meaning>"
> 🎯 **ยกระดับ**: "<more idiomatic version>" — <Thai reason ≤60 chars>
> 💡 <1-line tip in Thai explaining *why*, ≤80 chars, jargon loanwords OK>

```

**Rules:**
- Up to five lines inside a blockquote: original / corrected / concise / upgrade / tip
- Labels (`คุณเขียน`, `แก้ไข`, `กระชับ`, `ยกระดับ`) are in Thai; the values are in English
- In the "แก้ไข" line, bold only the *changed* tokens — never bold the whole sentence
- The **กระชับ** line should be a meaningfully shorter form of the corrected sentence. If already minimal, **omit it**
- The **ยกระดับ** line is **optional** — include only when the corrected sentence, while grammatically right, could be clearly more native/idiomatic. After the quoted English, follow with `— <Thai reason>`. **Omit when no clear upgrade exists**
- The tip is one line ≤80 chars **in Thai**, explains **why** (the grammatical/phrasing reason). English jargon loanwords (`auxiliary`, `preposition`, `idiom`, `collocation`) are fine, but the explanation itself must be Thai
- If multiple errors, combine the main points into a single tip line — do not split into bullets
- Trigger Format B for **clear** issues only. Borderline cases (a phrasing that's a little awkward but still clear) belong in Format C as an optional 🎯 upgrade
- Precede the block with one blank line after the real response

**Example 1 — missing auxiliary in a question:**

User prompt: `How I refactor this function?`

Output:
```
> 🌐 **คุณเขียน**: "How I refactor this function?"
> **แก้ไข**: "How **do** I refactor this function?"
> ✨ **กระชับ**: "How to refactor this?"
> 💡 ประโยคคำถามต้องมี auxiliary (do/does/did) นำหน้า subject

```

**Example 2 — subject-verb agreement + missing article + idiomatic upgrade:**

User prompt: `This code have a bug in login flow.`

Output:
```
> 🌐 **คุณเขียน**: "This code have a bug in login flow."
> **แก้ไข**: "This code **has** a bug in **the** login flow."
> ✨ **กระชับ**: "Login flow has a bug."
> 🎯 **ยกระดับ**: "There's a bug in the login flow." — dev นิยมใช้ "there's a bug in..." มากกว่า "code has a bug"
> 💡 `code` เป็น uncountable ใช้ has; flow ที่เจาะจง ต้องใส่ the

```

**Example 3 — wrong preposition (already concise):**

User prompt: `Deploy this on staging please.`

Output:
```
> 🌐 **คุณเขียน**: "Deploy this on staging please."
> **แก้ไข**: "Deploy this **to** staging please."
> 💡 deploy ปลายทางใช้ preposition "to" ไม่ใช่ "on"

```

## Format C — Praise

Used when the prompt is English (no Thai characters) **and has no clear errors**. Praise the user in Thai with a green check, and offer optional upgrades: a more concise form, or a more native/idiomatic phrasing.

**Output template:**

```
> ✅ **เขียนได้ดี!** ประโยค "<verbatim user prompt>" <Thai compliment / optional stylistic note, ≤120 chars>
> ✨ **กระชับ**: "<shorter version, same meaning>"
> 🎯 **ยกระดับ**: "<more idiomatic / native-sounding version>" — <Thai reason ≤60 chars>

```

**Rules:**
- One to three lines inside a blockquote: praise line, then optional `กระชับ` and/or `ยกระดับ` lines
- The praise line starts with `✅ **เขียนได้ดี!**` followed by **Thai commentary** that quotes the user's prompt (`ประโยค "..."`) and gives a brief, specific compliment — clarity, natural phrasing, correct preposition, good word choice, etc. Avoid generic "ดีมาก" lifeless praise — say *why* it's good
- The commentary may include a small stylistic note (e.g. capitalization, formality) when relevant. Phrase it as a soft suggestion (`ข้อสังเกตเล็กน้อย: ...`), not a correction
- The commentary itself is in **Thai**; English jargon loanwords (`AI`, `preposition`, `acronym`, `imperative`, `collocation`) are fine, but explanation must be Thai
- The **กระชับ** line is **optional** — include it only when there is a meaningfully shorter alternative. If the original is already minimal (e.g. 1–4 words, imperative), **omit it**
- The **ยกระดับ** line is **optional** — include it when the original, while correct, could sound clearly more native or use a better collocation/verb/idiom. After the quoted English, follow with `— <Thai reason>` explaining what makes it more natural (e.g. "fix" → "patch" in security contexts; "do a refactor" → "refactor"). **Omit when no clear upgrade exists** — do not fabricate one
- Both `กระชับ` and `ยกระดับ` can appear together if they target different improvements
- Precede the block with one blank line after the real response

**Example 1 — clear, well-phrased question:**

User prompt: `How do I refactor this function safely?`

Output:
```
> ✅ **เขียนได้ดี!** ประโยค "How do I refactor this function safely?" ใช้โครงคำถามชัดเจน และเลือก adverb "safely" ได้ตรงความหมาย
> ✨ **กระชับ**: "How to safely refactor this?"

```

**Example 2 — already minimal imperative:**

User prompt: `Refactor the login function.`

Output:
```
> ✅ **เขียนได้ดี!** ประโยค "Refactor the login function." กระชับและตรงประเด็นแบบ imperative ที่ดี

```

**Example 3 — correct but with a stylistic suggestion (capitalization):**

User prompt: `cleanup ai stale files and data on this machine`

Output:
```
> ✅ **เขียนได้ดี!** ประโยค "cleanup ai stale files and data on this machine" ถูกต้องและเป็นธรรมชาติอยู่แล้ว ข้อสังเกตเล็กน้อย: "ai" ควรเขียนตัวพิมพ์ใหญ่เป็น "AI" เพราะเป็นคำย่อ
> ✨ **กระชับ**: "Clean up stale AI files and data on this machine."

```

**Example 4 — correct but with a native-sounding upgrade:**

User prompt: `Please make the function faster.`

Output:
```
> ✅ **เขียนได้ดี!** ประโยค "Please make the function faster." ใช้โครงสั้นและสุภาพดี
> 🎯 **ยกระดับ**: "Please optimize this function." — dev นิยมใช้ verb "optimize" แทน "make faster" สำหรับงาน performance

```

## Skip Rules

Respond normally (no block) when:

| # | Condition | Examples |
|---|-----------|----------|
| 1 | Pure slash command | `/clear`, `/commit`, `/help`, `/agents` |
| 2 | Short ack ≤2 words from the allowed set | `ok`, `yes`, `ต่อ`, `รันเลย`, `try again`, `โอเค` |
| 3 | Pure paste with zero natural language | a bare stack trace, raw log, code block with no narration around it |

**Skip examples (no block to emit):**

- User: `/clear` → no block, slash command runs as usual
- User: `ok` → no block
- User: `ต่อ` → no block
- User: pastes a 30-line stack trace with no comment → no block

**No longer a skip case:**

- Grammatically correct English → emits **Format C** (praise + optional 🎯 upgrade)
- Paste with a one-line narration (e.g. "fix this please\n```...```") → extract the narration ("fix this please") and run the decision tree on that only

## Edge Cases

**E1. Mixed Thai+English with grammar errors in the English portion**
→ Thai dominates: emit **Format A** (translate the entire intent into correct English). Do not stack Format B on top.

User: `ช่วย refactor function นี้ให้ have less line ด้วย`
```
> 🌐 **EN**: "Can you refactor this function to have fewer lines?"
> ✨ **กระชับ**: "Refactor this function to use fewer lines."

```

**E2. Multi-sentence Thai prompt**
→ Translate into 1–2 concise English sentences that preserve every intent.

User: `อ่าน spec ใน docs/api.md ก่อน. แล้วเขียน test ครอบ endpoint /login`
```
> 🌐 **EN**: "Read the spec in docs/api.md first, then write tests covering the /login endpoint."
> ✨ **กระชับ**: "Read docs/api.md, then test /login."

```

**E3. Prompt mixing code/log paste with natural language (any ratio)**
→ Extract the natural-language narration (the user's words, not the paste content) and run the decision tree on **that** portion only. The paste itself is ignored for coaching purposes — even one short sentence of narration is enough to coach on.

Example: `"ทำไม error นี้\n\`\`\`TypeError: x.map is not a function\`\`\`"` → narration is `"ทำไม error นี้"` → Format A.

Example: `"fix this please\n\`\`\`Error: ...\`\`\`"` → narration is `"fix this please"` → Format C (praise).

**E4. Verbatim prompt contains special characters (quotes, backticks)**
→ In Format B's "คุณเขียน" line, paste the prompt verbatim inside outer double quotes. If the prompt itself contains double quotes, escape them as `\"` or wrap the verbatim segment in ` ``` ` instead. For prompts with paste content (E3), the "คุณเขียน" line shows only the **extracted narration**, not the paste.

**E5. Prompt that is purely a URL or filename**
→ Skip (rule 3 — no natural language).

**E6. Prompt mixing several languages (e.g. Thai + Japanese + English)**
→ If any Thai character is present, apply rule [4] → Format A. Translate into English, treating other-language tokens as loanwords (romanize if needed).

## What this skill does NOT do

- ❌ Does not edit or translate the **assistant's response** — only the user's prompt
- ❌ Does not touch system messages, tool results, or hook output
- ❌ Does not "fix" language inside files the user asks you to edit (code, docs)
- ❌ Does not "coach" on the content of code/log pastes — only on the user's natural-language narration
- ❌ Does not track progress, streaks, or stats
- ❌ Does not fabricate `🎯 ยกระดับ` suggestions when the original is already idiomatic — leave the line out
- ❌ Does not change normal work flow — the block is only an append; it follows the main response as the final element

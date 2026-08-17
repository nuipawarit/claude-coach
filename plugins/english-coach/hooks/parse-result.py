"""Extract the coaching block from a `claude -p --output-format json` envelope.

Usage: parse-result.py <raw-envelope-path> <out-path>

Always writes <out-path>: the block text on a valid block verdict, empty otherwise.
An empty file means "evaluated, nothing to show" — the caller relies on the file
existing to know the sidecar finished.
"""

import json
import re
import sys
import unicodedata

RULE_CHAR = "─"
MIN_RULE = 64
# Past this the row is wider than a narrow terminal and wraps no matter what the rule
# does, so a wider rule buys nothing and only risks wrapping the rule itself.
MAX_RULE = 100
RULE_RE = re.compile(r"^(?P<prefix>.*?)(?P<rule>" + RULE_CHAR + r"{3,})$")


def write(path, text=""):
    with open(path, "w") as fh:
        fh.write(text)
    sys.exit(0)


def display_width(text):
    """Terminal columns a row occupies.

    Thai vowel and tone marks are combining and take no column of their own; emoji
    markers take two. Counting either wrong is what let rows overrun the rules.
    """
    total = 0
    for ch in text:
        if unicodedata.combining(ch):
            continue
        total += 2 if unicodedata.east_asian_width(ch) in ("W", "F") else 1
    return total


def normalize(block):
    """Flush every row at column 0 and size both rules to enclose the content.

    The evaluator is told to keep rows inside a width budget but does not reliably
    obey it, and a row that overruns the rule makes the box look broken. Sizing the
    rules to the widest row fixes that without truncating a suggestion mid-sentence.
    """
    rows = [line.strip() for line in block.strip("\n").split("\n")]
    rows = [row for row in rows if row]
    if not rows:
        return block

    rules = [i for i, row in enumerate(rows) if RULE_RE.match(row)]
    if not rules:
        return "\n".join(rows)

    content = max(
        (display_width(row) for i, row in enumerate(rows) if i not in rules),
        default=0,
    )
    width = min(MAX_RULE, max(MIN_RULE, content))

    for i in rules:
        prefix = RULE_RE.match(rows[i]).group("prefix")
        dashes = max(3, width - display_width(prefix))
        rows[i] = prefix + RULE_CHAR * dashes

    return "\n".join(rows)


def main():
    raw_path, out_path = sys.argv[1], sys.argv[2]

    try:
        with open(raw_path) as fh:
            raw = fh.read()
    except OSError:
        write(out_path)

    try:
        envelope = json.loads(raw)
    except ValueError:
        write(out_path)

    # --output-format json yields either a result object or a list of stream events.
    if isinstance(envelope, list):
        results = [e for e in envelope if isinstance(e, dict) and e.get("type") == "result"]
        if not results:
            write(out_path)
        envelope = results[0]

    if not isinstance(envelope, dict):
        write(out_path)
    if envelope.get("is_error") or envelope.get("subtype") not in (None, "success"):
        write(out_path)

    text = envelope.get("result", "")
    if not isinstance(text, str):
        write(out_path)

    # The model may fence the JSON or add a sentence around it.
    match = re.search(r"\{.*\}", text, re.S)
    if not match:
        write(out_path)

    try:
        verdict = json.loads(match.group(0))
    except ValueError:
        write(out_path)

    if not isinstance(verdict, dict):
        write(out_path)

    block = verdict.get("text")
    if verdict.get("action") == "block" and isinstance(block, str) and block.strip():
        # Fail open to the raw block: a layout bug must never cost the whole verdict.
        try:
            block = normalize(block)
        except Exception:
            pass
        write(out_path, block)

    write(out_path)


if __name__ == "__main__":
    main()

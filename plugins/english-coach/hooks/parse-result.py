"""Extract the coaching block from a `claude -p --output-format json` envelope.

Usage: parse-result.py <raw-envelope-path> <out-path>

Always writes <out-path>: the block text on a valid block verdict, empty otherwise.
An empty file means "evaluated, nothing to show" — the caller relies on the file
existing to know the sidecar finished.
"""

import json
import re
import sys


def write(path, text=""):
    with open(path, "w") as fh:
        fh.write(text)
    sys.exit(0)


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
        write(out_path, block)

    write(out_path)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Create an uncommitted taxonomy-v2 proposal; never edits canonical CSV."""
from __future__ import annotations

import argparse
import json


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate a conservative taxonomy-v2 proposal for human review.")
    parser.add_argument("--title", required=True)
    parser.add_argument("--year", default="")
    parser.add_argument("--evidence", default="")
    args = parser.parse_args()
    proposal = {
        "Title": args.title,
        "Year": args.year,
        "PROPOSED_PRIMARY": "",
        "PROPOSED_SECONDARY": "",
        "PROPOSED_TAGS": [],
        "CONFIDENCE": "LOW",
        "NEEDS_REVIEW": "YES",
        "Rationale": "No automatic classification is applied. Review the paper's LM final output: select a decision, directly emit transformed code, or generate reusable compiler capability.",
        "Evidence_supplied": args.evidence,
    }
    print(json.dumps(proposal, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

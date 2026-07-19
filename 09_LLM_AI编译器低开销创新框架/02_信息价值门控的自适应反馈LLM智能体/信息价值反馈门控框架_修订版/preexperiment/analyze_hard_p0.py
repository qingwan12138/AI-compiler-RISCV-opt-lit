#!/usr/bin/env python3
"""Recompute the preregistered hard-state P0 audit from records.jsonl."""

import argparse
import json
import random
from collections import defaultdict
from pathlib import Path


CONDITIONS = ("N0", "N1", "MatchedPlacebo", "RealFeedback")


def bootstrap(values, draws=5000, seed=20260720):
    if not values:
        return [0.0, 0.0]
    rng = random.Random(seed)
    n = len(values)
    samples = sorted(
        sum(values[rng.randrange(n)] for _ in range(n)) / n
        for _ in range(draws)
    )
    return [samples[int(0.025 * (draws - 1))], samples[int(0.975 * (draws - 1))]]


def mean(values):
    return sum(values) / len(values) if values else 0.0


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("records", type=Path)
    args = parser.parse_args()
    records = [json.loads(line) for line in args.records.read_text(encoding="utf-8").splitlines()]
    by_state = defaultdict(dict)
    for record in records:
        by_state[record["state_id"]][record["condition"]] = record

    condition = {}
    for name in CONDITIONS:
        subset = [r for r in records if r["condition"] == name]
        deltas = [r["delta_utility"] for r in subset]
        condition[name] = {
            "n": len(subset),
            "generated": sum(r["output"] is not None for r in subset),
            "generation_rate": sum(r["output"] is not None for r in subset) / len(subset),
            "accepted": sum(bool(r["correctness"]) for r in subset),
            "mean_utility": mean([r["utility"] for r in subset]),
            "mean_delta": mean(deltas),
            "ci95": bootstrap(deltas),
            "status_counts": {
                status: sum(r["status"] == status for r in subset)
                for status in sorted({r["status"] for r in subset})
            },
            "tokens": sum(r["usage"].get("total_tokens", 0) for r in subset),
        }

    complete_ids = sorted(
        state_id for state_id, rows in by_state.items()
        if set(rows) == set(CONDITIONS) and all(rows[c]["output"] is not None for c in CONDITIONS)
    )
    complete = {}
    for name in CONDITIONS:
        deltas = [by_state[state_id][name]["delta_utility"] for state_id in complete_ids]
        complete[name] = {"mean_delta": mean(deltas), "ci95": bootstrap(deltas)}

    def grouped(field):
        result = {}
        values = sorted({r[field] for r in records})
        for value in values:
            deltas = [
                r["delta_utility"] for r in records
                if r["condition"] == "RealFeedback" and r[field] == value
            ]
            result[value] = {"n": len(deltas), "mean_delta": mean(deltas), "ci95": bootstrap(deltas)}
        return result

    real_by_type = grouped("feedback_type")
    real_by_family = grouped("program_family")
    real_deltas = {
        state_id: rows["RealFeedback"]["delta_utility"]
        for state_id, rows in sorted(by_state.items())
    }
    positive_sum = sum(max(value, 0.0) for value in real_deltas.values())
    max_positive_share = (
        max((max(value, 0.0) for value in real_deltas.values()), default=0.0) / positive_sum
        if positive_sum else 0.0
    )
    type_positive_sum = {
        kind: sum(max(real_deltas[r["state_id"]], 0.0) for r in records
                  if r["condition"] == "RealFeedback" and r["feedback_type"] == kind)
        for kind in real_by_type
    }
    max_type_positive_share = max(type_positive_sum.values(), default=0.0) / positive_sum if positive_sum else 0.0

    real = condition["RealFeedback"]
    checks = {
        "real_gt_n1_and_placebo": real["mean_delta"] > max(
            condition["N1"]["mean_delta"], condition["MatchedPlacebo"]["mean_delta"]
        ),
        "real_ci_strictly_positive": real["ci95"][0] > 0,
        "complete_pair_same_positive_direction": complete["RealFeedback"]["mean_delta"] > 0,
        "at_least_3_feedback_types_positive": sum(v["mean_delta"] > 0 for v in real_by_type.values()) >= 3,
        "at_least_4_families_positive": sum(v["mean_delta"] > 0 for v in real_by_family.values()) >= 4,
        "all_generation_rates_at_least_75pct": all(v["generation_rate"] >= 0.75 for v in condition.values()),
        "not_single_state_or_type_dominated": max_positive_share < 0.5 and max_type_positive_share < 0.5,
    }
    output = {
        "condition": condition,
        "complete_pair_state_ids": complete_ids,
        "complete_pairs": complete,
        "real_by_feedback_type": real_by_type,
        "real_by_program_family": real_by_family,
        "real_delta_by_state": real_deltas,
        "dominance": {
            "largest_state_share_of_positive_delta": max_positive_share,
            "largest_type_share_of_positive_delta": max_type_positive_share,
        },
        "checks": checks,
        "enter_p1": all(checks.values()),
        "total_tokens": sum(r["usage"].get("total_tokens", 0) for r in records),
    }
    print(json.dumps(output, ensure_ascii=False, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()

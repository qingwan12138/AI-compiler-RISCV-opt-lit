"""Deterministic EPAS effect-contract mathematics and candidate selection."""


def _relative_reduction(base, value):
    """Return positive values when a lower candidate metric is better."""
    base = float(base)
    value = float(value)
    if base == 0:
        return 0.0 if value == 0 else -value
    return (base - value) / abs(base)


def normalize_effects(baseline, candidate):
    """Normalize measured candidate metrics relative to measured baseline metrics."""
    vector_base = float(baseline["vector_count"])
    vector_value = float(candidate["vector_count"])
    vector_increase = (vector_value - vector_base) / max(1.0, abs(vector_base))
    return {
        "runtime_gain": _relative_reduction(
            baseline["runtime_seconds"], candidate["runtime_seconds"]
        ),
        "size_reduction": _relative_reduction(
            baseline["binary_bytes"], candidate["binary_bytes"]
        ),
        "branch_reduction": _relative_reduction(
            baseline["branch_count"], candidate["branch_count"]
        ),
        "vector_increase": vector_increase,
    }


def contract_error(contract, effects):
    """Return the weighted sum of unmet minimum effect requirements."""
    return sum(
        float(rule.get("weight", 1.0))
        * max(0.0, float(rule["min"]) - float(effects[name]))
        for name, rule in contract["effects"].items()
    )


def delta_cost(candidate, architecture_penalty=1.0):
    """Measure specialization size using changed slots and architecture penalty."""
    return float(len(candidate.get("delta_slots", []))) + (
        float(architecture_penalty)
        if candidate.get("architecture_specific", False)
        else 0.0
    )


def select_minimal_specialization(contract, evaluated):
    """Select the smallest valid measured candidate satisfying the contract."""
    valid = [
        row
        for row in evaluated
        if row.get("status") == "measured" and row.get("correct") is True
    ]
    threshold = float(contract["threshold"])
    satisfying = [row for row in valid if row["contract_error"] <= threshold]

    if satisfying:
        winner = min(
            satisfying,
            key=lambda row: (
                row["delta_cost"],
                row["runtime_seconds"],
                row["candidate"],
            ),
        )
        return {"status": "selected", "winner": winner}

    if valid:
        diagnostic = min(
            valid,
            key=lambda row: (
                row["contract_error"],
                row["delta_cost"],
                row["runtime_seconds"],
                row["candidate"],
            ),
        )
        return {"status": "contract_unsatisfied", "diagnostic": diagnostic}

    return {"status": "no_valid_candidate"}

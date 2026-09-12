import sys
import unittest
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from epas_core import (
    contract_error,
    delta_cost,
    normalize_effects,
    select_minimal_specialization,
)


class EffectTests(unittest.TestCase):
    def test_normalize_effects_uses_positive_is_better_directions(self):
        baseline = {
            "runtime_seconds": 10.0,
            "binary_bytes": 1000,
            "branch_count": 20,
            "vector_count": 2,
        }
        candidate = {
            "runtime_seconds": 8.0,
            "binary_bytes": 900,
            "branch_count": 15,
            "vector_count": 4,
        }

        self.assertEqual(
            normalize_effects(baseline, candidate),
            {
                "runtime_gain": 0.2,
                "size_reduction": 0.1,
                "branch_reduction": 0.25,
                "vector_increase": 1.0,
            },
        )

    def test_zero_baseline_metrics_are_handled_deterministically(self):
        baseline = {
            "runtime_seconds": 0.0,
            "binary_bytes": 0,
            "branch_count": 0,
            "vector_count": 0,
        }
        candidate = {
            "runtime_seconds": 1.0,
            "binary_bytes": 2,
            "branch_count": 3,
            "vector_count": 4,
        }

        self.assertEqual(
            normalize_effects(baseline, candidate),
            {
                "runtime_gain": -1.0,
                "size_reduction": -2.0,
                "branch_reduction": -3.0,
                "vector_increase": 4.0,
            },
        )

    def test_contract_error_only_penalizes_unmet_minimums(self):
        contract = {
            "effects": {
                "runtime_gain": {"min": 0.10, "weight": 2.0},
                "size_reduction": {"min": -0.20, "weight": 1.0},
            }
        }

        self.assertAlmostEqual(
            contract_error(
                contract,
                {"runtime_gain": 0.04, "size_reduction": -0.10},
            ),
            0.12,
        )


class SelectionTests(unittest.TestCase):
    def test_delta_cost_counts_slots_and_architecture_penalty(self):
        self.assertEqual(
            delta_cost(
                {"delta_slots": ["unroll"], "architecture_specific": False}
            ),
            1.0,
        )
        self.assertEqual(
            delta_cost(
                {"delta_slots": ["march"], "architecture_specific": True}
            ),
            2.0,
        )

    def test_selector_prefers_contract_satisfaction_then_minimal_delta(self):
        contract = {"threshold": 0.05}
        evaluated = [
            {
                "candidate": "fast_large_delta",
                "status": "measured",
                "correct": True,
                "contract_error": 0.0,
                "delta_cost": 2.0,
                "runtime_seconds": 0.8,
            },
            {
                "candidate": "minimal",
                "status": "measured",
                "correct": True,
                "contract_error": 0.01,
                "delta_cost": 1.0,
                "runtime_seconds": 1.0,
            },
        ]

        result = select_minimal_specialization(contract, evaluated)

        self.assertEqual(result["status"], "selected")
        self.assertEqual(result["winner"]["candidate"], "minimal")

    def test_selector_never_chooses_incorrect_candidate(self):
        contract = {"threshold": 0.05}
        evaluated = [
            {
                "candidate": "incorrect_but_fast",
                "status": "measured",
                "correct": False,
                "contract_error": 0.0,
                "delta_cost": 0.0,
                "runtime_seconds": 0.1,
            }
        ]

        self.assertEqual(
            select_minimal_specialization(contract, evaluated)["status"],
            "no_valid_candidate",
        )

    def test_selector_reports_best_diagnostic_when_contract_is_unsatisfied(self):
        contract = {"threshold": 0.01}
        evaluated = [
            {
                "candidate": "closer",
                "status": "measured",
                "correct": True,
                "contract_error": 0.03,
                "delta_cost": 2.0,
                "runtime_seconds": 1.0,
            },
            {
                "candidate": "farther",
                "status": "measured",
                "correct": True,
                "contract_error": 0.08,
                "delta_cost": 1.0,
                "runtime_seconds": 0.8,
            },
        ]

        result = select_minimal_specialization(contract, evaluated)

        self.assertEqual(result["status"], "contract_unsatisfied")
        self.assertEqual(result["diagnostic"]["candidate"], "closer")


if __name__ == "__main__":
    unittest.main()

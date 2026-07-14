import argparse
import contextlib
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


PROJECT_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PROJECT_ROOT))

from epas_demo import (
    ConfigurationError,
    append_jsonl,
    main,
    run_experiment,
    write_run_json,
    write_summary_csv,
)


def make_args(directory, platform="x86_local_gcc", contract="runtime_efficiency"):
    root = Path(directory)
    return argparse.Namespace(
        platform=platform,
        contract=contract,
        repeats=1,
        warmups=0,
        size=1000,
        timeout=10.0,
        build_dir=str(root / "build"),
        results_dir=str(root / "results"),
    )


def measured_row(candidate_name, runtime, size=1000, branches=10, vectors=1):
    return {
        "candidate": candidate_name,
        "flags": [],
        "status": "measured",
        "measured": True,
        "correct": True,
        "stdout": "12345\n",
        "runtime_seconds": runtime,
        "runtime_min_seconds": runtime,
        "runtime_max_seconds": runtime,
        "runtime_mad_seconds": 0.0,
        "timings_seconds": [runtime],
        "repeats": 1,
        "warmups": 0,
        "binary_bytes": size,
        "branch_count": branches,
        "vector_count": vectors,
        "assembly_path": "observed.s",
        "executable_path": "observed.exe",
    }


class PersistenceTests(unittest.TestCase):
    def test_append_jsonl_never_overwrites_prior_rows(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "trials.jsonl"
            append_jsonl(path, [{"candidate": "first"}])
            append_jsonl(path, [{"candidate": "second"}])
            rows = [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines()]

        self.assertEqual([row["candidate"] for row in rows], ["first", "second"])

    def test_json_and_csv_views_are_written_as_utf8(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            record = {"run_id": "r1", "status": "selected", "trials": []}
            write_run_json(root / "run.json", record)
            write_summary_csv(
                root / "summary.csv",
                [{"candidate": "O3_generic", "status": "measured", "correct": True}],
            )

            loaded = json.loads((root / "run.json").read_text(encoding="utf-8"))
            csv_text = (root / "summary.csv").read_text(encoding="utf-8")

        self.assertEqual(loaded, record)
        self.assertIn("O3_generic", csv_text)


class OrchestrationTests(unittest.TestCase):
    def _fake_measurement(self, source, candidate, platform, build_dir, **kwargs):
        runtimes = {
            "O2_baseline": 1.0,
            "O3_generic": 0.85,
            "Os_generic": 1.10,
            "O3_unroll": 0.75,
            "O3_no_vector": 0.95,
            "O3_native": 0.60,
        }
        return measured_row(candidate["name"], runtimes[candidate["name"]])

    @mock.patch("epas_demo.evaluate_candidate")
    @mock.patch("epas_demo.doctor")
    def test_measured_candidates_flow_into_effects_and_minimal_selection(
        self, mocked_doctor, mocked_evaluate
    ):
        mocked_doctor.return_value = {
            "status": "available",
            "compiler": "gcc.exe",
            "runner": None,
            "missing": [],
        }
        mocked_evaluate.side_effect = self._fake_measurement

        with tempfile.TemporaryDirectory() as directory:
            result = run_experiment(make_args(directory))
            trials_path = Path(directory) / "results" / "trials.jsonl"
            run_files = list((Path(directory) / "results" / "runs").glob("*.json"))

            persisted_rows = trials_path.read_text(encoding="utf-8").splitlines()

        self.assertEqual(result["status"], "selected")
        self.assertEqual(result["selection"]["winner"]["candidate"], "O3_unroll")
        self.assertEqual(len(persisted_rows), 6)
        self.assertEqual(len(run_files), 1)
        for row in result["trials"][1:]:
            self.assertIn("effects", row)
            self.assertIn("contract_error", row)
            self.assertIn("delta_cost", row)

    @mock.patch("epas_demo.doctor")
    def test_unavailable_platform_creates_no_trial_evidence(self, mocked_doctor):
        mocked_doctor.return_value = {
            "status": "unavailable",
            "compiler": None,
            "runner": None,
            "missing": ["compiler", "runner"],
        }
        with tempfile.TemporaryDirectory() as directory:
            args = make_args(directory, platform="riscv64_template")
            result = run_experiment(args)

            self.assertEqual(result["status"], "unavailable")
            self.assertFalse((Path(directory) / "results" / "trials.jsonl").exists())

    @mock.patch("epas_demo.evaluate_candidate")
    @mock.patch("epas_demo.doctor")
    def test_baseline_failure_stops_candidate_evaluation(
        self, mocked_doctor, mocked_evaluate
    ):
        mocked_doctor.return_value = {
            "status": "available",
            "compiler": "gcc.exe",
            "runner": None,
            "missing": [],
        }
        mocked_evaluate.return_value = {
            "candidate": "O2_baseline",
            "status": "compile_failed",
            "measured": False,
            "correct": False,
            "error": "compiler rejected source",
        }

        with tempfile.TemporaryDirectory() as directory:
            result = run_experiment(make_args(directory))

        self.assertEqual(result["status"], "baseline_failed")
        self.assertEqual(mocked_evaluate.call_count, 1)
        self.assertEqual(len(result["trials"]), 1)

    @mock.patch("epas_demo.evaluate_candidate")
    @mock.patch("epas_demo.doctor")
    def test_no_measured_nonbaseline_candidate_is_reported(
        self, mocked_doctor, mocked_evaluate
    ):
        mocked_doctor.return_value = {
            "status": "available",
            "compiler": "gcc.exe",
            "runner": None,
            "missing": [],
        }

        def baseline_then_fail(source, candidate, platform, build_dir, **kwargs):
            if candidate["name"] == "O2_baseline":
                return measured_row("O2_baseline", 1.0)
            return {
                "candidate": candidate["name"],
                "status": "compile_failed",
                "measured": False,
                "correct": False,
                "error": "unsupported flag",
            }

        mocked_evaluate.side_effect = baseline_then_fail
        with tempfile.TemporaryDirectory() as directory:
            result = run_experiment(make_args(directory))

        self.assertEqual(result["status"], "no_valid_candidate")
        self.assertEqual(result["selection"]["status"], "no_valid_candidate")

    def test_unknown_configuration_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaises(ConfigurationError):
                run_experiment(make_args(directory, platform="unknown-platform"))


class CliTests(unittest.TestCase):
    def test_missing_riscv_tools_exit_two_without_performance_fields(self):
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            exit_code = main(["doctor", "--platform", "riscv64_template"])

        payload = json.loads(output.getvalue())
        self.assertEqual(exit_code, 2)
        self.assertEqual(payload["status"], "unavailable")
        self.assertNotIn("runtime_seconds", payload)


class RepositoryGuardTests(unittest.TestCase):
    def test_entrypoint_and_readme_exist_and_production_has_no_fake_mode(self):
        entrypoint = PROJECT_ROOT / "run.ps1"
        readme = PROJECT_ROOT / "README.md"
        self.assertTrue(entrypoint.is_file())
        self.assertTrue(readme.is_file())

        prohibited_tokens = {
            "--" + "simulate",
            "synthetic" + "_runtime",
            "world" + "_model",
            "imagined" + "_rollout",
        }
        production_files = [
            path
            for path in PROJECT_ROOT.iterdir()
            if path.suffix in {".py", ".json"}
        ]
        for path in production_files:
            text = path.read_text(encoding="utf-8").lower()
            for token in prohibited_tokens:
                self.assertNotIn(token, text, msg="{} contains {}".format(path, token))

        entrypoint_text = entrypoint.read_text(encoding="utf-8")
        self.assertIn("200000", entrypoint_text)
        self.assertIn("repeats", entrypoint_text.lower())
        self.assertIn("真实", readme.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()

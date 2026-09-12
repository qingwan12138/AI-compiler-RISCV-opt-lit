import json
import shutil
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


PROJECT_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PROJECT_ROOT))

from epas_runner import (
    assembly_metrics,
    compile_candidate,
    doctor,
    evaluate_candidate,
    load_json,
    measure_executable,
    outputs_match,
)


class DoctorTests(unittest.TestCase):
    def test_missing_compiler_is_unavailable_without_fake_metrics(self):
        result = doctor(
            {"compiler": "definitely-missing-epas-compiler", "runner": []}
        )

        self.assertEqual(result["status"], "unavailable")
        self.assertIn("compiler", result["missing"])
        self.assertNotIn("runtime_seconds", result)

    def test_available_python_tool_is_resolved(self):
        result = doctor({"compiler": "py", "runner": []})

        self.assertEqual(result["status"], "available")
        self.assertTrue(result["compiler"])
        self.assertTrue(result["compiler_version"])
        self.assertEqual(result["missing"], [])


class ConfigurationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.platforms = load_json(PROJECT_ROOT / "platforms.json")["platforms"]
        cls.contracts = load_json(PROJECT_ROOT / "contracts.json")["contracts"]
        cls.candidates = load_json(PROJECT_ROOT / "candidates.json")["candidates"]

    def test_every_contract_references_an_existing_baseline(self):
        candidate_names = {candidate["name"] for candidate in self.candidates}
        for contract in self.contracts.values():
            self.assertIn(contract["baseline"], candidate_names)

    def test_candidate_schema_and_platform_references(self):
        for candidate in self.candidates:
            self.assertIsInstance(candidate["flags"], list)
            self.assertIsInstance(candidate["delta_slots"], list)
            self.assertIsInstance(candidate["architecture_specific"], bool)
            self.assertTrue(candidate["platforms"])
            for platform_name in candidate["platforms"]:
                self.assertIn(platform_name, self.platforms)

    def test_configuration_has_no_prohibited_prediction_or_fake_data_keys(self):
        prohibited = {
            "simulate",
            "synthetic_runtime",
            "world_model",
            "imagined_rollout",
        }

        def collect_keys(value):
            if isinstance(value, dict):
                keys = set(value)
                for child in value.values():
                    keys.update(collect_keys(child))
                return keys
            if isinstance(value, list):
                keys = set()
                for child in value:
                    keys.update(collect_keys(child))
                return keys
            return set()

        all_config = {
            "platforms": self.platforms,
            "contracts": self.contracts,
            "candidates": self.candidates,
        }
        self.assertTrue(prohibited.isdisjoint(collect_keys(all_config)))

    def test_json_files_are_utf8_and_round_trip(self):
        for filename in ("platforms.json", "contracts.json", "candidates.json"):
            text = (PROJECT_ROOT / filename).read_text(encoding="utf-8")
            self.assertEqual(json.loads(text), load_json(PROJECT_ROOT / filename))


class MeasurementHelperTests(unittest.TestCase):
    def test_x86_assembly_metrics_count_conditional_branches_and_vectors(self):
        assembly = """
            movl %eax, %ebx
            je .L1
            jmp .L2
            jne .L3
            addps %xmm0, %xmm1
            vmulps %ymm2, %ymm3, %ymm4
        """
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "sample.s"
            path.write_text(assembly, encoding="utf-8")

            metrics = assembly_metrics(path, "x86")

        self.assertEqual(metrics["branch_count"], 2)
        self.assertEqual(metrics["vector_count"], 5)
        self.assertEqual(metrics["assembly_path"], str(path.resolve()))

    def test_outputs_match_only_normalizes_line_endings(self):
        self.assertTrue(outputs_match("42\n", "42\r\n"))
        self.assertFalse(outputs_match("42\n", "42 \n"))
        self.assertFalse(outputs_match("42\n", "42\n\n"))

    @mock.patch("epas_runner.assembly_metrics", side_effect=ValueError("bad assembly"))
    @mock.patch("epas_runner.measure_executable")
    @mock.patch("epas_runner.compile_candidate")
    def test_metric_parse_failure_preserves_real_run_evidence(
        self, mocked_compile, mocked_measure, mocked_metrics
    ):
        candidate = {
            "name": "O2_baseline",
            "flags": ["-O2"],
            "delta_slots": [],
            "architecture_specific": False,
        }
        platform = {"compiler": "gcc", "runner": [], "isa": "x86"}
        with tempfile.TemporaryDirectory() as directory:
            executable = Path(directory) / "candidate.exe"
            assembly = Path(directory) / "candidate.s"
            executable.write_bytes(b"real-binary-evidence")
            assembly.write_text("invalid assembly", encoding="utf-8")
            mocked_compile.return_value = {
                "status": "compiled",
                "candidate": candidate["name"],
                "compiler": "gcc",
                "executable": str(executable),
                "assembly": str(assembly),
                "commands": {"executable": ["gcc"], "assembly": ["gcc", "-S"]},
            }
            mocked_measure.return_value = {
                "measured": True,
                "stdout": "42\n",
                "runtime_seconds": 0.1,
                "runtime_min_seconds": 0.1,
                "runtime_max_seconds": 0.1,
                "runtime_mad_seconds": 0.0,
                "timings_seconds": [0.1],
                "repeats": 1,
                "warmups": 0,
                "execution_command": [str(executable), "branch", "100"],
            }

            row = evaluate_candidate(
                PROJECT_ROOT / "bench.c",
                candidate,
                platform,
                Path(directory),
                kernel="branch",
                size=100,
                repeats=1,
                warmups=0,
                timeout=10,
                expected_output="42\n",
            )

        self.assertEqual(row["status"], "metric_failed")
        self.assertTrue(row["measured"])
        self.assertTrue(row["correct"])
        self.assertEqual(row["runtime_seconds"], 0.1)
        self.assertIn("bad assembly", row["error"])


@unittest.skipUnless(shutil.which("gcc"), "real GCC is not installed")
class RealGccTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.platform = load_json(PROJECT_ROOT / "platforms.json")["platforms"][
            "x86_local_gcc"
        ]
        cls.candidate = next(
            candidate
            for candidate in load_json(PROJECT_ROOT / "candidates.json")["candidates"]
            if candidate["name"] == "O2_baseline"
        )

    def test_real_gcc_compilation_and_repeated_output_are_deterministic(self):
        with tempfile.TemporaryDirectory() as directory:
            compiled = compile_candidate(
                PROJECT_ROOT / "bench.c",
                self.candidate,
                self.platform,
                Path(directory),
                timeout=30,
            )
            first = measure_executable(
                compiled["executable"],
                self.platform,
                kernel="branch",
                size=10000,
                repeats=2,
                warmups=0,
                timeout=10,
            )
            second = measure_executable(
                compiled["executable"],
                self.platform,
                kernel="branch",
                size=10000,
                repeats=1,
                warmups=0,
                timeout=10,
            )

        self.assertEqual(compiled["status"], "compiled")
        self.assertIn("executable", compiled["commands"])
        self.assertIn("assembly", compiled["commands"])
        self.assertTrue(first["measured"])
        self.assertGreater(first["runtime_seconds"], 0.0)
        self.assertEqual(first["execution_command"][-2:], ["branch", "10000"])
        self.assertEqual(first["stdout"], second["stdout"])

    def test_evaluation_preserves_real_metrics_when_output_is_incorrect(self):
        with tempfile.TemporaryDirectory() as directory:
            row = evaluate_candidate(
                PROJECT_ROOT / "bench.c",
                self.candidate,
                self.platform,
                Path(directory),
                kernel="branch",
                size=10000,
                repeats=1,
                warmups=0,
                timeout=15,
                expected_output="deliberately-wrong\n",
            )

        self.assertEqual(row["status"], "measured")
        self.assertTrue(row["measured"])
        self.assertFalse(row["correct"])
        self.assertGreater(row["binary_bytes"], 0)
        self.assertIn("branch_count", row)
        self.assertIn("compile_commands", row)
        self.assertIn("execution_command", row)


if __name__ == "__main__":
    unittest.main()

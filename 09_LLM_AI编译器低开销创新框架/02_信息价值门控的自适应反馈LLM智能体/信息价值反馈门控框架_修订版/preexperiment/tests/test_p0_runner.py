import importlib.util
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).resolve().parents[1] / "p0_runner.py"
SPEC = importlib.util.spec_from_file_location("p0_runner", str(MODULE_PATH))
P0 = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(P0)


class P0RunnerTests(unittest.TestCase):
    def test_ir_instruction_counter(self):
        ir = """
        define i32 @f() {
        entry:
          %1 = add i32 1, 2
          store i32 %1, i32* null
          ret i32 %1
        }
        attributes #0 = { nounwind }
        """
        self.assertEqual(P0.count_ir_instructions(ir), 3)

    def test_real_candidate_removes_redundancy(self):
        _, _, init, update = P0.TASKS[0]
        baseline = P0.candidate_body("N0", 0, 0, init, update)
        real = P0.candidate_body("RealFeedback", 0, 0, init, update)
        self.assertIn("if (v == v)", baseline)
        self.assertNotIn("if (v == v)", real)

    def test_source_contains_reference_and_candidate(self):
        source = P0.make_source("return 0;", "return 0;")
        self.assertIn("static uint64_t candidate", source)
        self.assertIn("static uint64_t reference_impl", source)

    def test_bootstrap_is_reproducible(self):
        first = P0.bootstrap_mean_ci([0.0, 1.0, 2.0], draws=100)
        second = P0.bootstrap_mean_ci([0.0, 1.0, 2.0], draws=100)
        self.assertEqual(first, second)


if __name__ == "__main__":
    unittest.main()


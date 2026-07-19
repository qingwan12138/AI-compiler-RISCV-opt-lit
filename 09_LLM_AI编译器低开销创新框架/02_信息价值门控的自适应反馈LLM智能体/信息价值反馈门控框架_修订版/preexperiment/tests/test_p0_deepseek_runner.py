import importlib.util,json,sys,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]; sys.path.insert(0,str(ROOT)); SPEC=importlib.util.spec_from_file_location("p0_deepseek_runner",str(ROOT/"p0_deepseek_runner.py")); P0=importlib.util.module_from_spec(SPEC); SPEC.loader.exec_module(P0)
class Tests(unittest.TestCase):
    def test_function_ir(self):
        module="define internal i64 @candidate(ptr %0) {\nentry:\n %1 = load i32, ptr %0\n ret i64 0\n}\ndefine internal i64 @reference_impl(ptr %0) {\nentry:\n %1 = add i32 1, 2\n ret i64 0\n}\n"; selected=P0.extract_function_ir(module); self.assertNotIn("reference_impl",selected); self.assertEqual(P0.mech.count_ir_instructions(selected),2)
    def test_json(self):
        value={"candidate_body":"return 0;","action_type":"replace","target":"body","rationale":"same"}; self.assertEqual(P0.parse_output(json.dumps(value)),value)
    def test_reject_full_function(self):
        value={"candidate_body":"uint64_t candidate(const uint32_t *a, size_t n) { return 0; }","action_type":"replace","target":"body","rationale":"bad"}
        with self.assertRaises(ValueError): P0.parse_output(json.dumps(value))
    def test_placebo(self): self.assertNotIn("same unsigned accumulator",P0.feedback("MatchedPlacebo",0,"x"))
    def test_seed_blocks(self):
        task=P0.mech.TASKS[0]; self.assertNotEqual(P0.prompt_for(task,0,0,"N0"),P0.prompt_for(task,0,0,"N1"))
if __name__=="__main__": unittest.main()

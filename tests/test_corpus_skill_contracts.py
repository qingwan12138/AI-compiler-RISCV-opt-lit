from __future__ import annotations

import csv
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SKILLS = ROOT / "skills"
PRIMARY_CATEGORIES = {"SELECTOR", "TRANSLATOR", "GENERATOR", "SUPPORTING"}
OLD_MIGRATION_FIELDS = {
    "Old_Category",
    "Old_PDF_Path",
    "Old_Note_Path",
    "Proposed_PDF_Path",
    "Proposed_Note_Path",
}


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


class TaxonomyContractTests(unittest.TestCase):
    def test_current_taxonomy_has_only_current_paths_and_preserves_records(self) -> None:
        with (ROOT / "taxonomy_v2.csv").open(encoding="utf-8-sig", newline="") as stream:
            reader = csv.DictReader(stream)
            fields = set(reader.fieldnames or [])
            rows = list(reader)

        self.assertIn("PDF_Path", fields)
        self.assertIn("Note_Path", fields)
        self.assertTrue(OLD_MIGRATION_FIELDS.isdisjoint(fields))
        self.assertEqual(len(rows), 171)
        paper_ids = [row["Paper_ID"] for row in rows]
        self.assertEqual(len(set(paper_ids)), 171)
        self.assertEqual({row["Primary_Category"] for row in rows}, PRIMARY_CATEGORIES)
        for row in rows:
            if row["PDF_Path"] != "SOURCE_LIMITED_NO_LOCAL_PDF":
                self.assertTrue((ROOT / row["PDF_Path"]).is_file(), row["Paper_ID"])
            self.assertTrue((ROOT / row["Note_Path"]).is_file(), row["Paper_ID"])


class MaintainingSkillContractTests(unittest.TestCase):
    def test_maintenance_uses_current_taxonomy_and_indexes(self) -> None:
        skill_dir = SKILLS / "maintaining-compiler-literature-corpus"
        skill_files = [
            skill_dir / "SKILL.md",
            skill_dir / "references/corpus-contract.md",
            skill_dir / "scripts/validate_literature_corpus.ps1",
            ROOT / "scripts/maintain_literature_candidates.ps1",
        ]
        content = "\n".join(read_text(path) for path in skill_files)

        self.assertIn("taxonomy_v2.csv", content)
        self.assertIn("00_三大类分类索引_v2.md", content)
        for category in PRIMARY_CATEGORIES:
            self.assertIn(category, content)

        validator = read_text(skill_dir / "scripts/validate_literature_corpus.ps1")
        candidate_script = read_text(ROOT / "scripts/maintain_literature_candidates.ps1")
        self.assertNotIn("00_分类索引.md", validator)
        self.assertNotIn("00_分类索引.md", candidate_script)

        contract = read_text(skill_dir / "references/corpus-contract.md")
        self.assertNotIn("01 编译阶段排序与强化学习调优", contract)
        self.assertNotIn("06 多硬件编译、代价模型与 IR 基础设施", contract)


class ReadingSkillContractTests(unittest.TestCase):
    def test_reading_skill_obeys_taxonomy_and_leaves_ledger_ownership_to_maintainer(self) -> None:
        skill_dir = SKILLS / "reading-compiler-literature"
        entrypoint = skill_dir / "SKILL.md"
        requirements = skill_dir / "references/requirements.md"
        self.assertTrue(entrypoint.is_file(), "reading skill must be versioned in the repository")
        self.assertTrue(requirements.is_file(), "reading contract must be versioned in the repository")
        content = read_text(entrypoint) + "\n" + read_text(requirements)

        for term in ("Paper_ID", "Primary_Category", "Secondary_Category", "Note_Path"):
            self.assertIn(term, content)
        self.assertIn("文献逐篇阅读/00_逐篇阅读目录.md", content)
        self.assertIn("maintaining-compiler-literature-corpus", content)
        self.assertIn("13", content)


class InnovationSkillContractTests(unittest.TestCase):
    def test_innovation_skill_uses_three_roles_and_supporting_evidence(self) -> None:
        skill_dir = SKILLS / "developing-compiler-innovations"
        entrypoint = skill_dir / "SKILL.md"
        requirements = skill_dir / "references/requirements.md"
        self.assertTrue(entrypoint.is_file(), "innovation skill must be versioned in the repository")
        self.assertTrue(requirements.is_file(), "innovation contract must be versioned in the repository")
        content = read_text(entrypoint) + "\n" + read_text(requirements)

        for term in ("SELECTOR", "TRANSLATOR", "GENERATOR", "SUPPORTING"):
            self.assertIn(term, content)
        self.assertIn("横向标签", content)
        self.assertIn("唯一论文主线", content)
        self.assertNotIn("六类文献必须", content)
        self.assertNotIn("六类文献数量", content)


if __name__ == "__main__":
    unittest.main()

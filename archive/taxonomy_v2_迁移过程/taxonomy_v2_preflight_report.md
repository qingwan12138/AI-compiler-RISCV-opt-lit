# taxonomy v2 preflight report

- Source commit: `a6cc71496c356c73ecc29dd47679498a4b225397`
- Branch: `main`
- Created (UTC): `2026-09-07T10:59:20.851026+00:00`
- Git status at preflight: `M taxonomy_v2.csv
 M taxonomy_v2_migration_map.csv
?? scripts/classify_new_paper_template.py
?? scripts/validate_taxonomy_links.py
?? scripts/validate_taxonomy_v2.py
?? taxonomy_v2_pre_migration_manifest.json
?? taxonomy_v2_rules.md`
- Remote fetch: attempted before preflight; GitHub TLS handshake failed, while local `HEAD` and configured upstream remained the same commit. No remote state was changed.

## Frozen corpus assets

| Asset | Count |
|---|---:|
| Indexed papers | 169 |
| `paper.pdf` files | 164 |
| Reading notes | 174 |
| Repository Markdown files | 383 |

The manifest records SHA256 hashes for the legacy index, every local PDF, and every reading note before physical relocation. The taxonomy path columns and migration map were generated after this asset freeze; they do not change corpus content.

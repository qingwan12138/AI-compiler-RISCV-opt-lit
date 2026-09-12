"""Command-line orchestration for the EPAS real-measurement mini demo."""

import argparse
import csv
import hashlib
import json
import platform as host_platform
from datetime import datetime, timezone
from pathlib import Path

from epas_core import (
    contract_error,
    delta_cost,
    normalize_effects,
    select_minimal_specialization,
)
from epas_runner import doctor, evaluate_candidate, load_json


PROJECT_ROOT = Path(__file__).resolve().parent


class ConfigurationError(ValueError):
    """Raised when a named EPAS platform or contract does not exist."""


def append_jsonl(path, rows):
    """Append records to an evidence file without replacing prior trials."""
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8", newline="\n") as stream:
        for row in rows:
            stream.write(json.dumps(row, ensure_ascii=False, sort_keys=True))
            stream.write("\n")


def write_run_json(path, record):
    """Write one immutable run record."""
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(record, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def _csv_value(value):
    if isinstance(value, (dict, list)):
        return json.dumps(value, ensure_ascii=False, sort_keys=True)
    return value


def write_summary_csv(path, rows):
    """Replace the explicitly latest-only CSV view."""
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    rows = list(rows)
    fieldnames = sorted({key for row in rows for key in row})
    if not fieldnames:
        fieldnames = ["candidate", "status"]
    with path.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        for row in rows:
            writer.writerow({key: _csv_value(row.get(key, "")) for key in fieldnames})


def _run_id():
    return datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")


def _source_sha256(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def _load_configuration():
    platforms = load_json(PROJECT_ROOT / "platforms.json")["platforms"]
    contracts = load_json(PROJECT_ROOT / "contracts.json")["contracts"]
    candidates = load_json(PROJECT_ROOT / "candidates.json")["candidates"]
    return platforms, contracts, candidates


def _persist_run(record, results_dir):
    results_dir = Path(results_dir)
    evidence_rows = []
    for trial in record["trials"]:
        evidence = dict(trial)
        evidence.update(
            {
                "run_id": record["run_id"],
                "platform": record["platform"],
                "contract": record["contract"],
                "knowledge_id": record["knowledge_id"],
                "timestamp_utc": record["timestamp_utc"],
            }
        )
        evidence_rows.append(evidence)

    append_jsonl(results_dir / "trials.jsonl", evidence_rows)
    write_run_json(results_dir / "runs" / (record["run_id"] + ".json"), record)
    write_summary_csv(results_dir / "latest_summary.csv", evidence_rows)


def _make_record(run_id, args, contract, platform_check, trials, status, selection):
    source_path = PROJECT_ROOT / "bench.c"
    return {
        "run_id": run_id,
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "status": status,
        "platform": args.platform,
        "contract": args.contract,
        "knowledge_id": contract["knowledge_id"],
        "kernel": contract["kernel"],
        "selection": selection,
        "measurement": {
            "size": int(args.size),
            "repeats": int(args.repeats),
            "warmups": int(args.warmups),
            "timeout_seconds": float(args.timeout),
            "source_sha256": _source_sha256(source_path),
            "host": host_platform.platform(),
            "compiler": platform_check.get("compiler"),
            "compiler_version": platform_check.get("compiler_version"),
            "runner": platform_check.get("runner"),
        },
        "trials": trials,
    }


def run_experiment(args):
    """Run one platform/contract experiment from real compiler measurements."""
    platforms, contracts, candidates = _load_configuration()
    if args.platform not in platforms:
        raise ConfigurationError("unknown platform: {}".format(args.platform))
    if args.contract not in contracts:
        raise ConfigurationError("unknown contract: {}".format(args.contract))
    if int(args.repeats) <= 0 or int(args.size) <= 0 or int(args.warmups) < 0:
        raise ConfigurationError("size/repeats must be positive and warmups non-negative")

    platform_config = platforms[args.platform]
    contract = contracts[args.contract]
    platform_check = doctor(platform_config)
    if platform_check["status"] != "available":
        return {
            "status": "unavailable",
            "platform": args.platform,
            "contract": args.contract,
            "doctor": platform_check,
            "trials": [],
        }

    legal_candidates = [
        candidate for candidate in candidates if args.platform in candidate["platforms"]
    ]
    by_name = {candidate["name"]: candidate for candidate in legal_candidates}
    baseline_name = contract["baseline"]
    if baseline_name not in by_name:
        raise ConfigurationError(
            "baseline {} is not legal for {}".format(baseline_name, args.platform)
        )

    run_id = _run_id()
    source_path = PROJECT_ROOT / "bench.c"
    run_build_dir = Path(args.build_dir) / run_id
    baseline_candidate = by_name[baseline_name]
    baseline = evaluate_candidate(
        source_path,
        baseline_candidate,
        platform_config,
        run_build_dir,
        kernel=contract["kernel"],
        size=int(args.size),
        repeats=int(args.repeats),
        warmups=int(args.warmups),
        timeout=float(args.timeout),
        expected_output=None,
    )
    baseline["role"] = "baseline"
    trials = [baseline]

    if baseline.get("status") != "measured" or baseline.get("correct") is not True:
        record = _make_record(
            run_id,
            args,
            contract,
            platform_check,
            trials,
            "baseline_failed",
            {"status": "no_valid_candidate"},
        )
        _persist_run(record, args.results_dir)
        return record

    evaluated = []
    for candidate in legal_candidates:
        if candidate["name"] == baseline_name:
            continue
        row = evaluate_candidate(
            source_path,
            candidate,
            platform_config,
            run_build_dir,
            kernel=contract["kernel"],
            size=int(args.size),
            repeats=int(args.repeats),
            warmups=int(args.warmups),
            timeout=float(args.timeout),
            expected_output=baseline["stdout"],
        )
        if row.get("status") == "measured" and row.get("correct") is True:
            row["effects"] = normalize_effects(baseline, row)
            row["contract_error"] = contract_error(contract, row["effects"])
            row["delta_cost"] = delta_cost(candidate)
        trials.append(row)
        evaluated.append(row)

    selection = select_minimal_specialization(contract, evaluated)
    for row in evaluated:
        row["selection_role"] = "not_selected"
    if selection["status"] == "selected":
        selection["winner"]["selection_role"] = "selected"
    elif selection["status"] == "contract_unsatisfied":
        selection["diagnostic"]["selection_role"] = "diagnostic_only"

    record = _make_record(
        run_id,
        args,
        contract,
        platform_check,
        trials,
        selection["status"],
        selection,
    )
    _persist_run(record, args.results_dir)
    return record


def _build_parser():
    parser = argparse.ArgumentParser(
        description="EPAS real-measurement compiler specialization demo"
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    doctor_parser = subparsers.add_parser("doctor", help="check platform tools")
    doctor_parser.add_argument("--platform", required=True)

    run_parser = subparsers.add_parser("run", help="run a real measurement experiment")
    run_parser.add_argument("--platform", required=True)
    run_parser.add_argument("--contract", required=True)
    run_parser.add_argument("--repeats", type=int, default=5)
    run_parser.add_argument("--warmups", type=int, default=1)
    run_parser.add_argument("--size", type=int, default=1000000)
    run_parser.add_argument("--timeout", type=float, default=60.0)
    run_parser.add_argument("--build-dir", default=str(PROJECT_ROOT / "build"))
    run_parser.add_argument("--results-dir", default=str(PROJECT_ROOT / "results"))
    return parser


def main(argv=None):
    args = _build_parser().parse_args(argv)
    platforms, _, _ = _load_configuration()

    if args.command == "doctor":
        if args.platform not in platforms:
            print(
                json.dumps(
                    {"status": "configuration_error", "error": "unknown platform"},
                    ensure_ascii=False,
                )
            )
            return 2
        result = doctor(platforms[args.platform])
        result["platform"] = args.platform
        print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
        return 0 if result["status"] == "available" else 2

    try:
        result = run_experiment(args)
    except ConfigurationError as error:
        print(
            json.dumps(
                {"status": "configuration_error", "error": str(error)},
                ensure_ascii=False,
            )
        )
        return 2

    print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
    if result["status"] == "unavailable":
        return 2
    if result["status"] in {"baseline_failed", "no_valid_candidate"}:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

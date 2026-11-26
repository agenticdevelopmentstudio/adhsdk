#!/usr/bin/env python3
"""Self-test for run-local-ci's step selection. Needs neither git nor pnpm."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from run_local_ci_lib import steps_to_run  # noqa: E402


def check(label: str, got, want) -> None:
    if got != want:
        print(f"FAIL {label}: got {got!r}, want {want!r}", file=sys.stderr)
        sys.exit(1)


# --skip drops the named steps and keeps the order; --from composes with it; an
# unknown name is an error rather than a skip of nothing.
names = ["a", "b", "c", "d"]
check("no skip runs all", steps_to_run(names, None, []), names)
check("skip drops one", steps_to_run(names, None, ["b"]), ["a", "c", "d"])
check("skip repeats", steps_to_run(names, None, ["a", "d"]), ["b", "c"])
check("from and skip compose", steps_to_run(names, "b", ["c"]), ["b", "d"])
try:
    steps_to_run(names, None, ["nope"])
    check("unknown skip raises", "returned", "ValueError")
except ValueError:
    pass

print("ok")

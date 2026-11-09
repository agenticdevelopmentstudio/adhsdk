#!/usr/bin/env python3
"""Regenerate the typed OpenAPI clients into Sources/Generated/ and AuthSources/Generated/.

Manual-generate-and-commit workflow (the generated output is committed, NOT
produced by a per-build SwiftPM plugin — those are unreliable inside an
XcodeGen .xcodeproj). This script:

  1. Ensures a pinned checkout of apple/swift-openapi-generator under .tooling/
     (cloned on demand; .tooling/ is gitignored).
  2. Runs the generator against the spec once per target, emitting
     Client.swift + Types.swift for each:
       - openapi-generator-config.yaml      -> Sources/Generated/
         (AgenticDeveloperHubClient: the whole API)
       - openapi-generator-auth-config.yaml -> AuthSources/Generated/
         (AgenticDeveloperHubAuth: only the sign-in/session paths)
  3. Renames the auth target's client to HubAuthClient (file and struct), so
     the full client's `Client` never collides with it where both are visible.

Pass --spec <path> to generate from a freshly-dumped local spec (the parent
orchestrator uses this). The spec is copied into ROOT/openapi.v1.json first,
refreshing the committed snapshot.

Refresh the spec snapshot from the live backend:
    python3 scripts/generate.py --refresh-spec

Usage:
    python3 scripts/generate.py [--spec <path>] [--refresh-spec]
"""
from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
import urllib.request
from pathlib import Path

GENERATOR_REPO = "https://github.com/apple/swift-openapi-generator"
GENERATOR_VERSION = "1.12.2"
# The client is generated from the Stripe-style /v1 API, whose spec the backend's
# gateway serves at GET /v1/openapi.json on the API host
# (https://api.agenticdeveloperhub.com — see DaemonContract.backendURL).
SPEC_URL = "https://api.agenticdeveloperhub.com/v1/openapi.json"

ROOT = Path(__file__).resolve().parent.parent
TOOLING = ROOT / ".tooling" / "swift-openapi-generator"
SPEC = ROOT / "openapi.v1.json"
# The auth target's generated `Client`, renamed so it cannot shadow or collide
# with the full client's `Client` in a module that sees both.
AUTH_CLIENT_NAME = "HubAuthClient"

# (config, output directory) per target. The auth target's config filters the
# spec down to the sign-in/session paths; the full target takes everything.
TARGETS = (
    (ROOT / "openapi-generator-config.yaml", ROOT / "Sources" / "Generated"),
    (ROOT / "openapi-generator-auth-config.yaml", ROOT / "AuthSources" / "Generated"),
)


def run(cmd: list[str], cwd: Path | None = None) -> None:
    print(f"$ {' '.join(cmd)}")
    subprocess.run(cmd, cwd=cwd, check=True)


def refresh_spec() -> None:
    print(f"Fetching {SPEC_URL} -> {SPEC}")
    with urllib.request.urlopen(SPEC_URL, timeout=30) as resp:
        SPEC.write_bytes(resp.read())
    print(f"  wrote {SPEC.stat().st_size} bytes")


def ensure_generator() -> None:
    """Clone the pinned generator if absent; otherwise pin it to the tag."""
    if not TOOLING.exists():
        TOOLING.parent.mkdir(parents=True, exist_ok=True)
        run([
            "git", "clone", "--depth", "1",
            "--branch", GENERATOR_VERSION,
            GENERATOR_REPO, str(TOOLING),
        ])
        return
    # Already cloned — make sure it's at the pinned tag.
    describe = subprocess.run(
        ["git", "describe", "--tags", "--exact-match"],
        cwd=TOOLING, capture_output=True, text=True,
    )
    if describe.stdout.strip() != GENERATOR_VERSION:
        run(["git", "fetch", "--depth", "1", "origin", "tag", GENERATOR_VERSION], cwd=TOOLING)
        run(["git", "checkout", GENERATOR_VERSION], cwd=TOOLING)


def parse_args(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--spec",
        help="path to an OpenAPI spec to generate from; refreshes the committed "
             "openapi.v1.json snapshot. Omit to use the existing snapshot.",
    )
    parser.add_argument(
        "--refresh-spec", action="store_true",
        help="re-download openapi.v1.json from the live backend before generating",
    )
    return parser.parse_args(argv)


def resolve_spec(args) -> Path:
    """Decide which spec to generate from and ensure SPEC holds it."""
    if args.spec:
        shutil.copyfile(args.spec, SPEC)
    elif args.refresh_spec:
        refresh_spec()
    if not SPEC.exists():
        sys.exit(f"Missing spec snapshot {SPEC}. Pass --spec or --refresh-spec.")
    return SPEC


def generate(config: Path, output: Path) -> None:
    output.mkdir(parents=True, exist_ok=True)
    run([
        "swift", "run",
        "--package-path", str(TOOLING),
        "swift-openapi-generator", "generate",
        str(SPEC),
        "--config", str(config),
        "--output-directory", str(output),
    ])
    print(f"\nGenerated sources in {output}:")
    for f in sorted(output.glob("*.swift")):
        print(f"  {f.name}  ({f.stat().st_size:,} bytes)")


def rename_auth_client(output: Path) -> None:
    """Rename the auth target's Client.swift / `struct Client` to HubAuthClient."""
    generated = output / "Client.swift"
    renamed = output / f"{AUTH_CLIENT_NAME}.swift"
    text = generated.read_text()
    declaration = "public struct Client: APIProtocol {"
    count = text.count(declaration)
    if count != 1:
        sys.exit(f"{generated}: expected exactly one `{declaration}`, found {count}")
    renamed.write_text(text.replace(declaration, f"public struct {AUTH_CLIENT_NAME}: APIProtocol {{"))
    generated.unlink()
    print(f"  renamed Client.swift -> {renamed.name}")


def main() -> None:
    args = parse_args()
    resolve_spec(args)
    ensure_generator()
    for config, output in TARGETS:
        generate(config, output)
    rename_auth_client(TARGETS[1][1])


if __name__ == "__main__":
    main()

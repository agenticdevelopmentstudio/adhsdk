# Build output and generated code are not committed

adhsdk's git history holds source only. Build output and generated code are
produced on each machine and ignored by the root `.gitignore`, in the block
that starts "Generated code is never committed".

Derived from `b95e5fe87` ("chore: stop tracking build output and generated
code", PR #55). That commit removed 4,453 files from git (about 1.29M lines).
The files stayed on disk in every checkout that already had them.

## Why

adhsdk is embedded as a submodule in about 25 website repos and several apps.
Every copy carried the committed output twice: once in the checkout and again
in that repo's `.git/modules` history. Under `~/Development/projects/websites`,
that added up to most of an 18.2G total. Only about 56M of a 234M adhsdk copy
was hand-written code. The rest was the cookbook, generated clients, adh's
`dist/` and history. A submodule should be its code.

## What is ignored

| Path | Produced by |
|---|---|
| `packages/web/packages/adh/dist/` | adh's build (ignored like every other package's `dist/`) |
| `packages/terminal/src/apt_terminal/generated/` | openapi-python-client, from adhbackend's spec |
| `packages/apple/AgenticDeveloperHubClient/{Sources,AuthSources}/Generated/` | `scripts/generate.py` (swift-openapi-generator) |
| `packages/web/packages/adh-api-types/src/schema.ts` | openapi-typescript, from the spec |
| `packages/web/packages/crud/src/generated/`, `api-explorer/src/generated/` | the TS client generators |
| `packages/web/packages/adh/src/help/content.generated.ts` | `adh/tools/gen-help-content.py`, from adhbackend's catalog |
| `packages/web/packages/adh-registry/src/sites/routes.<site>.generated.ts` | each website repo's own route generation |

Some files have "generated" or "schema" in their names but are hand-written
inputs, so they stay tracked: `adh-registry/src/sites/routes.generated.ts`,
`status-server/src/libsql/schema.ts`, `api-explorer/src/lib/schema.ts`, and
the `openapi*.json` specs.

`deployment/run-local-ci` lost its `adh-dist-drift` step. With no committed
dist, there is nothing to drift. `run_local_ci_lib.py` now holds only
`steps_to_run`.

## Known breakages (accepted)

The change was made knowing these break, to be fixed one at a time as they
come up:

- Websites that import `@adh/...` without the `development` export condition
  get `dist/`, which a fresh clone no longer has. The fix is to build adh
  first, or to transpile from `src` (Next `transpilePackages` plus the
  `development` condition).
- The TS clients and help content need adhbackend's spec and catalog to be
  generated.
- `routes.<site>.generated.ts` files come from the website repos, not from
  adhsdk.
- The Swift client must run `scripts/generate.py` before it builds. It stays
  an explicit step because the client's README says swift-openapi-generator's
  build plugin is unreliable in an XcodeGen project.

## Building outside the source tree

The output could also be built outside the source tree entirely, in a temp or
cache directory, with packages pointing there. That was discussed but not
built. Ignoring the in-tree output was the smallest change that solved the
size problem.

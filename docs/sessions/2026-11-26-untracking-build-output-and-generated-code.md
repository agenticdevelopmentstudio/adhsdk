# Session: why the websites folder is 18G, and untracking adhsdk's build output

- **Date:** 2026-11-26
- **Session:** `b5c0166f-3f05-4e5e-ac39-f1bbd97abaec`
- **Branch:** `untrack-build-products` (merged as `b95e5fe87`, PR #55)

## Orientation

The session started with a question: why is `~/Development/projects/websites`
18.2G? The answer was the adhsdk submodule, duplicated across about 25 sites.
Each site held a checkout plus that submodule's history in `.git/modules`.
There were also orphaned agentictoolkit module histories and adhubwebsite's
`node_modules`. A closer look showed that only about 56M of a 234M adhsdk copy
was hand-written code. The rest was the markdown cookbook, generated clients,
adh's `dist/` and history.

The user asked to take generated files and dist out of git, knowing builds
would break, and to fix those breaks as they come up. That landed in
`b95e5fe87`: 4,453 files were untracked and added to `.gitignore`, and they
stayed on disk. The design and the list of known breakages are in
[build-output-not-committed](../architecture/build-output-not-committed.md).

## Decisions

- **Untrack and ignore. Don't move output out of the tree yet.** The user
  asked whether artifacts could be built into a temp dir instead. They can,
  but ignoring the in-tree output was the smallest change that fixed the size
  problem.
- **Breakages are fixed later, one at a time.** This was the user's explicit
  call. The branch adds no build-time generation.
- **Hand-written files with "generated" or "schema" names stay tracked:**
  `routes.generated.ts`, `status-server/src/libsql/schema.ts`,
  `api-explorer/src/lib/schema.ts` and the `openapi*.json` specs. They are
  inputs, not outputs.
- **The `adh-dist-drift` CI step was removed** along with its library code and
  tests. With no committed dist, it has nothing to check.
- **Swift generation stays an explicit `scripts/generate.py` step.** The
  client's README says the swift-openapi-generator build plugin is unreliable
  in an XcodeGen project. An earlier suggestion in this session to use the
  plugin was wrong and was withdrawn.

## Considered and rejected

- **Running the whole test suite for this branch.** The development
  playbook's scope script counted the 4,443 untracked files as changed code
  and said "a big change: run all". Those files stay on disk, so no test
  could fail because of the change. The user stopped the run. The fix, in
  adtoolkit's development-playbook 0.1.32, gives the script an
  `untracked` kind. Those files are neither reviewed nor tested and don't
  count toward size. The script also learned to find test files that sit
  beside the file they test. SKILL.md now says to check that a run can fail
  before starting it.

## Open threads

- Fix builds as they break: sites that need adh's `dist/`, TS clients and help
  content that need adhbackend's spec and catalog, `routes.<site>.generated.ts`
  from the website repos, and Swift's `generate.py`.
- The disk space itself is still used. Every website's submodule copy and its
  `.git/modules` history still hold the old blobs until they are re-cloned or
  pruned. Orphaned agentictoolkit module dirs are still in the site repos.
- The updated scope script still says "all" for this branch, because
  `gen-help-content.py` sits in a shared path, even though only its docstring
  changed.

## Pointers

- [build-output-not-committed](../architecture/build-output-not-committed.md):
  what is ignored, why, and what breaks.
- adhsdk PR #55, commit `b95e5fe87`.
- adtoolkit development-playbook 0.1.32, `tools/development-playbook/skill/scripts/playbook_scope.py`.

# Session: why the disk filled, and shrinking Apple build folders

- **Date:** 2026-11-11
- **Session:** `7bf5d64c-d2d8-4ad6-947f-588cfb6ebc41`
- **Branch:** `fix-build-size`

## Orientation

The disk ran out. The cause was Xcode DerivedData: one folder per worktree,
across adhsdk and its consumers, each carrying ~5 GB of Swift package clones
and ~560 MB of module cache. The session made three changes:

- vendored CodeEditLanguages
- shared one package folder per machine
- shared one clang module cache per machine

It also deleted the orphaned per-folder package copies. Free space went from
33 GB to 64 GB. Landed as PR #47 (squashed to one commit). The design and the
measurements are in
[`docs/architecture/apple-build-footprint.md`](../architecture/apple-build-footprint.md).

## Decisions

- **Vendor CodeEditLanguages rather than fork it into a new repo.** The user
  asked why another repo would be needed, and it isn't. A local path package
  with the same identity replaces the remote one, including the indirect
  dependency from CodeEditSourceEditor. The 34 MB binary is fetched by
  `binaryTarget(url:checksum:)` from upstream's raw URL at the pinned commit.
- **Licensing was set aside on the user's instruction.** Upstream has no
  license file and adhsdk is public. I stopped over this once and deleted the
  vendored copy. The user said "ignore the licencing issue, we need to fix this
  asap", so it went back in.
- **Share the package folder machine-wide** with the Xcode default
  `IDEClonedSourcePackagesDirPathOverride`. This is a machine setting, not a
  repo one, and it is documented in `.claude/CLAUDE.md`. The accepted cost:
  concurrent resolves of different pins can switch a checkout under each other.
- **Share the clang module cache** with `MODULE_CACHE_DIR` in all three
  projects. It's safe only because they use implicit modules. Measured savings:
  ~375 MB per folder.
- **Keep indexing on.** Turning it off saves ~170 MB per folder but breaks
  jump-to-definition in Xcode.
- **Exclude `Vendor/` from SwiftLint.** The first build failed because
  `--strict` linted a stray `.build` folder inside the vendored package.

## Considered and rejected

- **Splitting the editor into its own target to cut downloads.** I first said
  this would help, then corrected myself. Xcode resolves every package declared
  anywhere in the workspace, so only a separate xcodeproj outside the workspace
  would avoid a download.
- **Wrapper frameworks per external package, as a disk or warnings fix.** They
  don't help either. The user then asked about them for project organization,
  and that analysis is in the topic doc. The recommendation:
  - real wrappers for the editor and terminal
  - a re-exporting framework for GRDB
  - leave the rest alone

  Costs: duplicate-class risk, embedding in every app, iOS variants. Not built.

## Open threads

- **Wrapper-framework restructuring.** The user said "let's circle back on
  this", so it is parked by their choice, not done.
- **Consumers still clone the remote CodeEditLanguages** until their adhsdk
  submodule moves past PR #47. Affected: Kitchen, Stenographer, Olylo, Rooster.
- **Two folders weren't cleaned.**
  `AgenticDeveloperKitchen-browser-plugins/SourcePackages` was skipped because
  a build was running in it. It also goes once mydiskspace's one-day stale
  rule catches it.
- **Upstream quirk:** the CodeEdit SwiftLint plugin reports two failed commands
  on a brand-new build folder, even though the build succeeds. Not ours to fix.

## Pointers

- Topic doc: [`docs/architecture/apple-build-footprint.md`](../architecture/apple-build-footprint.md)
- Vendored package: `packages/apple/AgenticDeveloperHubSDK/Vendor/CodeEditLanguages/` (README has upgrade steps)
- PR #47: `fix(apple): shrink per-worktree build folders`
- Biggest non-build disk users at the time:
  - Stenographer Application Support: 100 GB
  - `~/Pictures`: 102 GB
  - `~/.agenticdeveloperkitchen/adkd`: 49 GB
  - Ollama: 45 GB

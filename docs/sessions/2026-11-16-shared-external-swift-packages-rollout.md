# Session: one machine-wide copy of the external Swift packages

- **Date:** 2026-11-16
- **Session:** `8a25f1cb-7b2c-4919-b6fd-3d56a03e5c6e`
- **Branch:** `shared-packages`

## Orientation

The session rolled out one machine-wide copy of the shared external Swift
packages. The `~/Development/projects/shared/externalpackages` repo installs them
into `~/Library/Developer/SharedPackages`, and every repo's XcodeGen
`project.yml` now references packages by local path through `$(HOME)` instead of
remote package URLs. `Package.resolved` files were removed. In adhsdk the work
landed as PR #50 (`build(packages)` plus `fix(ios)`) and PR #51 (`fix(tools)`:
embed and sign transitive frameworks in iOS apps). Each repo's work went through a
`shared-packages` worktree, squashed with squashr and merged with `proj wt merge`.

## Decisions

- **Local path packages, no versions in consumers.** The user's goal, in their
  words: "there is one version of the shared external libraries and everyone MUST
  conform to using that." A policy would be ignorable and a submodule could still
  pin its own version; removing every `url:` and `Package.resolved` leaves no place
  to write a different version, so no submodule can change a shared package's version.
- **Versions live only in externalpackages `packages.json`.** Adding a package
  means adding it there, never pinning it in a consumer.
- **`postGenCommand` runs `externalpackages.py portable`** on each generated
  project so the project stays portable across machines.
- **adhsdk's embed script handles flat iOS bundles and signs unsigned
  frameworks** with `EXPANDED_CODE_SIGN_IDENTITY`. This fixed adhubapp's
  iOS code-signed build, which the shared-package build had broken.
- **Replaced PR #47's vendored CodeEditLanguages and
  `IDEClonedSourcePackagesDirPathOverride`.** The shared folder keeps their disk
  saving without their cost.

## Open threads

- Other consumer repos pick the change up as their adhsdk submodule advances past
  PR #50 and PR #51.

## Pointers

- Design: [shared-external-packages.md](../architecture/shared-external-packages.md)
- Earlier disk work: [apple-build-footprint.md](../architecture/apple-build-footprint.md)
- Earlier session: [2026-11-11-apple-build-folder-size.md](2026-11-11-apple-build-folder-size.md)
- Code: `tools/apple/embed_transitive_frameworks.py`, `packages/apple/*/project.yml`

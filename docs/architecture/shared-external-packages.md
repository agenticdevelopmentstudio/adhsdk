# Shared external Swift packages

One copy of every external Swift package, at one version, for every project on
the machine. Derived from adhsdk commits `72fc62d2a` (`build(packages): take
external Swift packages from one shared folder`), `13451309a` (`fix(ios): clear
two Swift 6 concurrency errors in the iOS UI`) and `90ba2ad91` (`fix(tools):
embed and sign transitive frameworks in iOS apps`), merged as PR #50 and PR #51.

## The rule

The user's goal, in their words: "there is one version of the shared external
libraries and everyone MUST conform to using that." Nothing below a consumer can
override it, so the design removes the place a version could be written.

## How it works

- The `~/Development/projects/shared/externalpackages` repo owns `packages.json`,
  the only list of versions. `setup/install` puts each package in
  `~/Library/Developer/SharedPackages/<folder>` at the listed revision.
  `externalpackages.py pin|check|import` edits and verifies the list.
- Every XcodeGen `project.yml` in adhsdk (`AIPlugins`, `AgenticDeveloperHubClient`,
  `AgenticDeveloperHubSDK`, the app) names each package with `path:` through
  `$(HOME)/Library/Developer/SharedPackages/...`, never `url:`.
- Each `project.yml` runs
  `python3 "${HOME}/Library/Developer/SharedPackages/.tools/externalpackages.py" portable <Name>.xcodeproj`
  as its `postGenCommand`, which rewrites the generated project so it is portable.
- No `Package.resolved` is committed: with only local packages there is nothing
  to resolve. The existing ones were deleted.
- A package missing from the folder is added to the externalpackages list. It is
  never pinned in a consumer.
- Because a submodule cannot change a shared package's version, adhsdk as a
  submodule of an app cannot drift the app's packages either.
- The same rollout touched `SharedRuntime/Package.swift` and
  `tools/embedding-parity/swift/Package.swift`, which now point at the folder.

## What it replaced

PR #47's vendored `Vendor/CodeEditLanguages` package and the machine setting
`IDEClonedSourcePackagesDirPathOverride`. See
[apple-build-footprint.md](apple-build-footprint.md) for the disk-size reasoning
those served; the shared folder keeps that saving (one checkout per machine) and
removes the cost it carried (two worktrees pinning different versions).

## iOS frameworks: `tools/apple/embed_transitive_frameworks.py`

The shared-package build exposed that the iOS app bundle is flat, which the
script did not handle, so adhubapp's code-signed iOS build failed. The script now:

- finds the binary and Frameworks folder through `bundle_layout`: `Contents/MacOS`
  and `Contents/Frameworks` for macOS, binary and `Frameworks` at the bundle root
  for iOS-family apps. The executable name comes from `CFBundleExecutable`, falling
  back to the bundle name.
- signs, through `signing_identity`, any framework in the Frameworks folder that
  does not pass `codesign --verify`, using `EXPANDED_CODE_SIGN_IDENTITY` (skipped
  when `CODE_SIGNING_ALLOWED=NO`). It signs earlier runs' leftover copies too,
  since an incremental build keeps them. Xcode signs the app itself afterwards,
  so its seal covers the signed copies. A framework that cannot be signed makes
  the script exit non-zero.
- tests: `tools/apple/embed_transitive_frameworks_test.py`.

## Also in this change

Two Swift 6 concurrency errors in the iOS UI were cleared
(`MobileThinkingIndicatorView.swift`, `MarkdownFileImporter.swift`) and two
`.swiftlint.yml` lines dropped with the removed `Vendor/` directory.

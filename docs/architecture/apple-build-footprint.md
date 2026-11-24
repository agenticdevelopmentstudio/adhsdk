# Apple build footprint

How big an Apple build folder is, why, and what keeps it that size. Derived
from PR #47 (`fix(apple): shrink per-worktree build folders`), which changed
`packages/apple/*/project.yml`, every `Package.resolved`,
`AgenticDeveloperHubSDK/.swiftlint.yml`, `AgenticDeveloperHubSDK/Vendor/` and
`.claude/CLAUDE.md`. Its vendored CodeEditLanguages and shared clone folder have
since been replaced by the machine's shared package folder (below; design in
[shared-external-packages.md](shared-external-packages.md)).

## The problem it solved

Every worktree builds into its own DerivedData folder, and each folder carried:

- **~5.0 GB of Swift package clones** (`SourcePackages`). 3.2 GB of that was
  CodeEditLanguages, because upstream commits its 34 MB
  `CodeLanguagesContainer.xcframework.zip` on every release, and a SwiftPM
  clone takes the whole history (about a hundred copies of the zip).
- **~560 MB of clang module cache** (`ModuleCache.noindex`).

With a dozen worktrees open across adhsdk and its consumers (Kitchen,
Stenographer, Olylo, Rooster), that filled the disk.

The shared-code architecture is not the cause. A workspace resolves every
package declared by every project in it, so how targets are split makes no
difference to what gets downloaded.

## What is in place

| Measure | Where | Effect |
|---|---|---|
| One shared package folder per machine | `~/Library/Developer/SharedPackages`, installed by the externalpackages repo from its one version list. Every `project.yml` names each package by `path:` into it, and its `postGenCommand` runs `.tools/externalpackages.py portable` on the generated project. No `Package.resolved` is committed. | Xcode resolves nothing and clones nothing: every package is a local package, checked out once per machine at the one version the list names. A consumer cannot pin a different version, because there is no version to pin. CodeEditLanguages comes from that folder too; a local package of the same identity also replaces CodeEditSourceEditor's own dependency on it, so the old 3.2 GB clone is gone (externalpackages clones shallow). |
| One clang module cache per machine | `MODULE_CACHE_DIR: $(HOME)/Library/Developer/Xcode/SharedModuleCache` in the AIPlugins, AgenticDeveloperHubSDK and AgenticDeveloperHubSDKApp `project.yml` | Safe because these projects build with implicit modules (`SWIFT_ENABLE_EXPLICIT_MODULES: NO`). Keep the two settings together. A fresh folder's own cache drops to 185 MB (SwiftPM package targets keep theirs), and the shared 311 MB is reused. |

Consumers get the module-cache setting once their adhsdk submodule moves past
PR #47, and the shared package folder once it moves past the change that
replaced `Vendor/` and `IDEClonedSourcePackagesDirPathOverride` with it. Their own app targets still keep a small
per-folder module cache.

## What a build folder holds now (~4.6 GB, measured)

- `Build/Intermediates.noindex`, 2.8 GB: object files and dependency-tracking
  files (`.d`, `.swiftdeps`). Incremental builds need them.
- `Build/Products`, 1.3 GB. The largest items:
  - `AgenticDeveloperHubClient.framework` (401 MB): the generated API client.
    Products that only need sign-in link the HubAuth tier and avoid it.
  - `CodeLanguages_Container.framework` (375 MB): upstream's prebuilt grammar
    binary. Shrinking it means dropping languages.
- `Index.noindex`, ~170 MB. Left on deliberately: turning off
  `COMPILER_INDEX_STORE_ENABLE` for CLI builds breaks jump-to-definition when
  that folder is opened in Xcode.
- `ModuleCache.noindex` (185 MB) and `SDKExplicitPrecompiledModules` (~150 MB):
  per folder by design.

What's left to manage is the **number** of folders, not their size.
mydiskspace deletes a DerivedData folder once its worktree is gone, or once a
day has passed without a build.

## Known quirk

On a brand-new build folder, the SwiftLint build-tool plugin bundled with
CodeEditSourceEditor and CodeEditTextView reports two failed commands ("The
folder 'Output' doesn't exist"), even though lint finds 0 violations. The build
still succeeds, and rebuilding the same folder doesn't repeat it. This is
upstream's issue and unrelated to the settings above.

## Considered, not done: wrapper frameworks for external packages

Each external package would get its own framework, so the package is linked in
exactly one place. This doesn't save disk or change warnings: package targets
already build with their own settings.

- **Worth it for:**
  - GRDB, which 8 frameworks link today, through a re-exporting framework. Its
    protocols are adopted by our types, so it can't be truly wrapped.
  - Editor (CodeEdit\*) and terminal (SwiftTerm), as real wrappers. They are
    self-contained features, and 21 files import them directly.
- **Costs:**
  - Each package must be removed from every other target in the same change,
    or dyld reports duplicate classes, which is the problem SharedRuntime fixed.
  - Every consumer app has to embed each new framework, a cross-repo change.
    Plugins link without embedding, so they are unaffected.
  - Each wrapper needs iOS variants for the multi-platform users, an
    `.abstractr.json` tier and aggregate-scheme entries.
- **Not worth it for:** OpenAPI, Sparkle, onnxruntime and the LSP packages.
  Each is already linked by a single framework or one tight group.

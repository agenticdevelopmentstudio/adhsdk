
- **path-resolver-kinds**: `PathResolverKind` MUST have exactly four cases, `document`, `editor`, `terminal` and `none`, each with a string raw value equal to its name.
- **path-resolver-codable**: `PathResolverKind` MUST be `Codable` and `Sendable`.
- **tracked-app-fields**: `TrackedApp` MUST carry `bundleId`, `name` and `resolver` as immutable fields set by its initializer.
- **tracked-app-identity**: `TrackedApp.id` MUST equal `bundleId`.
- **tracked-app-conformances**: `TrackedApp` MUST be `Equatable`, `Codable`, `Sendable` and `Identifiable`.
- **defaults-list**: `AppAllowlist.defaults` MUST list exactly the 32 built-in apps in the Default apps table below, each with the name and resolver given there.
- **defaults-unique-ids**: Every bundle id in `AppAllowlist.defaults` MUST be unique.
- **defaults-resolver-assignment**: Each default MUST use the resolver in the Default apps table below.
- **construct-from-preferences**: `AppAllowlist.init(preferences:defaults:)` MUST take a `WorkTrackingPreferences` and an optional `defaults` list that defaults to `AppAllowlist.defaults`.
- **removed-excluded**: The initializer MUST drop every default whose `bundleId` is in `preferences.removedBundleIds`.
- **added-appended**: The initializer MUST append a `TrackedApp` for each id in `preferences.addedBundleIds` that is not a `defaults` bundle id and is not in `removedBundleIds`.
- **added-app-shape**: An added `TrackedApp` MUST use the bundle id as its `name` and `PathResolverKind.editor` as its `resolver`.
- **removed-beats-added**: An id present in both `addedBundleIds` and `removedBundleIds` MUST NOT appear in the allowlist.
- **added-default-ignored**: An added id equal to a `defaults` bundle id MUST NOT create a second entry; the default entry, with its own name and resolver, stays.
- **added-duplicates-collapsed**: The same id listed more than once in `addedBundleIds` MUST yield one entry.
- **sorted-apps**: `apps` MUST be sorted ascending by the pair `(name, bundleId)`, comparing each string in Unicode scalar order after normalizing it to NFC (Swift's default `String` ordering), not by locale and not by UTF-16 code unit.
- **apps-immutable**: `apps` MUST be a `let`; an `AppAllowlist` MUST NOT change after it is built.
- **is-allowed**: `isAllowed(_:)` MUST return `true` exactly when the bundle id is in `apps`, compared as an exact string match.
- **app-lookup**: `app(for:)` MUST return the `TrackedApp` for the bundle id, or `nil` when the id is not in `apps`.
- **lookup-first-wins**: When the `defaults` argument repeats a bundle id, the lookup MUST return the first of those entries in the sorted `apps` order (the table is built after the sort), while `apps` still contains both.
- **allowlist-equatable**: `AppAllowlist` MUST be `Equatable` and `Sendable`.
- **pure-no-side-effects**: Building and querying an `AppAllowlist` MUST NOT read or write files, use the network, start processes or post notifications.
- **empty-id-not-validated**: The initializer MUST NOT validate or reject bundle ids; an empty string in `addedBundleIds` MUST become an entry whose bundle id and name are both empty.

### Default apps

| bundleId | name | resolver |
|----------|------|----------|
| `com.apple.dt.Xcode` | Xcode | `document` |
| `com.apple.iphonesimulator` | Simulator | `none` |
| `com.apple.dt.Instruments` | Instruments | `none` |
| `com.google.android.studio` | Android Studio | `editor` |
| `com.jetbrains.intellij` | IntelliJ IDEA | `editor` |
| `com.jetbrains.intellij.ce` | IntelliJ IDEA CE | `editor` |
| `com.jetbrains.pycharm` | PyCharm | `editor` |
| `com.jetbrains.pycharm.ce` | PyCharm CE | `editor` |
| `com.jetbrains.WebStorm` | WebStorm | `editor` |
| `com.jetbrains.goland` | GoLand | `editor` |
| `com.jetbrains.CLion` | CLion | `editor` |
| `com.jetbrains.rubymine` | RubyMine | `editor` |
| `com.jetbrains.rider` | Rider | `editor` |
| `com.jetbrains.PhpStorm` | PhpStorm | `editor` |
| `com.jetbrains.rustrover` | RustRover | `editor` |
| `com.jetbrains.fleet` | Fleet | `editor` |
| `com.microsoft.VSCode` | Visual Studio Code | `editor` |
| `com.microsoft.VSCodeInsiders` | VS Code Insiders | `editor` |
| `com.todesktop.230313mzl4w4u92` | Cursor | `editor` |
| `com.exafunction.windsurf` | Windsurf | `editor` |
| `dev.zed.Zed` | Zed | `document` |
| `com.panic.Nova` | Nova | `document` |
| `com.barebones.bbedit` | BBEdit | `document` |
| `com.sublimetext.4` | Sublime Text | `document` |
| `com.apple.Terminal` | Terminal | `terminal` |
| `com.googlecode.iterm2` | iTerm2 | `terminal` |
| `com.mitchellh.ghostty` | Ghostty | `terminal` |
| `dev.warp.Warp-Stable` | Warp | `terminal` |
| `com.fournova.Tower3` | Tower | `none` |
| `com.sublimemerge` | Sublime Merge | `none` |
| `com.DanPristupov.Fork` | Fork | `none` |
| `com.github.GitHubClient` | GitHub Desktop | `none` |

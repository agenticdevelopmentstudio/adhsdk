# CodeEditLanguages (vendored)

Upstream: <https://github.com/CodeEditApp/CodeEditLanguages>, version 0.1.20,
commit `331d5dbc5fc8513be5848fce8a2a312908f36a11`.

## Why it is vendored

Upstream commits its prebuilt `CodeLanguagesContainer.xcframework.zip` (34 MB)
into git on every release. A SwiftPM clone takes the whole history, so each
build folder carried a 3.2 GB clone of about a hundred copies of that zip. With
one clone per DerivedData folder and one folder per worktree, it filled the
disk.

This copy holds only `Sources/CodeEditLanguages` (Swift plus tree-sitter
queries; the DocC catalogue is left out). `Package.swift` fetches the one zip
by URL and checksum, which SwiftPM downloads once into its shared artifact
cache.

`project.yml` references this directory as a local package. Xcode lets a local
package replace a remote one with the same identity, so CodeEditSourceEditor's
own dependency on CodeEditLanguages resolves here as well. The identity is the
directory name, so keep it `CodeEditLanguages`.

## Moving to a new upstream version

1. Check out the upstream tag and note its commit SHA.
2. Replace `Sources/CodeEditLanguages` with the tag's copy, minus
   `Documentation.docc`.
3. Copy any `Package.swift` changes from upstream, keeping the `binaryTarget`
   as `url:` + `checksum:`.
4. Point the URL at
   `https://raw.githubusercontent.com/CodeEditApp/CodeEditLanguages/<sha>/CodeLanguagesContainer.xcframework.zip`
   and set the checksum to `swift package compute-checksum` of that file.
5. Check that CodeEditSourceEditor's version range still accepts the new
   version.

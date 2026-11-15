---
id: e75d7d1e-2a25-452d-9c26-ea5f7cd7fa6d
title: "Git Context Fingerprint"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Samples a working tree's branch, status and recent commits as lengths and SHA-256 hashes and splices them into a status-line payload without re-encoding it."
platforms:
  - swift
  - macos
tags:
  - claude-hooks
  - foundation
  - source-control
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Git Context Fingerprint

## Overview

`GitContextFingerprint` records a fingerprint of a session's working tree each time the status line renders: the branch, the status output and the recent-commits list, the last two as a character count and a SHA-256 hash. Claude Code puts the same information in a context block of its system prompt, but that block is a snapshot taken when the conversation starts, so a change in these fields between two renders is tree drift, not a prompt change. The first sample of a session recovers the prompt's block; later samples show how far the tree has moved from what the model believes.

It stores a fingerprint and not the text because a prompt change re-caches the whole prefix whatever its size, which makes which component changed the only useful question, and a hash answers that without keeping the user's file names. `enriched(payload:)` nests the fingerprint in the status-line payload under a namespaced key, by splicing bytes into the original text. It runs in the status-line command, in the session's own directory, so the sample is not taken minutes later against a moved tree.

## Behavioral Requirements

### Sampling

- **sample-nil-outside-repo**: `sample(directory:)` MUST return nil when the branch cannot be resolved (the directory is not a repository, or the lookup fails or is empty), because there is then no block in the prompt to fingerprint.
- **sample-fields**: A sample MUST be a dictionary of exactly these keys and JSON types: `branch` (string), `status_char_count` (integer), `status_entry_count` (integer), `status_sha256` (string), `recent_commits_char_count` (integer), `recent_commits_sha256` (string) and `sampled_at` (string).
- **sample-branch**: `branch` MUST be the trimmed abbreviated name of `HEAD`.
- **sample-directory-scope**: When a directory is given every command MUST run with `-C <directory>`, and when it is nil the commands MUST run against the inherited working directory.
- **sample-config-pinned**: The status and log commands MUST be pinned against user configuration (the branch lookup is not pinned) so the fingerprint moves when the tree moves and only then: status MUST use `core.quotePath=true`, `-unormal` (matching Claude Code's own block) and `--no-renames`; the log MUST use `log.showSignature=false`, `--oneline`, `--no-decorate` and a limit of `recentCommitCount`.
- **sample-status-untrimmed**: The status output MUST be read untrimmed, see Design Decisions.
- **sample-entry-count**: `status_entry_count` MUST be the number of non-empty lines of the status output, not the number of pieces after splitting on newline, which would count the empty string after the final newline.
- **sample-counts-characters**: The two character counts MUST be the character counts of the untrimmed status text and of the trimmed commit text, and each hash MUST be the lowercase hex SHA-256 of that same text's UTF-8 bytes.
- **sample-clean-tree**: A clean tree MUST give a status count of 0, an entry count of 0 and the SHA-256 of the empty string for `status_sha256`.
- **sample-sampled-at**: `sampled_at` MUST be the UTC time of the sample in the exact form `yyyy-MM-ddTHH:mm:ssZ` (no fractional seconds, a literal `Z`), so a consumer can tell a render-time sample from one taken later on the drop-file path.
- **sample-recent-count**: `recentCommitCount` MUST be 5, the number of commits Claude Code's block lists.
- **sample-subcommand-failure**: NEEDS REVIEW: Not implemented in source. When the branch resolves but the status or log command then fails, the failure (a non-zero exit, a timeout of five seconds in `ReadOnlyGit`, or output that is not valid UTF-8) yields the empty string, which is indistinguishable from a clean tree or an empty history, so the sample reports a clean tree with the empty-string hash and no signal that the sample is wrong.

### Enrichment

- **enrich-nesting**: `enriched(payload:)` MUST return the payload with the fingerprint nested under `payloadKey`, which MUST be `stenographer_git`, a namespaced key that cannot collide with a field Anthropic adds and that the shared schema's columns are keyed on.
- **enrich-fallback**: `enriched(payload:)` MUST return the payload byte for byte unchanged when it is not a JSON object, the directory is not a repository, the fingerprint is not a valid JSON object, or the fingerprint cannot be encoded, because enrichment is best effort and a fumbled sample must never cost the daemon the row it decorates.
- **enrich-directory**: The directory sampled MUST be the payload's top-level `cwd` when it is a string, else `workspace.current_dir`, else nil, so the sample cannot drift onto whatever directory the process inherited.
- **enrich-splice**: The original bytes MUST be spliced, never re-encoded: the text up to the payload's last `}` is kept, a comma is added when the object is not empty, then `"stenographer_git":` and the fingerprint's JSON, then the remainder from that `}` on.
- **enrich-empty-object**: An empty object `{}` MUST get the fingerprint with no leading comma.
- **enrich-valid-check**: `JSONSerialization.isValidJSONObject` MUST be checked before encoding rather than relying on `try?`, see Design Decisions.
- **enrich-encoding**: The fingerprint MUST be encoded with sorted keys, so the spliced text is stable.

## Appearance

Not applicable — this is a sampling and payload-enrichment helper, not a visual component.

## States

Not applicable — this is a sampling and payload-enrichment helper, not a visual component.

## Accessibility

Not applicable — this is a sampling and payload-enrichment helper, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| git-context-fingerprint-001 | sample-nil-outside-repo | A plain directory; `testSampleReturnsNilOutsideAGitRepository` | `sample` returns nil |
| git-context-fingerprint-002 | sample-fields, sample-branch, sample-clean-tree | A fresh repository with one commit; `testSampleReportsTheBranchAndACleanTree` | The branch name, counts of 0 and the empty-string hash for status |
| git-context-fingerprint-003 | sample-config-pinned | An untracked file added; `testAnUntrackedFileMovesTheStatusHashButNotTheCommitHash` | The status hash changes and the commit hash does not |
| git-context-fingerprint-004 | sample-fields | A new commit; `testANewCommitMovesTheCommitHashButNotTheStatusHash` | The commit hash changes and the status hash does not |
| git-context-fingerprint-005 | sample-status-untrimmed | An unstaged-only change to the first path; `testTheStatusHashCountsPorcelainsLeadingStatusColumn` | The status text keeps its leading space and the hash is of the untrimmed text |
| git-context-fingerprint-006 | sample-status-untrimmed | The raw command helper on output with leading whitespace; `testRawGitKeepsWhitespaceThatGitTrimsAway` | Whitespace is kept by the raw form and trimmed by the plain form |
| git-context-fingerprint-007 | enrich-nesting | A payload with several keys, inside a repository; `testEnrichedNestsTheFingerprintAndKeepsEveryOriginalKey` | Every original key is present and `stenographer_git` holds the fingerprint |
| git-context-fingerprint-008 | enrich-directory | No `cwd`, a `workspace.current_dir`; `testEnrichedFallsBackToTheWorkspaceCurrentDir` | The repository at `current_dir` is sampled |
| git-context-fingerprint-009 | enrich-splice | A payload holding `"hit_ratio":1.0` beside `cwd`; `testEnrichedPreservesTheOriginalBytesOfEveryValue` | The output text still contains `"hit_ratio":1.0` and the output parses with the fingerprint key present |
| git-context-fingerprint-010 | enrich-nesting | `payloadKey`; `testEnrichedNamespacesTheFingerprintSoTheDaemonCanStripIt` | The key has the prefix `stenographer_` (it is `stenographer_git`) |
| git-context-fingerprint-011 | enrich-fallback | The text `not json at all`; `testEnrichedReturnsThePayloadUnchangedWhenItIsNotJSONObject` | Returned byte for byte unchanged |
| git-context-fingerprint-012 | enrich-fallback, sample-nil-outside-repo | A valid payload whose `cwd` is not a repository; `testEnrichedReturnsThePayloadUnchangedOutsideAGitRepository` | Returned byte for byte unchanged |
| git-context-fingerprint-013 | sample-entry-count | A repository with two untracked files | `status_entry_count` is 2, not 3 |
| git-context-fingerprint-014 | sample-sampled-at | Any sample | `sampled_at` matches `^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$` |
| git-context-fingerprint-015 | sample-recent-count | A repository with seven commits | `recent_commits_char_count` is the length of the five newest `--oneline` lines |
| git-context-fingerprint-016 | enrich-empty-object | The payload `{}` inside a repository | The output is `{"stenographer_git":{...}}` with no leading comma and parses |
| git-context-fingerprint-017 | sample-directory-scope | A directory argument other than the process's working directory | The sample describes the repository at that directory |
## Edge Cases

- Null and empty input: a nil directory samples the inherited directory (`sample-directory-scope`); an empty payload is not a JSON object and returns unchanged (`enrich-fallback`); an empty object `{}` gets the fingerprint with no leading comma (`enrich-empty-object`).
- Malformed input: a payload that is not a JSON object returns unchanged (`enrich-fallback`); a payload whose `cwd` is not a string falls back to `workspace.current_dir` (`enrich-directory`); a payload whose top level is an array returns unchanged (`enrich-fallback`).
- Boundary values: a repository with fewer than five commits lists those it has; a repository with no commits has no `HEAD` to abbreviate, so the branch lookup fails and the sample is nil (`sample-nil-outside-repo`).
- Concurrent access: the type holds no state, so concurrent calls are independent; two samples of a moving tree may differ, and that is the point.
- Error states: an unreadable branch gives nil, never a thrown error (`sample-nil-outside-repo`); a failed status or log command after the branch resolved is silently read as empty, see the open question on `sample-subcommand-failure`.
- Trailing content: whitespace after the payload's last `}` is preserved by the splice (`enrich-splice`); a `}` inside a string value does not matter because the last `}` of a parsed object always closes it.
- Offline or disconnected state: not applicable; the commands read the local repository only.
- Exotic paths: non-ASCII file names are escaped identically across machines by the pinned `core.quotePath=true`, and signed commits do not add signature text to the log (`sample-config-pinned`).
- Hashing: the hash input is the exact text counted, so a status text with a trailing newline hashes with it (`sample-counts-characters`).

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `directory` | `String?` | nil | The session's working directory; nil samples the inherited one |
| `recentCommitCount` | fixed | `5` | Commits in the log sample; a constant, not a caller option (`sample-recent-count`) |
| `payloadKey` | `String` | `stenographer_git` | Key the fingerprint is nested under; any future injected key carries the same prefix |
| status flags | fixed | `-unormal --no-renames` with `core.quotePath=true` | Pinned against user configuration |
| log flags | fixed | `--oneline --no-decorate` with `log.showSignature=false` | Pinned against user configuration |

## Deep Linking

Not applicable: this code defines no URL or deep link.

## Localization

Not applicable: this code produces no user-facing text, and the pinned commands run so their output does not depend on user configuration.

## Accessibility Options

Not applicable: this code has no visual surface, so no accessibility display option applies.

## Feature Flags

Not applicable: this code reads no feature flag.

## Analytics

Not applicable: this code emits no analytics events itself; the fingerprint it adds is read by the daemon that ingests the payload.

## Privacy

- **Data collected**: The branch name in the clear and, for status and recent commits, only a length and a hash; no file name or commit message is kept, which is the reason for fingerprinting.
- **Storage**: None by this type; the enriched payload is passed on to the daemon.
- **Transmission**: None; commands read the local repository and the result goes to a local daemon.
- **Retention**: Not applicable here; the consumer decides.

The branch name can itself carry meaning (a ticket id or a person's name), and a hash of a short or guessable status text can be reversed by trying candidates, so it is not an anonymisation.

## Logging

Not applicable: this code uses no OSLog; a failed sample yields nil or unchanged bytes with no log line.

## Platform Notes

- **SwiftUI**: Not used; there is no view layer.
- **Compose**: Port with `ProcessBuilder` running the same pinned arguments, `java.security.MessageDigest` for SHA-256 and `kotlinx.serialization.json` or Jackson to read `cwd`; splice with `ByteArray` operations, not a re-serialisation.
- **React/Web**: Node `child_process.execFile` with the same arguments, `crypto.createHash('sha256')`, and `Buffer` slicing for the splice; never `JSON.stringify` the payload back, which would rewrite `1.0` as `1`.
- **AppKit / UIKit**: `Core/ClaudeHooks/GitContextFingerprint.swift`, using CryptoKit's `SHA256`, `JSONSerialization` with `.sortedKeys` for the fingerprint only, `ISO8601DateFormatter` (UTC, `Z`, no fractional seconds), and `ReadOnlyGit` in `Core/Process/ReadOnlyGit.swift` for the trimmed and untrimmed command wrappers. macOS only in practice, since iOS cannot run `git`.
- **WinUI 3**: Use `System.Diagnostics.Process` with `ArgumentList` (not a joined string) to run `git.exe`, redirecting standard output as UTF-8 and reading it untrimmed for status. Hash with `System.Security.Cryptography.SHA256.HashData` and format with `Convert.ToHexStringLower`, and read `cwd` with `System.Text.Json.JsonDocument`, which never rewrites the original bytes, so splice with `Span<byte>` or `ReadOnlyMemory<byte>` and `Utf8JsonWriter` for the fingerprint only, writing its fields by hand in lexicographic key order because `System.Text.Json` has no key-sorting option. Format `sampled_at` with `DateTimeOffset.UtcNow.ToString("yyyy-MM-dd'T'HH:mm:ss'Z'", CultureInfo.InvariantCulture)` to match the pinned form. Call it from a `Task` off the UI thread.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/ClaudeHooks/GitContextFingerprint.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Store a length and a SHA-256 hash, not the status or log text.
**Rationale**: The question is which component changed, a hash answers it, and keeping the text would copy the user's file names on every render for a yes or no question.
**Approved**: pending

**Decision**: Sample in the status-line command, in the session's own directory, not at ingest.
**Rationale**: On the drop-file path ingest can run minutes later against a moved tree; `sampled_at` lets a consumer tell the two apart.
**Approved**: pending

**Decision**: Pin the status and log commands against user configuration.
**Rationale**: A fingerprint that moves with a config change, or stays put when the tree moves (as `status.showUntrackedFiles=no` freezes status at the empty digest), is worthless.
**Approved**: pending

**Decision**: Read the status untrimmed.
**Rationale**: Porcelain's first two columns are significant and the first line can begin with a space.
**Approved**: pending

**Decision**: Splice the original bytes instead of decoding and re-encoding.
**Rationale**: A round trip turns `1.0` into `1`, a schema that types columns from the first value would then declare a warm cache ratio column integer for good, and key order must stay stable for literal-JSON subtrees.
**Approved**: pending

**Decision**: Check `isValidJSONObject` before encoding.
**Rationale**: An unrepresentable value raises an Objective-C exception that `try?` does not catch, which would kill the status-line command and blank the line.
**Approved**: pending

**Decision**: When the branch resolves but the status or log command then fails, report the sample as failed (nil, or a marked field) instead of as a clean tree with the empty-string hash.
**Rationale**: Today the failure is read as `""`, so the fingerprint claims no drift when the truth is unknown; see the open question on `sample-subcommand-failure`.
**Approved**: pending

**Decision**: When the branch resolves but the status or log command then fails, report the sample as failed (nil, or a marked field) instead of as a clean tree with the empty-string hash.
**Rationale**: Today the failure is read as `""`, so the fingerprint claims no drift when the truth is unknown; see the open question on `sample-subcommand-failure`.
**Approved**: pending

**Decision**: Any failure returns the payload unchanged.
**Rationale**: Enrichment decorates a row; losing the decoration is cheaper than losing the row.
**Approved**: pending

**Decision**: The key is `stenographer_git` for every daemon.
**Rationale**: The shared schema's columns and a daemon's payload audit are keyed on that namespace, and a prefix keeps a field Anthropic adds from merging with it.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

separation-of-concerns passes: running commands lives in `ReadOnlyGit`, and this type decides what is sampled, hashes it and splices the result. unit-test-coverage passes: `GitContextFingerprintTests` (`Tests/AgenticDeveloperHubSDKCoreTests/ClaudeHooks/GitContextFingerprintTests.swift`) has a test for every vector, 001 to 017 (013 to 017 are the `testV013` to `testV017` tests). The failing-status-or-log case is `NEEDS REVIEW` in the source and has no vector.
## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (GitContextFingerprintTests.swift, 17 of 17 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Pinned field types and the sampled_at format, dropped the splice-reason requirement and duplicated rationale, fixed the recentCommitCount and WinUI notes, added five test vectors and a pending decision on subcommand failure. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |

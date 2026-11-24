---
id: 8ced488f-9037-4254-907a-ef5444f8690f
title: "MCPBearerToken"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Generates a 64-hex-character random secret and loads or creates it in a mode-0600 file, refusing symlinks and tightening wider files, for the app's local MCP endpoint."
platforms:
  - swift
  - macos
tags:
  - mcp
  - security
  - token
  - credential
depends-on: []
related:
  - 52650804-a096-4b71-b4eb-da3afa95ac56
references: []
approved-by: ""
approved-date: ""
---

# MCPBearerToken

## Overview

`MCPBearerToken` is a caseless enum holding two static operations and an error type. Its source comment calls the token "the shared secret between the app and the processes it hands the MCP URL to", stored "on disk, mode 0600, created on first load". `generate()` returns 32 random bytes as 64 lowercase hexadecimal characters. `load(from:)` reads the token from a file, or creates the file with a fresh token when there is none.

The token is the credential a caller presents as `Authorization: Bearer <token>` to the local MCP HTTP endpoint (`MCPHTTPEndpoint`), which compares the header to `Bearer <token>` without an early exit on the first differing byte. This recipe covers only the token's creation and file handling; the comparison and the route belong to the endpoint, and the registration command that puts the token in a Claude Code install belongs to `MCPRegistration`.

## Behavioral Requirements

Generation

- **generate-length**: `generate()` MUST return exactly 64 characters.
- **generate-alphabet**: Every character MUST be a hexadecimal digit, written as two lowercase digits per byte (`%02x`).
- **generate-entropy**: The 32 bytes MUST come from the system's secure random generator (`SecRandomCopyBytes` with the default generator), not from a pseudo-random generator seeded by the caller.
- **generate-fresh**: Two calls MUST NOT return the same token (`testGenerateIs64HexCharacters` asserts they differ).
- **generate-crash-on-failure**: If the secure random generator reports an error, `generate()` MUST stop the process with a precondition failure whose message names the status, and MUST NOT return a weaker token.

Loading an existing file

- **load-reads-existing**: When a regular file exists at the path and holds a non-empty token, `load(from:)` MUST return that token.
- **load-trims**: The returned token MUST be the file's content with leading and trailing whitespace and line feeds removed.
- **load-stable**: Loading the same path twice MUST return the same token.
- **load-no-format-check**: `load(from:)` MUST NOT check that an existing token is 64 hexadecimal characters; any non-empty text is returned (the test keeps the token `keepme`).
- **load-tightens**: When an existing file has any group or other permission bit set, `load(from:)` MUST set its mode to 0600 and keep its token.
- **load-leaves-narrow**: When an existing file's mode has no group or other bit set, `load(from:)` MUST NOT change its permissions.
- **load-directory-mode**: `load(from:)` MUST NOT change the mode of the directory that holds the file.

Creating the file

- **load-creates**: When nothing exists at the path, `load(from:)` MUST create the file with a freshly generated token and return it.
- **load-regenerates-empty**: When the file exists but is empty or holds only whitespace, `load(from:)` MUST treat it as no token, write a new token to the same path and return it.
- **load-creates-directory**: `load(from:)` MUST create the parent directory, including missing intermediate directories, before writing.
- **file-mode-created**: A newly written file MUST have mode 0600, and the mode MUST be set in the call that opens the file, so the file is never briefly wider.
- **file-no-newline**: The written file MUST hold the 64 characters as UTF-8 with no trailing line feed.
- **write-truncates**: When it writes over an existing empty file, the write MUST truncate it first.
- **write-no-follow**: The write MUST refuse to follow a symbolic link at the path, so a link planted after the check in `load(from:)` is refused rather than written through.
- **write-chmod**: After opening, the write MUST also set the descriptor's mode to 0600; the result of that call is not checked.

Refusing unsafe paths

- **refuse-non-regular**: When something exists at the path that is not a regular file (a symbolic link, directory, device or other), `load(from:)` MUST throw `LoadError.unreadable` and MUST NOT follow or read the target.
- **refuse-dangling-link**: A dangling symbolic link MUST be refused the same way, and nothing MUST be created at its target.
- **refuse-link-target-untouched**: The target of a refused symbolic link MUST be left unchanged.

Errors

- **error-unreadable**: Any failure while tightening or reading an existing file, or finding a non-regular file at the path, MUST be thrown as `LoadError.unreadable`, carrying the URL and the underlying error.
- **error-unwritable**: Any failure while creating the directory or writing the new file MUST be thrown as `LoadError.unwritable`, carrying the URL and the underlying error.
- **error-descriptions**: `LoadError` MUST provide a description `could not read <path>: <reason>` for the unreadable case and `could not write <path>: <reason>` for the unwritable case.
- **error-no-partial-token**: When `load(from:)` throws, it MUST NOT return a token, so a caller can use none in place of a token it could not keep.
- **concurrent-first-load**: NEEDS REVIEW: Not implemented in source. `load(from:)` checks the path, then writes it, with no lock and no exclusive-create flag (the write uses create and truncate), so two processes or threads that load a missing path at once can each write a different token and return a different one; a test or a decision about a lock or an exclusive-create open would settle it.

Security properties

- **token-lifetime**: The token MUST persist until its file is deleted; the source defines no expiry and no rotation.
- **token-revocation**: Deleting the file MUST cause the next `load(from:)` to create a new token; the source has no other revocation call, and processes already holding the old token are not told.
- **token-not-logged**: The component MUST NOT log or print the token; the source makes no log call.
- **violation-handling**: A symbolic link or other non-regular file at the path MUST be treated as a violation and refused with an error, never repaired or replaced.

## Appearance

Not applicable — this is a credential helper that reads and writes a file, not a visual component.

## States

Not applicable — this is a credential helper, not a visual component. The enum holds no state; the only state is the token file on disk, whose cases (absent, empty, present, wider than 0600, non-regular) are described under Behavioral Requirements.

## Accessibility

Not applicable — this is a credential helper, not a visual component.

## Conformance Test Vectors

Derived from `MCPBearerTokenTests` where named; the rest are traced to the source. File paths are in a fresh temporary directory.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mcp-bearer-token-001 | generate-length, generate-alphabet, generate-fresh | `generate()` twice (`testGenerateIs64HexCharacters`) | Each has 64 characters, all hexadecimal; the two differ |
| mcp-bearer-token-002 | load-creates, load-creates-directory, file-mode-created, load-stable | `load(from:)` twice on a path whose directory does not exist (`testLoadCreatesTheFileWithMode600AndIsStable`) | Both calls return the same token; the file's mode is 0600 |
| mcp-bearer-token-003 | load-tightens, load-reads-existing, load-no-format-check | File holds `keepme` with mode 0644 (`testLoadTightensAWiderExistingFileAndKeepsItsToken`) | Returns `keepme`; the file's mode is now 0600 |
| mcp-bearer-token-004 | load-trims | File holds `abc123` and a line feed (`testLoadReadsAnExistingTokenTrimmed`) | Returns `abc123` |
| mcp-bearer-token-005 | error-unwritable, error-no-partial-token | Path `/dev/null/cannot/mcp-token` (`testTokenLoadFailureIsThrown`) | Throws an error |
| mcp-bearer-token-006 | refuse-non-regular, refuse-link-target-untouched, error-unreadable | Symbolic link at the path pointing to a file holding `not-a-token` (`testASymlinkAtTheTokenPathIsRefused`) | Throws; the target file still holds `not-a-token` |
| mcp-bearer-token-007 | refuse-dangling-link | Symbolic link at the path pointing to a missing file (`testASymlinkAtTheTokenPathIsRefused`) | Throws; the missing target is not created |
| mcp-bearer-token-008 | load-regenerates-empty | File holds only spaces and a line feed | Returns a 64-character token and the file now holds it |
| mcp-bearer-token-009 | load-leaves-narrow | File holds `abc` with mode 0400 | Returns `abc`; the mode is still 0400 |
| mcp-bearer-token-010 | refuse-non-regular | A directory at the path | Throws `LoadError.unreadable` |
| mcp-bearer-token-011 | error-descriptions | Throw from a read failure and a write failure | Descriptions start `could not read <path>: ` and `could not write <path>: ` |
| mcp-bearer-token-012 | file-no-newline, write-truncates | Missing file, then read its bytes | Exactly 64 bytes, no line feed |
| mcp-bearer-token-013 | token-revocation, token-lifetime | Load, delete the file, load again | The second token differs from the first |
| mcp-bearer-token-014 | load-directory-mode | Directory with mode 0755 holding a wider token file | After `load(from:)` the directory is still 0755 |
| mcp-bearer-token-015 | generate-crash-on-failure, generate-entropy, write-no-follow, write-chmod, token-not-logged, violation-handling, error-unreadable, error-unwritable, load-reads-existing | Not testable without injecting a failing random source, or racing a link into place after the check; asserted from the source comments and calls | No test exists for these; the source's `precondition` and the `O_NOFOLLOW` open flag are the evidence |

## Edge Cases

- **Missing file**: MUST create it with mode 0600, its directory if needed, and return the new token.
- **Empty or whitespace-only file**: MUST count as no token and be overwritten with a new one.
- **Existing token with odd content**: any non-empty text, trimmed, is returned; a hand-edited short token is accepted.
- **Wider file mode**: MUST be tightened to 0600 on every load; the token is kept.
- **Unwritable location**: a path under a file, or a read-only volume, MUST throw `LoadError.unwritable`; covered by `testTokenLoadFailureIsThrown`.
- **Unreadable existing file**: a file the process cannot read MUST throw `LoadError.unreadable`.
- **Symbolic link, directory or device at the path**: MUST be refused with `LoadError.unreadable`; covered by `testASymlinkAtTheTokenPathIsRefused` for links.
- **Link planted between the check and the write**: the open uses the no-follow flag, so the write is refused and `LoadError.unwritable` is thrown.
- **Secure random failure**: MUST stop the process with a precondition failure; the source does not fall back.
- **Concurrent first load**: see the open question on `concurrent-first-load`.
- **Concurrent load of an existing file**: each caller reads the same content, so each returns the same token; tightening is idempotent.
- **Offline or disconnected state**: not applicable — the component uses only the local file system and the system random generator.
- **Token wiped while the app runs**: a caller that loaded the token once keeps using its copy; the new file is read only on the next `load(from:)`.
- **Non-UTF-8 content in an existing file**: reading as UTF-8 throws and MUST surface as `LoadError.unreadable`; the file is not overwritten.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `file` | URL | none (required) | The token file passed to `load(from:)`; the caller chooses its location and name |
| Token size | constant | 32 bytes (64 hex characters) | Fixed in `generate()`; not configurable |
| File mode | constant | 0600 | Fixed in the write and in the tightening step; not configurable |

## Deep Linking

Not applicable: the component reads and writes a file and defines no URL scheme or route.

## Localization

`LoadError` descriptions are English strings built in the source, `could not read <path>: <reason>` and `could not write <path>: <reason>`, with the underlying error's localized description as the reason. The test comment says the feature turns a thrown error into a status line, so the text can reach a user. The source passes them through no localization table.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none; literal) | `could not read <path>: <reason>` | `LoadError.unreadable` description |
| (none; literal) | `could not write <path>: <reason>` | `LoadError.unwritable` description |

## Accessibility Options

Not applicable: the component has no visual output, so Reduce Motion, Increase Contrast and Differentiate Without Color do not apply.

## Feature Flags

Not applicable: the source reads no flag or setting.

## Analytics

Not applicable: the source emits no analytics events.

## Privacy

- **Data collected**: The bearer token, a random secret that identifies no person. It is the only credential this component handles.
- **Storage**: In a regular file at the caller's path, mode 0600 from creation, as plain text with no encryption and no Keychain use; the directory's mode is left as it was.
- **Transmission**: This component sends nothing. The token leaves the file when the app writes it into the registration command or into the environment of processes it hands the MCP URL to, and callers present it as a bearer header to the local endpoint.
- **Retention**: Until the file is deleted. The source defines no expiry and no rotation; deleting the file is the only revocation, and the next load creates a new token.

## Logging

Not applicable: the source makes no log call, so the token and the paths are never logged by this component.

## Platform Notes

- **SwiftUI**: Source is `packages/apple/AgenticDeveloperHubSDK/macOS/Features/MCP/MCPBearerToken.swift` in the macOS module; it imports `Foundation` and `Security` and has no view code. A SwiftUI app calls `load(from:)` once at launch from a non-UI context and shows a thrown `LoadError` as a status line.
- **Compose**: Use `java.security.SecureRandom` for 32 bytes and format with `joinToString("") { "%02x".format(it) }`. Create the file with `java.nio.file.Files.createFile` and `PosixFilePermissions.fromString("rw-------")` as the attribute so the mode is set at creation, and refuse links with `LinkOption.NOFOLLOW_LINKS` and `Files.readAttributes` (`isRegularFile`). On Android, app-private storage is already per-app, and the Android Keystore with `EncryptedFile` is the stronger store; the Swift source uses a plain file.
- **React/Web**: In Node, use `crypto.randomBytes(32).toString("hex")`, `fs.openSync(path, fs.constants.O_WRONLY | fs.constants.O_CREAT | fs.constants.O_TRUNC | fs.constants.O_NOFOLLOW, 0o600)` to match the open call, and `fs.lstatSync(path).isFile()` for the regular-file check; `fs.chmodSync` tightens. A browser has no such file, so use a server-side store or an HTTP-only cookie instead; do not put the secret in `localStorage`.
- **AppKit / UIKit**: Same file, which lives in the macOS module; it uses `FileManager`, `lstat`, `open(2)` with `O_NOFOLLOW`, `fchmod`, `FileHandle` and `SecRandomCopyBytes`, and nothing in it is AppKit-specific, so a UIKit port needs only a different file location. The Keychain is the platform's usual place for secrets; this source deliberately uses a 0600 file so child processes and shell scripts can read the same file.
- **WinUI 3**: Implement as a static .NET class. Generate with `RandomNumberGenerator.GetBytes(32)` and `Convert.ToHexString(bytes).ToLowerInvariant()` (64 lowercase characters). Windows has no POSIX modes, so replace mode 0600 with a file ACL: create the file with `FileStream` and a `FileSecurity` (`System.Security.AccessControl`) granting access to the current user only, or use `Windows.Storage.ApplicationData.Current.LocalFolder` (per-user app data) and DPAPI (`ProtectedData.Protect` with `DataProtectionScope.CurrentUser`) if the token must not be readable as plain text. Refuse reparse points the way the source refuses links: check `FileAttributes.ReparsePoint` on `FileInfo.Attributes` and `File.GetAttributes`, and open with `FileOptions` that do not follow them (`FILE_FLAG_OPEN_REPARSE_POINT` through `CreateFile`). Return errors as a `LoadException` with `Unreadable` and `Unwritable` cases carrying the path and the inner exception, and throw it from `static string Load(string path)`. Use `File.ReadAllText(path, Encoding.UTF8).Trim()`. The source has no XAML or observable state, so no `INotifyPropertyChanged` is needed.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/MCP/MCPBearerToken.swift` | confirmed (1.0.0) |
| apple | (planned) | planned |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The file is created with mode 0600 in the `open(2)` call itself, with `fchmod` as a second step.
**Rationale**: The source comment says this leaves no window in which the file is wider than 0600. The `fchmod` result is not checked. A umask can only narrow the open mode, so the call matters only when the file already existed, and the tightening step has already run in that case.
**Approved**: pending

**Decision**: A symbolic link, directory or device at the token path is refused, and the write uses `O_NOFOLLOW`.
**Rationale**: The source comment says that following a link would read the token from, or write it to, wherever the link points; `O_NOFOLLOW` covers a link planted after the check in `load(from:)`.
**Approved**: pending

**Decision**: An existing file wider than 0600 is tightened instead of refused, and its token is kept.
**Rationale**: A token written by an earlier version or by hand keeps working; `testLoadTightensAWiderExistingFileAndKeepsItsToken` asserts it. The directory's mode is left alone because it may be shared.
**Approved**: pending

**Decision**: An empty or whitespace-only file counts as no token and is regenerated.
**Rationale**: The source returns a token only when the trimmed content is non-empty, so an empty bearer token is never handed out; the source does not say what leaves an empty file behind.
**Approved**: pending

**Decision**: Existing token text is trimmed but not checked against the 64-hex format.
**Rationale**: The source returns any non-empty content; the test keeps `keepme`. A hand-chosen secret keeps working, at the cost that the strength of an existing token is the file owner's responsibility.
**Approved**: pending

**Decision**: A failure of the secure random generator stops the process.
**Rationale**: The source uses a `precondition`; returning a weaker or empty token would silently weaken the only credential protecting the local endpoint.
**Approved**: pending

**Decision**: The token is stored as plain text in a file, not in the Keychain, with no expiry and no rotation.
**Rationale**: The source comment names the token as shared with processes the app hands the MCP URL to, which read the same file. Rotation is by deleting the file. The source gives no reason for omitting expiry, so this is recorded as the actual behaviour.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | partial | security |
| [adc.check.security.token-lifecycle](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/61edfc73-f26a-5cfa-8c09-d1011eb8b7cd) | partial | security |
| [adc.check.security.secure-log-output](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b258657f-bb73-5491-9c70-0d14afdfa6ce) | passed | security |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |

The component does one job, creating and loading the token file, and leaves comparison and registration to other types. `MCPBearerTokenTests` covers generation, creation, tightening, trimming, an unwritable path and symbolic links, but not an empty file, a directory at the path, the crash on random failure or concurrent first loads, so coverage is partial. Secure storage is partial: the file is mode 0600 from the first byte and links are refused, but the token sits in plain text rather than the Keychain. Token lifecycle is partial: creation and revocation by deletion are defined, but there is no expiry or rotation. The component never logs the token, and every failure is thrown as a typed error.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |

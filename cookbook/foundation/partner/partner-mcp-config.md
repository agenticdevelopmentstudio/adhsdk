---
id: ad0b0d88-6ade-49aa-8fd3-5d9926060112
title: "Partner MCP Config"
type: ingredient
version: 1.1.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-23
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Builds and securely writes the --mcp-config file that points the partner's claude at the app's local MCP endpoint, carrying a bearer token and a caller id."
platforms:
  - swift
  - macos
tags:
  - partner
  - mcp
  - config
  - security
depends-on: []
related:
  - 0a3f46c1-aa22-4af3-91f0-6631c9fdddfd
  - c77c4cfb-e9be-4339-b40d-3f7abc6a4543
references: []
approved-by: ""
approved-date: ""
---

# Partner MCP Config

## Overview

`PartnerMCPConfig` is a case-less enumeration that produces the JSON file handed to the partner's `claude` process through `--mcp-config`. The file names one HTTP MCP server, `adkitchen`, at `http://127.0.0.1:<port>/mcp`, and carries two headers: an `Authorization: Bearer <token>` header and an `X-ADHD-Pane: <callerID>` header that tells the endpoint which caller is speaking. `json` builds the bytes; `write` stores them in a file that the owner alone can read at every moment. The partner controller writes it each time it starts the partner, using the port and token of the app's MCP endpoint.

## Behavioral Requirements

Constants

- **server-name**: `serverName` MUST be the string `adkitchen`; it is the only key under `mcpServers`.
- **caller-header-name**: `callerHeader` MUST be the string `X-ADHD-Pane`, `HostMCPServer.callerHeader`.

Building the JSON (`json(port:token:callerID:)`)

- **json-shape**: The output MUST be a JSON object with one key, `mcpServers`, whose value is an object with one key, `adkitchen`, whose value is an object with exactly the keys `type`, `url` and `headers`.
- **json-type**: `type` MUST be the string `http`.
- **json-url**: `url` MUST be `http://127.0.0.1:` followed by the decimal port and `/mcp`; the host MUST be the loopback address, never a hostname or a configurable value.
- **json-headers**: `headers` MUST be an object with exactly two keys: `Authorization`, whose value is `Bearer ` followed by the token, and `X-ADHD-Pane`, whose value is the caller id.
- **json-sorted-keys**: Keys MUST be written in sorted order, so equal inputs give byte-identical output.
- **json-unescaped-slashes**: Forward slashes MUST NOT be escaped, so the url reads `http://127.0.0.1:...` rather than with `\/`.
- **json-compact**: The output MUST be compact (no pretty-printing whitespace).
- **json-no-validation**: The function MUST NOT validate the token or the caller id: an empty or unusual string is written as given (JSON-escaped), and any `UInt16` port, 0 included, is written as is.
- **json-cannot-fail**: Serialization MUST be treated as infallible, because every value is a plain string; if it ever fails the function MUST halt (trap) rather than return empty data; the source halts with `preconditionFailure`, and the message text is not part of the contract.
- **json-pure**: The function MUST be pure: no I/O, no clock, no shared state.

Writing the file (`write(port:token:callerID:to:)`)

- **write-parent-directory**: The function MUST create the parent directory of the target, with intermediate directories, with permissions 0700.
- **write-parent-tightened**: The function MUST then set the parent directory's permissions to 0700 even when it already existed with looser permissions.
- **write-temp-sibling**: The data MUST first go to a temporary file in the same directory, named `.<target file name>.<UUID>.tmp`, so the later rename stays on one volume and the name cannot collide.
- **write-temp-mode**: The temporary file MUST be created with `open` using `O_CREAT | O_EXCL | O_WRONLY` and mode 0600, so it is never readable by others at any moment; the data MUST NOT be written before the file has its final restrictive mode.
- **write-open-failure**: If `open` fails, the function MUST throw `CocoaError(.fileWriteNoPermission)`, whatever the cause; the underlying errno is not carried in the error.
- **write-content**: The temporary file MUST hold exactly the bytes from `json` for the same arguments.
- **write-atomic-rename**: After writing and closing the handle, the function MUST `rename` the temporary file over the target, so a concurrent reader sees the old complete file or the new complete file, never a partial one. This makes no promise about crash durability: the source does not `fsync` before the rename, so after a crash or power loss the target may be empty or partly flushed.
- **write-rename-failure**: If `rename` fails, the function MUST throw `CocoaError(.fileWriteUnknown)`, whatever the cause; the underlying errno is not carried in the error.
- **write-cleanup**: If writing, closing or renaming fails, the function MUST remove the temporary file (ignoring any error from the removal) and rethrow the original error.
- **write-overwrite-mode**: When the target already exists with looser permissions (for example 0644), the result MUST be at most mode 0600 and never group- or world-accessible (the `open` mode is masked by the process umask, so a umask of 0277 gives 0400), because the new file replaces the old one rather than being written into it.
- **write-no-residue**: After a successful write the directory MUST hold no leftover temporary file.
- **write-errors-propagate**: Errors from directory creation or from setting permissions MUST propagate to the caller unchanged; the function MUST NOT swallow them.

## Appearance

Not applicable — this is a configuration writer, not a visual component.

## States

Not applicable — this is a stateless namespace of two functions, not a visual component; each `write` call is independent and leaves either the new complete file or the previous state of the target.

## Accessibility

Not applicable — this is a configuration writer, not a visual component.

## Conformance Test Vectors

Vectors 001 and 002 are asserted in `PartnerProcessConfigurationTests`; the rest are derived from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| partner-mcp-config-001 | write-temp-mode, write-overwrite-mode, json-headers, json-url | `write(port: 51477, token: "tok", callerID: "c1", to: <new file>)` (`mcpConfigWritesHeadersAndMode0600`) | File mode is 0600; text contains `"X-ADHD-Pane":"c1"` and `http://127.0.0.1:51477/mcp` |
| partner-mcp-config-002 | write-parent-tightened, write-overwrite-mode, write-no-residue | Parent directory 0755 holding `mcp.json` with content `old`, mode 0644; `write(port: 1, token: "new", callerID: "c1", to: mcp.json)` (`mcpConfigOverwritesLooseFileAndSecuresDirectory`) | File mode 0600; directory mode 0700; content contains `new`; directory listing is exactly `["mcp.json"]` |
| partner-mcp-config-003 | json-shape, json-type, json-sorted-keys, json-compact, json-unescaped-slashes | `json(port: 8080, token: "t", callerID: "c")` | `{"mcpServers":{"adkitchen":{"headers":{"Authorization":"Bearer t","X-ADHD-Pane":"c"},"type":"http","url":"http://127.0.0.1:8080/mcp"}}}` |
| partner-mcp-config-004 | server-name, caller-header-name | Read `serverName` and `callerHeader` | `adkitchen` and `X-ADHD-Pane` |
| partner-mcp-config-005 | json-sorted-keys, json-pure | Call `json` twice with the same arguments | The two results are byte-identical |
| partner-mcp-config-006 | json-no-validation | `json(port: 0, token: "", callerID: "")` | Url is `http://127.0.0.1:0/mcp`; `Authorization` is `Bearer ` (with trailing space); `X-ADHD-Pane` is the empty string; nothing is thrown |
| partner-mcp-config-007 | json-no-validation | `json(port: 1, token: "a\"b", callerID: "c")` | The token appears JSON-escaped as `Bearer a\"b`; the result parses back to `Bearer a"b` |
| partner-mcp-config-008 | json-url | `json(port: 65535, token: "t", callerID: "c")` | Url is `http://127.0.0.1:65535/mcp` |
| partner-mcp-config-009 | write-parent-directory | Target in a directory that does not exist, nested two levels deep | Both levels are created; the immediate parent has mode 0700 |
| partner-mcp-config-010 | write-content | Write, then read the file | The bytes equal `json` for the same arguments |
| partner-mcp-config-011 | write-errors-propagate | Target whose parent directory belongs to another user, so `setAttributes` fails | The call throws the `setAttributes` error unchanged; no file appears at the target |
| partner-mcp-config-012 | write-cleanup, write-rename-failure | Target path that is an existing non-empty directory, so `rename` fails | `CocoaError(.fileWriteUnknown)` is thrown; no `.tmp` file remains in the parent |
| partner-mcp-config-013 | write-temp-sibling | Write twice to the same target in a row | Both succeed; the second replaces the first; no temp name collides |
| partner-mcp-config-014 | write-atomic-rename | Write once, open a handle on the target, then write again to the same target | The target now holds the complete new JSON in a different file (inode); the earlier handle still reads the complete old content |

## Edge Cases

- **Target exists, looser mode**: Replaced by a 0600 file through rename (MUST; see write-overwrite-mode).
- **Parent exists, looser mode**: Tightened to 0700 (MUST; see write-parent-tightened). This changes the mode of a directory the caller may have created for other uses, so the caller MUST pass a target that lives in a directory dedicated to the partner.
- **Failure between temp creation and rename**: The temp file is removed; the target is untouched (MUST).
- **Failure of the cleanup itself**: Ignored; the original error is thrown (MUST).
- **Process killed between temp creation and rename**: A hidden `.tmp` file holding the token, mode 0600, can remain in the directory. The source has no sweep for it; the 0700 parent and the 0600 mode keep it private to the owner.
- **Empty or odd token or caller id**: Written as given, JSON-escaped (MUST; see json-no-validation); rejecting them is the caller's job.
- **Concurrent writers to one target**: Each uses its own unique temp name and renames atomically, so the target always holds one complete writer's output; which writer wins is not defined.
- **Token or port changes between starts**: The file is rewritten on each partner start by the controller, so a stale file is replaced rather than edited.
- **Network, timeouts, offline**: Not applicable — the type opens no connection; it only writes the address and credentials of a local endpoint.
- **Symbolic link at the target**: `rename` replaces the link itself, not its destination; the source does not follow or check links.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `serverName` | string constant | `adkitchen` | Key of the server under `mcpServers` |
| `callerHeader` | string constant | `X-ADHD-Pane` | Name of the caller-id header |
| `port` | `UInt16` | none (required) | Port of adhd's MCP endpoint on the loopback address (the channel's port) |
| `token` | string | none (required) | Bearer token the endpoint accepts |
| `callerID` | string | none (required) | Identifies the caller to the endpoint |
| `url` (`write`) | file URL | none (required) | Target file; its parent is created and secured |

The directory mode (0700), the file mode (0600), the path `/mcp` and the host `127.0.0.1` are fixed in the source, not configurable.

## Deep Linking

Not applicable: the type writes a config file and has no URL routing; the `url` it writes points at a local HTTP endpoint, not a deep link.

## Localization

Not applicable: the output is machine-read JSON with fixed keys and the header names are protocol identifiers, so nothing is shown to a person.

## Accessibility Options

Not applicable: the type renders nothing, so Reduce Motion, Increase Contrast and Differentiate Without Color do not reach it.

## Feature Flags

Not applicable: the source reads no flag.

## Analytics

Not applicable: the source emits no analytics event.

## Privacy

- **Data collected**: None. The type receives a port, a token and a caller id from its caller.
- **Storage**: The bearer token is stored in clear text in the config file. The protection is the file system: the parent directory is 0700 and the file is 0600, so only the owning user can read it. The source does not encrypt the file or keep the token in a keychain.
- **Transmission**: The token is not sent by this type. The partner's `claude` reads the file and sends the token in the `Authorization` header to `127.0.0.1`, so it stays on the machine. The transport is plain `http` on the loopback address, with no TLS.
- **Retention**: The file stays on disk until something removes or replaces it; `write` replaces it on each partner start. Token lifetime and revocation belong to the MCP endpoint that issues the token, not to this type.

## Logging

Not applicable: the source makes no log call. A caller that logs the config bytes or the token would leak the bearer token, so neither belongs in a log.

## Platform Notes

- **SwiftUI**: This is UI-agnostic Foundation code, importing only `Foundation`. It uses `JSONSerialization` with `.sortedKeys` and `.withoutEscapingSlashes`, `FileManager` for the directory, and POSIX `open` and `rename` for the file; the file handle is wrapped with `FileHandle(fileDescriptor:closeOnDealloc: true)`.
- **Compose**: Port as a Kotlin `object PartnerMcpConfig` that builds the JSON with a serializer that sorts keys and does not escape slashes. Write with `Files.createTempFile` in the same directory using `PosixFilePermissions` 0600 passed at creation, then `Files.move` with `ATOMIC_MOVE` and `REPLACE_EXISTING`; set the directory to `rwx------` on POSIX file systems.
- **React/Web**: Not applicable in a browser. A Node port uses `fs.mkdir` with mode 0o700 plus `fs.chmod`, `fs.open` with flags `wx` and mode 0o600 for a unique sibling temp name, then `fs.rename`. Build the JSON with sorted keys; `JSON.stringify` does not escape slashes.
- **AppKit / UIKit**: Identical to the SwiftUI note: the type is UI-framework agnostic. On iOS the same code runs but the partner process it serves is macOS-only in this source.
- **WinUI 3**: Port as a static class with `Build(ushort port, string token, string callerId)` returning UTF-8 bytes from `System.Text.Json` with ordered keys and `JavaScriptEncoder.UnsafeRelaxedJsonEscaping` so slashes stay literal, and `Write(...)`. POSIX modes do not exist on Windows, so create the directory and temp file with an access-control list that grants only the current user (`DirectorySecurity` and `FileSecurity` with inheritance removed), open the temp file with `FileMode.CreateNew`, then `File.Move` with overwrite (`File.Replace` for atomic replace on one volume). Treat the access-control list as the equivalent of 0700 and 0600.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Partner/PartnerMCPConfig.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The file is created 0600 at creation, never written then chmod-ed.
**Rationale**: The source comment says the file carries the bearer token, "so it is never readable by others at any moment". Creating with the mode and `O_EXCL` closes the window in which a file with the default umask would be readable.
**Approved**: pending

**Decision**: Write to a sibling temp file and rename over the target.
**Rationale**: The rename is atomic on one volume, so the partner's `claude` never reads a half-written file, and it replaces a pre-existing file of looser mode with a fresh 0600 file.
**Approved**: pending

**Decision**: The parent directory is forced to 0700 on every write.
**Rationale**: A directory created earlier with looser permissions would otherwise expose the file name and allow others to swap files; the tests assert the 0755 to 0700 tightening.
**Approved**: pending

**Decision**: The endpoint address is fixed to `127.0.0.1` over plain `http`.
**Rationale**: The endpoint is the app's own local MCP server, so the token never leaves the machine; fixing the host removes a configuration that could point the token at another machine.
**Approved**: pending

**Decision**: `json` halts with `preconditionFailure` instead of throwing if serialization fails.
**Rationale**: The input is all plain strings, so failure would be a programming error and not a runtime condition worth a throwing signature; the message records the reason.
**Approved**: pending

**Decision**: The type neither issues, rotates nor revokes the token.
**Rationale**: It only records what the caller supplies; token lifetime and revocation are owned by the MCP endpoint that creates the token, which keeps this type a pure file writer.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | partial | security |
| [adc.check.security.secure-transport](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0a75f61f-9508-506e-b92e-0f5b29a91c95) | partial | security |

The type does one job, building and writing the file, so separation of concerns passes. `PartnerMCPConfigConformanceTests` covers the full JSON shape, escaping, file and directory modes, nested parents, the rename failure and its cleanup, repeated writes and the atomic swap, so 13 of 14 vectors have tests; vector 011 (a parent directory owned by another user) is skipped because a unit test cannot create one safely, so coverage is partial. Failures throw named `CocoaError` values and the temp file is removed, so error handling passes. Secure storage is partial: the token is protected by 0700 and 0600 permissions and an atomic rename, but it is stored in clear text and a killed process can leave a temp file behind. Secure transport is partial: the token travels only to the loopback address, but over plain `http` without TLS.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.0 | 2026-11-23 | Mike Fullerton | The partner's config sends adhd's caller header, X-ADHD-Pane, to adhd's endpoint. |
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (PartnerMCPConfigConformanceTests.swift, 13 of 14 vectors; 011 skipped); unit-test-coverage stays partial. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Corrected the umask, durability, errno, trap and vector 011/014 claims, made the dedicated-directory rule a MUST, linked the sibling recipes and trimmed the platform note. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |

---
id: 81fb66c5-e31d-4817-ba36-5ccace191e8f
title: "Digest Hex"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Lowercase two-digit-per-byte hex string of any CryptoKit digest, the one place hash bytes become the hex strings the daemon stores."
platforms:
  - swift
  - macos
tags:
  - foundation
  - text
  - hashing
  - hex
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Digest Hex

## Overview

`Digest.hexString` is a public computed property added to every CryptoKit `Digest` (SHA-256, SHA-1, MD5 and the rest). It renders the digest's bytes as a lowercase hexadecimal string, two digits per byte, and is the one place the daemon turns hash bytes into the hex strings it stores: `transcript_lines.line_hash` and `ConfigChange.file_sha256`. Keeping it in one place means every stored hash is spelled the same way, so two hashes of the same bytes compare equal as strings.

## Behavioral Requirements

- **extension-scope**: The component MUST be a public computed property `hexString` of type `String` on the `Digest` protocol, available to every conforming digest type.
- **lowercase**: Every hexadecimal letter in the result MUST be lowercase (`a` to `f`).
- **two-digits-per-byte**: Each byte MUST render as exactly two hexadecimal digits, with a leading zero for a byte below 0x10, so the result length is twice the digest's byte count.
- **byte-order**: The digits MUST appear in the digest's iteration order, first byte first, with no separator, prefix or suffix.
- **empty-digest**: A digest with no bytes MUST render as the empty string; no standard CryptoKit digest has zero bytes, so the source does not reach it.
- **pure**: The property MUST have no side effect and MUST return the same string each time for the same digest value.
- **single-rendering**: Daemon code that stores a digest as text MUST obtain it through this property, which the source states is "the one place" that does it.
- **no-failure**: The property MUST NOT throw or return an optional; it cannot fail.
- **dependencies**: The component MUST depend only on CryptoKit and Foundation (`String(format:)`).

## Appearance

Not applicable — this is a string-rendering extension on a hash type, not a visual component.

## States

Not applicable — this is a pure computed property, not a visual component; it holds no state.

## Accessibility

Not applicable — this is a string-rendering extension, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| digest-hex-001 | lowercase, two-digits-per-byte, byte-order | `SHA256.hash(data: Data("abc".utf8)).hexString` (test: sha256OfAKnownStringIsItsLowercaseHex). | `ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad`. |
| digest-hex-002 | two-digits-per-byte | `SHA256.hash(data: Data()).hexString` (derived from the source; no test). | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`, 64 characters. |
| digest-hex-003 | extension-scope, two-digits-per-byte | `Insecure.SHA1.hash(data: Data("abc".utf8)).hexString` (derived from the source; no test). | `a9993e364706816aba3e25717850c26c9cd0d89d`, 40 characters. |
| digest-hex-004 | extension-scope | `Insecure.MD5.hash(data: Data("abc".utf8)).hexString` (derived from the source; no test). | `900150983cd24fb0d6963f7d28e17f72`, 32 characters. |
| digest-hex-005 | lowercase | Any digest rendered with `hexString`, tested for the pattern of one or more characters from `0-9a-f` only (derived from the source; no test). | No upper-case letter appears. |
| digest-hex-006 | two-digits-per-byte | `Insecure.MD5.hash(data: Data("a".utf8)).hexString` (derived from the source; no test). | `0cc175b9c0f1b6a831c399e269772661`, 32 characters: the first byte 0x0c renders as `0c`, keeping its leading zero. |
| digest-hex-007 | pure | Call `hexString` twice on one digest value (derived from the source; no test). | Both calls return identical strings. |

## Edge Cases

- **Null / empty input**: Hashing empty data still gives a full-length digest (SHA-256 gives 32 bytes), which renders as 64 characters (MUST). A zero-byte digest would render as the empty string; CryptoKit has no such digest.
- **Boundary values**: A byte of 0x00 renders as `00` and 0xFF as `ff` (MUST); a byte below 0x10 keeps its leading zero (MUST).
- **Concurrent access**: The property reads an immutable value digest and keeps no shared state, so calls from any thread are independent.
- **Error states**: Not applicable: the property cannot fail and has no error path.
- **Offline / disconnected state**: Not applicable: the property performs no I/O.
- **Performance**: Each byte goes through `String(format:)` and the pieces are joined, so the cost is per byte; the source makes no claim about speed and hashes rendered are digest-sized (16 bytes for MD5 to 64 for SHA-512).

## Configuration

None — the property takes no parameter and reads no environment variable or settings key; it renders whatever `Digest` it is called on.

## Deep Linking

Not applicable: The component defines no URL scheme, route or navigation destination.

## Localization

Not applicable: The component contains no user-facing string; `String(format:)` is given only `%02x` for an integer, which has no locale-dependent output.

## Accessibility Options

Not applicable: The component presents no UI.

## Feature Flags

Not applicable: The source contains no feature-flag reference.

## Analytics

Not applicable: The source contains no analytics call.

## Privacy

- **Data handled**: A hash of whatever the caller digested; the hash can identify content, so the caller decides whether storing it is acceptable.
- **Storage**: None; the caller stores the string (the daemon uses `transcript_lines.line_hash` and `ConfigChange.file_sha256`).
- **Transmission**: None; it performs no network access.
- **Retention**: None beyond the lifetime of the returned string.

## Logging

Not applicable: The source calls no logging API.

## Platform Notes

- **SwiftUI**: The source is `packages/apple/AgenticDeveloperHubSDK/Core/Text/DigestHex.swift`, imports `CryptoKit` and `Foundation`, and has no SwiftUI dependency. Its single test is `DigestHexTests` in `AgenticDeveloperHubSDKCoreTests/Text`, using Swift Testing.
- **Compose**: Hash with `java.security.MessageDigest` and render with `joinToString("") { "%02x".format(it) }` (a boxed `Byte` already formats as two unsigned hex digits under `%x`, so no mask is needed), or `HexFormat.of().formatHex(bytes)` on JDK 17, which is lowercase by default.
- **React/Web**: Hash with `crypto.subtle.digest("SHA-256", data)` and render with `Array.from(new Uint8Array(buf), b => b.toString(16).padStart(2, "0")).join("")`; `toString(16)` is lowercase and `padStart(2, "0")` keeps the leading zero. In Node, `createHash("sha256").update(data).digest("hex")` is the same string.
- **AppKit / UIKit**: Identical to the SwiftUI note: CryptoKit is the same on both and nothing in the file touches UI.
- **WinUI 3**: Use `System.Security.Cryptography` (`SHA256.HashData(bytes)`, which returns `byte[]`) and render with `Convert.ToHexString(hash).ToLowerInvariant()` (.NET 5 and later; `Convert.ToHexString` is upper-case, so the `ToLowerInvariant` call is required) or `string.Concat(hash.Select(b => b.ToString("x2")))`. Put it in a static extension class over `byte[]` rather than over a digest type, since .NET hash APIs return a plain byte array and have no `Digest` protocol.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Text/DigestHex.swift` | confirmed (1.0.0) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Render lowercase hex, two digits per byte, with no separator or prefix.
**Rationale**: The strings are stored in the daemon's database columns and compared as text; one spelling means equal hashes are equal strings.
**Approved**: pending

**Decision**: Put the rendering on `Digest` as one shared property.
**Rationale**: The source calls it "the one place the daemon turns hash bytes into the hex strings it stores", so a second copy cannot drift.
**Approved**: pending

**Decision**: Build the string byte by byte with `String(format: "%02x", ...)` and `joined()`.
**Rationale**: The source gives none; this is recorded as the implementation, and a port need only match the output, not the mechanism.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

separation-of-concerns passes: the extension only renders bytes as text; hashing and storing the string belong to its callers. unit-test-coverage is partial: `DigestHexTests` asserts the SHA-256 of `abc`, which exercises lowercase letters and the byte order, but nothing asserts the leading zero of a byte below 0x10, the empty-data digest, or a digest type other than SHA-256.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |

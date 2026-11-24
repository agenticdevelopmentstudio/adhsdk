---
id: 81fb66c5-e31d-4817-ba36-5ccace191e8f
title: "Digest Hex"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Lowercase two-digit-per-byte hex string of any CryptoKit digest, one spelling for every hash stored as text."
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

`Digest.hexString` is a public computed property added to every CryptoKit `Digest` (SHA-256, SHA-1, MD5 and the rest). It renders the digest's bytes as a lowercase hexadecimal string, two digits per byte, and gives every caller that stores a digest as text the same spelling. Keeping the rendering in one place means two hashes of the same bytes compare equal as strings.

## Behavioral Requirements

- **extension-scope**: The component MUST be a public computed property `hexString` of type `String` on the `Digest` protocol, available to every conforming digest type.
- **lowercase**: Every hexadecimal letter in the result MUST be lowercase (`a` to `f`).
- **two-digits-per-byte**: Each byte MUST render as exactly two hexadecimal digits, with a leading zero for a byte below 0x10, so the result length is twice the digest's byte count.
- **byte-order**: The digits MUST appear in the digest's iteration order, first byte first, with no separator, prefix or suffix.
- **pure**: The property MUST have no side effect and MUST return the same string each time for the same digest value.
- **no-failure**: The property MUST NOT throw or return an optional; it cannot fail.
- **dependencies**: The component MUST depend only on CryptoKit and Foundation.

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
| digest-hex-005 | lowercase, byte-order, two-digits-per-byte | `SHA512.hash(data: Data("abc".utf8)).hexString` (derived from the source; no test). | `ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f`, 128 characters, no upper-case letter. |
| digest-hex-006 | two-digits-per-byte | `Insecure.MD5.hash(data: Data("a".utf8)).hexString` (derived from the source; no test). | `0cc175b9c0f1b6a831c399e269772661`, 32 characters: the first byte 0x0c renders as `0c`, keeping its leading zero. |
| digest-hex-007 | pure | Call `hexString` twice on one digest value (derived from the source; no test). | Both calls return identical strings. |

## Edge Cases

- **Null / empty input**: Hashing empty data still gives a full-length digest (SHA-256 gives 32 bytes), which renders as 64 characters (MUST). A digest with no bytes would render as the empty string; no CryptoKit digest has zero bytes, so this case is not reachable and no vector covers it.
- **Boundary values**: A byte of 0x00 renders as `00` and 0xFF as `ff` (MUST); a byte below 0x10 keeps its leading zero (MUST).
- **Concurrent access**: The property reads an immutable value digest and keeps no shared state, so calls from any thread are independent.
- **Error states**: Not applicable: the property cannot fail and has no error path.
- **Offline / disconnected state**: Not applicable: the property performs no I/O.
- **Performance**: Each byte goes through `String(format:)` and the pieces are joined, so the cost is per byte; no speed claim is made, and hashes rendered are digest-sized (16 bytes for MD5 to 64 for SHA-512).

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
- **Storage**: None; the caller stores the string.
- **Transmission**: None; it performs no network access.
- **Retention**: None beyond the lifetime of the returned string.

## Logging

Not applicable: The source calls no logging API.

## Platform Notes

- **SwiftUI**: The component imports only `CryptoKit` and `Foundation`, has no UI dependency, and so is the same on AppKit and UIKit; a SwiftUI view calls `hexString` on any digest.
- **Compose**: Hash with `java.security.MessageDigest` and render with `joinToString("") { "%02x".format(it) }` (a boxed `Byte` already formats as two unsigned hex digits under `%x`, so no mask is needed), or `HexFormat.of().formatHex(bytes)` on JDK 17, which is lowercase by default.
- **React/Web**: Hash with `crypto.subtle.digest("SHA-256", data)` and render with `Array.from(new Uint8Array(buf), b => b.toString(16).padStart(2, "0")).join("")`; `toString(16)` is lowercase and `padStart(2, "0")` keeps the leading zero. In Node, `createHash("sha256").update(data).digest("hex")` is the same string.
- **AppKit / UIKit**: Same as the SwiftUI note: CryptoKit is the same on both.
- **WinUI 3**: Use `System.Security.Cryptography` (`SHA256.HashData(bytes)`, which returns `byte[]`) and render with `Convert.ToHexString(hash).ToLowerInvariant()` (.NET 5 and later; `Convert.ToHexString` is upper-case, so the `ToLowerInvariant` call is required) or `string.Concat(hash.Select(b => b.ToString("x2")))`. Put it in a static extension class over `byte[]` rather than over a digest type, since .NET hash APIs return a plain byte array and have no `Digest` protocol.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Text/DigestHex.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Render lowercase hex, two digits per byte, with no separator or prefix.
**Rationale**: Stored hashes are compared as text, so one spelling means equal hashes are equal strings.
**Approved**: pending

**Decision**: Put the rendering on `Digest` as one shared property.
**Rationale**: With one rendering, callers that store a digest as text should take it from this property, so a second copy of the spelling cannot drift. That constrains callers, so each consuming recipe states it as its own integration requirement.
**Approved**: pending

**Decision**: Build the string byte by byte with `String(format: "%02x", ...)` and `joined()`.
**Rationale**: It is the simplest correct rendering, and digests are small (16 to 64 bytes), so the per-byte cost does not matter. A port need only match the output, not the mechanism.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

separation-of-concerns passes: the extension only renders bytes as text; hashing and storing the string belong to its callers. unit-test-coverage passes: `DigestHexTests` (`Tests/AgenticDeveloperHubSDKCoreTests/Text/DigestHexTests.swift`) has a test for each of the seven vectors, covering the leading zero, the empty digest, SHA-1, MD5 and SHA-512.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (DigestHexTests.swift, 7 of 7 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Described the guarantee generally instead of naming one consumer, gave real rationales, moved empty-digest to Edge Cases, dropped the String(format:) mechanism and the caller-side requirement, replaced vector 005 with SHA-512 of abc and merged the Apple notes. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |

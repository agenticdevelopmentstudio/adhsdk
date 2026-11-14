---
id: cdadfe1d-e4a2-4e2d-96a7-a5eb615a1302
title: "Gmail Message Parser"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-13
modified: 2026-11-13
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Turns a Gmail format=full message into an EmailMessage: headers, addresses, bodies, attachments, charsets and dates."
platforms:
  - swift
  - macos
  - ios
tags:
  - gmail
  - mail-sync
  - mime
  - parser
depends-on:
  - 888b7ba2-61f6-4251-88df-3586c5c86b1f
  - ea7a9ec6-0a0c-4e97-8b03-ebc5f6246a43
related:
  - aed9acc9-6340-487b-acfb-b7b13f14e59a
references: []
approved-by: ""
approved-date: ""
---

# Gmail Message Parser

## Overview

`GmailMessageParser` is a caseless `enum` of static functions that converts one decoded Gmail API message (`GmailMessageDTO`, requested with `format=full`) into an `EmailMessage` record. It keeps no shared state, performs no I/O and raises no errors: every malformed or missing input degrades to an empty value or a fallback. Use it wherever a Gmail message is mirrored into local storage.

The input is a tree of `GmailPart` values (`mimeType`, `filename`, `headers`, `body`, `parts`). `GmailBody` carries `attachmentId`, `size` and base64url `data`. The output is a flat record: sender, recipients, subject, snippet, plain and HTML bodies, label ids, an ISO 8601 date, the history id, a list of attachment references (`EmailAttachmentRef`) and a `MailClass` derived by `MailClassifier.classify` (cookbook:ea7a9ec6-0a0c-4e97-8b03-ebc5f6246a43) from the label ids. The output types `EmailMessage` and `EmailAttachmentRef` are specified in the integration records recipe (cookbook:888b7ba2-61f6-4251-88df-3586c5c86b1f). `MailClassifier` and the persistence of the record are separate components; `MailIntegrationService` (cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a) is the caller that mirrors parsed messages into storage.

## Behavioral Requirements

Contract: `parse(_ dto: GmailMessageDTO, connectionId: String, existingId: String?, now: Date = Date()) -> EmailMessage`. It is `public static`. Two helpers, `base64URLDecode` and `splitAddresses`, are module-internal and are also specified here because tests call them.

### Record identity and passthrough fields

- **total-function**: `parse` MUST return an `EmailMessage` for every input and MUST NOT throw or return an optional.
- **existing-id-kept**: The record `id` MUST equal `existingId` when `existingId` is non-nil.
- **generated-id**: The record `id` MUST be a newly generated UUID string in lowercase when `existingId` is nil. The generator is `UUID()` called inside `parse`, not an injected dependency, so the id cannot be fixed by a caller.
- **connection-id-passthrough**: The record `connectionId` MUST equal the `connectionId` argument.
- **external-id-passthrough**: The record `externalId` MUST equal the message `id` and `threadId` MUST equal the message `threadId`.
- **provider-default**: The record `provider` MUST be `gmail`, because the parser does not pass a provider and the `EmailMessage` initializer defaults it.
- **record-defaults**: The record `isDeleted` MUST be false and `deletedAt` MUST be nil, and `createdAt` and `updatedAt` MUST be the current time at the moment of the call, because the parser leaves those `EmailMessage` initializer defaults untouched; the `now` argument does not feed them.
- **snippet-default**: The record `snippet` MUST equal the message `snippet`, or the empty string when it is absent.
- **label-ids-passthrough**: The record `labelIds` MUST equal the message `labelIds`, or an empty list when they are absent.
- **history-id-passthrough**: The record `historyId` MUST equal the message `historyId` and stay nil when it is absent.
- **mail-class-derived**: The record `mailClass` MUST be the result of `MailClassifier.classify` (cookbook:ea7a9ec6-0a0c-4e97-8b03-ebc5f6246a43) applied to the same label ids that populate `labelIds`.

### Headers and addresses

- **header-lookup**: A header MUST be found by a case-insensitive name comparison, and when several headers share a name the first one in `payload.headers` MUST win.
- **headers-absent**: A message with no `payload`, or a payload with no `headers`, MUST be treated as having an empty header list.
- **from-raw**: The record `fromAddress` MUST be the unmodified value of the `From` header, or the empty string when there is none.
- **subject-raw**: The record `subject` MUST be the unmodified value of the `Subject` header, or the empty string when there is none.
- **recipient-lists**: The record `toAddresses` and `ccAddresses` MUST each be the `To` and `Cc` header value passed through the address splitter, and MUST be empty lists when the header is absent.
- **address-split-commas**: The address splitter MUST split on every comma that is outside double quotes.
- **address-split-escapes**: Inside double quotes, a backslash MUST cause the next character to be kept literally, so an escaped quote does not close the quoted section.
- **address-split-trim**: The address splitter MUST trim leading and trailing horizontal whitespace (spaces, tabs and other Unicode space separators, but not newlines) from each piece and MUST drop pieces that are empty after trimming.
- **address-split-keeps-text**: The address splitter MUST keep each piece's text, including display names and angle brackets, exactly as written apart from that trimming.

### Date

- **date-from-internal-date**: The record `internalDate` MUST be derived from the message `internalDate` read as a decimal number of epoch milliseconds when that value parses as a number.
- **date-from-header**: When the message `internalDate` is absent or does not parse as a number, the record `internalDate` MUST be derived from the `Date` header.
- **date-header-formats**: The `Date` header MUST be read with the POSIX English locale (`en_US_POSIX`) in exactly three layouts, tried in this order: `EEE, d MMM yyyy HH:mm:ss Z`, `d MMM yyyy HH:mm:ss Z` and `EEE, d MMM yyyy HH:mm Z` (Unicode date-format pattern letters; `Z` accepts a numeric zone such as `+0000`).
- **date-header-comment**: Everything from the first opening parenthesis of the `Date` header onward MUST be ignored before parsing, and surrounding spaces MUST be trimmed.
- **date-now-fallback**: When neither source yields a date, the record `internalDate` MUST be derived from the `now` argument, so the message sorts as new and not as 1970.
- **date-output-format**: The record `internalDate` MUST be an ISO 8601 string in UTC with fractional seconds to three digits, produced by `IntegrationClock.string(from:)`.

### Body and attachments

- **part-walk**: The parser MUST visit the payload and then every descendant part depth first, in document order, with no depth limit.
- **mime-match**: A part's `mimeType` MUST be compared in lowercase against the exact strings `text/plain`, `text/html` and `message/rfc822`; a missing `mimeType` MUST be treated as the empty string.
- **first-text-wins**: The record `bodyText` MUST come from the first `text/plain` part that belongs to the message's own content, and `bodyHtml` from the first such `text/html` part; later parts of the same type MUST be ignored.
- **named-part-is-file**: A part with a non-empty `filename` MUST NOT supply body text or body HTML, and neither MUST any part nested inside it.
- **attachment-listed**: A part with a non-empty `filename` and a non-nil `body.attachmentId` MUST add one `EmailAttachmentRef` carrying that `attachmentId`, the `filename`, the `mimeType` and the `size` to `attachments`, in document order.
- **attachment-defaults**: An attachment reference MUST use `application/octet-stream` when the part has no `mimeType` and MUST use size 0 when the part has no `body.size`.
- **attachment-nested-listed**: A named part with an attachment id MUST be listed even when it sits inside an embedded `message/rfc822` or inside another named part.
- **named-inline-unlisted**: A named part with no `attachmentId` (Gmail inlined its data) MUST NOT be listed as an attachment and MUST NOT become the body.
- **unnamed-in-named-ignored**: An unnamed part nested inside a named part MUST NOT be listed as an attachment, even when it carries an `attachmentId`.
- **embedded-message-isolated**: Text and HTML inside an unnamed `message/rfc822` part that sits in the message's own content MUST NOT be merged into the message body when the message has a body of its own.
- **embedded-message-fallback**: When the message has neither own plain text nor own HTML, `bodyText` and `bodyHtml` MUST be taken from the first plain text and first HTML found inside the embedded message.
- **embedded-fallback-all-or-nothing**: When the message has either an own plain text or an own HTML body, both `bodyText` and `bodyHtml` MUST come only from the message's own content, so an embedded body never fills the missing half.
- **no-body-is-nil**: `bodyText` and `bodyHtml` MUST be nil when no qualifying part exists.

### Decoding

- **base64url-decode**: Body data MUST be decoded as base64url: `-` read as `+`, `_` read as `/`, and `=` padding appended until the length is a multiple of four.
- **charset-declared**: Body bytes MUST be decoded with the charset named by the `charset` parameter of that part's own `Content-Type` header when the name is a recognised IANA charset and the bytes are valid in it.
- **charset-parameter-parsing**: The `charset` parameter name MUST be matched case-insensitively, and its value MUST have surrounding spaces and surrounding single or double quotes removed.
- **charset-fallback**: When no usable charset is declared, or decoding with it fails, the bytes MUST be decoded as UTF-8, and when that fails as ISO Latin-1.
- **undecodable-body-data**: A part whose `body.data` is not valid base64url MUST yield a nil body for that part with no log, error or flag, and a later part of the same type MUST then fill the body instead. Whether a dropped body should be surfaced is a pending Design Decision.

### Concurrency and side effects

- **no-shared-state**: The parser MUST NOT read or write shared mutable state, so concurrent calls on different inputs are independent. It is not referentially transparent: the environmental reads are the current time for the `now` default, `createdAt` and `updatedAt`, and a random UUID for the generated id.
- **no-io**: The parser MUST NOT perform file, network, process or notification side effects and MUST NOT log.

## Appearance

Not applicable — this is a data-transformation function, not a visual component.

## States

Not applicable — this is a data-transformation function, not a visual component.

## Accessibility

Not applicable — this is a data-transformation function, not a visual component.

## Conformance Test Vectors

Tests live in `GmailMessageParserTests.swift` beside the SDK; fixtures are `gmail-message-multipart.json`, `gmail-message-html-only.json`, `gmail-message-latin1.json`, `gmail-message-windows1252.json` and `gmail-message-quoted-charset.json`. Vectors marked "derived" come from the code, not from a named test.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| parser-001 | total-function, part-walk, first-text-wins, attachment-listed, from-raw, subject-raw, external-id-passthrough, mail-class-derived | Test `parsesPlainAndHtmlFromNestedAlternative`: fixture `message-multipart`, connection `c1`, no existing id | `bodyText` is `Hello plain`; `bodyHtml` is `<b>Hi</b>`; `attachments` is one ref (`att1`, `a.pdf`, `application/pdf`, 1234); `fromAddress` is `Jane <j@x.com>`; `subject` is `Hi`; `mailClass` is `filed`; `externalId` is `m1` |
| parser-002 | no-body-is-nil, mail-class-derived | Test `parsesHtmlOnly`: fixture `message-html-only` | `bodyText` is nil; `bodyHtml` is `<p>x</p>`; `mailClass` is `trash` |
| parser-003 | charset-declared | Test `decodesLatin1Charset`: bytes C3 A9 with declared Latin-1 | `bodyText` is U+00C3 U+00A9, not the UTF-8 reading |
| parser-004 | charset-declared | Test `decodesWindows1252Charset`: fixture `message-windows1252`, part header `Content-Type: text/plain; charset=windows-1252`, data the single byte 80 | `bodyText` is U+20AC |
| parser-005 | charset-parameter-parsing | Test `decodesQuotedMixedCaseCharsetParameter`: fixture `message-quoted-charset`, part header `Content-Type: text/plain; CharSet="iso-8859-1"`, data bytes C3 A9 | `bodyText` is U+00C3 U+00A9 |
| parser-006 | recipient-lists, address-split-commas, address-split-keeps-text, headers-absent | Test `splitsAddressListsRespectingQuotes`: `To` is `"Doe, Jane" <j@x.com>, b@y.com`, no `Cc` | `toAddresses` is two entries, `"Doe, Jane" <j@x.com>` and `b@y.com`; `ccAddresses` is empty |
| parser-007 | date-from-internal-date, date-output-format | Test `internalDateConvertsToISO`: `internalDate` `1730800000000` | `internalDate` is `2024-11-05T09:46:40.000Z` |
| parser-008 | header-lookup, recipient-lists | Test `parsesANonEmptyCcList`: header named lowercase `cc` | `ccAddresses` is `"Roe, Ann" <a@x.com>` and `b@y.com` |
| parser-009 | named-part-is-file, named-inline-unlisted | Test `aNamedTextPartWithoutAnAttachmentIdIsNotTheBody`: named `notes.txt` text part without attachment id, then an unnamed text part | `bodyText` is `body`; `attachments` is empty |
| parser-010 | embedded-message-fallback | Test `aMessageWhoseOnlyContentIsAnUnnamedEmbeddedMessageShowsItsBody`: payload `multipart/mixed` with one unnamed `message/rfc822` child holding `text/plain` data `inner` and `text/html` data `<b>inner</b>` | `bodyText` is `inner`; `bodyHtml` is `<b>inner</b>` |
| parser-011 | embedded-message-isolated, embedded-fallback-all-or-nothing | Test `anEmbeddedMessageIsNotMergedIntoAnOuterBody`: own plain text `body`, embedded message with text and HTML | `bodyText` is `body`; `bodyHtml` is nil |
| parser-012 | named-part-is-file, embedded-message-fallback | Test `aNamedPartInsideAnEmbeddedMessageNeverBecomesTheBody`: payload `multipart/mixed` with one unnamed `message/rfc822` child whose only text part is named `inner.txt` and has no attachment id | `bodyText` is nil |
| parser-013 | date-from-header, date-header-formats | Test `missingInternalDateFallsBackToTheDateHeader`: no `internalDate`, `Date` is `Tue, 05 Nov 2024 09:46:40 +0000` | `internalDate` is `2024-11-05T09:46:40.000Z` |
| parser-014 | date-now-fallback, date-from-header | Test `missingInternalDateAndDateHeaderFallsBackToNowNotTheEpoch`: `internalDate` `not-a-number`, `Date` `garbage`, `now` fixed | `internalDate` equals `IntegrationClock.string(from: now)` |
| parser-015 | existing-id-kept, generated-id | Test `keepsExistingIdElseGeneratesOne`: existing id `keep`, then nil | First result `id` is `keep`; second is non-empty (the id cannot be asserted exactly because the generator is not injected) |
| parser-016 | generated-id | Derived: parse with `existingId` nil | `id` equals its own lowercased form and is a valid UUID string |
| parser-017 | provider-default, record-defaults, connection-id-passthrough | Derived: any parse with connection `c9` | `provider` is `gmail`; `connectionId` is `c9`; `isDeleted` is false; `deletedAt` is nil |
| parser-018 | snippet-default, label-ids-passthrough, history-id-passthrough | Derived: DTO with no snippet, no label ids, no history id | `snippet` is empty; `labelIds` is empty; `historyId` is nil |
| parser-019 | address-split-escapes | Derived: `splitAddresses` on the literal `"Doe \"Jr\", Jane" <j@x.com>, b@y.com` | Two entries, `"Doe \"Jr\", Jane" <j@x.com>` and `b@y.com`; the escaped quote does not close the quoted name, so the comma inside it does not split |
| parser-020 | address-split-trim | Derived: `splitAddresses` on ` a@x.com , , b@y.com ,` | `a@x.com` and `b@y.com`; empty pieces dropped |
| parser-021 | headers-absent, recipient-lists | Derived: `splitAddresses` on nil, which is what an absent `To` or `Cc` header gives | Empty list |
| parser-022 | date-header-comment, date-header-formats | Derived: no `internalDate`, `Date` is `Tue, 05 Nov 2024 09:46:40 +0000 (UTC)` | `internalDate` is `2024-11-05T09:46:40.000Z` |
| parser-023 | date-header-formats | Derived: no `internalDate`, `Date` is `5 Nov 2024 09:46:40 +0000` | `internalDate` is `2024-11-05T09:46:40.000Z` |
| parser-024 | date-header-formats | Derived: no `internalDate`, `Date` is `Tue, 05 Nov 2024 09:46 +0000` | `internalDate` is `2024-11-05T09:46:00.000Z` |
| parser-025 | date-from-internal-date | Derived: `internalDate` `1730800000000` and a differing `Date` header | The `internalDate` value wins; the header is ignored |
| parser-026 | base64url-decode | Derived: `base64URLDecode` on `SGVsbG8gcGxhaW4` and on `PGI-SGk8L2I-` | `Hello plain` bytes and `<b>Hi</b>` bytes |
| parser-027 | base64url-decode, undecodable-body-data | Derived: `base64URLDecode` on `a` (length remainder 1) | nil |
| parser-028 | charset-fallback | Derived: part without a `Content-Type` header, bytes C3 A9 | `bodyText` is the single character U+00E9 |
| parser-029 | charset-fallback | Derived: bytes E9 only, no charset | `bodyText` is U+00E9 through the ISO Latin-1 fallback |
| parser-030 | charset-fallback | Derived: declared charset `x-not-a-charset`, bytes `Ym9keQ` | `bodyText` is `body` |
| parser-031 | first-text-wins | Derived: two sibling `text/plain` parts, `one` then `two` | `bodyText` is `one` |
| parser-032 | mime-match | Derived: part `mimeType` `TEXT/PLAIN` | Treated as plain text; `bodyText` set |
| parser-033 | attachment-defaults | Derived: named part with attachment id, no `mimeType`, no size | Ref has `application/octet-stream` and size 0 |
| parser-034 | attachment-nested-listed | Derived: named part with attachment id inside an unnamed `message/rfc822` | Listed in `attachments`; `bodyText` unaffected |
| parser-035 | unnamed-in-named-ignored | Derived: unnamed part with an attachment id inside a named part | `attachments` is empty |
| parser-036 | embedded-fallback-all-or-nothing | Derived: own HTML only, embedded message with plain text | `bodyHtml` is the own HTML; `bodyText` is nil |
| parser-037 | headers-absent, total-function, no-body-is-nil | Derived: DTO with `payload` nil and no `internalDate` | `fromAddress`, `subject` empty; no bodies; no attachments; `internalDate` from `now` |
| parser-038 | undecodable-body-data, first-text-wins | Derived: first `text/plain` part has data `a`, second has `Ym9keQ` | `bodyText` is `body` |
| parser-039 | no-shared-state, no-io | Derived: two parses of the same DTO with `existingId` set and the same `now` | The two records are equal except that `createdAt` and `updatedAt` are the call-time clock and may differ |

## Edge Cases

- **Null and empty input**: A DTO with no payload yields empty `fromAddress`, `subject`, address lists and attachments, and nil bodies. The parse MUST still return a record.
- **Empty address header**: A `To` header that is empty or only commas and spaces yields an empty list. This MUST hold.
- **Missing label ids**: Absent `labelIds` become an empty list, and the classifier decides the class from that empty list. This MUST hold.
- **Malformed numeric date**: An `internalDate` that is not a number, such as `not-a-number`, falls through to the `Date` header and then to `now`. This MUST hold.
- **Unreadable Date header**: A header that matches none of the three layouts, or that is empty after trimming, falls through to `now`. This MUST hold. Layouts without a zone, or without a weekday and with no seconds, are not recognised.
- **Boundary lengths in base64url**: Padding is added by length modulo four; a length remainder of one produces three pad characters that Foundation rejects, so the part's body is nil, and a later part of the same type then fills the body. A remainder of zero adds none.
- **Unbalanced quote in an address header**: An opening quote with no close keeps the remainder of the header, commas included, as one piece. This is the splitter's behavior and no error is raised. Ports MUST keep this behavior.
- **Backslash outside quotes**: A backslash outside a double-quoted section is kept as an ordinary character and does not escape anything. Ports MUST keep this behavior.
- **Whitespace trimming scope**: Address pieces are trimmed of horizontal whitespace only (spaces, tabs and Unicode space separators); newlines stay. Ports MUST keep this behavior.
- **Duplicate headers**: The first header with a matching name wins, so a second `Subject` is ignored. This MUST hold.
- **Multiple bodies of one type**: Only the first plain text and the first HTML part in document order are kept. This MUST hold.
- **Unknown or invalid charset**: An unrecognised charset name, or bytes invalid in the declared charset, falls back to UTF-8 and then ISO Latin-1, so decoding always succeeds when the base64url is valid. This MUST hold.
- **Mislabelled charset**: A body declared Latin-1 that is really UTF-8 is decoded as Latin-1, because the declaration wins when it decodes. Ports MUST keep this behavior, because correcting it needs content sniffing that the source does not do.
- **Wrapper message with only an embedded message**: A bounce or forward whose only content is a `message/rfc822` shows the embedded body. This MUST hold.
- **Embedded message beside an own body**: The embedded body never merges into the outer body, though files inside it are still listed. This MUST hold.
- **Named part Gmail inlined**: A named part whose data came inline (no attachment id) is dropped from both body and attachments. This MUST hold, and the part is not recoverable from the record.
- **Part types other than text and message**: Parts such as `text/calendar` or `image/png` without a filename are ignored for the body and for attachments, though their children are still walked.
- **Deeply nested parts**: Recursion has no depth or count limit, so an adversarially deep tree is bounded only by the stack. No limit exists and none is applied. This is deliberate prudent debt recorded in Design Decisions with a trigger for revisiting it.
- **Concurrent access**: The parser keeps no shared state, so concurrent calls need no coordination. Only the generated id and the current-time defaults (`createdAt`, `updatedAt`) differ between runs.
- **Error states, network and offline**: Not applicable: the parser performs no I/O, takes an already-fetched message, and has no network or dependency to fail.
- **Cancellation and timeouts**: Not applicable: the function is synchronous and has no suspension point.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `dto` | `GmailMessageDTO` | none | The decoded `format=full` message. |
| `connectionId` | `String` | none | Copied to the record. |
| `existingId` | `String?` | none | Local record id to keep; nil generates a new one. |
| `now` | `Date` | `Date()` | The date given to a message with neither a numeric `internalDate` nor a readable `Date` header. |

There are no environment variables, settings keys or injected dependencies; `MailClassifier` and `IntegrationClock` are called directly.

## Deep Linking

Not applicable: the parser is a stateless function with no URLs or routes.

## Localization

Not applicable: the parser produces no user-facing strings; `application/octet-stream` is a protocol default and dates use the fixed POSIX English locale on purpose.

## Accessibility Options

Not applicable: the parser has no display and responds to no accessibility setting.

## Feature Flags

Not applicable: the source reads no flag and has no switchable behavior.

## Analytics

Not applicable: the source emits no events.

## Privacy

Not applicable: the parser stores nothing and transmits nothing. It does handle personal data (addresses, subject, snippet, bodies) and returns it in memory in the `EmailMessage`; storing it is up to the callers, outside this source.

## Logging

Not applicable: the source makes no log call.

## Platform Notes

- **SwiftUI**: Not a view, so nothing to translate. A SwiftUI caller reads the finished `EmailMessage` fields and renders `bodyHtml` or `bodyText` itself; the parser has no SwiftUI or `Observable` dependency.
- **Compose**: Port as a Kotlin `object` of stateless functions. Use `java.util.Base64.getUrlDecoder()` (it accepts missing padding; check its rejection of invalid input to match the nil result), `java.nio.charset.Charset.forName` guarded by `try`/`catch` for unknown names with a fallback to UTF-8 then ISO-8859-1, `java.util.UUID.randomUUID().toString()` (already lowercase), and `java.time.Instant.ofEpochMilli` formatted with `DateTimeFormatter.ISO_INSTANT` forced to three fractional digits. Use `DateTimeFormatter` with `Locale.US` for the three Date layouts.
- **React/Web**: Port as a module of stateless functions in TypeScript. Decode with `atob` after swapping the alphabet and padding, then `TextDecoder` with the declared label (it throws `RangeError` for unknown labels and supports `windows-1252` and `iso-8859-1`) in a fallback chain with `fatal: true` on every decoder, the declared-charset one included, so invalid bytes throw and fall through as `charset-fallback` requires instead of becoming U+FFFD. Dates need an explicit parser for the three layouts because `Date.parse` is implementation-defined; format output with `toISOString`, which already gives three fractional digits in UTC.
- **AppKit / UIKit**: Source platform. The code is in `packages/apple/AgenticDeveloperHubSDK/Integrations/Gmail/GmailMessageParser.swift`. It uses Foundation only: `Data(base64Encoded:)`, `CFStringConvertIANACharSetNameToEncoding` with `CFStringConvertEncodingToNSStringEncoding` to resolve a charset name (the Core Foundation call makes it Apple-only), `String(data:encoding:)`, a `DateFormatter` with the `en_US_POSIX` locale, and `Date.ISO8601FormatStyle(includingFractionalSeconds: true)` inside `IntegrationClock.string(from:)`. The DTO types `GmailMessageDTO`, `GmailPart`, `GmailBody` and `GmailHeader` are `Decodable, Sendable` in `GmailAPI.swift`; the output `EmailMessage` and `EmailAttachmentRef` are in `IntegrationRecords.swift`. The enum has no stored state and every type it touches is `Sendable`.
- **WinUI 3**: Write a `static class GmailMessageParser` in C# with a `public static EmailMessage Parse(GmailMessageDto dto, string connectionId, string? existingId, DateTimeOffset? now = null)` method, using `DateTimeOffset.UtcNow` when `now` is null. Model the DTOs as `record` types with nullable members and deserialize with `System.Text.Json` (`JsonSerializer.Deserialize` with `PropertyNameCaseInsensitive`). Decode body data with `Convert.FromBase64String` after replacing `-` and `_` and padding to a multiple of four; catch `FormatException` to return null, the equivalent of the Swift nil. Resolve the charset with `Encoding.GetEncoding(name, EncoderFallback.ExceptionFallback, DecoderFallback.ExceptionFallback)` inside `try`/`catch` for `ArgumentException` and `DecoderFallbackException`, because plain `Encoding.GetString` replaces invalid bytes instead of failing and would not reproduce the fall-through to UTF-8; call `Encoding.RegisterProvider(CodePagesEncodingProvider.Instance)` once so `windows-1252` resolves on .NET (the Swift call needs no registration). Parse the Date header with `DateTimeOffset.TryParseExact`, `CultureInfo.InvariantCulture`, `DateTimeStyles.None` and the three format strings `ddd, d MMM yyyy HH:mm:ss zzz`, `d MMM yyyy HH:mm:ss zzz` and `ddd, d MMM yyyy HH:mm zzz`; the Swift `Z` pattern accepts `+0000` without a colon while .NET `zzz` wants `+00:00`, so normalise the zone first. Format output with `ToString("yyyy-MM-ddTHH:mm:ss.fffZ", CultureInfo.InvariantCulture)` on the UTC value. The function returns plain immutable values, so no `ObservableCollection` or `INotifyPropertyChanged` belongs in it; a view model can wrap the result.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Integrations/Gmail/GmailMessageParser.swift` | unverified |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: An unnamed `message/rfc822` is treated as an embedded message whose text is used only when the message has no body of its own, and a named part is always a file.
**Rationale**: A bounce's original or a forwarded `.eml` carries a body that is not this message's body. The source comments say nothing inside it "is this message's body, though the files inside it are still listed", while a wrapper with nothing but an embedded message would otherwise show empty.
**Approved**: pending

**Decision**: The embedded fallback is all or nothing: one own body of either kind suppresses both embedded bodies.
**Rationale**: The code gates on `hasOwnBody` (own text or own HTML) and then replaces both fields, so an own HTML-only message never takes the embedded plain text. This keeps the two bodies from coming from different messages.
**Approved**: pending

**Decision**: A named part without an `attachmentId` is neither the body nor an attachment.
**Rationale**: The source comment states "A named part is a file even when Gmail inlined it; it is never the message body." The cost is that an inlined named file is dropped from the record, because an `EmailAttachmentRef` needs an `attachmentId` to be fetched later.
**Approved**: pending

**Decision**: The declared charset wins when it decodes; otherwise the parser tries UTF-8, then ISO Latin-1.
**Rationale**: Test `decodesLatin1Charset` notes that bytes C3 A9 are valid UTF-8 and only the declared charset makes the result a different string. ISO Latin-1 is the last resort because it accepts any byte sequence, so decoding never fails after valid base64url.
**Approved**: pending

**Decision**: A message with no usable date sorts as now rather than as the epoch, and the `now` argument is injectable.
**Rationale**: The doc comment on `now` says the date is given so the message "sorts as new rather than as 1970". Injection makes the fallback testable.
**Approved**: pending

**Decision**: `internalDate` takes precedence over the `Date` header, and the header is read only in three fixed layouts after removing a trailing comment.
**Rationale**: `internalDate` is Gmail's own value and numeric when present, while the `Date` header is sender-controlled text. The layouts and comment stripping follow the doc comment "with or without the weekday and a trailing comment" and miss other legal RFC 5322 forms.
**Approved**: pending

**Decision**: Address splitting is a hand-written scanner that respects quotes and backslash escapes, and it does not parse mailboxes.
**Rationale**: Display names such as `"Doe, Jane"` contain commas, so a plain comma split is wrong. The splitter keeps each mailbox as raw text and leaves interpretation to callers. Unbalanced quotes are not repaired.
**Approved**: pending

**Decision**: Deliberate prudent debt: undecodable body data is dropped without a signal, and recursion over parts has no depth limit.
**Rationale**: Both affect malformed or hostile input only, and the source handles neither. Revisit the silent drop when the sync worker needs to show or count messages whose body failed to decode; revisit the depth limit when the parser reads messages from a source other than the Gmail API, or when a crash from a deeply nested message is reported. Until then a port copies both behaviors, or adds a deliberate signal or limit and says so.
**Approved**: pending

**Decision**: Whether a dropped body should be surfaced is open: today `undecodable-body-data` yields nil with no log, error or flag.
**Rationale**: Settling it needs the Gmail API contract for `data` and a decision from the owner of the sync worker. The recipe states the current behavior as a MUST until then.
**Approved**: pending

**Decision**: The parser is not pure: it keeps no shared state, but `createdAt`, `updatedAt` and the generated id read the wall clock and a random UUID inside `parse`, and `now` feeds only the date fallback.
**Rationale**: `EmailMessage` initializer defaults supply `createdAt` and `updatedAt`, and `UUID()` supplies the id, so none of them is injectable. The cost is that `record-defaults` and `generated-id` can only be asserted loosely. Feeding `now` into both timestamps and injecting an id generator would make them exact; revisit when a test needs exact values.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | reliability |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | internationalization |
| [adc.check.privacy-and-data.no-pii-in-logs](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/23bca2e1-dc0f-5ff4-beaf-03891ad48e6b) | passed | privacy-and-data |

The parser separates concerns cleanly: it only maps a DTO to a record, delegating classification to `MailClassifier`, time formatting to `IntegrationClock` and storage to other components. Unit-test coverage is partial: `GmailMessageParserTests` covers bodies, charsets, embedded messages, address splitting and both date fallbacks, but not the date comment stripping, the second and third date layouts, escaped quotes in addresses, unknown charset names or undecodable data (vectors parser-016 to parser-039 are derived from the code). Explicit error handling is partial because every failure degrades to an empty or fallback value, which is deliberate and total, yet an undecodable body vanishes with no signal. Graceful degradation passes because each missing input has a defined fallback. Unicode support passes because declared charsets are honoured with UTF-8 and ISO Latin-1 fallbacks. No-PII-in-logs passes because the source never logs.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|

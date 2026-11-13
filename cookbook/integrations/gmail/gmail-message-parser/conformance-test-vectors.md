
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


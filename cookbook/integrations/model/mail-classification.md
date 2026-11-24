---
id: ea7a9ec6-0a0c-4e97-8b03-ebc5f6246a43
title: "Mail Classification"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-13
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Derives a MailClass (filed, archived, spam, trash) from Gmail label ids, with fixed precedence, to decide whether a message is mirrored."
platforms:
  - swift
  - macos
  - ios
tags:
  - integrations
  - mail
  - classification
depends-on: []
related:
  - df121975-deb8-49a9-b023-0aadcb0923d8
  - 888b7ba2-61f6-4251-88df-3586c5c86b1f
  - cdadfe1d-e4a2-4e2d-96a7-a5eb615a1302
  - 18871853-95b7-492a-9f1f-417283594824
references: []
approved-by: ""
approved-date: ""
---

# Mail Classification

## Overview

MailClassification answers one question for the Gmail integration: where does a message sit, for the purposes of deciding whether to mirror it. It has two public types in one file. `MailClass` is a four-case enum (`filed`, `archived`, `spam`, `trash`). `MailClassifier` is a caseless enum namespace whose single operation, `classify(labelIds:)`, maps a list of Gmail label id strings to one `MailClass`. It is a pure function with no I/O. Callers use it in two places: the Gmail message parser ([adhsdk.ingredient.integrations.gmail.gmail-message-parser](cookbook:cdadfe1d-e4a2-4e2d-96a7-a5eb615a1302), `GmailMessageParser.swift`) classifies each fetched message, and the `EmailMessage` record ([adhsdk.ingredient.integrations.model.integration-records](cookbook:888b7ba2-61f6-4251-88df-3586c5c86b1f), `IntegrationRecords.swift`, its initializer) classifies itself when it is built without an explicit class. A connection's `MailSyncSettings` `allows(_:)` ([adhsdk.ingredient.integrations.model.mail-sync-settings](cookbook:df121975-deb8-49a9-b023-0aadcb0923d8)) then decides, per class, whether the message is kept; that policy is specified there, not here. The Gmail query (`GmailQuery` in `GmailAPI.swift`, [adhsdk.ingredient.integrations.gmail.gmail-api](cookbook:18871853-95b7-492a-9f1f-417283594824)) only narrows the fetch, and `MailClassifier` stays the authority on what is mirrored.

## Behavioral Requirements

### MailClass

- **class-cases**: `MailClass` MUST have exactly four cases with these raw string values: `filed`, `archived`, `spam`, `trash`.
- **class-codable**: `MailClass` MUST be `Codable` and encode as its raw string value.
- **class-enumerable**: `MailClass` MUST be `CaseIterable`, so a caller can enumerate all four classes.
- **class-sendable**: `MailClass` MUST be `Sendable`, so it can cross concurrency domains.

### MailClassifier

- **classify-signature**: `MailClassifier.classify(labelIds:)` MUST accept an array of label id strings and return a single `MailClass`.
- **classify-pure**: `classify(labelIds:)` MUST be a synchronous function that reads only its argument and immutable static constants, with no I/O and no side effects. `MailClassifier` therefore holds no mutable state, and concurrent calls from any thread are safe and need no serialisation.
- **classify-total**: `classify(labelIds:)` MUST return a class for every input and MUST NOT throw or trap.
- **trash-first**: When `labelIds` contains `TRASH`, `classify(labelIds:)` MUST return `.trash`, regardless of every other label.
- **spam-second**: When `labelIds` does not contain `TRASH` and contains `SPAM`, `classify(labelIds:)` MUST return `.spam`, regardless of every other label.
- **filed-by-filing-label**: When the message is neither trash nor spam and `labelIds` contains any of `INBOX`, `SENT`, `DRAFT` or `STARRED`, `classify(labelIds:)` MUST return `.filed`.
- **filed-by-user-label**: When the message is neither trash nor spam and `labelIds` contains any label that is not a system label, `classify(labelIds:)` MUST return `.filed`.
- **archived-otherwise**: When none of the rules above match, including when `labelIds` is empty, `classify(labelIds:)` MUST return `.archived`.
- **attribute-labels-not-filing**: The labels `UNREAD`, `IMPORTANT`, `CHAT` and any label starting with `CATEGORY_` MUST NOT by themselves make a message `.filed`.
- **system-label-set**: `MailClassifier.systemLabelIds` MUST be the public constant set `INBOX`, `SENT`, `DRAFT`, `STARRED`, `SPAM`, `TRASH`, `UNREAD`, `IMPORTANT`, `CHAT`.
- **category-by-prefix**: A label MUST count as a system label when it is in `systemLabelIds` or when it starts with `CATEGORY_`; the `CATEGORY_` family is matched by prefix and is not listed in `systemLabelIds`.
- **label-match-exact**: Label ids MUST be matched as exact, case-sensitive strings; the `CATEGORY_` prefix test is also case-sensitive.
- **label-order-independent**: The result MUST NOT depend on the order of `labelIds` or on repeated ids.
- **no-validation**: `classify(labelIds:)` MUST NOT validate label ids; an empty string is treated as a user label and therefore classifies as `.filed`.

### Downstream use

- **mirroring-is-elsewhere**: Which classes are mirrored is decided by `MailSyncSettings` `allows(_:)` ([adhsdk.ingredient.integrations.model.mail-sync-settings](cookbook:df121975-deb8-49a9-b023-0aadcb0923d8)), not by this file, which does not read settings.

## Appearance

Not applicable — this is a classification function and its result enum, not a visual component.

## States

Not applicable — this is a stateless function and a value enum, not a visual component.

## Accessibility

Not applicable — this is a classification function and its result enum, not a visual component.

## Conformance Test Vectors

The vectors with a test name come from `MailClassificationTests.swift`; the test gap is recorded under Compliance.

| ID | Requirements | Input | Expected | Test |
|----|-------------|-------|----------|------|
| mail-classification-001 | filed-by-filing-label, attribute-labels-not-filing | `["INBOX", "UNREAD"]` | `.filed` | `classifies` |
| mail-classification-002 | filed-by-filing-label | `["SENT"]` | `.filed` | `classifies` |
| mail-classification-003 | filed-by-filing-label | `["DRAFT"]` | `.filed` | `classifies` |
| mail-classification-004 | filed-by-filing-label, category-by-prefix | `["STARRED", "CATEGORY_PROMOTIONS"]` | `.filed` | `classifies` |
| mail-classification-005 | filed-by-user-label | `["Label_123"]` | `.filed` | `classifies` |
| mail-classification-006 | archived-otherwise, attribute-labels-not-filing, category-by-prefix | `["CATEGORY_PROMOTIONS", "UNREAD", "IMPORTANT"]` | `.archived` | `classifies` |
| mail-classification-007 | archived-otherwise, classify-total | `[]` | `.archived` | `classifies` |
| mail-classification-008 | spam-second | `["SPAM", "INBOX"]` | `.spam` | `classifies` |
| mail-classification-009 | trash-first | `["TRASH", "SPAM"]` | `.trash` | `classifies` |
| mail-classification-010 | trash-first | `["TRASH", "Label_9"]` | `.trash` | `classifies` |
| mail-classification-011 | attribute-labels-not-filing | `["CHAT"]` | `.archived` | none |
| mail-classification-012 | label-match-exact, filed-by-user-label | `["inbox"]` | `.filed`, because lowercase `inbox` is not a system id and so counts as a user label | none |
| mail-classification-013 | label-match-exact, category-by-prefix | `["category_updates"]` | `.filed`, because the prefix test is case-sensitive and the id is a user label | none |
| mail-classification-014 | no-validation | `[""]` | `.filed` | none |
| mail-classification-015 | label-order-independent | `["TRASH", "INBOX"]` and `["INBOX", "TRASH"]` | `.trash` for both | none |
| mail-classification-016 | class-cases, class-codable | Encode `MailClass.spam` to JSON | The JSON string `"spam"` | none |
| mail-classification-017 | class-enumerable | `MailClass.allCases` | Four elements: `filed`, `archived`, `spam`, `trash` | none |
| mail-classification-018 | system-label-set | `MailClassifier.systemLabelIds.count` | 9 | none |
| mail-classification-019 | classify-pure | Call `classify(labelIds:)` from many concurrent tasks with the same input | Every call returns the same class; no crash. This checks only that concurrent calls are safe; the signature, totality and `Sendable` conformance are checked by the compiler and the other vectors | none |

## Edge Cases

- **Empty array**: See #requirements/archived-otherwise. No label means no filing label and no user label; the test suite pins this.
- **Only attribute labels**: See #requirements/attribute-labels-not-filing and #requirements/archived-otherwise.
- **Conflicting labels**: See #requirements/trash-first and #requirements/spam-second. `["TRASH", "SPAM"]`, `["TRASH", "Label_9"]` and `["SPAM", "INBOX"]` are pinned by the test suite; `TRASH` with `INBOX` follows from the same rule but has no test case.
- **Duplicate ids**: See #requirements/label-order-independent.
- **Unknown or future system label**: See #requirements/filed-by-user-label. The classifier cannot tell it from a user label.
- **Empty or whitespace id**: See #requirements/no-validation. An id with surrounding whitespace is likewise a user label.
- **Case**: See #requirements/label-match-exact.
- **Very large arrays**: The cost is linear in the number of labels; there is no cap.
- **Concurrent access**: See #requirements/classify-pure; no ordering rule is needed.
- **Error states, network and offline**: Not applicable. The function does no I/O, takes no dependency that can fail, and never throws.
- **Stale classification**: The class is computed from the label ids at the moment of the call. This file does not recompute it when labels change; a caller that re-fetches a message gets a new result by calling again.
## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `labelIds` | `[String]` | none (required argument) | The Gmail label ids of one message, as returned by the Gmail API. |
| `MailClassifier.systemLabelIds` | `Set<String>` | `INBOX`, `SENT`, `DRAFT`, `STARRED`, `SPAM`, `TRASH`, `UNREAD`, `IMPORTANT`, `CHAT` | Public constant; the ids Gmail owns. Not configurable at runtime. |

No environment variables, settings keys or injected dependencies. Whether a class is mirrored is configured elsewhere, in `MailSyncSettings`.

## Deep Linking

Not applicable: the source is a pure classification function with no URLs, routes or screens.

## Localization

Not applicable: the source produces no user-facing strings. The `MailClass` raw values are stable identifiers used for storage, not display text.

## Accessibility Options

Not applicable: the source has no visual surface, so Reduce Motion, Increase Contrast and Differentiate Without Color do not apply.

## Feature Flags

Not applicable: the source reads no flags; its behavior is fixed by constants.

## Analytics

Not applicable: the source emits no events.

## Privacy

Not applicable: the function receives label ids (system names and opaque user label ids, not message content), stores nothing and transmits nothing. Persistence of the resulting class is the job of the caller's record.

## Logging

Not applicable: the source makes no log calls.

## Platform Notes

- **SwiftUI**: Not a view. It is a `String`-backed `Codable`, `Sendable`, `CaseIterable` enum and a caseless enum used as a namespace of static members, with no dependency beyond Foundation. A SwiftUI view model can show the class directly; macOS and iOS share it unchanged.
- **Compose**: Use a Kotlin `enum class MailClass` with a serial name per entry (`@SerialName` with kotlinx.serialization) and an `object MailClassifier` with a `classify(labelIds: List<String>): MailClass` function. Hold the sets as `val` constants and use `startsWith("CATEGORY_")`. Keep the precedence order as sequential early returns.
- **React/Web**: Use a string-literal union type `"filed" | "archived" | "spam" | "trash"` and a pure function over `string[]`. Build the sets as `Set<string>` constants; use `labelIds.includes`, `some` and `startsWith`. JavaScript string comparison is case-sensitive, matching the source. Single-threaded, so no ordering rule is needed.
- **AppKit / UIKit**: Same Swift source as above; there is no AppKit or UIKit dependency, so no change between macOS and iOS.
- **WinUI 3**: Write a C# `enum MailClass { Filed, Archived, Spam, Trash }` and a `static class MailClassifier` with `public static MailClass Classify(IEnumerable<string> labelIds)`. Hold the sets in `static readonly HashSet<string>` with `StringComparer.Ordinal` so matching stays case-sensitive, and test the prefix with `labelId.StartsWith("CATEGORY_", StringComparison.Ordinal)` (the default culture-sensitive overload would differ). For JSON, use `System.Text.Json` with `JsonStringEnumConverter` and a camel-case naming policy so the values are `filed`, `archived`, `spam` and `trash`; a bare enum would serialise as an integer. The function is pure and thread-safe, so it needs no `Task` or `async` and is safe to call from the UI thread or a background worker. A port that fetches Gmail data through `HttpClient` should call this once per message after reading `labelIds`, and a bound XAML view model needs no `INotifyPropertyChanged` for a value that does not change.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Mail/Model/MailClassification.swift` | confirmed (1.0.1) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The precedence is trash, then spam, then filed, then archived, and it does not depend on label order.
**Rationale**: A trashed or spam message that still carries `INBOX` or a user label must not be mirrored as filed, and the test cases `["SPAM", "INBOX"]` and `["TRASH", "Label_9"]` pin it.
**Approved**: pending

**Decision**: Any label that is not a Gmail system label counts as a user label and makes a message filed.
**Rationale**: Gmail user label ids are opaque (such as `Label_123`), so the code tests for non-membership in the system set instead of matching user ids. The cost is that a new Gmail system id not yet in `systemLabelIds` is treated as a user label and classifies as filed until the constants change, and an empty string is not rejected.
**Approved**: pending

**Decision**: `UNREAD`, `IMPORTANT`, `CHAT` and `CATEGORY_*` are attribute labels that never make a message filed, and `CATEGORY_*` is matched by prefix.
**Rationale**: These labels describe a message but do not file it. The `CATEGORY_` set is open-ended, so a prefix test avoids listing every id. The test case `["CATEGORY_PROMOTIONS", "UNREAD", "IMPORTANT"]` yields archived.
**Approved**: pending

**Decision**: The classifier returns the class and does not decide what is mirrored; `MailSyncSettings` `allows(_:)` ([adhsdk.ingredient.integrations.model.mail-sync-settings](cookbook:df121975-deb8-49a9-b023-0aadcb0923d8)) makes that decision.
**Rationale**: Keeping classification separate from policy lets a user change the include flags without changing the classifier, and keeps the function pure. Because the Gmail query only narrows the fetch, the classifier stays the authority on what is mirrored.
**Approved**: pending

**Decision**: `systemLabelIds` is public while the filing subset is private.
**Rationale**: The system set is public so a caller can tell system labels from user labels; no code outside `MailClassification.swift` reads it today. The filing subset is an internal detail of the classifier that no caller needs.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | passed | reliability |

The classifier is a pure, stateless function that only classifies and leaves the mirroring policy to `MailSyncSettings`, so it meets separation-of-concerns, and the same labels always give the same class, so repeated calls are idempotent. Unit-test coverage is partial: `MailClassificationTests` has ten cases covering every precedence step, the filing labels, user labels and the archived outcomes, but it has no case for vectors 011 through 019: `CHAT`, `inbox`, `category_updates`, the empty-string label, the `["INBOX", "TRASH"]` order, `MailClass` coding, `allCases`, the system-label count and concurrent calls. `TRASH` with `INBOX` follows from the trash-first rule but has no test case.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Retitled to Mail Classification, rewrote links with rdid labels, removed the duplicated test gap, filing-set row and doc-comment citations, added a Test column to the vectors, and stated the consumer of systemLabelIds. |

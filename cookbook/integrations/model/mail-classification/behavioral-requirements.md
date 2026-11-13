
### MailClass

- **class-cases**: `MailClass` MUST have exactly four cases with these raw string values: `filed`, `archived`, `spam`, `trash`.
- **class-codable**: `MailClass` MUST be `Codable` and encode as its raw string value.
- **class-enumerable**: `MailClass` MUST be `CaseIterable`, so a caller can enumerate all four classes.
- **class-sendable**: `MailClass` MUST be `Sendable`, so it can cross concurrency domains.

### MailClassifier

- **classify-signature**: `MailClassifier.classify(labelIds:)` MUST accept an array of label id strings and return a single `MailClass`.
- **classify-pure**: `classify(labelIds:)` MUST be a synchronous function that reads only its argument and static constants, with no I/O and no side effects.
- **classify-total**: `classify(labelIds:)` MUST return a class for every input and MUST NOT throw or trap.
- **trash-first**: When `labelIds` contains `TRASH`, `classify(labelIds:)` MUST return `.trash`, regardless of every other label.
- **spam-second**: When `labelIds` does not contain `TRASH` and contains `SPAM`, `classify(labelIds:)` MUST return `.spam`, regardless of every other label.
- **filed-by-filing-label**: When the message is neither trash nor spam and `labelIds` contains any of `INBOX`, `SENT`, `DRAFT` or `STARRED`, `classify(labelIds:)` MUST return `.filed`.
- **filed-by-user-label**: When the message is neither trash nor spam and `labelIds` contains any label that is not a system label, `classify(labelIds:)` MUST return `.filed`.
- **archived-otherwise**: When none of the rules above match, including when `labelIds` is empty, `classify(labelIds:)` MUST return `.archived`.
- **precedence-order**: The precedence MUST be trash, then spam, then filed, then archived.
- **attribute-labels-not-filing**: The labels `UNREAD`, `IMPORTANT`, `CHAT` and any label starting with `CATEGORY_` MUST NOT by themselves make a message `.filed`.
- **system-label-set**: `MailClassifier.systemLabelIds` MUST be the public constant set `INBOX`, `SENT`, `DRAFT`, `STARRED`, `SPAM`, `TRASH`, `UNREAD`, `IMPORTANT`, `CHAT`.
- **category-by-prefix**: A label MUST count as a system label when it is in `systemLabelIds` or when it starts with `CATEGORY_`; the `CATEGORY_` family is matched by prefix and is not listed in `systemLabelIds`.
- **label-match-exact**: Label ids MUST be matched as exact, case-sensitive strings, apart from the `CATEGORY_` prefix test.
- **label-order-independent**: The result MUST NOT depend on the order of `labelIds` or on repeated ids.
- **unknown-label-is-user-label**: A label id that is neither in `systemLabelIds` nor `CATEGORY_`-prefixed MUST be treated as a user label, so an id Gmail adds later to its system set classifies as filed until the constants change.
- **no-validation**: `classify(labelIds:)` MUST NOT validate label ids; an empty string is treated as a user label and therefore classifies as `.filed`.

### Downstream use

- **filed-always-allowed**: Per the sibling `MailSyncSettings.allows(_:)`, a `.filed` message is always mirrored, and the other three classes are mirrored only when their include flag (`includeArchived`, `includeSpam`, `includeTrash`) is set. This file does not itself read settings.
- **concurrency**: `MailClassifier` MUST hold no mutable state, so concurrent calls from any thread are safe and need no serialisation.



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
- **filed-by-user-label**: When the message is neither trash nor spam and `labelIds` contains any label that is not a system label, `classify(labelIds:)` MUST return `.filed`. A label id that is neither in `systemLabelIds` nor `CATEGORY_`-prefixed is a user label, so an id Gmail adds later to its system set classifies as filed until the constants change.
- **archived-otherwise**: When none of the rules above match, including when `labelIds` is empty, `classify(labelIds:)` MUST return `.archived`.
- **attribute-labels-not-filing**: The labels `UNREAD`, `IMPORTANT`, `CHAT` and any label starting with `CATEGORY_` MUST NOT by themselves make a message `.filed`.
- **system-label-set**: `MailClassifier.systemLabelIds` MUST be the public constant set `INBOX`, `SENT`, `DRAFT`, `STARRED`, `SPAM`, `TRASH`, `UNREAD`, `IMPORTANT`, `CHAT`.
- **category-by-prefix**: A label MUST count as a system label when it is in `systemLabelIds` or when it starts with `CATEGORY_`; the `CATEGORY_` family is matched by prefix and is not listed in `systemLabelIds`.
- **label-match-exact**: Label ids MUST be matched as exact, case-sensitive strings; the `CATEGORY_` prefix test is also case-sensitive.
- **label-order-independent**: The result MUST NOT depend on the order of `labelIds` or on repeated ids.
- **no-validation**: `classify(labelIds:)` MUST NOT validate label ids; an empty string is treated as a user label and therefore classifies as `.filed`.

### Downstream use

- **mirroring-is-elsewhere**: Which classes are mirrored is decided by [MailSyncSettings](cookbook:df121975-deb8-49a9-b023-0aadcb0923d8) `allows(_:)`, not by this file, which does not read settings.



The vectors marked with a test name come from the `MailClassification` suite in `MailClassificationTests.swift` (test `classifies`, parameterised). The rest are traced to the source rules and have no backing test yet. The mirroring decision (`MailSyncSettings.allows(_:)`) is tested in the MailSyncSettings recipe.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mail-classification-001 | filed-by-filing-label, attribute-labels-not-filing | `["INBOX", "UNREAD"]` (test `classifies`) | `.filed` |
| mail-classification-002 | filed-by-filing-label | `["SENT"]` (test `classifies`) | `.filed` |
| mail-classification-003 | filed-by-filing-label | `["DRAFT"]` (test `classifies`) | `.filed` |
| mail-classification-004 | filed-by-filing-label, category-by-prefix | `["STARRED", "CATEGORY_PROMOTIONS"]` (test `classifies`) | `.filed` |
| mail-classification-005 | filed-by-user-label | `["Label_123"]` (test `classifies`) | `.filed` |
| mail-classification-006 | archived-otherwise, attribute-labels-not-filing, category-by-prefix | `["CATEGORY_PROMOTIONS", "UNREAD", "IMPORTANT"]` (test `classifies`) | `.archived` |
| mail-classification-007 | archived-otherwise, classify-total | `[]` (test `classifies`) | `.archived` |
| mail-classification-008 | spam-second | `["SPAM", "INBOX"]` (test `classifies`) | `.spam` |
| mail-classification-009 | trash-first | `["TRASH", "SPAM"]` (test `classifies`) | `.trash` |
| mail-classification-010 | trash-first | `["TRASH", "Label_9"]` (test `classifies`) | `.trash` |
| mail-classification-011 | attribute-labels-not-filing | `["CHAT"]` | `.archived` |
| mail-classification-012 | label-match-exact, filed-by-user-label | `["inbox"]` | `.filed`, because lowercase `inbox` is not a system id and so counts as a user label |
| mail-classification-013 | label-match-exact, category-by-prefix | `["category_updates"]` | `.filed`, because the prefix test is case-sensitive and the id is a user label |
| mail-classification-014 | no-validation | `[""]` | `.filed` |
| mail-classification-015 | label-order-independent | `["TRASH", "INBOX"]` and `["INBOX", "TRASH"]` | `.trash` for both |
| mail-classification-016 | class-cases, class-codable | Encode `MailClass.spam` to JSON | The JSON string `"spam"` |
| mail-classification-017 | class-enumerable | `MailClass.allCases` | Four elements: `filed`, `archived`, `spam`, `trash` |
| mail-classification-018 | system-label-set | `MailClassifier.systemLabelIds.count` | 9 |
| mail-classification-019 | classify-pure | Call `classify(labelIds:)` from many concurrent tasks with the same input | Every call returns the same class; no crash. This checks only that concurrent calls are safe; the signature, totality and `Sendable` conformance are checked by the compiler and the other vectors |


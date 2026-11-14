
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



The vectors are derived from the initializers, the declared conformances and the standard `Codable` rules for the declared shapes.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| partner-attention-001 | item-init-defaults, item-init-id-default | `AttentionItem(kind: .question, text: "Ship it?", createdBy: "partner")` | `state == .open`, `reference == [:]`, `completedAt == nil`, and `id` is a non-empty UUID string |
| partner-attention-002 | item-init-id-default | Two items built with the same arguments | The two `id` values differ and the items are not equal |
| partner-attention-003 | item-init-dates | One item built with no dates | `createdAt` and `updatedAt` are both within a second of the call time |
| partner-attention-004 | item-init-explicit | `AttentionItem(id: "a", kind: .blocked, text: "t", reference: ["file": "x"], state: .discussing, createdBy: "p", createdAt: d1, updatedAt: d2, completedAt: d3)` | Every field holds exactly the value passed |
| partner-attention-005 | kind-values | `AttentionKind.allCases.map(\.rawValue)` | `["question", "blocked", "notification"]` |
| partner-attention-006 | state-values | Raw values of `.open`, `.discussing`, `.sent`, `.done` | `"open"`, `"discussing"`, `"sent"`, `"done"` |
| partner-attention-007 | action-kind-values | Raw values of `.discuss`, `.resolved`, `.confirm`, `.reopen` | `"discuss"`, `"resolved"`, `"confirm"`, `"reopen"` |
| partner-attention-008 | wire-keys, wire-enum-strings | Encode an item with `kind: .notification` and `state: .sent` | JSON object whose `kind` is `"notification"`, `state` is `"sent"` and keys include `createdBy`, `createdAt` and `updatedAt` |
| partner-attention-009 | item-conformances, wire-optional-on-decode | Encode then decode an item with `completedAt == nil` and whole-second dates, using `.iso8601` for both the encoder and the decoder (it drops sub-second precision) | The decoded item equals the original |
| partner-attention-010 | wire-required-on-decode | JSON for an item with `text` removed | Decoding throws |
| partner-attention-011 | wire-unknown-enum-fails | JSON for an item whose `state` is `"archived"` | Decoding throws |
| partner-attention-012 | action-init-defaults, action-init-required | `AttentionAction(itemID: "a", action: .confirm)` | `messageID == nil`, `at` is within a second of the call time and `id` is a fresh non-empty UUID string |
| partner-attention-013 | action-fields, wire-keys | Encode `AttentionAction(itemID: "a", action: .resolved, messageID: "m1")` | JSON keys `id`, `itemID`, `action`, `at`, `messageID`, with `action` equal to `"resolved"` |
| partner-attention-014 | wire-optional-on-decode, action-conformances | JSON for an action with no `messageID` | Decodes with `messageID == nil` |
| partner-attention-015 | item-mutable | Build an item, then set `state = .done` and `completedAt = Date()` | The item holds the new values and `updatedAt` is unchanged |
| partner-attention-016 | action-conformances, wire-dates-strategy | Encode then decode `AttentionAction(id: "x", itemID: "a", action: .confirm, at: d, messageID: "m1")` with a whole-second `d`, using `.iso8601` for both the encoder and the decoder | The decoded action equals the original |
| partner-attention-017 | wire-required-on-decode | JSON for an action with `itemID` removed, and likewise one with `action` removed and one with `at` removed | Decoding throws in each case |

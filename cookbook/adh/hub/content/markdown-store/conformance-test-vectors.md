
| ID | Requirements | Input | Expected |
|----|--------------|-------|----------|
| markdown-core-001 | delete-tombstones-both-flags | The delete operation invoked on a live document | Both delete columns set on the document row and every marker row |
| markdown-core-002 | update-refuses-authored-drift | The update operation called with visibility changed from the stored row | Throws the dedicated-intent error naming the visibility field |
| markdown-core-003 | publish-invariant | The publish operation called with an empty route | Throws the inconsistent-publication error |
| markdown-core-004 | outbox-order-is-sequence | Operations enqueued out of creation order but in sequence order | The pending-operations read returns them in sequence order |
| markdown-core-005 | opposing-intents-cancel | The publish operation followed by the unpublish operation before the queue drains | Exactly one operation remains queued |
| markdown-core-006 | cycle-refusal | Adding a category edge where the proposed parent is already a descendant of the proposed child | Throws the category-cycle error; a diamond shape is still allowed |
| markdown-core-007 | revive-on-conflict | Creating a keyword for a label whose only holder is tombstoned | The tombstoned row is revived, not duplicated |
| markdown-core-008 | number-range-clamping | A pulled JSON number outside the 64-bit signed integer range | The value is stored as a lossy floating-point value rather than trapping |
| markdown-core-009 | unencodable-value-throws | A pulled array or object value bound for a scalar column | Throws rather than binding a null value |
| markdown-core-010 | postgres-form-repair | The timestamp reader given a database wire-form timestamp with a space separator and a two-digit offset | Parses to the same instant the writer would produce for the ISO-8601 spelling |
| markdown-core-011 | local-version-column | Migrate a database holding `markdown` rows written before `markdown-v7-local-version` | Every existing row reads back with `local_version` 1 |
| markdown-core-012 | local-version-bumped-by-every-write, document-carries-version | Create a document, then update it once | The created document has version 1; after the update it reads back with version 2, and the change log holds two `content.markdown` upsert entries with versions 1 and 2 |
| markdown-core-013 | expected-version-check | Update a document at version 2 quoting expected version 1 | Throws the stale-version error carrying current version 2; the stored content is unchanged |
| markdown-core-014 | expected-version-check, delete-is-idempotent | Delete a document that is already gone, quoting any expected version | Succeeds without throwing |
| markdown-core-015 | shared-database-init | Construct the store over a host-owned database and an already-prepared sync store | The markdown tables exist and the sync store is not prepared again |
| markdown-core-016 | unchanged-pull-is-silent | Pull a row, then pull it again with the same content and only a newer sync version and `updated_at` | The document stays at version 1 and the change log holds one entry for it |
| markdown-core-017 | local-version-never-travels, unchanged-pull-is-silent | Pull a row, then pull it again with different content | The document reads back at version 2 and the change log holds entries with versions 1 and 2 |
| markdown-core-018 | writes-return-version | Create a document, update it quoting version 1, then mutate it quoting version 2 | The update returns 2, the mutate returns 3, and the document reads back at version 3 |
| markdown-core-019 | claim-is-never-released, sent-operation-is-frozen | Create a document, drain it into a writer that throws, then update the document | Two operations queued, create then update; the create keeps its operation id and its original body |
| markdown-core-020 | claim-is-never-released | Create a document, drain into a writer that throws, then drain into a writer that accepts | The accepting writer receives the same operation id and body the failing one did; the queue is empty |
| markdown-core-021 | delete-keeps-claimed-create | Create a document, drain into a writer that throws, delete the document, then drain into a writer that mints remote id R | The writer receives create (no remote id) then delete addressed to R |
| markdown-core-022 | delete-drops-undelivered-create | Create a document and delete it before any drain | Nothing is queued |

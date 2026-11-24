
**Decision**: Preferences are normalized on both read and write.
**Rationale**: The doc comment says a hand-edited row "still means the nearest valid value", and an older or foreign writer cannot push an out-of-range retention or an unsorted id list into the tracker.
**Approved**: pending

**Decision**: The four preference keys are written in one transaction, but `load` does not read them in one.
**Rationale**: The source wraps writes in `transaction` and reads with plain `setting(for:)` calls; the protocol offers no read transaction, so a consistent read is the store's business. The open question on `load-key-reads-separate` records this.
**Approved**: pending

**Decision**: An undecodable id list reads as empty, not as an error.
**Rationale**: The comment on `decodeIds` says "anything else (absent, empty, garbage) is no ids", so a corrupt row degrades to the default instead of blocking tracking. The cost is that a corrupt row looks the same as a user who never added any ids, because the source neither logs nor reports the failure.
**Approved**: pending

**Decision**: A stored `.granted` holds only under the signature recorded with it; a denial holds under any.
**Rationale**: The doc comment on `trustedAccessibility` explains that TCC keys a grant to the code's designated requirement, so a grant recorded by a differently signed build is not known to hold; trusting a denial never calls Accessibility, while trusting a grant wrongly could make the tracker issue an Accessibility call that stalls.
**Approved**: pending

**Decision**: The raw last answer and its trusted reading are separate functions.
**Rationale**: `lastAccessibility` returns what was stored and `trustedAccessibility` applies the signature rule, so the daemon can show history while acting only on trusted answers; the test asserts "the raw answer is kept".
**Approved**: pending

**Decision**: The settings store is a protocol the host conforms, not a concrete database.
**Rationale**: The doc comment ties it to `BillingPersistence`; this keeps the SDK tier free of any SQLite dependency, and tests use a dictionary-backed store.
**Approved**: pending


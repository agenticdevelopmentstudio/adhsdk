
**Decision**: Store a length and a SHA-256 hash, not the status or log text.
**Rationale**: The question is which component changed, a hash answers it, and keeping the text would copy the user's file names on every render for a yes or no question.
**Approved**: pending

**Decision**: Sample in the status-line command, in the session's own directory, not at ingest.
**Rationale**: On the drop-file path ingest can run minutes later against a moved tree; `sampled_at` lets a consumer tell the two apart.
**Approved**: pending

**Decision**: Pin the status and log commands against user configuration.
**Rationale**: A fingerprint that moves with a config change, or stays put when the tree moves (as `status.showUntrackedFiles=no` freezes status at the empty digest), is worthless.
**Approved**: pending

**Decision**: Read the status untrimmed.
**Rationale**: Porcelain's first two columns are significant and the first line can begin with a space.
**Approved**: pending

**Decision**: Splice the original bytes instead of decoding and re-encoding.
**Rationale**: A round trip turns `1.0` into `1`, a schema that types columns from the first value would then declare a warm cache ratio column integer for good, and key order must stay stable for literal-JSON subtrees.
**Approved**: pending

**Decision**: Check `isValidJSONObject` before encoding.
**Rationale**: An unrepresentable value raises an Objective-C exception that `try?` does not catch, which would kill the status-line command and blank the line.
**Approved**: pending

**Decision**: When the branch resolves but the status or log command then fails, report the sample as failed (nil, or a marked field) instead of as a clean tree with the empty-string hash.
**Rationale**: Today the failure is read as `""`, so the fingerprint claims no drift when the truth is unknown; see the open question on `sample-subcommand-failure`.
**Approved**: pending

**Decision**: When the branch resolves but the status or log command then fails, report the sample as failed (nil, or a marked field) instead of as a clean tree with the empty-string hash.
**Rationale**: Today the failure is read as `""`, so the fingerprint claims no drift when the truth is unknown; see the open question on `sample-subcommand-failure`.
**Approved**: pending

**Decision**: Any failure returns the payload unchanged.
**Rationale**: Enrichment decorates a row; losing the decoration is cheaper than losing the row.
**Approved**: pending

**Decision**: The key is `stenographer_git` for every daemon.
**Rationale**: The shared schema's columns and a daemon's payload audit are keyed on that namespace, and a prefix keeps a field Anthropic adds from merging with it.
**Approved**: pending



**Decision**: Work tracking is its own protocol, separate from the daemon's main protocol.
**Rationale**: The doc comment gives the reason: any app can talk to work tracking without linking the daemon's whole protocol.
**Approved**: pending

**Decision**: Payloads are JSON data rather than typed Objective-C objects.
**Rationale**: The protocol comment says every body and reply is JSON in the daemon's snake-case style; the models file says the failure-row convention is the same as `BillingWire.readFailedRow`.
**Approved**: pending

**Decision**: Failure is empty data for status calls and a sentinel row for the spans list.
**Rationale**: The comments say empty `Data` on failure, and a failed read replies `readFailedRow` "so a failure never reads as 'no activity'". An empty array has to stay a true answer, so a failed list needs its own marker (review F25).
**Approved**: pending

**Decision**: The recheck selector is the one explicit, user-driven Accessibility check.
**Rationale**: The comment calls it "the one explicit, user-driven check"; the client source notes the live check stalls on `tccd` for about ten seconds without the grant, which is why the client gives it a 15 second wait.
**Approved**: pending


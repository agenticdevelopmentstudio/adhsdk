
**Decision**: Work tracking is its own protocol, separate from the daemon's main protocol.
**Rationale**: The doc comment gives the reason: any app can talk to work tracking without linking the daemon's whole protocol.
**Approved**: pending

**Decision**: Payloads are JSON data rather than typed Objective-C objects.
**Rationale**: The protocol comment says every body and reply is JSON in the daemon's snake-case style; the models file says the failure-row convention is the same as `BillingWire.readFailedRow`. The source does not state why JSON was chosen over typed `NSSecureCoding` objects.
**Approved**: pending

**Decision**: Failure is empty data for status calls and a sentinel row for the spans list.
**Rationale**: The comments say empty `Data` on failure, and a failed read replies `readFailedRow` "so a failure never reads as 'no activity'". An empty array has to stay a true answer, so a failed list needs its own marker.
**Approved**: pending

**Decision**: The recheck selector is the one explicit, user-driven Accessibility check.
**Rationale**: The comment calls it "the one explicit, user-driven check"; the doc comment on `recheckTimeout` in `WorkTrackingXPCClient.swift` notes the live check stalls on `tccd` for about ten seconds without the grant, which is why the client gives it a 15 second wait ([adhsdk.ingredient.foundation.work-tracking.work-tracking-xpc-client](cookbook:f3f1af27-6cd7-4b3f-9024-135c6f6e89da)).
**Approved**: pending

**Decision**: Failure carries no reason; empty `Data` and the sentinel row are all the protocol says.
**Rationale**: The doc comments give empty `Data` or the sentinel row and no reason code, so "failed", "did not apply" and "undecodable" look the same to a caller. This is accepted debt, recorded here as a cost. The source names no trigger for adding a reason code; the natural one is a caller that must tell an unreachable daemon, a refusal and a bad reply apart, and that stays an open question for the maintainer.
**Approved**: pending

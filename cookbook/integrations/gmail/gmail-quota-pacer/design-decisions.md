
**Decision**: Pace with the generic cell rate algorithm, one `drainedAt` instant, rather than a token bucket with a refill timer or a per-minute counter.
**Rationale**: The doc comment says Google enforces "a moving average of about 250 units a second". One instant gives that average exactly, needs no timer or background task, and makes `reserve` a pure calculation over the injected clock, which is why the tests can use a stopped clock.
**Approved**: pending

**Decision**: `reserve` returns a wait and the caller sleeps; the pacer does not sleep itself.
**Rationale**: The REST client already has an injected `sleep` that tests replace to record delays. Keeping the wait outside the actor means the actor is never suspended while holding a reservation, so concurrent callers are not blocked behind one sleeper.
**Approved**: pending

**Decision**: The shared instance runs at 200 units a second with a 200-unit burst, not Google's 250.
**Rationale**: The doc comment on `shared` says the figure is "below Google's 250 units a second, leaving room for clock drift and other clients." The burst equals one second of rate. The 200 and 250 values are the source's choices; whether 200 leaves enough headroom for other clients is outside the source.
**Approved**: pending

**Decision**: One pacer is shared by every account in the process.
**Rationale**: The doc comment explains that each account has its own 250-unit allowance, so sharing only slows down syncing several accounts together and never lets one account exceed its quota. The cost is lost throughput when several accounts sync, in return for a single simple object.
**Approved**: pending

**Decision**: Reservations are final: a failed, retried or cancelled call keeps its reserved units.
**Rationale**: The source has no release operation, and the REST client reserves again for each retry. This over-counts rather than under-counts, which keeps the process under quota at the cost of some throughput after errors. This is non-obvious, so a port must not add a refund.
**Approved**: pending

**Decision**: The initializer traps on a non-positive rate instead of throwing.
**Rationale**: A bad rate is a programming error in code that passes constants, and a throwing initializer would force `shared` to be a throwing or optional value. The cost is that the check disappears under unchecked optimisation, and an overflowing duration is not checked at all.
**Approved**: pending

**Decision**: Technical debt: `reserve` does not validate the sign of `units`.
**Rationale**: A negative reservation refunds quota already counted, which is behavior the source does not intend and its callers do not use. The open question on `units-nonnegative` records it so a port either copies or rejects it deliberately.
**Approved**: pending

**Decision**: The cost table is a set of `Int` constants in the same file, from Google's published table.
**Rationale**: The doc comment cites developers.google.com/workspace/gmail/api/reference/quota. Keeping costs beside the pacer keeps the unit scale and the rate in one place. The table covers only the calls `GmailRESTClient` makes; other Gmail methods have no entry.
**Approved**: pending


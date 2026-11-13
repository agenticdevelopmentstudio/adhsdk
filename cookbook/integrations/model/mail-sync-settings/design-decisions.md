
**Decision**: Decode each key leniently with a default instead of failing on a missing key.
**Rationale**: Old rows must keep loading after a field is added, and hand-edited JSON should not brick a connection. Defaulting per key keeps every row readable.
**Approved**: pending

**Decision**: Keep range checking in `validated()` and out of decoding and the initializer.
**Rationale**: A stored row with a bad number still loads and can be shown and corrected, while the service calls `validated()` at the point a user's change is accepted. The cost is that an unvalidated instance can carry out-of-range numbers, and `validated()` returns the same type, so nothing in the type system tells a checked instance from an unchecked one. A distinct validated type or a throwing initializer was considered and rejected: either would make decoding fail on a bad stored row, which is the case this design keeps loadable.
**Approved**: pending

**Decision**: `.filed` is always allowed and has no flag.
**Rationale**: The user's filed mail is the core of what a connection exists to mirror, so turning it off would make the connection pointless; only the optional classes (archived, spam, trash) are opt-in.
**Approved**: pending

**Decision**: Window of 1 to 3650 days and poll interval of 1 to 1440 minutes.
**Rationale**: The bounds are fixed in `windowDaysRange` and `pollIntervalRange`; 3650 days is ten years and 1440 minutes is one day. The source gives no further reason for the numbers.
**Approved**: pending



**Decision**: Decode each key leniently with a default instead of failing on a missing key.
**Rationale**: The doc comment says "Decoding is lenient per key: a missing key takes its default", so rows stored before a field existed, or hand-edited JSON, still load.
**Approved**: pending

**Decision**: Keep range checking in `validated()` and out of decoding and the initializer.
**Rationale**: A stored row with a bad number still loads and can be shown and corrected, while the service calls `validated()` at the point a user's change is accepted. The cost is that an unvalidated instance can carry out-of-range numbers.
**Approved**: pending

**Decision**: `.filed` is always allowed and has no flag.
**Rationale**: The doc comment says "Filed mail is always mirrored; the other classes follow their flag", so the connection always mirrors the mail the user has filed.
**Approved**: pending

**Decision**: Window of 1 to 3650 days and poll interval of 1 to 1440 minutes.
**Rationale**: The bounds are fixed in `windowDaysRange` and `pollIntervalRange`; 3650 days is ten years and 1440 minutes is one day. The source gives no further reason for the numbers.
**Approved**: pending


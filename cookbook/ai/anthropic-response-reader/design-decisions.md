
**Decision**: The reader is passive and never throws; unreadable input leaves fields nil.
**Rationale**: Its doc comment says it reads "for the record", so a recording fault must never break or alter the response the caller is relaying. The cost is that a parse failure and an absent field look the same to a caller.
**Approved**: pending

**Decision**: A non-streaming body over 4 MiB is dropped entirely instead of parsed.
**Rationale**: The source documents "JSON bodies larger than this are not buffered; every field stays nil", bounding memory for a passive observer. A large valid body therefore yields no usage record.
**Approved**: pending

**Decision**: Streaming mode also discards its buffer when an unterminated line exceeds the same 4 MiB.
**Rationale**: The source comment says "A line with no newline for this long is not an event we need." The discard also drops any valid line prefix in the buffer.
**Approved**: pending

**Decision**: The last value read wins for each usage key, and a missing key keeps the earlier value.
**Rationale**: Anthropic reports input counts at `message_start` and the final output count at `message_delta`; the reader merges both into one set of fields. The reader does not sum counts.
**Approved**: pending



**Decision**: The spool stores the drop-file envelope, written by this encoder and read by `ParseResult`.
**Rationale**: One opaque blob and one decoder mean spooling adds no second format to keep in step and no second decoder to get wrong.
**Approved**: pending

**Decision**: The envelope is built at capture time, never at drain time.
**Rationale**: The envelope builder resolves the live `claude` process by cwd and reads its environment, so `context` is only true when the hook fires; deferring would attribute the event to whatever process holds that cwd later.
**Approved**: pending

**Decision**: Serializability is checked up front and throws a typed error.
**Rationale**: Finding out on the hook delivery, with the event in hand, costs one logged capture failure; finding out later leaves a row that fails to decode on every drain forever.
**Approved**: pending

**Decision**: `oauth_account_email` is written only when non-nil, including the empty string.
**Rationale**: The key's absence is the nil that means "predates the field"; an empty value means "resolved, no login", and a round trip must keep the two apart.
**Approved**: pending

**Decision**: The encoder does not reject an empty event type or a missing `session_id`.
**Rationale**: Those are the parser's outcomes (`.unparseable`, `.skip`); the drain handles each, so the encoder stays a plain serializer.
**Approved**: pending

**Decision**: The error description is a hardcoded English literal.
**Rationale**: The source has no localization table, and the text is read by developers in logs, not shown as an end-user message.
**Approved**: pending



**Decision**: Persist non-column properties as JSON text through the `Codable` conformance instead of writing per-record encode code.
**Rationale**: The protocol's doc comment states GRDB stores `[String]`, `MailSyncSettings`, `[EmailAttachmentRef]` and `LabelColor` as JSON TEXT, so adding a field needs no mapping code.
**Approved**: pending

**Decision**: Cache `mailClass` on `EmailMessage`, derived once in the initializer when not supplied.
**Rationale**: The field's doc comment says queries and tombstoning need not re-derive it from `labelIds`; the explicit parameter lets the store restore a stored class unchanged.
**Approved**: pending

**Decision**: Keep `EmailLabel.type`, `ActionLog.status` and `ActionLog.requestPayload` as plain strings rather than enums or typed payloads.
**Rationale**: The source documents their value sets only in comments (`"system"` or `"user"`; `"pending"`, `"ok"` or `"error"`; JSON text). Whether to promote them to enums is a decision for the owner.
**Approved**: pending

**Decision**: Store every timestamp as an ISO-8601 UTC string with fractional seconds.
**Rationale**: The `IntegrationClock` doc comment calls this the format every integration column uses, so the strings sort and compare as text.
**Approved**: pending


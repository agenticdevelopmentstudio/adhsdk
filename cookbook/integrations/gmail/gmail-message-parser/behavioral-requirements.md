
Contract: `parse(_ dto: GmailMessageDTO, connectionId: String, existingId: String?, now: Date = Date()) -> EmailMessage`. It is `public static`. Two helpers, `base64URLDecode` and `splitAddresses`, are module-internal and are also specified here because tests call them.

### Record identity and passthrough fields

- **total-function**: `parse` MUST return an `EmailMessage` for every input and MUST NOT throw or return an optional.
- **existing-id-kept**: The record `id` MUST equal `existingId` when `existingId` is non-nil.
- **generated-id**: The record `id` MUST be a newly generated UUID string in lowercase when `existingId` is nil. The generator is `UUID()` called inside `parse`, not an injected dependency, so the id cannot be fixed by a caller.
- **connection-id-passthrough**: The record `connectionId` MUST equal the `connectionId` argument.
- **external-id-passthrough**: The record `externalId` MUST equal the message `id` and `threadId` MUST equal the message `threadId`.
- **provider-default**: The record `provider` MUST be `gmail`, because the parser does not pass a provider and the `EmailMessage` initializer defaults it.
- **record-defaults**: The record `isDeleted` MUST be false and `deletedAt` MUST be nil, and `createdAt` and `updatedAt` MUST be the current time at the moment of the call, because the parser leaves those `EmailMessage` initializer defaults untouched; the `now` argument does not feed them.
- **snippet-default**: The record `snippet` MUST equal the message `snippet`, or the empty string when it is absent.
- **label-ids-passthrough**: The record `labelIds` MUST equal the message `labelIds`, or an empty list when they are absent.
- **history-id-passthrough**: The record `historyId` MUST equal the message `historyId` and stay nil when it is absent.
- **mail-class-derived**: The record `mailClass` MUST be the result of `MailClassifier.classify` (cookbook:ea7a9ec6-0a0c-4e97-8b03-ebc5f6246a43) applied to the same label ids that populate `labelIds`.

### Headers and addresses

- **header-lookup**: A header MUST be found by a case-insensitive name comparison, and when several headers share a name the first one in `payload.headers` MUST win.
- **headers-absent**: A message with no `payload`, or a payload with no `headers`, MUST be treated as having an empty header list.
- **from-raw**: The record `fromAddress` MUST be the unmodified value of the `From` header, or the empty string when there is none.
- **subject-raw**: The record `subject` MUST be the unmodified value of the `Subject` header, or the empty string when there is none.
- **recipient-lists**: The record `toAddresses` and `ccAddresses` MUST each be the `To` and `Cc` header value passed through the address splitter, and MUST be empty lists when the header is absent.
- **address-split-commas**: The address splitter MUST split on every comma that is outside double quotes.
- **address-split-escapes**: Inside double quotes, a backslash MUST cause the next character to be kept literally, so an escaped quote does not close the quoted section.
- **address-split-trim**: The address splitter MUST trim leading and trailing horizontal whitespace (spaces, tabs and other Unicode space separators, but not newlines) from each piece and MUST drop pieces that are empty after trimming.
- **address-split-keeps-text**: The address splitter MUST keep each piece's text, including display names and angle brackets, exactly as written apart from that trimming.

### Date

- **date-from-internal-date**: The record `internalDate` MUST be derived from the message `internalDate` read as a decimal number of epoch milliseconds when that value parses as a number.
- **date-from-header**: When the message `internalDate` is absent or does not parse as a number, the record `internalDate` MUST be derived from the `Date` header.
- **date-header-formats**: The `Date` header MUST be read with the POSIX English locale (`en_US_POSIX`) in exactly three layouts, tried in this order: `EEE, d MMM yyyy HH:mm:ss Z`, `d MMM yyyy HH:mm:ss Z` and `EEE, d MMM yyyy HH:mm Z` (Unicode date-format pattern letters; `Z` accepts a numeric zone such as `+0000`).
- **date-header-comment**: Everything from the first opening parenthesis of the `Date` header onward MUST be ignored before parsing, and surrounding spaces MUST be trimmed.
- **date-now-fallback**: When neither source yields a date, the record `internalDate` MUST be derived from the `now` argument, so the message sorts as new and not as 1970.
- **date-output-format**: The record `internalDate` MUST be an ISO 8601 string in UTC with fractional seconds to three digits, produced by `IntegrationClock.string(from:)`.

### Body and attachments

- **part-walk**: The parser MUST visit the payload and then every descendant part depth first, in document order, with no depth limit.
- **mime-match**: A part's `mimeType` MUST be compared in lowercase against the exact strings `text/plain`, `text/html` and `message/rfc822`; a missing `mimeType` MUST be treated as the empty string.
- **first-text-wins**: The record `bodyText` MUST come from the first `text/plain` part that belongs to the message's own content, and `bodyHtml` from the first such `text/html` part; later parts of the same type MUST be ignored.
- **named-part-is-file**: A part with a non-empty `filename` MUST NOT supply body text or body HTML, and neither MUST any part nested inside it.
- **attachment-listed**: A part with a non-empty `filename` and a non-nil `body.attachmentId` MUST add one `EmailAttachmentRef` carrying that `attachmentId`, the `filename`, the `mimeType` and the `size` to `attachments`, in document order.
- **attachment-defaults**: An attachment reference MUST use `application/octet-stream` when the part has no `mimeType` and MUST use size 0 when the part has no `body.size`.
- **attachment-nested-listed**: A named part with an attachment id MUST be listed even when it sits inside an embedded `message/rfc822` or inside another named part.
- **named-inline-unlisted**: A named part with no `attachmentId` (Gmail inlined its data) MUST NOT be listed as an attachment and MUST NOT become the body.
- **unnamed-in-named-ignored**: An unnamed part nested inside a named part MUST NOT be listed as an attachment, even when it carries an `attachmentId`.
- **embedded-message-isolated**: Text and HTML inside an unnamed `message/rfc822` part that sits in the message's own content MUST NOT be merged into the message body when the message has a body of its own.
- **embedded-message-fallback**: When the message has neither own plain text nor own HTML, `bodyText` and `bodyHtml` MUST be taken from the first plain text and first HTML found inside the embedded message.
- **embedded-fallback-all-or-nothing**: When the message has either an own plain text or an own HTML body, both `bodyText` and `bodyHtml` MUST come only from the message's own content, so an embedded body never fills the missing half.
- **no-body-is-nil**: `bodyText` and `bodyHtml` MUST be nil when no qualifying part exists.

### Decoding

- **base64url-decode**: Body data MUST be decoded as base64url: `-` read as `+`, `_` read as `/`, and `=` padding appended until the length is a multiple of four.
- **charset-declared**: Body bytes MUST be decoded with the charset named by the `charset` parameter of that part's own `Content-Type` header when the name is a recognised IANA charset and the bytes are valid in it.
- **charset-parameter-parsing**: The `charset` parameter name MUST be matched case-insensitively, and its value MUST have surrounding spaces and surrounding single or double quotes removed.
- **charset-fallback**: When no usable charset is declared, or decoding with it fails, the bytes MUST be decoded as UTF-8, and when that fails as ISO Latin-1.
- **undecodable-body-data**: A part whose `body.data` is not valid base64url MUST yield a nil body for that part with no log, error or flag, and a later part of the same type MUST then fill the body instead. Whether a dropped body should be surfaced is a pending Design Decision.

### Concurrency and side effects

- **no-shared-state**: The parser MUST NOT read or write shared mutable state, so concurrent calls on different inputs are independent. It is not referentially transparent: the environmental reads are the current time for the `now` default, `createdAt` and `updatedAt`, and a random UUID for the generated id.
- **no-io**: The parser MUST NOT perform file, network, process or notification side effects and MUST NOT log.


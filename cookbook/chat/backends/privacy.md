
- **Data collected**: the caller's typed message text and (for `ChatBackend`
  implementations) the full `ChatMessage[]` history are passed into
  `sendMessage`/`sendMessageStream`; tool-call `argumentsJSON` and
  `resultJSON`/`errorMessage` payloads flow through unmodified and may
  contain arbitrary caller/tool data. None of these classes inspect or
  redact that content.
- **Storage**: none of these seven files write to `localStorage`,
  `sessionStorage`, IndexedDB, or disk; all state is held in memory for the
  lifetime of the class instance.
- **Transmission**: `FetchBackend` POSTs `{ message, history }` as JSON to
  the caller-configured `url` over `fetch`, with whatever `headers` the
  caller supplies (including, potentially, credentials placed there by the
  caller). `PersonaChatBackend` never attaches credentials itself — every
  outbound request goes through the caller-injected `authorize` function,
  which is documented as the credential-attaching layer
  (`PersonaChatBackendOptions.authorize`); this class only supplies the path
  and body.
- **Retention**: none of these seven files persist or expire data of their
  own; retention of the conversation is entirely adh's (for
  `PersonaChatBackend`) or the caller's endpoint's (for `FetchBackend`)
  concern.


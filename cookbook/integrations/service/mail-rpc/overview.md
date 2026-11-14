
`MailRPC.swift` is the contract between a host and the mail integration service. It holds the request and response enums, the records they carry, and `MailClient`, a thin client that sends one request over any byte transport and turns the reply into a typed value or a thrown error.

- `MailRequest` lists every operation a caller can ask for, including the ones that administer the integration (the OAuth client, accounts, sign-in, sync settings) and the ones that read or label mail.
- `MailResponse` lists every reply, including `.failure`, which carries an optional `notFound` flag.
- `MailMessageFilter` describes which messages to list and clamps its `limit` to 1 through 500.
- `MailAccount`, `MailProviderStatus`, `MailLabel`, `MailMessage`, `MailMessagePage`, `MailThread` and `MailMoveResult` are the records the replies carry.
- `MailClient` is the caller's side: it encodes a request to JSON, decodes the reply, throws `MailClientError` for a `.failure`, refuses a page that an older service answered without honoring the filter, and reports a thread request that an older service cannot decode as a service too old to show threads.

The service side ([MailIntegrationService](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a)) is outside this file and answers these requests; the transport is injected, so the same client works over XPC, a socket or in-process.


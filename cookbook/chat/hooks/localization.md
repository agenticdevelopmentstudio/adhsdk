
Nearly every user-facing string surfaced through these hooks — persona and
user names, `useConnectRitual`'s `waitLines`/`stallLines`/`welcome`/
`greeting`/`connectingLine`/`connectedLine`, `useRotatingPhrase`'s pool
contents, and any text passed to `say`/`sayStream` — is caller-supplied
configuration, not a string this package owns, so there is nothing here for
a translation layer to intercept.

The one string this package does own: when `useChatSession` wraps a
legacy `ChatBackend` (one without `inboundEvents`) via `ChatBackendAdapter`
and that backend's `sendMessage` rejects, the persona reply is the fixed
English string "Sorry, something went wrong. Let's try again."
(`ChatBackendAdapter.ts`; `useChatSession.test.ts` "handles backend errors
gracefully"). `UseChatSessionOptions` has no override for it, so a port
ships the same string and localizes it in its own resource table.


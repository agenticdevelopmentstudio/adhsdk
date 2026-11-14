
**Decision**: Answer the existing mail RPC rather than give the UI a second, hub-shaped API.
**Rationale**: The mail browser, Email App and settings panel already speak `MailClient`; one adapter at the transport seam switches all three, and the UI keeps one code path while the direct worker still exists.
**Approved**: pending

**Decision**: A separate framework, built for macOS and iOS, rather than putting the bridge in Mail or HubMail.
**Rationale**: Mail holds the RPC types and HubMail holds the mirror; either holding the bridge would make one link the other. A third framework keeps both deletable on their own, which matters while the owner decides the direct path's fate.
**Approved**: pending

**Decision**: Write label changes into the mirror after the hub accepts them.
**Rationale**: The hub's action changes Gmail but not the hub's row, so without a local write the browser would show the old labels until the worker's next sync and the next pull. Keeping the sync version lets that pull replace the local write.
**Approved**: pending

**Decision**: Refuse search instead of matching text locally.
**Rationale**: Callers send Gmail search syntax (`from:`, `label:`, quoted phrases); a substring match would answer something different with no sign that it did.
**Approved**: pending

**Decision**: One stable client from `HubMailService`, swapped underneath on sign-in and sign-out.
**Rationale**: Windows take a `MailClient` when they open and keep it. A client that answers "sign in first" while signed out, and the mirror once signed in, means no window has to be told about a sign-in.
**Approved**: pending

**Decision**: Sign-out purges the mirror; `.restoring` and `.error` do not.
**Rationale**: A departing identity's mail must not stay readable on the machine. A failed refresh or a launch-time restore says nothing about who is signed in, so purging there would throw away mail for a user who is still signed in.
**Approved**: pending

**Decision**: `MailClient.routed` and `MailSource` live in the Mail framework, beside `MailClient`.
**Rationale**: The router reaches the client's private transport, and the source names belong to the mail RPC, not to the hub. An app picks a source without linking anything new.
**Approved**: pending

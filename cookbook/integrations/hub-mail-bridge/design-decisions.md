
**Decision**: Answer the existing mail RPC rather than give the UI a second, hub-shaped API.
**Rationale**: The mail browser, Email App and settings panel already speak `MailClient`; one adapter at the transport seam switches all three, and the UI keeps one code path while the direct worker still exists.
**Approved**: pending

**Decision**: A separate macOS framework rather than putting the bridge in Integrations or HubMail.
**Rationale**: Integrations is macOS-only and HubMail builds for iOS; either holding the bridge would make one link the other. A third framework keeps both deletable on their own, which matters while the owner decides the direct path's fate.
**Approved**: pending

**Decision**: Write label changes into the mirror after the hub accepts them.
**Rationale**: The hub's action changes Gmail but not the hub's row, so without a local write the browser would show the old labels until the worker's next sync and the next pull. Keeping the sync version lets that pull replace the local write.
**Approved**: pending

**Decision**: Refuse search instead of matching text locally.
**Rationale**: Callers send Gmail search syntax (`from:`, `label:`, quoted phrases); a substring match would answer something different with no sign that it did.
**Approved**: pending


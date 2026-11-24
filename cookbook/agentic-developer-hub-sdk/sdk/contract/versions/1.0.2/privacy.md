
- **Data collected**: `Backend.send` carries the new message's `text` and
  `attachments` only — never a transcript or prior history, matching the
  toolkit's stated design that a coordinator holds no history. `PermissionStore`
  persists `PermissionDecision` values keyed by `(permission, requesterID)`.
- **Storage**: `PermissionStore` is the one type in these sources responsible
  for retaining anything past a single call (`remember(decision:for:requesterID:)`);
  everything else — messages, drafts, read markers, command activity — lives
  only in the in-memory `ChatViewModel`/`Orchestrator` state these protocols
  describe, with no persistence mechanism given.
- **Transmission**: `Backend.send`, `setLocalTyping`, and
  `submitWidgetResponse` are the three points where locally authored content
  (message text, attachments, typing state, widget responses) leaves the
  client through a `Backend` conformer; the contract defines no encryption or
  transport requirement, leaving that to the conformer.
- **Retention**: Not specified by this contract for messages, drafts, or read
  markers — no expiry, TTL, or deletion method exists on any type here;
  `PermissionStore` decisions persist until a conformer's own storage says
  otherwise, which these sources do not define.


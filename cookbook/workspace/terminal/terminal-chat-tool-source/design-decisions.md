
**Decision**: Reach the terminal through a Terminal Chat, not the terminal itself.
**Rationale**: The source says that connected to a private terminal the persona only ever sees that terminal's privacy words, never the real ones.
**Approved**: pending

**Decision**: Look the Terminal Chat up on every call and hold nothing.
**Rationale**: The source says connecting one after the persona chat opened, or closing it, takes effect on the next tool call.
**Approved**: pending

**Decision**: Always advertise all three tools, even when no chat is connected, and answer the missing chat inside the call.
**Rationale**: The definitions do not depend on the chat, so the persona can be told what to ask the user for; the missing-chat message names the pane to add and the setting to turn on.
**Approved**: pending

**Decision**: Return the session's text as a non-error, including its own not-connected and still-running lines.
**Rationale**: Only this source's own failures (no chat, no command, unknown tool) are errors; the session's text is the terminal's answer, for the persona to read and act on.
**Approved**: pending

**Decision**: Tell the model that pseudonyms in the output are to be used as given.
**Rationale**: The run description says names in the output are pseudonyms, translated on the way in, so the model must not try to recover the real ones.
**Approved**: pending


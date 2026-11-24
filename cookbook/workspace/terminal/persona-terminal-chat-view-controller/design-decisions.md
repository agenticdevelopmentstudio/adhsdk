
**Decision**: The persona reaches the terminal only through the Terminal Chat in
the same tab.
**Rationale**: The source comment says the chat works the terminal "by way of the
Terminal Chat in the same tab, never the terminal directly", so a private
terminal's privacy words are all the persona sees. The feature is experimental
and deliberately narrow, and "the Terminal Chat" is the first one in the tab.
**Approved**: pending

**Decision**: Every session closure reads the pane's settings when the turn runs.
**Rationale**: The source comment says this applies a changed provider, model or
persona to the next message without rebuilding the session.
**Approved**: pending

**Decision**: Tool definitions are described in the provider's prompt by wrapping the
plugin in `PromptedToolCallingPlugin`.
**Rationale**: The source comment says no provider plugin sends tool definitions
natively and the Claude Code CLI cannot take custom ones.
**Approved**: pending

**Decision**: Choosing a provider clears the model override.
**Rationale**: The source comment says a model belongs to the provider it was
chosen from.
**Approved**: pending

**Decision**: The persona field commits on losing focus, and a blank or
default-equal text removes the stored key.
**Rationale**: The source comment says closing the sheet without pressing Return
must not throw the edit away; storing nothing for the default keeps the default
text updatable in one place.
**Approved**: pending

**Decision**: The status is re-applied on appear.
**Rationale**: The source comment says the Terminal Chat can only be found once
the pane is in the tree.
**Approved**: pending

**Decision**: Live model lists replace the template list only when non-empty and
current.
**Rationale**: Inferred from the guards (not cancelled, not empty, picker alive):
a slow or failed fetch must not blank a usable list or fill a closed sheet.
**Approved**: pending

**Decision**: Connect is stored as `1` and removed when off.
**Rationale**: Inferred from the setter; it keeps the default (off) as an absent
key like the other three settings.
**Approved**: pending


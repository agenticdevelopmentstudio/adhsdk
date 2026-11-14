
**Decision**: Tools are described in the system prompt and requested as `<tool_call>` JSON blocks in the reply text.
**Rationale**: The doc comment says it serves a provider that has no tool calling of its own, or whose plugin does not send the context's tools, so text is the only channel every provider has.
**Approved**: pending

**Decision**: The decoder holds the whole reply back until it ends.
**Rationale**: A block can be split across any chunk boundary, so the decoder cannot know whether a fragment is prose or a call until the reply ends; the comment names the cost, streaming, and the opt-in nature that follows from it.
**Approved**: pending

**Decision**: Earlier calls and results are written back into the history as text in the same block format.
**Rationale**: The comment says this makes the history read as one protocol, since the provider has no other way to see them.
**Approved**: pending

**Decision**: A malformed block stays in the prose.
**Rationale**: The comment says the user should see what the model wrote rather than lose it.
**Approved**: pending

**Decision**: Built-in tools are switched off for a turn that describes tools.
**Rationale**: The source comment says the described tools are the only ones the turn may use.
**Approved**: pending

**Decision**: A provider's native tool-use events pass through the decoder immediately.
**Rationale**: The comment says a provider that does call tools natively still gets through.
**Approved**: pending

**Decision**: A parameterless initializer wraps a plugin that fails every request with a clear message.
**Rationale**: The plugin contract requires it for loading a principal class from a bundle, which a wrapper never is, so a misuse fails loudly instead of silently producing nothing.
**Approved**: pending

**Decision**: The type is a wrapper that others opt into, not a base class or a change to every plugin.
**Rationale**: Wrapping keeps the buffering cost, which the comment names, with only the caller that needs tools.
**Approved**: pending


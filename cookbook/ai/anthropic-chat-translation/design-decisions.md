
**Decision**: Translation operates on untyped JSON dictionaries and copies only known fields; unknown content blocks and Anthropic-only fields are dropped.
**Rationale**: The doc comment says "only structural failure throws, unknown content blocks are dropped". Providers differ in what they accept, so dropping unknown input (thinking, cache control, metadata) keeps requests valid, at the cost of silently losing that data.
**Approved**: pending

**Decision**: The stream translator keeps at most one content block open and drops a late fragment for a tool call whose block has closed.
**Rationale**: The source comment states Anthropic's streaming format requires one open block at a time and "Anthropic cannot reopen" a closed block. Providers that interleave parallel tool-call fragments therefore lose the later fragments of an earlier call.
**Approved**: pending

**Decision**: A tool block starts only when the call has a name, buffering arguments until then; at the end, named pending calls start in descending key order and unnamed ones are dropped.
**Rationale**: An Anthropic `tool_use` start needs a name. The descending order is what the code does; the source gives no reason, and for keyless calls (negative keys counting down) it means arrival order, while for indexed calls it means highest index first.
**Approved**: pending

**Decision**: `maxTokensKey` is an argument and `max_tokens` is never defaulted.
**Rationale**: Some OpenAI-compatible providers want `max_completion_tokens`; the caller picks the name. Anthropic requires `max_tokens`, but this translator forwards the request's value only when present and leaves enforcement to the provider.
**Approved**: pending

**Decision**: Reply tool arguments that fail to parse as an object become an empty input object, and stream arguments are forwarded unvalidated.
**Rationale**: A whole reply must return a valid Anthropic message, so bad arguments are replaced; a stream cannot know completeness mid-flight, so it forwards fragments. The two paths therefore differ for invalid arguments.
**Approved**: pending

**Decision**: The stream's closing `message_delta` includes `input_tokens` as well as `output_tokens`, and `message_start` reports zero usage.
**Rationale**: Chat Completions reports usage once, late; the translator holds it for the closing event. This differs from Anthropic's own stream, where input usage arrives at the start. A reader such as the Anthropic response reader picks both up, because it applies usage from either event.
**Approved**: pending


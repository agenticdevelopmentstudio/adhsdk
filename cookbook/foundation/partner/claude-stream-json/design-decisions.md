
**Decision**: Decoding uses `JSONSerialization` and manual casts rather than `Codable`.
**Rationale**: Claude's stream has many message and block types and the app reads a few fields from each; manual casts let every unknown shape degrade to `.other` or `nil` instead of failing the line. Only a line that is not a JSON object throws.
**Approved**: pending

**Decision**: `reportsLostSession` requires an error `result` whose `errors` contain the phrase, not just the phrase anywhere.
**Rationale**: The source comment says claude emits an error `result` and then exits for a `--resume` id it does not have, and that other errors before any turn ran (authentication, quota) are not a lost session; matching the structured field keeps those from being treated as a lost session.
**Approved**: pending

**Decision**: A `tool_use` block carries its name and id but not its input.
**Rationale**: The source reads only `name` and `id` for it; consumers identify which tool ran (for example an MCP notify tool) without the arguments, which are not retained in the decoded message.
**Approved**: pending

**Decision**: A `tool_result` with array content joins the parts' text with a newline, and parts without text contribute nothing.
**Rationale**: The source flattens the parts to one string for display; non-text parts are dropped, so a result made only of non-text parts yields an empty string rather than `nil`.
**Approved**: pending

**Decision**: `userMessage` stops the process with a precondition failure if serialisation fails, instead of throwing.
**Rationale**: The source message states a user message is plain strings and always serializes; a failure would be a programmer error, and a non-throwing signature keeps every caller simple.
**Approved**: pending

**Decision**: The input line is terminated with a line feed and escapes no slashes.
**Rationale**: Claude reads stream-json input one line per message, so the newline is the message delimiter; unescaped slashes keep paths and URLs in prompts readable.
**Approved**: pending


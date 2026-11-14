
`PartnerProcessing` is the protocol and `PartnerProcess` the actor that runs `claude -p --input-format stream-json` over a `SubprocessChannel` and presents it as typed messages: text goes in as stream-json user messages, and stdout comes out as a stream of decoded `ClaudeStreamMessage` values that ends when the process ends. It also reports whether the process is running and what it wrote to stderr, so a crash can be told from a clean end.


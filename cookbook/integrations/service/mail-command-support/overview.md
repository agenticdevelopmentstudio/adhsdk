
`MailCommandSupport.swift` holds two caseless, internal enums used by both front ends of the mail integration: the `--json` flag of the command-line tool (`MailCommandLine`) and the MCP tools (`MailToolSource`). Putting them in one place means the two front ends print the same JSON and read dates by the same rules.

- `MailJSON` turns any `Encodable` value into the JSON text both front ends print.
- `MailDateBound` reads a `since` or `until` value and returns a UTC timestamp string, or nil when the text is not a date or timestamp.

Neither type holds state, touches a file, uses the network, or logs.


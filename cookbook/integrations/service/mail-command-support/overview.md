
`MailCommandSupport.swift` holds two caseless, internal enums used by both front ends of the mail integration: the `--json` flag of the command-line tool ([MailCommandLine](cookbook:be4db0fe-628d-41f8-9fdf-25a6d46844cf)) and the MCP tools ([MailToolSource](cookbook:cbee8b02-9456-4d9b-942a-51f8a9c074fc)). Putting them in one place means the two front ends print the same JSON and read dates by the same rules.

- `MailJSON` turns any `Encodable` value into the JSON text both front ends print.
- `MailDateBound` reads a `since` or `until` value and returns a UTC timestamp string, or nil when the text is not a date or timestamp.

They sit beside the [mail integration service](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a). The source file is `packages/apple/AgenticDeveloperHubSDK/Integrations/Service/MailCommandSupport.swift`. It uses `Foundation` only: `JSONEncoder` with `.prettyPrinted` and `.sortedKeys`, `Calendar(identifier: .gregorian)` pinned to UTC, and `ISO8601DateFormatter` with two option sets. No test sits beside it.

Neither type holds state, touches a file, uses the network, or logs.


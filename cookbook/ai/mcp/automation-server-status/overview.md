
`AutomationServerStatus` is an `ObservableObject` that holds what the CLI settings panel shows about the host's MCP endpoint. Its doc comment gives the division of labor: it is "filled by the host's automation feature when it starts, read by the panel." The host writes five published values (`port`, `token`, `command`, `isRegistered`, `failureReason`); the model derives the endpoint `url` and a one-sentence status `line` from them. It starts and stops nothing, performs no registration, and owns no I/O.


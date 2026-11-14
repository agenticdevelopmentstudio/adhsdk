
- **Data collected**: The model holds a bearer token for the MCP endpoint, a credential that lets a caller use the host's automation tools, plus a port and a free-text failure reason that may include a file path.
- **Storage**: In memory only, as a `@Published` `String?`. The model does not write the token to disk, Keychain or logs; where the token is persisted is up to the host feature that fills it.
- **Transmission**: None by the component. The token is made available to the registration command (see `MCPRegistration.claudeCommand(port:token:)`, which the panel copies to the pasteboard), and `url` is a `127.0.0.1` loopback URL.
- **Retention**: The token lives as long as the instance and is not cleared by the model. `line` and `url` never include the token, but the token property is readable by anything holding the instance.


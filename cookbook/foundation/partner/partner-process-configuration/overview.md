
`PartnerProcessConfiguration` is a value type describing how the partner's long-running `claude` process is launched. It holds the executable, the session ID, whether to resume it, the model, the permission mode, the allowed tools, the MCP config path, the system prompt path and the working directory, and exposes `arguments`, the exact argument list handed to the process.


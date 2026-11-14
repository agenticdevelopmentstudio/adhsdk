
`HostAppToolSource` is a final class conforming to `ChatToolSource` that gives a chat engine or an MCP host two tools every host application offers: `host_app_info`, which says what the host app is, and `host_open_chat_window`, which asks the host app to open a new AI chat window. Its source comment says it is "what `HostMCPServer` used to hard-code, now one source among several": the host server registers it like any other tool source.

The class holds four values given at construction: the app name, the app version, the names of loaded plugins, and a callback that opens a chat window. It keeps no other state and reads nothing from the environment. Both tools take no arguments. A call to any other tool name returns an error result rather than throwing.


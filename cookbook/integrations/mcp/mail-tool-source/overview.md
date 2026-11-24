
`MailToolSource` is a value type conforming to `ChatToolSource` that exposes a mail account service to a chat engine or MCP host as seven tools. It holds one `MailClient` and nothing else. It advertises each tool's name, description and JSON-schema parameters, then turns a tool call's JSON arguments into a typed `MailClient` call and the typed result back into text.

Results are pretty-printed JSON with sorted keys (the shared `MailJSON.encode` shape that the mail command-line tool's `--json` flag also prints). A bad argument or a service failure comes back as an error result, never as a thrown error. The tools are `mail_list_accounts`, `mail_list_labels`, `mail_list_messages`, `mail_get_message`, `mail_get_thread`, `mail_modify_labels` and `mail_move_messages`.


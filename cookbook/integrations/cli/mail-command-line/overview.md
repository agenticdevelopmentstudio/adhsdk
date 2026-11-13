
`MailCommandLine` is a caseless Swift `enum` that implements the `mail` command line for a host program. A host passes it the arguments after `mail`, a `MailClient` and two output closures. It parses the arguments, makes one call on the client, formats the answer as text (or JSON with `--json`), writes it to the supplied closures and returns a process exit status. It never touches the network, the file system or the process streams itself; the host owns those. It is a headless **logic** component, so Appearance, States and Accessibility are not applicable and the runtime contract lives in Behavioral Requirements.

The commands are `accounts`, `labels`, `list`, `get`, `thread`, `label add`, `label remove` and `move`. The public surface is `usage(program:)`, `run(_:program:client:stdout:stderr:)` and the constant `notFoundStatus`.


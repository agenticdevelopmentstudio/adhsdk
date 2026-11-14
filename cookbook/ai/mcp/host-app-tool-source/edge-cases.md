
- **Empty plugin list**: MUST render `(none)`; covered by `testHostAppInfoSaysNoneWhenThereAreNoPlugins`.
- **Plugin names with commas or line feeds**: MUST be written as given, joined with a comma and a space; the source does not escape them, so a name containing a line feed adds a line to the result.
- **Empty app name or version**: MUST be written as an empty value after the label; the source does not validate them.
- **Malformed argument bytes**: MUST be ignored; both tools take no arguments and the source never decodes them.
- **Unknown tool name, including empty**: MUST return `unknown tool <name>` with `isError` true, never a thrown error.
- **Callback that does nothing or fails to open a window**: the call MUST still report success; the callback returns nothing, so the source cannot observe the outcome.
- **Repeated `host_open_chat_window` calls**: each call MUST invoke the callback once; the source does not deduplicate or rate-limit, so two calls open two windows if the callback does.
- **Concurrent calls**: the class holds only immutable values, so concurrent calls do not interfere. The callback runs on the main actor, so concurrent open requests are serialised there and run one at a time.
- **Offline or disconnected state**: not applicable — the component performs no network or file operation; it only formats stored strings and calls the injected callback.
- **Error states from dependencies**: the only dependency is the callback, which cannot throw or return an error, so the call reports success regardless (open-reports-success-unconditionally).


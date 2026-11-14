
Construction

- **tool-source-conformance**: The component MUST conform to the host's tool-source contract (`ChatToolSource`), providing a tool-definition list and a call operation that takes a tool name, the argument bytes and an optional caller identifier.
- **construction-parameters**: The component MUST be constructed from an app name (string), an app version (string), an optional list of plugin names and an optional open-chat-window callback.
- **plugin-names-default**: When no plugin names are given, the plugin list MUST default to empty.
- **open-callback-default**: When no callback is given, the open-chat-window callback MUST default to one that does nothing.
- **open-callback-isolation**: The open-chat-window callback MUST be a main-actor-isolated, sendable closure that returns nothing.
- **concurrency-safety**: The component MUST be safe to share across concurrent callers; it MUST hold only immutable values fixed at construction (the source declares `Sendable`, and every stored property is a `let`).

Tool definitions

- **tool-list-order**: `toolDefinitions()` MUST return exactly two definitions, in this order: `host_app_info`, then `host_open_chat_window`.
- **info-description**: The `host_app_info` definition MUST carry the description "Returns the host app's name, version and loaded plugins."
- **open-description**: The `host_open_chat_window` definition MUST carry the description "Opens a new AI chat window in the host app."
- **empty-parameter-schema**: Both definitions MUST declare a JSON object schema with no properties.
- **names-are-bare**: The component MUST advertise and accept the unprefixed names; any prefix is added by the registering server and stripped before a call reaches the component.

Tool calls

- **info-result-format**: A call to `host_app_info` MUST return the three lines `Host: <appName>`, `Version: <appVersion>` and `Plugins: <plugins>` joined by a single line feed, with no trailing line feed.
- **info-plugins-joined**: In `host_app_info`, plugin names MUST be joined with a comma and a space, in the order they were given.
- **info-plugins-none**: In `host_app_info`, an empty plugin list MUST be written as `(none)`.
- **info-not-error**: A `host_app_info` call MUST return `isError` false.
- **open-invokes-callback**: A call to `host_open_chat_window` MUST invoke the open-chat-window callback exactly once and MUST wait for it to finish before returning.
- **open-result-text**: A `host_open_chat_window` call MUST return the text `Opened a new chat window.` with `isError` false.
- **open-reports-success-unconditionally**: A `host_open_chat_window` call MUST return the success text even when the callback is the default no-op, because the callback has no return value and cannot signal failure.
- **unknown-tool-error**: A call with any other tool name MUST return the text `unknown tool <name>` with `isError` true.
- **arguments-ignored**: The component MUST ignore the argument bytes; it MUST NOT parse or validate them, so malformed or non-empty arguments have no effect.
- **caller-ignored**: The component MUST ignore the caller identifier.
- **no-throw**: The call operation MUST NOT throw; every outcome is a returned content string and an error flag.
- **no-side-effects-for-info**: `host_app_info` MUST NOT invoke the open-chat-window callback.


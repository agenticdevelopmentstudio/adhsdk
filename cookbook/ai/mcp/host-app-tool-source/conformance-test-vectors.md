
Derived from `HostAppToolSourceTests` where named; the rest are traced to the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| host-app-tool-source-001 | tool-list-order, info-description, open-description | `toolDefinitions()` on a source built with app name "Kitchen" (`testHostAppToolSourceAnswersInfoAndOpensChat`) | Two definitions with names `host_app_info`, `host_open_chat_window`, in that order, with the two descriptions above |
| host-app-tool-source-002 | empty-parameter-schema | `toolDefinitions()` | Both definitions' schemas are object schemas with an empty property map |
| host-app-tool-source-003 | info-result-format, info-plugins-joined, info-not-error | App name "Kitchen", version "2.0", plugins `["ClaudeAPI"]`; call `host_app_info` with `{}` | Content `Host: Kitchen\nVersion: 2.0\nPlugins: ClaudeAPI`, `isError` false (`testHostAppToolSourceAnswersInfoAndOpensChat`) |
| host-app-tool-source-004 | info-plugins-none, plugin-names-default | App name "Kitchen", version "2.0", no plugins; call `host_app_info` | Content `Host: Kitchen\nVersion: 2.0\nPlugins: (none)` (`testHostAppInfoSaysNoneWhenThereAreNoPlugins`) |
| host-app-tool-source-005 | info-plugins-joined | Plugins `["A", "B", "C"]`; call `host_app_info` | The third line is `Plugins: A, B, C` |
| host-app-tool-source-006 | open-invokes-callback, open-result-text | Callback increments a counter; call `host_open_chat_window` once | Content `Opened a new chat window.`, `isError` false, counter is 1 (`testHostAppToolSourceAnswersInfoAndOpensChat`) |
| host-app-tool-source-007 | open-callback-default, open-reports-success-unconditionally | Source built without a callback; call `host_open_chat_window` | Content `Opened a new chat window.`, `isError` false, nothing else happens |
| host-app-tool-source-008 | no-side-effects-for-info | Callback increments a counter; call `host_app_info` | Counter stays 0 |
| host-app-tool-source-009 | unknown-tool-error | Call name `nope` with `{}` | Content `unknown tool nope`, `isError` true |
| host-app-tool-source-010 | arguments-ignored, caller-ignored | Call `host_app_info` with argument bytes `not json` and caller `pane-7` | Same content and `isError` as with `{}` and no caller |
| host-app-tool-source-011 | unknown-tool-error | Call with the empty string as the name | Content `unknown tool ` (trailing space), `isError` true |
| host-app-tool-source-012 | names-are-bare | Call `host_open_chat_window` with a prefixed name such as `app_host_open_chat_window` | Content `unknown tool app_host_open_chat_window`, `isError` true |


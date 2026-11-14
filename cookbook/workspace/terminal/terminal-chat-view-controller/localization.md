
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none (literal) | Not connected — click the link to choose a terminal | Status while no pane is remembered |
| none (literal) | Its terminal isn't available yet — or click the link to choose another | Status while a pane is remembered but has no terminal |
| none (literal) | Starting the terminal… | Status while a start is in flight |
| none (literal) | The terminal could not start: <description> | Status after a failed start |
| none (literal) | Connected to <pane title> — click to disconnect | Link title, tooltip and accessibility label |
| none (literal) | Not connected — click to choose a terminal | Link title while unconnected |
| none (literal) | Disconnect from <pane title>? | Confirmation message |
| none (literal) | This chat stops typing into the terminal and reading what it prints. | Confirmation detail |
| none (literal) | Connect to Terminal… | Settings row |

- **string-localization**: Every user-visible string MUST be an English literal written in the source; the controller does no localization lookup, and the macOS package has no string catalog or localized-string call.

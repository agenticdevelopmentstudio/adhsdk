
The component has no UI text of its own other than the default `emptyMessage`; column titles and log content are supplied by the consumer and are outside the component's control.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `emptyMessage` | `(no events)` | Shown in the scrollable body when there are no visible rows |

The default value is hardcoded English. Consumers that support additional locales SHOULD supply a localized `emptyMessage` string rather than rely on the built-in default.


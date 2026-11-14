
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `batch_select.select` | "Select" | Label for `BatchSelectButton` when not in batch mode. The `selectLabel` prop overrides this default. The web source ships the default as a literal English string (a JavaScript default parameter), so consumers localize by passing `selectLabel`; resolving the default through a platform localization system is a requirement for ports, not behavior the web source has today. |
| `batch_select.done` | "Done" | Label for `BatchSelectButton` when in batch mode. The `doneLabel` prop overrides this default. As with `selectLabel`, the web source ships a literal English default, so consumers localize by passing `doneLabel`. |


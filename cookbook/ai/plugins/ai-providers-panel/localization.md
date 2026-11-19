
The panel routes none of its user-facing strings through a localization
mechanism; they are hardcoded English literals:

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — hardcoded literal) | `AI Connections` | The panel's title |
| (none — hardcoded literal) | `Connections` | The sidebar's heading |
| (none — hardcoded literal) | `Add a provider` / `Remove the selected provider` | The footer buttons' tooltips |
| (none — hardcoded literal) | `Delete “<name>”?` | The delete confirmation's message |
| (none — hardcoded literal) | `This removes the configuration and its stored settings, including any API key.` | The delete confirmation's explanation |
| (none — hardcoded literal) | `Delete` / `Cancel` | The delete confirmation's buttons |
| (none — hardcoded literal) | `1 plugin failed to load` / `<n> plugins failed to load` | The load-failures row's title |
| (none — hardcoded literal) | `Name` | The editor's name row label |
| (none — hardcoded literal) | `Default Model` | The editor's default model row label |
| (none — hardcoded literal) | `<provider> - <LLM> - <config type>` | A configuration panel's subtitle; the separator is a literal |
| (none — hardcoded literal) | `<provider>, <LLM>, <config type>` | The configuration editor's title; the `, ` separator is a literal |
| (none — hardcoded literal) | `Choose Model…` | The Test Chat's button that opens the popover model chooser |
| (none — hardcoded literal) | `Test Chat` | The caption over the Test Chat card under a configuration's editor |

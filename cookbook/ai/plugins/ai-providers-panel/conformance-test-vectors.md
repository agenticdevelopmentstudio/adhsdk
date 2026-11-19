
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ai-providers-panel-001 | providers-panel-subtitle, providers-editor-title | Template with provider "Acme", LLM "Chat", config type "API key" | The subtitle is "Acme - Chat - API key" and the editor title is "Acme, Chat, API key" |
| ai-providers-panel-002 | providers-panel-subtitle, providers-editor-title | Template with provider "Acme", empty LLM, config type "Local" | The subtitle is "Acme - Local" and the editor title is "Acme, Local" |
| ai-providers-panel-003 | providers-editor-default-model-row | Configuration with stored model ""; template default "m1" | The "Default Model" row names "m1"; choosing "m2" writes "m2" to `aiplugin.config.<id>.model` and the row names "m2" |
| ai-providers-panel-004 | providers-editor-no-free-text-model, providers-editor-untitled-connection-group | Open a configuration's editor | No free-text model field is present; the connection group has no title; its first row is "Name" |
| ai-providers-panel-005 | providers-editor-secret-reveal | A configuration with a stored API key "sk-123" | The key field shows six dots (one per character, per the secure text row's `stored-secret-shows-as-dots`) with copy and eye buttons; a non-secret field such as Base URL is a plain text row |
| ai-providers-panel-006 | providers-test-chat-model-only | Open the editor's Test Chat | Only the model row shows; its Choose Model action opens the popover chooser for this configuration |
| ai-providers-panel-007 | providers-panel-add | Add the template with display name "Acme" twice | Two configurations, named "Acme" and "Acme 2"; the first holds the template's seeded field values |
| ai-providers-panel-008 | providers-panel-remove-clears-values | One configuration, named by the selected-configuration-id setting; delete it | The list is empty and the selected-configuration-id setting is "" |
| ai-providers-panel-009 | providers-panel-load-failures | One load failure, then two | The row is titled "1 plugin failed to load", then "2 plugins failed to load" |

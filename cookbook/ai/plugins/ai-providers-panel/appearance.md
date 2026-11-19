
- **Sidebar**: headed "Connections", one row per configuration titled with
  the configuration's name, with the subtitle "Provider - LLM - Config type"
  (see **providers-panel-subtitle**), and a trailing load-failures row when
  plugins failed to load (see **providers-panel-load-failures**). Below the
  list, a footer with + ("Add a provider") and − ("Remove the selected
  provider") buttons.
- **Editor**: a title line reading "Provider, LLM, Config type" (the
  configuration's name when all three parts are empty), then one untitled
  group holding the Name row, one row per template field in the plugin's
  order (secret fields as the secure text row), and the "Default Model"
  model picker row (see **providers-editor-title**,
  **providers-editor-untitled-connection-group** and
  **providers-editor-default-model-row**). The editor is sized to its
  content.
- **Test Chat**: a card captioned "Test Chat" below the editor, at least
  240 points tall, showing the model row with its "Choose Model…" button and
  no provider choice (see **providers-test-chat-model-only**).

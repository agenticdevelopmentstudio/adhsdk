
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Plugin manager | plugin manager | — (required) | Supplies the available templates, each template's fields and the plugin load failures. |
| `"aiplugin.configurations"` | list of provider configurations (settings key) | `[]` | The configurations the panel lists, adds to, renames and removes from (owned by the plugin runtime). |
| Per-configuration field and model settings | text settings | the template's defaults | What each editor row reads and writes, through the plugin runtime's configuration store. |

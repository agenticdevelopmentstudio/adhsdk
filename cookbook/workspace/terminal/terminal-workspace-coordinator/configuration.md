
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| database | project database | required | Where the window keeps its tabs and layout. |
| directory | URL | the user's home directory | The folder the workspace, and so every new shell, starts in. |
| name | string | required | The window's title and the workspace row's name. |
| commandRegistry | command registry | required | Where the two commands are registered. |
| pluginManager | plugin manager, optional | none | The LLM providers persona chat panes run on; nil leaves that pane type out. |
| chatDirectory | terminal chat directory, optional | none | Where terminal chat panes list themselves for outside processes to drive; nil keeps them private. |
| privacyVault | privacy words vault, optional | none | The privacy words private terminal panes run behind; nil leaves that pane type out. |
| windowManager | project window manager | the shared manager | What opens and tracks the window. |


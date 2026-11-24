
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| preferredAxis | split axis | required | Which way the Split menu proposes adding another terminal; a host stacking terminals beside other panes wants vertical, a terminal-only window wants side by side. |
| pluginManager | plugin manager, optional | none | The LLM providers a persona chat runs on; without it the persona terminal chat pane is not offered. |
| chatDirectory | terminal chat directory, optional | none | Where terminal chats list themselves for outside processes to drive. |
| privacyVault | privacy words vault, optional | none | Without it the private terminal pane is not offered. |
| environment | dictionary or closure | empty | Extra shell variables for every terminal pane's shell, under the pane's own identity variables, read each time a pane is created. |
| browserTools | chat tool source, optional | none | Tools for driving the Browser pane, offered to persona chats beside the terminal tools. |


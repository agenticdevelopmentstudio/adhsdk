
The Tool Call Pill View displays a single `CommandActivity` as a bordered, status-colored pill in a chat transcript. It shows the command name and, when the command has failed, appends the error message. The pill is color-coded by execution state: neutral blue (info) while running, green (success) on successful completion, and red (danger) on failure. The component observes theme palette changes and recolors its border and text live without requiring a rebuild.


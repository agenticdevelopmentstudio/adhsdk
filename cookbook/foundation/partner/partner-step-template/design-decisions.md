
**Decision**: Substitution is one pass over the original command.
**Rationale**: A value can contain text written by someone else (a commit subject). Scanning values again would let that text pull in other values or placeholders; a test pins it.
**Approved**: pending

**Decision**: Terminal steps quote values; Claude steps do not.
**Rationale**: A terminal step is a shell command line where an unquoted `opus[1m]` is a glob, while a Claude step is a prompt where quotes would show up as literal characters.
**Approved**: pending

**Decision**: A plain word is left unquoted.
**Rationale**: So that a command such as `claude --model opus` still reads naturally; only values with a character outside the plain set are quoted.
**Approved**: pending

**Decision**: `=` and `~` are outside the plain set.
**Rationale**: A leading `=` is zsh's command-path expansion and `~` expands to a home directory.
**Approved**: pending


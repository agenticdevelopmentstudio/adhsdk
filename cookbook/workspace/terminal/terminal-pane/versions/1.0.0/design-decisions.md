
**Decision**: The terminal pane opens on a live shell.
**Rationale**: The source comment says an empty pane is a dead end the user would have to click out of every time.
**Approved**: pending

**Decision**: The terminal pane shows no session list.
**Rationale**: In a project window the tab already carries the directory and branch that list would identify a shell by.
**Approved**: pending

**Decision**: The shell environment is a closure read when a pane's content is created.
**Rationale**: A value the host learns later, such as the port a server has bound, must reach every pane opened after it is known; the source comment says each shell, but the closure is evaluated in the pane factory and the resulting dictionary is fixed for that pane's shells.
**Approved**: pending

**Decision**: The pane's own variables replace host variables of the same name.
**Rationale**: ADKITCHEN_PANE_ID is how "this pane" resolves to the Browser pane beside it, so a host value must not override it.
**Approved**: pending

**Decision**: Registration and allowance come from one family value.
**Rationale**: A pane added to the family reaches every host that offers it with no edit there, and no host can register a pane without allowing it.
**Approved**: pending

**Decision**: The raw value of the terminal view identifier is fixed.
**Rationale**: Persisted layout rows already name it.
**Approved**: pending


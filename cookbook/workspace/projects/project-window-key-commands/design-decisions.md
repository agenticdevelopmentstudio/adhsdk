
**Decision**: The window is resolved when a command runs, not when the section is
built.
**Rationale**: The source comment (like `ConversationsKeyCommands`) says this lets
the section be declared at launch, before any project window exists.
**Approved**: pending

**Decision**: A command declines (returns `false`) unless a project window is key.
**Rationale**: The source comment says this lets Command-0 also be the
Conversations window's list; `isWindowSpecific` records it in the section.
**Approved**: pending

**Decision**: A declined command is logged at debug level with the key window's
title.
**Rationale**: The source comment says declining is normal, but a chord that
silently does nothing is the hardest thing to debug, so the log says which window
had the keyboard.
**Approved**: pending

**Decision**: Shortcuts are defaults only, not fixed bindings.
**Rationale**: The commands are described as bindable, so the user can rebind
them in the key-command settings.
**Approved**: pending


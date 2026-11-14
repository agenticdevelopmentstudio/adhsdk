
StatusPill is a small, presentational pill-shaped label. It accepts arbitrary children as its status text and an optional `free` boolean prop that switches on an accented style — a distinct border color over a dimmed background — to make one status stand out from the rest. Per the source comment, it backs two call sites that deliberately share this same pill shape: a `Hero`'s shipping status and a `Chips` list of model providers, where `free` marks the one item that should read as accented.


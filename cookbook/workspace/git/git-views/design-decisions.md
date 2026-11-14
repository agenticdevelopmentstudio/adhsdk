
**Decision**: The sidebar hosts a topic list as a child rather than subclassing it.
**Rationale**: The sidebar's public surface is its data source, delegate and `reload()`; a subclass would also publish the list's own setters, letting a caller replace the sections behind the sidebar's back.
**Approved**: pending

**Decision**: Remote branches are grouped as one flat section per remote (`Remotes · origin`) rather than nested under one `Remotes` header.
**Rationale**: The topic list is deliberately flat (no disclosure, no indentation); a section per remote groups them without a second list type.
**Approved**: pending

**Decision**: The ahead/behind badge and the bold head row are topic-list features (`badge`, `isEmphasized`), not sidebar drawing.
**Rationale**: Built from the shared component upward: any sectioned sidebar can show a count or mark the current row, and the topic list keeps owning its cells.
**Approved**: pending

**Decision**: The data source vends the repository root, so a submodule row can name its directory.
**Rationale**: `git submodule status` reports paths relative to the working tree; the model already knows its root.
**Approved**: pending


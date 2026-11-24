
**Decision**: Transport the title by registering the publisher's id and portalling the node into a stack-owned slot, rather than publishing the title value.
**Rationale**: The earlier transport carried only a string, because a node is a new object every render and an effect keyed on one re-publishes forever. Registering the id lets any node be the title, and the stack provides the context itself, so no host plumbs anything.
**Approved**: pending

**Decision**: Split the transport into a registrar context and a target context.
**Rationale**: With one context, every slot or winner change would hand publishers a new value, re-run their registration effects, and re-append each one, reshuffling who wins on every render.
**Approved**: pending

**Decision**: When several panes register, the last to register wins and the others draw inline.
**Rationale**: This is the old registry's rule, and it means a second title is never lost.
**Approved**: pending

**Decision**: Expose the strip cell as `role="heading"` with `aria-level="2"` on a span, and only while titled.
**Rationale**: Hoisting the title out of an `h2` took the pane's accessible level 2 heading with it. A role keeps the slot element's type constant, and applying it only while titled keeps an empty strip from announcing an empty heading.
**Approved**: pending

**Decision**: Render `DetailTitleSuppressed`'s provider on every render and swap the registrar for null rather than unmounting the provider.
**Rationale**: A pane the stack keeps mounted but hidden must stay mounted; re-parenting would remount its children, and a null registrar simply unregisters their titles.
**Approved**: pending

**Decision**: Hold the last seen label for the selected row, derive it during render, and fall back to the id.
**Rationale**: A search or tag filter can drop the open row from its level while it stays open; the bare lookup then blanked the strip while the crumb showed the raw id. Updating state during render avoids painting the blank strip once before correcting it.
**Approved**: pending

**Decision**: Keep the title inline in server HTML and move it with a layout effect.
**Rationale**: The slot is DOM, so on the server the inline title stays for crawlers and readers without JavaScript, and the layout effect moves it before the first client paint.
**Approved**: pending

**Decision**: A host's `fallback` title is used only while no pane publishes, and null or false opts out.
**Rationale**: A pane's own title is the more specific name for what is on screen, while a host that owns the whole detail still names it through the prop.
**Approved**: pending


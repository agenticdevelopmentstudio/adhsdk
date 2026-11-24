
- **Stale focus**: a deleted item's id falls back to the All view (MUST), because the id no longer matches.
- **Empty items**: the selector still renders; the All view shows `allEmptyLabel`.
- **No active topic**: with focus but no matching topic, the derived header cannot form, so it is omitted unless `title` is given.
- **Id collision with the All row**: `PopupMenu` warns on the console when an item id collides with its All sentinel (`__all__`).
- **Selector without All**: not reachable from this block, which always leaves the All row on.
- **Disabled topic while focused**: a topic's own `disabled` is kept.
- **Error and offline states**: not applicable; the block does no I/O and surfaces no errors. Loading and failure states belong to the consumer's pane content.


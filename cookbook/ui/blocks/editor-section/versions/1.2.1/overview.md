
`EditorSection` in `@adh-sdk/ui/blocks/editor-section` is the platform's
standard master/detail **editor shell**: a records rail on the left, an editing
detail pane on the right, and a fixed editing toolbar across the top. It is a
**pure assembly** — it owns no visual grammar of its own. It stacks three shared
blocks:

1. a `ButtonBar` (the recessed editing strip) carrying a gold mono title on the
   left and the standard **New / Delete / Cancel / Save** action preset on the
   right;
2. a `TopicDetail` two-pane primitive whose collapsible rail lists the records
   (each row may show a `⚠` warn badge), and
3. the shared `EmptyState` placeholder, shown in the detail pane whenever nothing
   is selected.

The consumer owns all state — the record list, the current selection, the draft
and its `dirty` flag, the `busy` (saving) flag, and every mutation callback.
`EditorSection` maps that state onto the three parts and computes the derived
"editing" condition (a selection exists) and the derived Save/Delete enablement.
`children` is the record's editor form, rendered in the pane only while editing.

It is the base editor shell behind hub/admin topics that manage a list of records
(sites, integrations, personas, …) and is reusable platform-wide.


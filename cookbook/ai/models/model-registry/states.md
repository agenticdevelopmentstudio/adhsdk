
Not applicable — this is a persistent store, resolver and secret-store seam, not
a visual component. Its one runtime lifecycle (opened and migrated, then
serving reads and writes) is covered under Behavioral Requirements
(`store-migration`, `upsert-signals`, `changes-stream`), not as a visual-state table.


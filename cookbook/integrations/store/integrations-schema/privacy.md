
- **Data collected**: The tables are built to hold email message addresses, subjects, snippets, bodies, labels and connection scopes mirrored from the hub; the schema itself collects nothing.
- **Storage**: Plain TEXT columns in the local SQLite file behind the `BoundedDatabase`; the schema declares no encryption, and protecting the file is outside this source.
- **Transmission**: None. The schema only creates local tables.
- **Retention**: Rows remain until a store operation tombstones them through `deleted_at` or `is_deleted`; the schema declares no expiry and no purge. Action log rows have no tombstone column.


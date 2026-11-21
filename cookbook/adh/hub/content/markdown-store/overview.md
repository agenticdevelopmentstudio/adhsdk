
This is the local persistence and outbound-sync layer for the `content.markdown`
resource family. Six responsibilities divide the work: a schema definition owns the
database's structure and migrations; a projection translates pulled rows into and out
of that schema as a sync-mirror projection; a store owns document creation, update,
lifecycle (publish/unpublish/finalize/definalize/delete), and a dedicated outbox
queue; a taxonomy extension adds categories, category edges, and keywords on top of
the store, and the store conforms to the note-taxonomy interface — the synchronous
category calls a notes window makes, declared beside it so a storage that keeps its
categories elsewhere can answer them too; a timestamp component is the one place a column becomes a date and back;
and a remote-writer contract declares — without yet implementing — the interface a
host uses to actually send a queued operation to adh.

The store owns one local database holding `markdown` rows plus three marker tables
(`notes`, `docs`, `papers`) and a taxonomy of
`categories`/`category_edges`/`category_items`/`keywords`/`keyword_items`. Local
writes land synchronously in the database and enqueue a row in the local-only
`_markdown_outbox` table; the queue drain later sends each queued operation through a
caller-supplied remote-writer contract in strict `seq` order. Remote pulls arrive
through a generic sync-mirror-projection engine via the projection component, the
only place adh's rows are translated into this schema's columns; `content.markdown`,
`content.notes`, `content.docs`, and `content.papers` are pull-only, while taxonomy
resources ride the same generic push path documents deliberately do not.

Each document row also carries a local-only `local_version`, bumped by every local
write and every applied pull and logged to the sync store's change feed, which a
writer may quote as an expected version to have a stale write refused. The store can
open its own database or share one a host already owns.



**Decision**: one store and one file for both lists, with a `list` column,
rather than two stores.
**Rationale**: The two lists have the same shape and are asked the same
question; one implementation keeps them from drifting (`dry`) while the
`list` column and a list argument on every query keep them apart.
**Approved**: pending

**Decision**: a standalone file, `BrowserHiddenItems.db`, not a migration
of the project database.
**Rationale**: A call recorded in the design. A file holding only these
lists can be deleted without a migration touching anything else
(`design-for-deletion`), as the browser history store's own file can.
**Approved**: pending

**Decision**: the site switch lives in its own table keyed by list and
site, with absence meaning on.
**Rationale**: The default needs no row for every site visited, and a
list-keyed switch leaves room to give the agent list a switch later without
a migration; today the agent list's value is ignored.
**Approved**: pending

**Decision**: the store refuses an entry with an empty selector.
**Rationale**: Builder's choice. An empty selector would produce an
invalid rule; the picker already refuses such picks, and the store
enforces it once more at the boundary.
**Approved**: pending


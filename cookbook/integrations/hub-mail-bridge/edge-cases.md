
- A `from` with no angle brackets is used whole, trimmed and lowercased.
- Two connections that derive the same address both list; a lookup by that address takes the first in connection order, and a lookup by id is always exact.
- A message id that matches no live row is not found; the bridge cannot read Gmail directly, so a message the hub has not synced is not reachable.
- A label change written into the mirror is replaced by the hub's row on the next pull that carries it; until the worker syncs, a pull that carries an older copy of the row puts the old labels back.


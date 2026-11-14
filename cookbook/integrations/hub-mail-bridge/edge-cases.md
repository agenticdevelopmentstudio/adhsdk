
- A `from` with no angle brackets is used whole, trimmed and lowercased.
- Two connections that derive the same address both list; a lookup by that address takes the first in connection order, and a lookup by id is always exact.
- A message id that matches no live row is not found; the bridge cannot read Gmail directly, so a message the hub has not synced is not reachable.
- A label change written into the mirror is replaced by the hub's row on the next pull that carries it; until the worker syncs, a pull that carries an older copy of the row puts the old labels back.

- An id stored under the device-id key that is empty is treated as missing and replaced, so a blank value never reaches the hub as a device id.
- Two apps that share one `UserDefaults` and one key share one device id; an app wanting its own passes a different `deviceIdKey`.
- Deleting the defaults loses the device id, so the next launch is a new device to the hub and starts a new cursor.
- `HubMailLocation.app(_:)` only names the file; a folder that does not exist yet is created when the database first opens on sign-in.

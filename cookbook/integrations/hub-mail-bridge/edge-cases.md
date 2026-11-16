
- A `from` with no angle brackets is used whole, trimmed and lowercased.
- Two connections that derive the same address both list; a lookup by that address takes the first in connection order, and a lookup by id is always exact.
- A message id that matches no live row is not found; the bridge cannot read Gmail directly, so a message the hub has not synced is not reachable.
- A label change written into the mirror is replaced by the hub's row on the next pull that carries it; until the worker syncs, a pull that carries an older copy of the row puts the old labels back; the Design Decisions record this as deliberate prudent debt.
- An id stored under the device-id key that is empty is treated as missing and replaced, so a blank value never reaches the hub as a device id.
- Two apps that share one `UserDefaults` and one key share one device id; an app wanting its own passes a different `deviceIdKey`.
- Deleting the defaults loses the device id, so the next launch is a new device to the hub and starts a new cursor.
- A launch whose restore ends signed out finds the mirror the previous launch's identity left on disk (the app quit while signed in); `signedOut()` opens it and purges it, so a different identity signing in next never reads that mail.
- A sign-in that arrives while a sign-out is still purging waits for the purge, then opens the mirror; otherwise the purge would delete the rows the new identity had just pulled.
- `HubMailLocation.app(_:)` only names the file; a folder that does not exist yet is created when the database first opens, on sign-in or on a sign-out purge.


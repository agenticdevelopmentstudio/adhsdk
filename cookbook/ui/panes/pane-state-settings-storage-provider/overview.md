
This provider is the override layer for a layered settings store. It
implements the settings storage contract (get, set, remove, contains, keys
with a prefix, and a change publisher) on top of a pane's state store, which
holds one string per key. A pane that uses it keeps its own setting overrides
with the rest of its state, so they are saved, restored and deleted along with
the pane. See [adhsdk.ingredient.foundation.layered-settings-store](cookbook:846ec786-5b96-4ee0-b7db-d6ae4bd6e333)
for the store that layers it over a broader fallback and
[adhsdk.ingredient.foundation.settings-storage](cookbook:6363b5ff-f511-4e21-9ba7-6850787dba62)
for the contract it implements.

Each value is written as JSON inside a one-element array, because a bare
scalar is not a JSON document. Every value is stored under the key made of a
prefix (default `settings.`) and the setting's name. A second entry, the index
(prefix plus `__keys`), holds a JSON array of the names this provider has
written. The index exists because the pane state store can read and write a
key but cannot list its keys, so it is the only way to answer a prefix query
after a relaunch.

A stored string that no longer decodes as the requested type, such as an enum
that lost a case, reads as absent, so the layer above falls back to its own
value instead of failing.



The Ecosystems ingredient is the Ecosystems ("Products") domain of the hub: the
non-UI logic that lists, creates, renames, and deletes an *ecosystem* - a
reverse-domain-identified (rdid) product row that can itself own child
ecosystems, and that other domains (applications, buckets, customers) hang
off of. Two independent, source-of-truth reference implementations model the
identical contract from opposite ends of one system; this ingredient covers both
together, and Platform Notes describes how each
realizes it.

Both implementations model the same backend fact: an ecosystem's public
identity is a *stored, mutable* rdid (`id` / `identifier`), but the row's
*own* address is *derived* from `(parent chain, slug)` - `slug` is the one
field a create or a rename actually supplies, and the two names for the same
value can drift (a handle renamed by the OTHER route - a generic identifier
rename - leaves the slug column behind). Every behavior below that looks
like string manipulation (deriving an identifier prefix, extracting an
address's last segment) exists to keep a caller on the correct side of that
distinction.

One reference implementation also owns a feature picker's data (the catalog
of addable ecosystem features, including "Coming soon" unbuilt ones, what an
ecosystem is provisioned with, what it may not add, adding a batch, and
removing a batch dependents first), the pure requirement rules over that
catalog, a feature manager that answers every surface's "what does this
ecosystem hold" question from one list, and the hub-data ecosystem
resolution that picks where a workspace's Notes, Research, Documents,
Integrations, Planning and Storage live; the other has no counterpart for
any of it in these sources.


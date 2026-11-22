
This module is the storage floor the sync stack and the app's other stores
sit on. It has two parts:

- The bounded database wraps an underlying multi-reader, single-writer
  database connection pool (or a single shared connection for a private
  in-memory database) with two guarantees so a runaway query can never
  wedge the process: a **bulkhead** (one writer plus N readers, using
  write-ahead logging, so reads never queue behind the writer) and
  **ejection** (every read/write carries a monotonic deadline; a low-level
  statement-abort mechanism aborts any statement that passes it, surfaced
  as a deadline-exceeded error). It keeps per-lane latency and eviction
  counters exposed as a metrics snapshot, and it is reentrant, so a code
  base can keep one read/write chokepoint instead of threading a raw
  connection handle everywhere.
- The storage-location helper derives where an app keeps its files — a
  dotfolder in the home directory — from the app's declared display name,
  reduced to characters a path can hold.

Consumers include the sync store (see
Offline Sync Client ([adhsdk.ingredient.data.sync.offline-sync-client](cookbook:d3a0b65f-92c0-43c1-b04c-77638eb72044))),
the markdown store (see Markdown Core ([adhsdk.ingredient.adh.hub.content.markdown-store](cookbook:11f7a665-60e9-42df-853c-fe4de3af0fd8))),
and the project database (see
Project Database ([adhsdk.ingredient.workspace.projects.project-database](cookbook:c212ea39-10e7-4146-89dd-36edb3b3455a))),
which names its file inside the storage-location helper's directory.

`summaryAIProviderSettings(for:)` resolves a `SummaryFeature`'s provider. Sessions reads the global selection. AI Conversations and Coding Projects read their own selection key: absent inherits the global one, an empty string means the command-line provider sentinel, and an id picks that configuration.

The daemon half of the module (`Database/Daemon`) also carries the Claude
account router, moved out of stenographerd so any daemon can host it:

- `AccountCredentialStore` keeps the Claude credentials a client relays to the
  daemon, as each credential's probe half. `KeychainAccountCredentialStore`
  holds the set as JSON in one Keychain generic-password item;
  `InMemoryAccountCredentialStore` is for tests and for a daemon that must not
  touch the Keychain.
- `AccountQuotaProbe` is the daemon's one custodian of those credentials and
  its live per-account quota cache: it judges a relayed set, keeps the probe
  halves, and measures each account's rate-limit headers on demand.
- `AccountRouterServer`, configured by `AccountRouterConfiguration`, is the
  local proxy that routes Claude Code's API traffic across the saved accounts
  and records each exchange; `RouterHistoryRetentionTask` trims that history.
- `AccountRouterRoutes` is the route set a daemon mounts for the router's read
  surface (`GET /router/status`, `GET /router/report`, `GET /router/exchanges`)
  and the credential relay (`POST /accounts/credentials`).

---
id: ea580796-8b16-4832-b11d-ad3cae991ecd
title: "Database"
type: ingredient
version: 1.5.0
status: review
language: en
created: 2026-09-24
modified: 2026-11-24
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Deadline-bounded SQLite connection pool (one writer, many readers, runaway-query ejection, lane metrics) plus the app's shared storage-directory naming."
platforms:
  - swift
  - macos
  - ios
tags:
  - database
  - sqlite
  - persistence
depends-on: []
related:
  - 355a8f54-aee5-45cd-a28d-12c3b7a3085c
  - d3a0b65f-92c0-43c1-b04c-77638eb72044
  - 11f7a665-60e9-42df-853c-fe4de3af0fd8
  - c212ea39-10e7-4146-89dd-36edb3b3455a
references:
  - packages/apple/AgenticDeveloperHubSDK/Database/BoundedDatabase.swift
  - packages/apple/AgenticDeveloperHubSDK/Database/AppStorageLocation.swift
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKDatabaseTests/BoundedDatabaseTests.swift
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKDatabaseTests/AppStorageLocationTests.swift
approved-by: ""
approved-date: ""
---

# Database

## Overview

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
## Behavioral Requirements

### Storage Location

- **fallback-token**: The fallback token MUST be the string `"AgenticDeveloperHubSDK"`.
- **token-filter**: The token-deriving operation MUST return the display name with every character that is not a letter, mark, or number removed, with no substitute character inserted.
- **token-order**: The token-deriving operation MUST keep the surviving characters in their original order and original case.
- **token-empty-fallback**: The token-deriving operation MUST return the fallback token when no character survives the filter, including for an empty input.
- **token-non-ascii**: The token-deriving operation MUST keep non-ASCII letters and digits (the filter matches any letter, mark, or number, not just ASCII ones), so `"Café"` stays `"Café"`.
- **display-name-source**: The display-name reader MUST read the app's declared display name from platform bundle metadata, resolved through the platform's own localization mechanism when the app localizes that value.
- **display-name-fallback**: The display-name reader MUST return the fallback token when the platform's declared display name is absent, is not a string, or is the empty string; absent and empty are the same answer.
- **display-name-unfiltered**: The display-name reader MUST return the name unfiltered ("spaces and all"); filtering happens only in the token-deriving operation.
- **running-token**: The default token MUST equal the token-deriving operation applied to the display name.
- **directory-shape**: The storage-directory operation MUST return the given home directory with one path component appended: `"."` followed by the token lowercased.
- **directory-case-fold**: The storage-directory operation MUST return the same location for two tokens that differ only in letter case.
- **directory-default-token**: The storage-directory operation MUST default its token argument to the default token.
- **directory-no-io**: The storage-directory operation MUST NOT touch the filesystem; it neither creates nor checks the directory.
- **shared-directory-distinct-files**: Each store MUST pick its own filename inside the shared directory and MUST NOT name that file after the token (naming it after its own contents instead); two stores MUST NOT share a file.

### Bounded Database: Construction

- **init-signature**: Constructing a bounded database MUST take a file path, a reader count (default `3`), a read deadline (default 10 seconds), a write deadline (default 60 seconds), a busy timeout in seconds (default `5`), and an optional prepare hook — a function that receives the raw connection and may raise (default none).
- **init-throws**: Construction MUST raise whatever the underlying database library raises while opening the database; it defines no error of its own for construction.
- **reader-count**: Construction MUST pass the reader count unchanged as the underlying database library's reader-count setting; this source does not validate it, and the behavior for values below 1 is owned by that library.
- **busy-mode**: Construction MUST configure every connection to wait up to the busy timeout, in seconds, on a locked database before failing.
- **temp-store-memory**: Every connection MUST apply a temp-store-in-memory setting at open, before the caller's prepare hook runs.
- **prepare-order**: The caller's prepare hook MUST run on every connection at open, after the temp-store setting and before the ejection mechanism is installed.
- **prepare-failure**: An error raised by the prepare hook MUST propagate out of the connection open (out of construction for the writer, out of the first read that opens a new reader).
- **ejection-installed**: Every connection MUST have the ejection mechanism installed at open without the caller asking for it.
- **file-backed-pool**: For any path other than exactly `":memory:"`, construction MUST open a write-ahead-logged, pooled connection at that path, giving one writer connection and up to the configured reader count of reader connections.
- **in-memory-queue**: For a path of exactly `":memory:"`, construction MUST open a single shared connection, so reads and writes share one connection; ejection and metrics MUST still apply.
- **writer-exposed**: The bounded database MUST expose the underlying writer connection object for direct access to the underlying database library; access through it bypasses deadlines and metrics.
- **no-directory-creation**: Construction MUST NOT create the parent directory of the path; a missing directory surfaces as the underlying database library's open error.

### Bounded Database: Operations

- **write-transaction**: The write operation MUST run its body on the writer connection inside a transaction and return its result; a failure from the body MUST roll the transaction back and propagate.
- **read-reader**: The read operation MUST run its body on a reader connection and return its result; a reader MUST see every write committed before it started.
- **read-concurrency**: Top-level reads on a file-backed database MUST NOT wait for the writer; up to the configured reader count of them MAY run in parallel.
- **write-serialised**: Top-level writes MUST be serialised on the single writer connection.
- **write-no-transaction**: The transaction-free write operation MUST run its body on the writer connection without opening a transaction, for bodies that issue their own begin/commit or run statements that cannot sit inside one (such as attaching another database file or reclaiming space).
- **open-transaction-rollback**: When a top-level transaction-free write's body returns or fails with a transaction still open, the database MUST roll that transaction back after the deadline is disarmed and before the connection is returned to the pool.
- **rollback-failure**: The safety-net rollback MUST be issued in a way that discards its own failure: if it fails, the error is lost, no signal reaches the caller or the metrics, and the writer connection returns to the pool still inside a transaction.
- **default-deadlines**: A top-level read with no explicit deadline MUST use the configured read deadline; a top-level write or transaction-free write with no explicit deadline MUST use the configured write deadline.
- **explicit-deadline**: An explicit deadline on a top-level call MUST replace the default for that call only.
- **synchronous-calls**: Every operation MUST be synchronous: it blocks the calling thread until its body finishes and returns the value or raises.

### Bounded Database: Ejection

- **deadline-clock**: The deadline MUST be measured on a monotonic clock, so a wall-clock step backward or a sleep/wake cannot stop ejection.
- **deadline-armed-on-connection**: The deadline MUST be armed after the connection is acquired and disarmed before any cleanup, so time spent waiting for the writer or a reader slot does not count against it and cleanup cannot itself be ejected.
- **non-positive-deadline**: A zero or negative deadline MUST eject at the first progress check instead of trapping.
- **progress-interval**: The ejection check MUST run every 1000 low-level execution steps on the statement's own thread and MUST abort the statement once the current monotonic time is at or past the armed deadline.
- **no-deadline-no-abort**: The ejection check MUST allow the statement to continue when no deadline is armed on the current thread, so statements run through direct writer access are never ejected.
- **eviction-error**: A top-level call whose statement is aborted by the deadline MUST raise the deadline-exceeded error, carrying a lane name of `"read"` for a read and `"write"` for a write or transaction-free write, and the elapsed milliseconds since the call began.
- **eviction-replaces-error**: The underlying low-level interruption error from an ejected statement MUST be replaced by the deadline-exceeded error; other errors from the body MUST propagate unchanged.
- **swallowed-eviction**: When the body catches the interruption itself and returns normally, the call MUST return that value and record a completion, not an eviction.
- **error-type**: The deadline-exceeded error MUST be a single, comparable value carrying a lane name (`"read"` or `"write"`) and elapsed milliseconds.

### Bounded Database: Reentrancy

- **reentrant-inline**: A read, write, or transaction-free write called on a thread already inside one MUST run its body inline on the enclosing operation's connection instead of re-entering the pool.
- **read-your-writes**: A read nested inside a write MUST see the enclosing write's uncommitted changes.
- **nested-no-transaction**: A nested write MUST NOT open its own transaction or savepoint; it runs inside whatever the enclosing operation has open.
- **nested-deadline-inherited**: A nested call MUST be bounded by the enclosing operation's armed deadline; its own deadline argument MUST be ignored.
- **nested-eviction-error**: An ejection inside a nested call MUST raise the deadline-exceeded error with the nested call's lane and an elapsed value of `0`; the enclosing top-level call then records one eviction on its own lane and re-raises that same error.
- **nested-not-metered**: A nested call MUST NOT change the in-flight, completed, or evicted counters; it is counted by its enclosing operation.
- **is-reentrant**: The reentrancy indicator MUST be true exactly when the calling thread is inside a read, write, or transaction-free write, so a consumer can translate errors only at the outermost boundary.
- **cross-instance-reentrancy**: The current-connection slot MUST be treated as a single per-thread value shared by every bounded database instance: a call on database B made inside an operation on database A runs B's body inline on A's connection, and B's reentrancy indicator reports `true`, even though its documentation says "on this database." Cross-instance nesting is unsupported.

### Bounded Database: Metrics

- **in-flight-accounting**: Each top-level call MUST increment its lane's in-flight counter before acquiring a connection and decrement it when the call ends, whether it returns or raises.
- **completion-record**: A top-level call that returns MUST increment its lane's completed counter and append its duration to the lane's window.
- **eviction-record**: A top-level call that raises the deadline-exceeded error MUST increment its lane's evicted counter and MUST NOT add its duration to the window.
- **other-errors-unrecorded**: A top-level call that raises any other error MUST NOT change the completed counter, the evicted counter, or the window.
- **duration-includes-wait**: The recorded duration MUST run from before connection acquisition to the end of the call, so it includes queueing for the writer or a reader slot.
- **percentile-window**: Each lane MUST compute its 50th- and 99th-percentile durations over at most the 128 most recent completed durations, choosing the sorted element at index `round((count - 1) * q)`, in milliseconds.
- **percentile-empty**: A lane with no completed durations MUST report both percentile values as `0`.
- **stats-shape**: The metrics snapshot MUST hold exactly two lane records in the order `"write"`, then `"read"`, each carrying a lane name, in-flight count, completed count, evicted count, and 50th-/99th-percentile durations.
- **stats-consistency**: The metrics snapshot MUST read both lanes under one lock acquisition, so the snapshot is internally consistent.
- **stats-sendable**: The metrics snapshot and its lane records MUST be plain, comparable data values, safe to pass across threads, with a straightforward public initializer.

### Bounded Database: Concurrency

- **sendable-class**: The bounded database MUST be safe to call concurrently from multiple threads and tasks, relying on the underlying database library's own thread safety for connections, a lock around the metrics, and per-thread state for the current operation's deadline and connection.
- **per-thread-state**: The armed deadline and the current connection MUST be stored per thread, so operations on different threads never observe each other's deadline or connection.

### Account Credential Store

- **credential-store-contract**: An `AccountCredentialStore` MUST offer `load()`, returning the set saved last or an empty list when none is, and `save(_:)`, replacing the saved set; both may throw.
- **credential-store-empty-save**: Saving an empty set MUST remove the saved set: the Keychain store deletes its item rather than writing an empty list.
- **keychain-store-item**: `KeychainAccountCredentialStore(service:)` MUST keep the whole set as JSON in one generic-password item named `claude-credentials` (`itemKey`) under the injected service, through AIPluginKit's `SecretStoring`.
- **keychain-store-write-failure**: A write the secret store refuses MUST throw `AccountCredentialStoreError.writeFailed`.
- **in-memory-store**: `InMemoryAccountCredentialStore` MUST keep the set in memory only, under a lock, and count every `save(_:)` in `saves`.

### Account Quota Probe

- **probe-one-per-daemon**: A daemon MUST build exactly one `AccountQuotaProbe` and hand it to both the database (as its quota source) and the account router (as its credential source), because a Claude refresh token is single-use and two evaluators spending one void each other's rotation.
- **probe-load-once**: The probe MUST load its store once, at init; a store that cannot be read MUST be logged and the probe MUST start with an empty set.
- **take-credentials**: `takeCredentials(_:refreshing:now:)` MUST evaluate the pushed set, keep only each probeable credential's probe half through `setCredentials(_:)`, record the secret-free token statuses, and return a `ClaudeCredentialEvaluationDTO` carrying `changed` and the logins it rotated.
- **take-credentials-serial**: Evaluations MUST run one at a time, so two relays can never both spend the same refresh token.
- **classify-only**: With `refreshing: false` the evaluation MUST NOT refresh any login; it only classifies the set.
- **set-credentials-change**: `setCredentials(_:)` MUST compare the new set to the held one by account, credential kind and token fingerprint, in any order; on a change it MUST replace the set, invalidate the quota cache and save the set to the store, and return `true`; otherwise it MUST do nothing and return `false`.
- **set-credentials-save-failure**: A store that throws on save MUST be logged; the in-memory set still changes.
- **held-token**: `heldToken(itemKey:)` MUST be the only read of a secret the probe allows, for the account router; it returns nil when nothing probeable is held under that key.
- **probe-on-demand**: Probes MUST run on a private utility queue and only when a consumer asks while the cache is past its TTL (`refreshIfStale`); the default TTL is 300 seconds (`defaultTTL`).

### Account Router Routes

- **router-routes-table**: `AccountRouterRoutes.table(router:probe:)` MUST return a route table that claims `GET /router/<sub>` (exactly two path components) and `POST /accounts/credentials`, and nothing else.
- **router-routes-endpoints**: `AccountRouterRoutes.endpoints` MUST list `GET /router/status`, `GET /router/report`, `GET /router/exchanges` and `POST /accounts/credentials`, for a daemon's endpoint index.
- **router-unavailable**: When the table was built with no router, every `GET /router/<sub>` MUST answer 503 with `{"status":"unavailable","error":"no account router on this daemon"}`.
- **router-status**: `GET /router/status` MUST answer 200 with the router's status in snake_case; the status names saved credentials by item key only.
- **router-report**: `GET /router/report` MUST answer the router's report for `since_hours` hours, defaulting to 24 (`defaultReportHours`); `0` means all time.
- **router-report-window**: `since_hours` MUST be ASCII digits only and MUST be clamped to `AccountRouterServer.maxReportHours` (a century), a run of digits too long for an integer included; anything else MUST answer 400 "since_hours must be a whole number of hours (0 for all time)".
- **router-exchanges**: `GET /router/exchanges` MUST pass `account` through unchanged and accept `after_id`, `before_id`, `limit` and `since_hours` as ASCII digits, a run too long for an integer reading as the largest integer; a malformed number MUST answer 400 naming the parameter.
- **router-exchanges-rule**: `rule` MUST be one of `AccountRouterRuleFilter`'s raw values; any other value MUST answer 400 listing the valid ones.
- **router-store-error**: A report or exchange query that throws MUST answer 500 with the error's description scrubbed by `AccountRouterLog.scrub`.
- **router-unknown-path**: Any other `GET /router/<sub>` MUST answer 404.
- **credential-relay**: `POST /accounts/credentials` MUST decode the body as a snake_case JSON array of `ClaudeCredentialDTO`, hand it to the probe classify-only (`takeCredentials(_:refreshing: false)`, which stores through `setCredentials(_:)`), and answer 200 with `{"changed": <Bool>}`.
- **credential-relay-no-echo**: The relay's reply MUST carry no token, and an undecodable body MUST answer 400 "the body must be a JSON array of credentials" without quoting the body or the decoding error.
- **credential-relay-router-free**: The relay MUST work whether or not the table has a router.

### Billing Routes

- **billing-routes-endpoints**: `BillingRoutes.endpoints` MUST list every billing route for a daemon's endpoint index: clients, projects and repos (list, save, delete), entries (list, save, audit, status, description, delete), segments (list, assign, promote, assign-repository), timers (list, start, stop), app names, backfill, the preferences push and the overview.
- **billing-routes-forward**: Every billing handler MUST forward to `BillingStore`, `BillingRollup`, `BillingTimer` or `BillingPrefs` and decide nothing itself, so each rule stays where a store test covers it.
- **billing-routes-writes-post**: Every billing write MUST be a `POST`, so a daemon's token gate on writes covers all of them.
- **billing-routes-bad-body**: A write whose body does not decode MUST answer 400 and change nothing.
- **billing-routes-since**: A billing `since` (`GET /billing/entries`, `POST /billing/backfill`) MUST be the whole of a real calendar day `YYYY-MM-DD` or an ISO-8601 timestamp, never a value that merely starts with a day; anything else answers 400. Backfill MUST also refuse an empty `since`, which would re-derive the whole history, and MUST pass a timestamp to the store as a whole-second UTC instant. Entries MUST read a timestamp as the earliest calendar day that instant falls on in any zone (UTC-12), never as its first ten characters: entries are filed by the local day of their own segment's zone, so that is the one day bound that leaves out no entry on or after the instant. The 400 MUST name both accepted forms.
- **billing-routes-failures**: A billing write that throws MUST answer 400 with the error's sentence only when a store refused it (`BillingStore.BillingError`, `BillingRollup.RollupError`, `BillingTimer.TimerError` or a wire error); a busy or locked database (SQLITE_BUSY or SQLITE_LOCKED, extended forms and a write deadline included) MUST answer 503 and any other failure 500, each with a fixed sentence, and the database's own text MUST reach only the log, never the reply.
- **billing-routes-preferences-values**: `POST /billing/preferences` MUST accept a JSON object whose values are strings, numbers or bools, storing each as the text `RawSetting` reads (`15`, `1.5`, `true`); a body that is not such an object (not JSON, an array, a `null`, an array or object value) MUST answer 400 and write nothing, and an empty body MUST write nothing and answer the snapshot in force.

### Activity Routes

- **activity-routes-table**: `ActivityRoutes.table(database:workTracking:appRegistry:)` MUST serve `GET /activity/status`, `POST /activity/preferences`, `POST /activity/recheck` and `GET /activity/spans`, and `POST /app/register` and `POST /app/unregister` only when given an app registry.
- **activity-not-running**: With no `WorkTrackingControl`, status, preferences and recheck MUST answer 503 "Work tracking is not running".
- **activity-status-quiet**: `GET /activity/status` MUST answer the tracker's last known state and MUST NOT ask the system for Accessibility.
- **activity-preferences**: `POST /activity/preferences` MUST decode a whole snake_case `WorkTrackingPreferences`, apply it and answer the status it produced; an undecodable body MUST answer 400 and change nothing.
- **activity-recheck**: `POST /activity/recheck` MUST ask for Accessibility again and answer the resulting status.
- **activity-spans**: `GET /activity/spans` MUST answer the spans since `since`, limited to 1...1000 (default 100); a malformed `since` MUST answer 400.

### Project Registry Follower

- **follower-subscribes-first**: `ProjectRegistryFollower.start(onFailure:)` MUST subscribe to the registry's `changes` before it reads the projects, so no change made between the read and the subscription is lost.
- **follower-syncs-then-applies**: The follower MUST `sync` the local `LocalProjectMirror` to the registry's projects, then `apply` each change as it arrives, so the local file's rows match the registry's.
- **follower-keeps-local-path**: Given `keepingLocal`, the follower MUST NOT mirror a project at that path, neither in the first sync nor in a later upsert.
- **follower-stop**: `stop()` MUST end the follow and leave the rows already mirrored in place; a failure to read or subscribe MUST reach `onFailure`.

### Pipeline Quarantine Heal

- **heal-after-clean-drain**: The `PipelineDrainer` worker MUST, after each drain that did not fail and completed at least one record, send back through the pipeline the quarantined records whose reason starts with one of `PipelineDrainer.transientFailurePrefixes` (a sink or the events.db write failed), without a restart and without a caller asking. An empty drain reached neither the store nor a sink, so it MUST NOT heal; a daemon left idle after an outage heals after the next record it completes.
- **heal-keeps-record-failures**: The heal MUST NOT requeue a record quarantined for itself (invalid JSON, an archive conflict, any reason without a transient prefix); it stays in quarantine.
- **record-store-failure-reason**: When the events.db write of a batch fails with an error that is not a store outage, the drainer MUST write each record on its own. A record refused while others in the batch were stored MUST be charged under `PipelineDrainer.recordStoreFailurePrefix` (`record not stored: `), which is not a transient prefix; when no record of the batch could be stored, every record MUST be charged under `storeFailurePrefix`, because the store, not the record, is at fault.
- **record-sink-failure-reason**: When a sink refuses a batch of more than one record with an error that is not a store outage, the drainer MUST write each record to that sink on its own. If the sink took some, each record it still refuses MUST be charged under `PipelineDrainer.recordSinkFailurePrefix` (`record refused by `), which is not a transient prefix, and the records it took MUST go on to the later sinks and be completed. If it took none, or the error is an outage, every record MUST be charged under `sinkFailurePrefix` and the pass fails.
- **heal-interval**: The heal MUST requeue at most once per `PipelineDrainer.quarantineHealInterval` (15 minutes, measured on the monotonic clock so a change to the wall clock neither stretches nor skips it), counted from the last heal that found anything in quarantine, so a record that keeps failing costs at most `ProviderSpool.maxAttempts` attempts per interval. A heal that finds the quarantine empty MUST NOT start the interval.
- **heal-drains-promptly**: A heal that requeued records MUST wake the worker so they drain without waiting for the idle poll.
- **heal-report**: The drainer MUST keep the last heal that requeued records or failed in `lastQuarantineHeal` (when, how many, the error); a failed heal MUST NOT stop draining.
## Appearance

Not applicable — this is a database access layer and storage-path helper, not a visual component.

## States

Not applicable — this is a database access layer and storage-path helper, not a visual component.

## Accessibility

Not applicable — this is a database access layer and storage-path helper, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| sed-001 | token-filter | the display name `"Coffee Grinder"` | `"CoffeeGrinder"` |
| sed-002 | token-order | the display name `"Percolator"` | `"Percolator"` |
| sed-003 | token-filter | the display name `"Coffee/Grinder 2.0"` | `"CoffeeGrinder20"` |
| sed-004 | token-empty-fallback, fallback-token | an input of only spaces, and separately an empty string | `"AgenticDeveloperHubSDK"` in both cases |
| sed-005 | token-non-ascii | the display name `"Café"` | `"Café"` |
| sed-006 | directory-shape | home directory `/tmp/home`, token `"CoffeeGrinder"` | path `/tmp/home/.coffeegrinder` |
| sed-007 | directory-case-fold | tokens `"COFFEEgrinder"` and `"CoffeeGrinder"` under `/tmp/home` | identical paths |
| sed-008 | directory-no-io | the storage-directory operation for a home with no such dotfolder | a location is returned; the directory still does not exist afterward |
| sed-009 | display-name-fallback | no declared display name available | display name and token both resolve to `"AgenticDeveloperHubSDK"` |
| sed-010 | write-transaction, read-reader, file-backed-pool | a file-backed database configured with 2 readers; a write creates a table and inserts the value `42`; then a top-level read selects it back | `42` |
| sed-011 | read-your-writes, reentrant-inline | inside one write: create a table, insert the value `7`, then a nested read selects it back | the nested read returns `7` before the write commits |
| sed-012 | eviction-error, progress-interval | a table of 1500 rows; a read with a 200ms deadline runs a triple self-join count | raises the deadline-exceeded error for lane `"read"` in under 3 seconds |
| sed-013 | in-memory-queue | an in-memory database (`":memory:"`); a write creates a table and inserts the value `5`; then a read | `5` |
| sed-014 | completion-record, in-flight-accounting, stats-shape | one write then one read, both returning normally | the write lane's and read lane's completed counts are both greater than `0`; the read lane's evicted count is `0`; both lanes' in-flight counts are `0` |
| sed-015 | open-transaction-rollback, swallowed-eviction | a transaction-free write that begins a transaction, creates a table, then runs a runaway select whose interruption is caught inside the body | the call does not raise; a following write creating another table succeeds |
| sed-016 | eviction-record, percentile-window | running sed-012, then reading the metrics snapshot | the read lane's evicted count is `1`; the read lane's completed count and 50th-percentile duration are unchanged by the ejected call |
| sed-017 | non-positive-deadline | a read with a deadline of zero, on a statement that needs more than 1000 low-level execution steps | raises the deadline-exceeded error for lane `"read"`; no crash |
| sed-018 | nested-deadline-inherited, nested-eviction-error | a write with a 200ms deadline whose body runs a nested read with a 60-second deadline on the runaway join | raises the deadline-exceeded error for lane `"read"` with an elapsed value of `0`, about 200ms in; the write lane's evicted count increments by `1`, the read lane is unchanged |
| sed-019 | default-deadlines | a bounded database configured with a 100ms read deadline; a read with no explicit deadline on the runaway join | raises the deadline-exceeded error for lane `"read"` |
| sed-020 | is-reentrant | reading the reentrancy indicator outside any operation, then inside a write's body | `false`, then `true` |
| sed-021 | other-errors-unrecorded | a read whose body raises a custom error | the custom error propagates; the read lane's completed and evicted counts are unchanged; its in-flight count is `0` |
| sed-022 | percentile-empty | a freshly opened database, reading the metrics snapshot | both lanes report a completed count of `0` and both percentile durations of `0`; lane order is `["write", "read"]` |
| sed-023 | write-transaction | a write whose body inserts a row then raises | the error propagates; a later read does not see the row |
| sed-024 | router-unavailable | `GET /router/status`, `/router/report` and `/router/exchanges` on a table with no router | 503 each, `status` is `"unavailable"` (`AccountRouterRoutesTests.testNoRouterIs503NotAnEmptyAnswer`) |
| sed-025 | router-report | `GET /router/report` with no query | 200, `since_hours` is `24` (`testReportDefaultsToTwentyFourHours`) |
| sed-026 | router-report-window | `since_hours` of `abc`, `-1`, `1.5`, `+5`, `%20` | 400 each (`testAMalformedWindowIs400`) |
| sed-027 | router-report-window | `since_hours` of `99999999999999999999` and `Int.max` | 200, `since_hours` is `maxReportHours` (`testAHugeWindowIsClampedToACentury`) |
| sed-028 | router-exchanges | three exchanges; `?before_id=3&limit=1` | ids `[2]` (`testExchangesFilterByEveryParameter`) |
| sed-029 | router-exchanges-rule | `?rule=bogus` | 400 whose message names every `AccountRouterRuleFilter` value (`testAnUnknownRuleIs400ListingTheValidOnes`) |
| sed-030 | router-status | a saved account `oauth:a@x.com` whose token is `sk-ant-...` | 200, `saved_credentials` is `["oauth:a@x.com"]`, the body never contains `sk-ant` (`testStatusIsSnakeCaseAndNamesNoSecret`) |
| sed-031 | credential-relay, credential-relay-no-echo | one long-lived credential posted to an empty in-memory store | 200, `changed` is `true`, the store holds the token and saved once, the reply does not contain it (`testRelayStoresTheSetAndEchoesNoToken`) |
| sed-032 | set-credentials-change | the same body posted twice | the second reply has `changed: false`; `saves` stays `1` (`testRelayingTheSameSetAgainChangesNothing`) |
| sed-033 | credential-relay-no-echo | a truncated array carrying a token, an empty body, a JSON object | 400 each, no token or account in the reply, nothing saved (`testAnUndecodableBodyIs400AndEchoesNothing`) |
| sed-034 | follower-syncs-then-applies | a registry holding one project, then an insert, an update and a delete | the local file holds the first project after `start`, then each change (`testStartMirrorsTheProjectsAlreadyRegistered`, `testARegistryChangeReachesTheLocalFile`) |
| sed-035 | follower-keeps-local-path | a registry project at the kept path | the local file never holds it (`testTheKeptPathIsNeverMirrored`) |
| sed-036 | follower-stop | `stop()`, then an insert in the registry | the earlier rows stay; the insert never arrives (`testStopLeavesTheMirroredRowsAndFollowsNoFurther`) |
| sed-037 | heal-after-clean-drain, heal-keeps-record-failures | two records quarantined by a failed sink and one by invalid JSON, then the sink recovers and a heal runs | the two sink records are requeued and stored; the invalid one stays quarantined (`testHealRequeuesTransientQuarantineAndLeavesRecordFailures`) |
| sed-038 | heal-interval | a heal that requeued, then a second heal 1 minute later and a third after `quarantineHealInterval` | the second requeues nothing; the third requeues (`testHealRunsAtMostOncePerInterval`) |
| sed-039 | heal-interval | a heal over an empty quarantine, then a sink-failure quarantine and a heal 1 second later | the second heal requeues (`testAnEmptyHealDoesNotStartTheInterval`) |
| sed-040 | heal-after-clean-drain, heal-drains-promptly | a started worker whose sink fails until two records are quarantined, then recovers; empty drains for 0.3 seconds; then a new record | nothing is requeued while the drains are empty; after the new record the quarantine empties and all three are stored with no manual retry (`testTheWorkerHealsAQuarantineOnItsOwn`) |
| sed-041 | record-store-failure-reason, heal-keeps-record-failures | `k0`, `poison` (a record events.db refuses) and `k1`, drained `maxAttempts` times, then a heal | `poison` is quarantined under `record not stored: `; the heal requeues nothing (`testHealLeavesARecordTheStoreRefusedOnItsOwn`) |
| sed-042 | record-store-failure-reason | three records, the events table hidden, drained `maxAttempts` times; then the table restored and a heal | every record is quarantined under `store write failed: `; the heal requeues all three and they are stored (`testABatchTheStoreRefusesWholeIsChargedAsAStoreFailureAndHealed`) |
| sed-043 | record-sink-failure-reason, heal-keeps-record-failures | `k0`, `bad` and `k1` through a sink that refuses any batch holding `bad`, then a second sink; drained `maxAttempts` times, then a heal | the first pass completes `k0` and `k1`, and only they reach the second sink; `bad` is quarantined under `record refused by `; the heal requeues nothing (`testASinkThatRefusesOneRecordTakesTheRestAndTheHealLeavesIt`) |
## Edge Cases

- **Empty display name**: The token-deriving operation applied to an empty string, or to a name made only of spaces or punctuation, MUST return `"AgenticDeveloperHubSDK"`; a missing or empty declared display name MUST make the display-name reader return `"AgenticDeveloperHubSDK"`.
- **Path separators in the name**: Path-separator characters, periods, and spaces MUST be dropped by the token-deriving operation, so the result can never escape the home directory or add a nested path component.
- **Localized bundle name**: When an app localizes its declared display name, the display-name reader and the token-deriving operation MUST follow the active localization, so the storage directory can differ between locales (see Design Decisions).
- **Non-ASCII names**: Letters, combining marks, and digits outside ASCII MUST survive the token-deriving operation; the directory then carries non-ASCII characters, lowercased by a locale-independent lowercasing operation.
- **Missing parent directory**: Constructing a bounded database on a path whose directory does not exist MUST raise the underlying database library's open error; neither component creates the directory.
- **Near-miss in-memory paths**: Only the exact string `":memory:"` MUST select the single-shared-connection mode; any other spelling (such as a file URI) MUST go to the pooled, file-backed mode.
- **Reader count below 1**: The reader count is passed to the underlying database library unvalidated; that library owns the outcome.
- **Zero or negative deadline**: MUST eject at the first progress check rather than trap.
- **Statement that never reaches a progress check**: Ejection MUST only happen at a 1000-step boundary, so time blocked outside actual statement execution (for example waiting on a lock, bounded instead by the busy timeout) is not interrupted by the deadline.
- **Locked database**: A write MUST wait up to the busy timeout for the lock, then fail with the underlying database library's busy error, which propagates unchanged and is not counted in the metrics.
- **Body swallows the ejection**: The call MUST return the body's value and count as a completion; for a transaction-free write, any transaction left open MUST be rolled back before the connection is reused (sed-015).
- **Failed safety-net rollback**: See `rollback-failure`: the failure is discarded and the connection returns to the pool inside the transaction.
- **Write nested inside a read**: A write called inside a top-level read MUST run inline on the reader connection; this source adds no check, so the write statement fails with whatever error the underlying database library raises for a read-only connection, and that error propagates.
- **Nested op on a different instance**: See `cross-instance-reentrancy`: the body runs inline on the enclosing instance's connection.
- **Nested ejection details**: The raised error MUST carry the nested call's lane and an elapsed value of `0`, even though the enclosing operation's lane records the eviction.
- **Concurrent callers**: Top-level reads on different threads MAY run in parallel up to the configured reader count; top-level writes MUST queue on the single writer; the metrics snapshot MAY be read from any thread.
- **Cancellation**: There is no cancellation interface; an external cancellation signal does not interrupt a running call, and the deadline is the only way a statement is stopped.
- **Offline or network loss**: Not applicable; the component performs only local file I/O.
- **Direct writer access**: Statements run through direct writer access MUST NOT be ejected or metered, because no deadline is armed on that thread.
- **Relayed empty set**: A relay of `[]` MUST count as a change when credentials were held and MUST clear the store (the Keychain item is deleted).
- **Repeated relay**: Relaying the same set again MUST answer `changed: false` and MUST NOT save.
- **Malformed relay body**: An empty body, a truncated array, or a JSON object instead of an array MUST answer 400 and save nothing.
- **Unreadable credential store**: A probe whose store throws on load MUST start empty and log the failure; the client's next relay fills it.
- **No router configured**: The credential relay still works; only `/router/*` answers 503.
- **Oversized report window**: `since_hours=99999999999999999999` MUST clamp to `maxReportHours` rather than fail.
- **Empty exchange parameter**: `limit=` (empty) MUST answer 400 naming `limit`.
## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `path` | string | required | Database file path, or `":memory:"` for a private in-memory database using a single shared connection. |
| `readers` | integer | `3` | Size of the read connection pool. |
| `readDeadline` | duration | 10 seconds | Default ejection ceiling for a top-level read. |
| `writeDeadline` | duration | 60 seconds | Default ejection ceiling for a top-level write or transaction-free write. |
| `busyTimeout` | duration (seconds) | `5` | Seconds to wait on a locked database before failing. |
| `prepare` | optional hook function | none | Runs on every connection at open, after the temp-store setting and before the ejection mechanism is installed; for app-specific setup. |
| `deadline` (per call) | optional duration | none (use the lane default) | Overrides the deadline for one top-level call; ignored on nested calls. |
| Declared display name (platform bundle metadata) | string | `"AgenticDeveloperHubSDK"` when absent or empty | Source of the display name and token. |
| `home` (storage-directory operation) | location | required | Directory under which the dotfolder is placed. |
| `token` (storage-directory operation) | string | the default token | Name folded to lowercase for the dotfolder. |
| Progress-check interval | constant | 1000 execution steps | Not configurable. |
| Percentile window | constant | 128 durations per lane | Not configurable. |
| `service` (`KeychainAccountCredentialStore`) | string | required | Keychain service the credential item lives under; a daemon passes `<its label>.accounts`. |
| `label` (`AccountQuotaProbe`, `AccountRouterConfiguration`) | string | required | The daemon's label; names the probe queue and the router's log subsystem and queues. |
| `credentials` (`AccountQuotaProbe`) | `AccountCredentialStore` | required | Where the held credential set is saved. |
| `userAgent` (`AccountQuotaProbe`) | string | `ClaudeTokenRefresher.userAgent` | The `User-Agent` every probe sends. |
| `dataDirectory`, `fingerprintsPath`, `upstream`, `templateDirectory`, `providerSecret` (`AccountRouterConfiguration`) | various | `upstream` is `https://api.anthropic.com`; templates go in the data directory's template subdirectory; provider keys come from the shared Keychain namespace | Where the router keeps its files, where it sends requests and how it reads provider keys. |
| `router` (`AccountRouterRoutes.table`) | optional `AccountRouterServer` | required | The daemon's router; nil makes `/router/*` answer 503. |
| `probe` (`AccountRouterRoutes.table`) | `AccountQuotaProbe` | required | The probe that takes custody of relayed credentials. |
| `since_hours` default | constant | `24` (`AccountRouterRoutes.defaultReportHours`) | The report window when the query omits it. |
| `workTracking` (`ActivityRoutes.table`) | optional `ActivityRoutes.WorkTrackingControl` | required | The daemon's work tracker (status, apply, recheck); nil makes those three routes answer 503. |
| `appRegistry` (`ActivityRoutes.table`) | optional `SessionAppRegistry` | required | The single-instance registry; nil leaves `/app/*` unserved. |
## Deep Linking

Not applicable: neither component handles URLs or routes; the only location value is the filesystem location the storage-directory operation returns.

## Localization

The storage-location helper contains no user-facing string of its own; the fallback token (`"AgenticDeveloperHubSDK"`) is a hardcoded, unlocalized identifier, and the display-name reader returns the platform's own resolution of the declared display name, which is the localized value when the app localizes that value. Consumers interpolate the display name into sentences the user reads.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| Declared display name (platform bundle metadata) | the app's declared name, or `AgenticDeveloperHubSDK` when absent | Returned by the display-name reader; also the input to the token-deriving operation and therefore to the storage directory name. |

## Accessibility Options

Not applicable: this module has no visual surface, so Reduce Motion, Increase Contrast and Differentiate Without Color have nothing to act on.

## Feature Flags

Not applicable: neither component reads a flag; every behavior is fixed or set through construction parameters.

## Analytics

Not applicable: neither component emits events; the metrics snapshot is an in-process snapshot the caller reads, and nothing leaves the process.

## Privacy

- **Data collected**: The storage floor collects nothing; it stores whatever rows its caller writes. The account router's credential store holds the Claude account tokens a client relays (probe halves only, never a refresh token) and the router records each routed exchange's metadata.
- **Storage**: A plain, unencrypted SQLite database file (plus its companion write-ahead-log and shared-memory files) at the caller's configured path, typically inside a per-app dotfolder in the home directory; an in-memory database is never written to disk.
- **Transmission**: The storage floor performs no network I/O. The quota probe sends one `max_tokens=1` request per held account to the Anthropic API, and the router relays Claude Code's requests upstream; no route reply carries a token.
- **Retention**: Data persists until the caller deletes it or the file; the module deletes nothing.
- **Credential storage**: `KeychainAccountCredentialStore` keeps the relayed set in the Keychain, one item under the daemon's service; `InMemoryAccountCredentialStore` keeps nothing past the process.
## Logging

The bounded database and the storage-location helper do not log; ejections surface as raised deadline-exceeded errors and as the evicted counters in the metrics snapshot. The quota probe logs through the unified logging system: a store it cannot read or write, the count of credentials a client relayed, and a one-time warning when no credentials are held. It never logs a token. The router's errors are scrubbed by `AccountRouterLog.scrub` before they reach a log or a route reply.
## Platform Notes

- **SwiftUI**: Source platform (`Database/BoundedDatabase.swift`, `Database/AppStorageLocation.swift`, module `AgenticDeveloperHubSDKDatabase`). It imports `Foundation`, `SQLite3` (for `sqlite3_progress_handler`) and GRDB; the per-op deadline and current connection live in `Thread.current.threadDictionary`, which works because GRDB runs each sync op on one thread; the handler is a capture-free `@convention(c)` closure; `DispatchTime` supplies the monotonic clock and `NSLock` guards the metrics. A SwiftUI app owns one instance per database file and should call it off the main actor, since every call blocks.
- **Compose**: Start from Android's `SQLiteDatabase` with `enableWriteAheadLogging()` or Room with `JournalMode.WRITE_AHEAD_LOGGING`, which already gives one writer plus a reader pool. Android exposes no progress handler, so ejection maps to `CancellationSignal` passed to `rawQuery`/`query` and cancelled from a `withTimeout` coroutine; the thread-local reentrancy slot becomes a `ThreadLocal<SupportSQLiteDatabase?>` or, in coroutines, a `CoroutineContext` element (Room's `withTransaction` already does this). Metrics use `AtomicInteger` or a `Mutex`. The storage folder is `Context.filesDir` rather than a home dotfolder, so `AppStorageLocation` reduces to the token filter.
- **React/Web**: The closest equivalent is IndexedDB or SQLite-WASM (`@sqlite.org/sqlite-wasm` with OPFS) in a Web Worker; SQLite-WASM exposes `sqlite3_progress_handler`, so ejection ports directly, with `performance.now()` as the monotonic clock. Single-threaded JS has no thread-locals, so reentrancy needs an explicit "current connection" passed down or an `AsyncLocalStorage`-style context in Node (`better-sqlite3` offers a synchronous API and `db.function`-level hooks but no progress handler). The home dotfolder applies only to Node (`os.homedir()`).
- **AppKit / UIKit**: The same Swift sources apply unchanged. On iOS the home directory is the app sandbox container, so a caller passes `FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)` as `home` if a hidden dotfolder at the container root is not wanted; `Bundle.main` supplies `CFBundleName` in both.
- **WinUI 3**: Use `Microsoft.Data.Sqlite` with `PRAGMA journal_mode=WAL`, one `SqliteConnection` guarded by a `SemaphoreSlim(1, 1)` for writes and a small pool of read-only connections (`Mode=ReadOnly` in the connection string) for reads. `Microsoft.Data.Sqlite` does not expose `sqlite3_progress_handler`; eject instead with `SqliteCommand.Cancel()` fired from a `CancellationTokenSource.CancelAfter(deadline)` registration, or call the raw handler through `SQLitePCL.raw.sqlite3_progress_handler`. Measure with `Stopwatch` (monotonic). Reentrancy maps to an `AsyncLocal<SqliteConnection?>`, which flows across `await` unlike the source's thread-local, so nested calls stay correct in `async` code. Translate `SqliteException` with `SqliteErrorCode == 9` (`SQLITE_INTERRUPT`) into a `DeadlineExceededException(lane, elapsedMs)`. Busy waiting is `DefaultTimeout` / `PRAGMA busy_timeout`. Expose `stats` as an immutable record, or as an `INotifyPropertyChanged` view model marshalled through `DispatcherQueue.TryEnqueue` if a UI shows it. The storage folder is `Windows.Storage.ApplicationData.Current.LocalFolder` for packaged apps or `Environment.GetFolderPath(Environment.SpecialFolder.UserProfile)` plus the dotfolder for unpackaged ones, with the name from `Package.Current.DisplayName`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Database/` | confirmed (1.5.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Database/Daemon/Projects/ProjectRegistryFollower.swift` | confirmed (1.5.0) |

## Design Decisions

### Deadline on the monotonic clock

**Decision**: The deadline is an uptime-nanosecond reading from `DispatchTime`, not wall-clock time.

**Rationale**: The `installEjectionHandler` comment: an NTP step or sleep/wake that moves the wall clock backward must not stop ejection, which "would re-enable the wedge this exists to prevent".

**Approved**: pending

### One armed deadline per thread

**Decision**: Nested calls run inline and inherit the enclosing op's deadline; their own `deadline:` is ignored and they are not metered separately.

**Rationale**: Re-entering GRDB's serial writer from inside a write would deadlock, and inline execution keeps a single `read`/`write` chokepoint without threading `Database` everywhere; the handler reads one thread-local deadline.

**Approved**: pending

### Rollback safety net for self-managed transactions

**Decision**: After a top-level `writeWithoutTransaction`, any transaction still open is rolled back with the deadline already disarmed.

**Rationale**: Interrupting a SELECT while a write is pending leaves the transaction open; if the body swallows the error, the pooled writer would come back mid-transaction and every later write would fail "cannot start a transaction within a transaction" (the scenario in `testSwallowedEjectionInWriteWithoutTransactionDoesNotPoisonPool`).

**Approved**: pending

### Serial queue for in-memory databases

**Decision**: `":memory:"` opens a `DatabaseQueue` rather than a `DatabasePool`.

**Rationale**: A pool needs a real WAL file, and in-memory databases are private per connection, so a reader connection would see an empty database.

**Approved**: pending

### Temp store in memory

**Decision**: Every connection runs `PRAGMA temp_store=MEMORY`.

**Rationale**: Recursive CTEs and ORDER BY spills then never need a temp file that a read-only connection could fail to create.

**Approved**: pending

### Drop, do not substitute, in the token

**Decision**: `token(for:)` removes non-alphanumerics instead of replacing them with `-` or `_`.

**Rationale**: A separator "would only move the problem" — `.coffee-grinder` versus `.coffee_grinder` is a guess every later lookup must repeat correctly.

**Approved**: pending

### Case-folded directory, content-named files

**Decision**: The dotfolder is the lowercased token, and stores name their files for their contents (`Markdown.db`, `Projects.db`), never for the app.

**Rationale**: Capitalization of a display name is cosmetic; renaming "Coffee grinder" to "Coffee Grinder" must not strand the store, and there is then no second spelling of the app name that could fold differently. The same reasoning does not cover a localized `CFBundleName`, which changes the token itself.

**Approved**: pending

### Absent and empty bundle name are the same

**Decision**: `displayName` treats a missing and an empty `CFBundleName` identically, returning `fallbackToken`.

**Rationale**: An empty name gives a user-facing sentence with a hole and a path component that silently collapses onto its parent; resolving it once avoids every call site having to remember.

**Approved**: pending

**Decision**: A failed safety-net rollback is discarded: it raises nothing, logs nothing and is not counted in the metrics.
**Rationale**: The rollback is issued so that its own error is dropped, which leaves a connection still inside a transaction in the pool with no signal. Closing it needs a choice between raising, logging, or counting the failure as an eviction, and a test that forces a failing rollback.
**Approved**: pending

**Decision**: Nesting a call on a different bounded database instance inside an operation is unsupported: it runs inline on the enclosing instance's connection and reports as reentrant.
**Rationale**: The current-connection slot is one per-thread value shared by all instances, so the second instance never gets its own connection. Closing it would take rejecting cross-instance nesting, routing the call to the second instance's own pool, or documenting it as unsupported at the API.
**Approved**: pending

**Decision**: The credential relay route evaluates classify-only (`takeCredentials(_:refreshing: false)`) and answers only `changed`.
**Rationale**: An HTTP reply that carries no token has nowhere to put a rotated login, so spending a refresh token in this route would kill the login it was asked about. Going through `takeCredentials` rather than calling `setCredentials` directly keeps the probe-half stripping and the serial evaluation gate, so no refresh token is ever stored.
**Approved**: pending

**Decision**: The relay route does no caller check of its own.
**Rationale**: Who may post credentials is the hosting daemon's front-door decision (its client token), not the route set's; the route trusts what reaches it, as the other shared route sets do.
**Approved**: pending

### The drainer heals its own transient quarantine

**Decision**: After every drain that did not fail and completed records, the worker requeues the quarantined records whose reason is a destination outage, at most once per 15 minutes; the requeue at daemon start stays.

**Rationale**: A destination stall of a few minutes (a read lane held past its 30-second deadline) spends every record's attempts and parks the batch, and the start-time requeue alone left it parked for days on a daemon that never restarted. A drain that completed records is the evidence the destination is back. An empty drain touched no destination, and healing on one would spend the records' attempts against a destination still down and then hold them for the whole interval. The cost is that a daemon left idle after an outage heals only when the next record arrives. A record the store or a sink refuses on its own while the rest of its batch goes through is charged under `record not stored: ` or `record refused by `, outside the transient prefixes, so the heal never retries it and it no longer holds its batch back. The interval bounds any other record that fails for itself under a transient prefix to `maxAttempts` cheap attempts per interval instead of a loop, and still lets a fresh outage heal on the next clean drain, because an empty heal does not start the interval.

**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.reliability.timeout-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f4d73297-4002-5b4d-91c2-74a20866ab61) | passed | Reliability |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | passed | Reliability |
| [adc.check.reliability.error-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/694a971d-282d-501b-8861-c4ece3b01edd) | passed | Reliability |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | Reliability |
| [adc.check.reliability.health-observability](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d4ece88d-eeff-5e3f-8823-d8c2929a35e0) | passed | Reliability |

The module keeps storage mechanics (pool, deadlines, metrics) and storage naming apart from every schema that uses it, and `BoundedDatabaseTests` and `AppStorageLocationTests` cover the cross-lane read, read-your-writes, ejection, in-memory, stats and poisoned-pool paths plus every token and directory rule. Every read and write carries a monotonic deadline and locked writes a busy timeout, and the reader pool keeps reads from queuing behind the writer. `stats` exposes in-flight, completed, evicted and p50/p99 per lane, so a wedge is visible. Explicit error handling is partial because the safety-net `ROLLBACK` discards its own failure, and errors other than an eviction go uncounted in `stats`. Data integrity is partial because the per-thread connection slot is shared across instances, so a call on one database nested inside an op on another runs against the wrong connection.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.5.0 | 2026-11-24 | Mike Fullerton | Pipeline quarantine heal: the drainer requeues transient quarantine after a clean drain, at most once per 15 minutes |
| 1.4.0 | 2026-11-23 | Mike Fullerton | Project registry follower (keeps a local Projects.db in step with adhd's registry) moved in from the Kitchen. |
| 1.3.1 | 2026-11-23 | Mike Fullerton | billing-routes-since: GET /billing/entries reads a timestamp `since` as the earliest calendar day that instant falls on in any zone (UTC-12), not its text prefix, and its 400 names both accepted forms (review f8). |
| 1.3.0 | 2026-11-21 | Mike Fullerton | Account credential store, quota probe, account router and its routes (credential relay) moved into Database/Daemon. Billing routes (every stenographerd billing call) and activity routes with a work tracker's controls added for adhd. |
| 1.2.2 | 2026-11-19 | Mike Fullerton | Name the CLI sentinel without the host's name |
| 1.2.1 | 2026-11-18 | Mike Fullerton | Per-feature summary provider resolution (`summaryAIProviderSettings(for:)`). |
| 1.2.0 | 2026-10-04 | Mike Fullerton | Restate rollback-failure and cross-instance-reentrancy as current behavior with pending decisions. |
| 1.1.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to data/storage/. |
| 1.0.1 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.0.0 | 2026-09-24 | Mike Fullerton | Initial creation from `BoundedDatabase.swift`, `AppStorageLocation.swift` and their tests |

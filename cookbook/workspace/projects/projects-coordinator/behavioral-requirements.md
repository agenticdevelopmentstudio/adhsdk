
- **did-change-notification-shape**: The coordinator's change notification
  MUST be a named notification (`"ProjectsCoordinatorDidChange"`) and
  MUST carry no payload — readers MUST re-read the repository list
  directly, which the doc comment calls "the one representation of that
  knowledge."
- **two-stores**: The coordinator MUST hold two stores: a project
  registry, which says which projects exist, and the app's own
  window-state database, which holds layout, panes and standalone-window
  rows keyed by the registry's ids. When the registry is not the
  window-state database itself, the coordinator MUST keep a local mirror
  of every registry project in the window-state database under the same
  id, applied before any window can be opened for it; when they are the
  same database, it MUST keep no mirror. A convenience construction from
  one database MUST use that database as both stores.
- **repos-initial-load**: Construction MUST populate the repository list
  by reading all repositories from the window-state database exactly once,
  swallowing any thrown error, so a failed read leaves the repository list
  at its default empty state rather than propagating out of construction;
  construction MUST then begin following the registry's change stream.
- **command-registry-required**: Construction MUST register an "Open
  Project…" command and a "Scan for Projects" command, both in the
  "Projects" category, on the caller-supplied command registry, and the
  command-registry parameter carries no default value — the doc comment
  states this is deliberate so a missing registry fails at build time
  rather than silently dropping every menu item this feature
  contributes.
- **menu-contributions-two-file-items**: Construction MUST set the menu
  contributions to exactly two entries, both in the File-menu slot: "Open
  Project…" ordered first, bound to the primary modifier plus Option and
  the plain key `"p"`, dispatching through the open-project command; and
  "Scan for Projects" ordered after it, dispatching through the
  scan-for-projects command, hidden whenever a scan is already running.
- **set-opener-replaces-unconditionally**: Setting the window-opening
  delegate MUST replace the current one with the argument regardless of
  whether one was already set.
- **start-loads-registry-then-scans**: Starting the feature MUST, off
  the caller's turn, first load the registry's whole list and only then
  trigger a scan with progress shown by default, so the scan is planned
  against what the registry holds; starting is declared able to fail by
  the interface it overrides, but its own body never actually fails.
- **load-from-registry**: Loading from the registry MUST read every
  project from it; on success it MUST sync the mirror (when there is one)
  to that list, logging a sync failure at error level and continuing,
  MUST make that list the repository list, and MUST reload. A registry
  read that fails MUST be logged at error level and MUST leave the
  repository list as it was.
- **follow-registry-changes**: Every change the registry reports — this
  app's own writes coming back, another app's, a scan's — MUST be applied
  locally: to the mirror when there is one (a mirror failure logged at
  error level naming the project's id) and to the repository list, where
  an upsert replaces the entry with that id or appends it and the list is
  re-sorted by lowercased name, and a deletion removes the entry with that
  id. Applying the same change twice MUST leave the same result. Each
  applied change MUST schedule a reload, and reloads scheduled before the
  pending one runs MUST coalesce into that one, so a burst of changes
  posts one notification.
- **stop-checkpoints-database**: Stopping the feature MUST stop
  following the registry's change stream and MUST checkpoint the
  window-state database.
- **terminate-casts-opener-for-language-services**: Terminating the
  feature MUST attempt to recognize the window-opening delegate as a
  project window manager; when it is one, terminating MUST await
  shutting down all language services on it; when it is not — the
  delegate is unset or a different project-opening implementation —
  terminating MUST return immediately having done nothing further. The
  doc comment states the type check is deliberate: widening the
  project-opening interface itself to carry a language-server concern
  "would push an LSP concern into the protocol the registry is tested
  against."
- **repo-lookup-by-id**: Looking up a repository by id MUST return the
  first entry in the repository list whose id equals the argument, or
  nothing when none matches.
- **rename-trims-and-guards-no-op**: Renaming a repository MUST return
  with no effect when looking it up by id finds nothing; MUST trim the
  new name of leading and trailing whitespace and newlines; and MUST
  return with no effect — no registry write, no reload — when the
  trimmed name is empty or equal to the repository's current name.
- **rename-persists-then-reloads-or-logs**: When the trimmed name is
  non-empty and differs from the current name, renaming a repository MUST
  apply the renamed row locally and reload at once, then write it to the
  registry off the caller's turn; on failure it MUST log the error at
  error level naming the repository's id at public log-visibility, MUST
  re-read that row from the registry (falling back to the row as it was
  before the rename when the re-read fails or finds nothing), apply it
  locally, and reload again.
- **open-project-opens-then-marks**: Opening a project MUST start
  recording the open time and MUST hand the repository to the
  window-opening delegate in the same turn, so the window shows before the
  stamp lands. Recording the open time MUST, off the caller's turn, mark
  the project opened in the registry at the current time and apply the
  registry's row for it locally, catching and logging any thrown error
  without propagating it, and MUST then reload unconditionally.
- **show-project-chooser-delegates-to-open**: Showing the project chooser
  MUST present it against the coordinator, with a callback that opens
  whatever repository the chooser passes back.
- **reload-refreshes-then-notifies-unconditionally**: Reloading MUST
  recompute the listed repositories from the current repository list,
  re-point the repository-state watcher, and MUST then post the change
  notification unconditionally; it reads no store.
- **scan-guards-reentrancy**: Scanning MUST return immediately,
  performing no work, when a scan is already running; otherwise it MUST
  mark a scan as running before doing anything else. The inline comment
  states the policy is deliberate: "two scans of the same disk produce
  the same answer, so the second is waste."
- **scan-progress-window-conditional**: When progress is to be shown (the
  default), scanning MUST construct and present a scan-progress window
  and hold onto it; when not, it MUST leave the progress window
  untouched.
- **scan-uses-injected-or-fresh-scanner**: Scanning MUST use an injected
  scanner when one was supplied; otherwise it MUST construct a fresh
  scanner seeded with the current value of the scan-skip-patterns
  setting, read at the moment the scan runs, not cached from
  construction time, so an edited skip list takes effect on the next
  scan.
- **scan-runs-detached-then-hops-main**: Scanning MUST run the chosen
  scanner's walk off the UI's main execution context, and MUST hand the
  result back to the scan-finishing step on that context.
- **finish-scan-builds-plan-from-current-repos**: Finishing a scan MUST
  compute a reconciliation plan from the current repository list and
  what the scan found, and MUST seed the running summary as a copy of
  that plan's own summary.
- **finish-scan-inserts-decrement-on-failure**: For each repository the
  plan calls for inserting, finishing a scan MUST insert it through the
  registry — under the id, name, first-seen and last-opened times of the
  window-state database's project row at the same path when there is a
  mirror and such a row has another id, so the local layout survives a
  registry that has not been given this app's projects yet — and apply it
  locally; on failure it MUST decrement the summary's added count by
  one and log the error naming the repository's path at public
  log-visibility, then MUST continue to the next insertion rather than
  aborting the loop.
- **finish-scan-closes-windows-before-deleting**: Finishing a scan MUST
  close the project window for every repository the plan calls for
  deleting, in a pass that completes entirely before the delete pass
  begins. The inline comment states the reason: closing a window writes
  to the row it belongs to, "which after the delete is a foreign key
  that no longer resolves."
- **finish-scan-deletes-decrement-and-clear-frames**: For each repository
  the plan calls for deleting, finishing a scan MUST delete it through the
  registry and apply the deletion locally; on failure it MUST decrement the summary's removed count,
  log the error naming the repository's path at public log-visibility,
  and skip ahead — bypassing the frame cleanup below — rather than abort
  the loop; on success it MUST clear both the saved state and the
  visibility of that repository's window frame.
- **finish-scan-final-state-order**: After all three loops, finishing a
  scan MUST record the running summary as the last-scan summary, MUST
  mark the scan as no longer running, and MUST reload, in that order,
  before logging completion and dismissing the progress window.
- **finish-scan-logs-completion-and-dismisses-progress**: Finishing a
  scan MUST log the summary's own summary text at info level and public
  visibility, and MUST finish and release the progress window,
  regardless of whether any of the three loops above logged an error of
  its own.
- **loggable-conformance**: The coordinator MUST expose a single shared
  logger for its own log messages, independent of any instance,
  following the same logging convention used across this codebase.
- **database-read-failure-unsignaled**: construction's initial load discards any thrown window-state read error with no logging call, falling back to an empty list; a caller cannot distinguish "no project is known locally" from "the read failed" until the registry load replaces the list, unlike every other store failure path in this file, which logs at error level (see Design Decisions).
- **stop-checkpoint-failure-unsignaled**: stopping's checkpoint call discards a checkpoint failure with no logging call, the only write-adjacent store call in this file that neither logs nor otherwise surfaces its outcome (see Design Decisions).
- **scan-task-not-tracked**: The background scan-and-reconcile
  continuation started by scanning is not stored, awaited, or
  cancellable: stopping and terminating can both run while it is in
  flight, and neither waits for or cancels it. Contrast terminating,
  whose doc comment describes the language-server shutdown race and
  which the host's termination sweep awaits. Each write inside
  scan-finishing is caught independently, so a scan cut off mid-loop
  does not corrupt either store; it leaves the is-scanning flag set and
  the last-scan summary unset for that run.
- **finish-scan-updates-no-decrement-on-failure**: For each repository
  the plan calls for updating, finishing a scan writes it through the
  registry, applies it locally, and on failure logs the error naming the repository's path at
  public log-visibility, as the insert and delete loops do, but unlike
  those loops it does not decrement any summary count. A failed update
  therefore leaves the summary's moved/unchanged count (whichever the
  reconciliation plan attributed the row to) overstated, despite the
  scan-finishing step's own comment that "the summary and what the user
  was told disagree" is the bug its per-row error handling fixes; the
  failure is visible only in the log.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.


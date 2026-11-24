
- **Null and empty input, Recents.** With nothing recorded, or signed out, the Recents flyout MUST be absent (recents-hidden). With a stored entry missing `url`, `label` or `ts`, that entry MUST be dropped and the rest kept (recents-validate).
- **Null and empty input, workspaces.** An empty, loading or failed workspaces list MUST give no Workspaces flyout (workspaces-no-placeholder). The reason is in the source: a placeholder row was once a menuitem the arrow keys landed on and Enter chose, closing the menu and going nowhere.
- **Null and empty input, topic.** A topic whose links all fail to resolve and that has no destination MUST be omitted (topic-flyout).
- **Boundary values, Recents cap.** At 10 places, recording an eleventh MUST evict the oldest; re-recording an existing url MUST NOT change the length (recents-record, recents-dedupe).
- **Boundary values, viewport.** At exactly 768px the host navigation rows MUST show, because the query is `max-width: 768px` (nav-links-collapsed).
- **Unresolved host.** Before the client hostname is known, a cross-site row resolves to `#` and choosing it MUST do nothing (navigate-no-target).
- **Admin flag still resolving.** `undefined` MUST behave as false, so the Admin block appears when the answer arrives (tree-admin-append).
- **Stale recents key.** A recorded icon key this build does not know MUST fall back to the hub icon so one row is not left blank (recents-row).
- **Not signed in, stale storage.** Recents left in storage by an earlier session MUST stay hidden while signed out; the menu hides them and does not clear them (recents-hidden).
- **Concurrent access.** Another tab's write MUST reach this tab through the `storage` event (recents-cross-tab). Two writers racing in one tab are serialized by the single-threaded module state and are last-write-wins in `localStorage`.
- **Error state, storage.** A quota or private-mode failure MUST be swallowed and the menu MUST still render (recents-storage-failure).
- **Error state, popover support.** A browser with no popover support MUST make the Help command and the "?" button do nothing visible, without an error (overview-guard).
- **Error state, guard declined.** A navigation the guard declines MUST leave the page where it is (navigate-guard).
- **Offline or disconnected.** Not applicable: the menu holds no network call. Hrefs are built from the registry and the page's hostname, and the Recents store is local, so a lost connection changes nothing until a chosen row navigates.
- **Dead destination.** A recent whose entity was deleted still navigates to its url; the destination renders its own not-found state, because the store is not authoritative and nothing prunes it.
- **Duplicate destinations.** Hub and Learn both list Help and both resolve to `hub-help`; this is deliberate, not a defect (fleet-help-single-destination).


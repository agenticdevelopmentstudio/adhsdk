
- **SwiftUI**: An `@Observable` store per client, holding the rows as an
  array and loading them with `async`/`await` on `URLSession`, stands in for
  the react-query entry. A `NotificationCenter` observer on the
  workspaces-changed name replaces the window event; keep one observer per
  store with a reader count, and tag the notifications this process posted
  (an `object` sender or a `userInfo` token) so they are skipped. The
  preference reads `UserDefaults` for the seed and writes it before the
  network call.
- **Compose**: A `ViewModel` exposing `StateFlow<List<WorkspaceRow>>`,
  loaded in `viewModelScope`, replaces the hook. A `SharedFlow` replaces the
  event; collect it once per repository, not per screen. DataStore holds the
  preference seed. The row helpers are top-level Kotlin functions
  (`distinctBy { it.slug }` is the first-per-slug helper).
- **React/Web**: The source. `use-workspaces.ts` (`useWorkspaces`, a
  `useQuery` on `getToolkitQueryClient()` under `WORKSPACE_ROWS_QUERY_KEY`
  with `retry: false`, and a module-scope `WeakMap<QueryClient, { readers,
  unsubscribe }>` that counts readers and subscribes through
  `onWorkspacesChangedElsewhere`); `workspace-rows.ts`
  (`workspaceCompositeId`, `workspaceListLabel`, `firstWorkspacePerSlug`);
  `use-workspace-preference.ts` (`useWorkspacePreference`,
  `WORKSPACE_PREFS_CACHE_KEY`, `WORKSPACE_PREFS_ID`, `loadWorkspacePrefs`,
  built on `useResourceItemQuery` and `useResourceItemWriter`, with a
  `useReducer` counter to re-render after a choice). Both hook modules are
  `"use client"`; `workspace-rows.ts` is not, so a server module can import
  it.
- **AppKit / UIKit**: The same store as SwiftUI, observed with Combine
  (`@Published` rows) or KVO by the menu's controller; an `NSMenu` or
  `UIMenu` is rebuilt from the rows. `NotificationCenter` carries the change
  event.
- **WinUI 3**: A singleton service holding an
  `ObservableCollection<WorkspaceRow>` that a `MenuFlyout` or
  `NavigationView` binds to, filled by `HttpClient.GetFromJsonAsync` with
  `System.Text.Json` (map snake_case with
  `JsonNamingPolicy.SnakeCaseLower`), on the UI thread through
  `DispatcherQueue`. The change event is a C# `event` on that service,
  subscribed once (a reference count of attached views, or
  `WeakEventManager`); tag events this process raised so its own direct
  refresh is not doubled. The preference seed lives in
  `ApplicationData.Current.LocalSettings`, written before the
  `HttpClient.PostAsJsonAsync` call, whose failure is caught and dropped.
  The row helpers are static methods; `DistinctBy(r => r.Slug)` is the
  first-per-slug helper.



- **SwiftUI**: An `@Observable` feed object injected with `.environment`
  replaces the context; the menu view reads it and is `nil`-safe for a scene
  that does not opt in. The registrar is a closure property the workspace
  route's view sets in `.onAppear` and clears in `.onDisappear`; keep it out
  of observation (`@ObservationIgnored`) so a registration re-renders
  nothing.
- **Compose**: A `CompositionLocal` (`staticCompositionLocalOf<WorkspacesMenu?>
  { null }`) carries the contract. The route registers its switch in a
  `DisposableEffect`, writing a plain holder rather than `State`, so the
  menu is not recomposed.
- **React/Web**: The source. `workspaces-menu.tsx` holds the contract
  (`MenuWorkspace`, `WorkspacesMenu`, `WorkspacesMenuProvider`,
  `useWorkspacesMenu`) inside the header barrel. `workspaces-feed.tsx` is a
  `"use client"` module with its own tsup entry and package export
  (`./header/workspaces-feed`), importing the context by package path so it
  fills the one `SiteMenuSwitcher` reads: `SiteWorkspacesMenuProvider`,
  `WorkspaceSelectRegistrar` (a context defaulting to a no-op, exported for
  tests) and `useRegisterWorkspaceSelect`, a `useLayoutEffect` that writes a
  `useRef`. It reads sign-in with `useTokenSubject`, the URL with Next's
  `usePathname`, navigates with `useRouter().push`, and builds hub URLs with
  `siteUrl` / `siteProdUrl` and `useClientHost`.
- **AppKit / UIKit**: The window controller (or scene delegate) owns the
  feed and rebuilds the `NSMenu` or `UIMenu` from its rows; the active
  workspace view controller sets a weak switch closure on it when it appears
  and clears it when it disappears.
- **WinUI 3**: A view-model implementing `INotifyPropertyChanged`, exposed as
  an app-level resource, holds the rows a `MenuFlyout` binds to. The
  workspace page sets a plain `Action<string>` field (not a bound property)
  in `OnNavigatedTo` and clears it in `OnNavigatedFrom`, so a registration
  raises no change notification. Preference-mode hrefs open with
  `Launcher.LaunchUriAsync`.


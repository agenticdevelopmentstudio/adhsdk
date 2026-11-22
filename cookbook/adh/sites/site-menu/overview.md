
`SiteMenu` is the family launcher: the command-style popover disclosed from the
header's hub brand. It turns a declarative tree of `MenuGroup` entries into rows
(icon, label, optional description), adds the chrome that depends on who is looking
(Login and Sign up, Home, a Workspaces flyout, Help, a Recents flyout, the host
site's own navigation on a phone), and navigates when a row is chosen. It is built
by composing `NavigationPopover`, which supplies the popover surface, the search
box, keyboard navigation and flyout submenus.

Three config-only components sit on one shared base:

- `SiteMenu` holds all the logic. It takes `groups` plus the header-chrome props
  and owns link resolution, the trigger, navigation, the top section, Recents,
  the search command and the trailing control.
- `MarketingSiteMenu` supplies the short public tree. It is what every site shows
  on its marketing pages, signed in or out.
- `WorkspaceSiteMenu` supplies the whole family tree. It is shown on the hub's
  workspace routes whenever `WorkspaceMenu` does not take over (signed out, or no
  workspaces context).
- `SiteMenuSwitcher` is a dispatcher with no content of its own. It picks one of
  the two menus by route, or swaps in the `WorkspaceMenu` (a different component,
  covered elsewhere) for a signed-in hub user inside a workspace.

Two further modules belong to the menu. `menu-icons` is the single source of every
row's icon. `recents` is the per-device store behind the Recents flyout; the
recorder that writes to it lives in the hub app, not in this package.


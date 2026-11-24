
| Name | Ingredient | Role | Required | Configuration |
|------|------------|------|----------|---------------|
| SiteWordmark | [adhsdk.ingredient.adh.sites.site-wordmark](cookbook:21cbbc1c-38a0-4e7a-8ca0-06e2f29429f5) | The header brand that the menu trigger sits beside | Yes | Unchanged |
| NavigationPopover | `@adh-sdk/adh/header` | Popover surface, search box, keyboard navigation, row rendering, flyout submenus, the command row | Yes | Consumes `PopoverEntry[]`, `openShortcut`, `searchCommand`, `commandTrailing`, `footer` |
| menu-icons map | `header/menu-icons.ts` | Single source of every row's icon, keyed by site id, route path, chrome key or `iconKey` | Yes | `MENU_ICONS` record and `menuIcon(key)` resolver |
| Recents store | `@adh-sdk/adh/header/recents` | Persists and publishes the last 10 visited places | Yes (signed in) | Import by this subpath only, never `./recents` and never the barrel |
| Workspaces context | `useWorkspacesMenu` from `@adh-sdk/adh/header` | Supplies the Workspaces flyout and gates the workspace swap | No | Absent on every host but the hub |
| Hub preferences | `@adh-sdk/adh/header/hub-preferences` | Supplies `siteMenuShortcut`, the chord that opens the menu | Yes | Empty string means no shortcut |
| Menu chrome helpers | `header/menuChrome.tsx` | The Help row and the settings gear, shared with `WorkspaceMenu` | Yes | `helpEntry`, `settingsTrailing` |
| Fleet trees | `header/fleetMenuGroups.ts` | `FLEET_MENU_GROUPS`, `SITE_MENU_GROUPS`, `ADMIN_MENU_GROUPS` and the section numbers | Yes | Module constants with stable identity |
| lucide-react icons | (library) | The icon glyphs | Yes | Reused wherever the platform already maps a glyph |


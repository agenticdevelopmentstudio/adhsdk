
| State | Source | Consumer | Direction | Mechanism |
|-------|--------|----------|-----------|-----------|
| Authenticated | Auth-aware header | Top section, Recents, gear, dispatcher | one-way | prop `authenticated` |
| Admin flag | Session, resolved asynchronously | Admin block | one-way | prop `userIsAdmin` |
| Current site | Header | `current` marking, in-hub rerouting, Help current flag | one-way | prop `currentSiteId` |
| Pathname | Router | Dispatch, `current` marking, Home and Recents `current` | read | `usePathname` |
| Workspaces list | Hub provider | Workspaces flyout, workspace swap | read | context `useWorkspacesMenu` |
| Recents list | Recents store | Recents flyout | read, write | module store with subscribe; the hub's recorder writes, the menu reads |
| Menu shortcut | Hub preferences | Open chord | read | `useHubPreferences` |
| Viewport collapse | Media query `(max-width: 768px)` | Host navigation rows | read | `useHeaderLinksCollapsed` |
| SSO resolver | Auth-aware header | Cross-site hrefs | one-way | prop `resolveHref` |
| Theme preview | Local, testing and staging only | Cross-site hrefs | read | appended to the href |


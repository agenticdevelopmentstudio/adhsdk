
**Decision**: One shared base, two config-only menus, one dispatcher.
**Rationale**: `SiteMenu` holds all the logic, `MarketingSiteMenu` and `WorkspaceSiteMenu` hold only a tree, and `SiteMenuSwitcher` picks between them by route. The source keeps the two menus as separate components even though they once rendered the same tree, so they can diverge without churn.
**Approved**: pending

**Decision**: The marketing menu is identical on every site and has no branch on `currentSiteId`.
**Rationale**: The source records that the owner ruled a per-site variant wrong (2026-10-25) after satellites had kept the whole fleet tree, and says in a comment not to add the branch back. The menu is shared code, so a visitor meets one menu across the family.
**Approved**: pending

**Decision**: The marketing menu drops the settings gear, the "?" button, Home, Workspaces, the chrome Help row and the Admin block.
**Rationale**: The owner removed each in turn (2026-10-23 and 2026-10-24) so the menu is the sites and the Help and Contact block only. User Settings stays in the avatar menu, and the workspace menu keeps its gear. The overrides are applied after the caller's props so a host cannot bring them back.
**Approved**: pending

**Decision**: Help and Contact form a block of their own in a later section, below the sites.
**Rationale**: They are where to go for help with the family, not members of it. The help section shares the Admin section's number, which is safe only because the marketing menu never shows the Admin block.
**Approved**: pending

**Decision**: Recents heads the family section rather than sitting with the top chrome.
**Rationale**: It is the same kind of thing as the rows under it, somewhere in the family to go. A different section number would rule a divider between Recents and the first site.
**Approved**: pending

**Decision**: No placeholder row in the Workspaces flyout; a not-ready list is simply no flyout.
**Rationale**: A flyout's rows are menuitems. The earlier "Loading" row was one the arrow keys landed on and Enter chose, closing the menu and going nowhere. On a workspace route the signed-in hub reports loading, failed and empty states as text in the `WorkspaceMenu` instead.
**Approved**: pending

**Decision**: Icons live in one `menu-icons` map, with the hub-segment fold derived and a hand-written key always winning.
**Rationale**: One map is the only place an icon is chosen. The fold joins two facts that already exist, which site a hub segment mounts and what that site's row looks like, so the join cannot go stale as the fleet grows and Recents does not show a blank slot. Three segments (`/tokens`, `/messaging`, `/teams`) keep a hub glyph that is deliberately not their site's.
**Approved**: pending

**Decision**: An `href` row carries no environment mapping, no SSO wrap and no current marking.
**Rationale**: The absolute row names a destination that has no registry entry (today the Agentic Development Studio in the Hire flyout, and the Fleet Monitor in the Admin flyout, which is a backend service). The registry cannot hold the Studio, because the registry test holds every id to a real site folder and a registry entry would add its origin to the OAuth return allowlist. When a site ships, replacing the row with a `site` row brings all three.
**Approved**: pending

**Decision**: The Recents store is a per-device `localStorage` list with no backend, and the recorder is outside this package.
**Rationale**: Recents are ephemeral and per-device, so there is no table or migration. The settle-debounced recorder that decides which places count belongs to the hub app, so this package pins only the store and the menu that reads it; a requirement to record only settled places is the recorder's, not the menu's.
**Approved**: pending

**Decision**: The store is imported by its package subpath, never the barrel and never a relative path.
**Rationale**: It holds module-level mutable state. Any other route risks a second copy in the bundle, and a visit recorded by the hub's recorder would then be invisible to the menu. Both tsup configs list the subpath `external` for this reason.
**Approved**: pending

**Decision**: The admin consoles are a separate export and a separate section, shown only when `userIsAdmin` is exactly true.
**Rationale**: The public tree stays readable as exactly what everyone sees. The flag resolves with the session, so undefined must equal false. The source warns that showing a link is not granting access; each console authorizes for itself.
**Approved**: pending

**Decision**: The comment on `SITE_MENU_GROUPS` says "seven sites" while `MarketingSiteMenu` says "the six sites"; the recipe requires six family rows plus the Help row.
**Rationale**: The seven counts Help (`hub-help`), which the tree holds as a row in its own Help and Contact block rather than in the family section. The code is the authority, so this recipe requires six family site rows (Bitbag, Hub, Dev Team, Cookbook, SDK, Persona Registry) and the Help row in the later section. The two comments count differently; behavior is unaffected.
**Approved**: pending

**Decision**: SHOULD-level latitude is not used; the localization and target-size gaps are left as open questions rather than invented requirements.
**Rationale**: The source holds no string catalog and no minimum target size for the trailing controls, so writing either as a requirement would describe behavior that does not exist.
**Approved**: pending


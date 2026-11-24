
Dispatch (`SiteMenuSwitcher`):

- **dispatch-workspace-route**: The switcher MUST render `WorkspaceSiteMenu` when the current site is the hub and the pathname is a hub workspace path (`/home`, `/<workspace>`, `/<workspace>/<feature>`), and the user is not swapped to the workspace menu.
- **dispatch-marketing-route**: The switcher MUST render `MarketingSiteMenu` on the landing `/`, on every other hub page, and on every satellite site, at every auth state. A signed-out visitor on a hub workspace path gets `WorkspaceSiteMenu`, because the route test does not look at auth.
- **dispatch-workspace-swap**: The switcher MUST render `WorkspaceMenu` in place of both site menus when the user is authenticated, the route is a workspace route, and a workspaces context is present.
- **dispatch-no-provider**: The switcher MUST keep a site menu at every auth state on a host that supplies no workspaces context.
- **dispatch-swap-no-admin**: The switcher MUST NOT pass `userIsAdmin` to `WorkspaceMenu`.
- **dispatch-swap-no-trigger-content**: The switcher MUST NOT pass `triggerContent` to `WorkspaceMenu`.
- **dispatch-swap-passthrough**: The switcher MUST pass `currentSiteId`, `resolveHref`, `personalSlug`, `hubOffersFeature`, `onSettings`, `settingsHref`, `navLinks` and `triggerClassName` through to `WorkspaceMenu`.
- **dispatch-prefetch**: The switcher MUST render `PrefetchSiblingSites` beside whichever site menu it shows, and MUST NOT render it with `WorkspaceMenu`.

Configs:

- **marketing-tree**: `MarketingSiteMenu` MUST supply `SITE_MENU_GROUPS`: six site rows in the family section (Bitbag, Hub, Dev Team, Cookbook, SDK, Persona Registry, in that order), then a Help row (the `hub-help` site) and a Contact row (the hub route `/contact`) in the help section, which is one section number above the family section.
- **marketing-overrides**: `MarketingSiteMenu` MUST apply `onSettings` undefined, `settingsHref` undefined, `userIsAdmin` false, `omitChromeRows` and `omitHelpButton` after the caller's props, so a caller cannot restore them.
- **marketing-no-site-branch**: `MarketingSiteMenu` MUST NOT vary its tree by `currentSiteId`; every site renders the same menu.
- **marketing-no-admin**: `MarketingSiteMenu` MUST NOT show the Admin block, for an admin or anyone else.
- **marketing-signed-out-top**: `MarketingSiteMenu` MUST still open on Login and Sign up when signed out.
- **workspace-tree**: `WorkspaceSiteMenu` MUST supply `FLEET_MENU_GROUPS` and pass every caller prop through unchanged.
- **fleet-tree-shape**: `FLEET_MENU_GROUPS` MUST hold ten top-level rows in the family section, in this order: Bitbag, Messages, Hub, Organizations, Learn, Plan, Build, Personas, Products, Hire.
- **fleet-grouping-headers**: The Plan and Build rows MUST be grouping headers with no destination of their own, each naming an `iconKey`.
- **fleet-help-single-destination**: The Hub flyout's Help row and the Learn flyout's Help row MUST both resolve to the `hub-help` site.
- **shared-base**: Both site menus MUST render through the one `SiteMenu` base, differing only in the `groups` they supply and the overrides above.

Trigger and open behavior:

- **trigger-brand-label**: The trigger text MUST be the hub site's header title, falling back to the literal "Agentic Developer Hub" when the registry has no hub site, and MUST NOT reflect the current site or workspace.
- **trigger-accessible-name**: The trigger's accessible name MUST be the brand label, a space, an em dash, a space, then "switch site".
- **trigger-mark**: The trigger MUST show the hub brand mark before the label, drawn in the current text color.
- **trigger-override**: The menu MUST replace the trigger's default content with `triggerContent` when one is given, and MUST add `triggerClassName` to the trigger button.
- **open-shortcut**: The menu MUST register the chord from the hub preference `siteMenuShortcut` under the label "Site menu", and MUST register no chord, with no fallback, when that preference is an empty string.
- **search-placeholder**: The search box MUST read "Search sites, or browse topics" and the empty result MUST read "No matching sites".
- **footer-wordmark**: The menu MUST close with the studio wordmark below its own divider, not as a row.

Rows and links:

- **entry-order**: The menu MUST list, in order: the host's navigation rows (phone only), the top section, the Help row (unless `omitChromeRows`), the Recents flyout, then the tree rows.
- **tree-admin-append**: The menu MUST append `ADMIN_MENU_GROUPS` below the tree when `userIsAdmin` is exactly true, and MUST treat undefined and false identically.
- **admin-is-not-access**: The Admin block MUST decide only who is shown the links; each console MUST do its own authorization.
- **admin-block-shape**: `ADMIN_MENU_GROUPS` MUST be one Admin flyout in the section one above the family section (the same section number as the marketing help block), listing the registry's admin-only sites and then a Fleet Monitor row pointing at `https://lewis.agenticdeveloperhub.com`.
- **row-icon-label-description**: Every row MUST render, in order, an icon slot, a label and, when present, a description.
- **site-row-defaults**: A `site` row MUST take its label and description from the registry unless the link overrides them.
- **site-row-unknown**: A `site` row whose id the registry does not know MUST be omitted without an error.
- **site-row-href**: A `site` row's href MUST be the in-page path when it is the current site (`/`, or the carried workspace path when one applies), the in-hub workspace route when the hub offers that feature (per `hubOffersFeature`) to a signed-in user in a workspace, and the target's environment-aware cross-site URL otherwise.
- **site-row-sso**: A cross-site href in the current environment MUST pass through `resolveHref` when one is supplied, and MUST be used plain when none is.
- **site-row-path**: A `site` row with `path` MUST name one page of that site, resolved environment-aware and wrapped like any site row, and MUST NOT be carried into a workspace or rerouted in-hub.
- **route-row-href**: A `route` row on the hub MUST resolve to `/<workspace>/<route>` when the route's first segment is a hub workspace segment and a workspace or personal slug is known, and to the bare route otherwise; on any other site it MUST resolve to the hub's cross-site URL.
- **href-row-literal**: An `href` row MUST use its absolute URL as written, with no environment host mapping, no `resolveHref` wrap and no `current` marking.
- **current-marking**: The row for the current location MUST be marked current; a site row is current when it is the current site (and no in-hub feature is active), or when its in-hub route is the pathname or a parent of it.
- **topic-flyout**: A `topic` entry MUST open a flyout of its resolvable links and MUST be omitted when it has neither a resolvable link nor a destination of its own.
- **topic-destination**: A `topic` with `link` MUST be a destination as well as a disclosure: choosing it navigates, while hover and the right arrow still open the flyout.
- **topic-icon**: A topic's icon MUST be its `iconKey`'s, else the one its `link` resolves to.
- **inline-row**: An `inline` entry MUST render as an always-visible link row indented under the row above it, not as a flyout.
- **section-dividers**: A divider MUST fall between sections and never within one.
- **blurb-flag**: A `leaf` entry MUST show its description as a tagline only when `blurb` is true.
- **icon-single-source**: A row's icon MUST resolve through `menuIcon(key)` and MUST NOT be hard-coded at a render site.
- **icon-missing**: A key with no mapped icon MUST leave the icon slot empty.
- **icon-segment-fold**: Every hub workspace segment that is a site's implementation MUST take that site's icon unless a hand-written key for the route already exists.
- **icon-jobs**: The hub knob `jobs` MUST have a hand-written key, `'/jobs'`, beside `'/sets'`, mapped to lucide's `Workflow` glyph, so its rows show the Jobs glyph rather than the hub icon that [recents-row](#requirements/recents-row) falls back to.
- **navigate-same-origin**: Choosing a row whose href begins with a single `/` MUST navigate in-app through the router.
- **navigate-cross-site**: Choosing any other row MUST navigate with a full-page load.
- **navigate-no-target**: Choosing a row with no href, or with the placeholder href `#`, MUST do nothing.
- **navigate-guard**: Navigation MUST wait on the shared navigation guard and MUST NOT happen when the guard declines.

Top section and chrome:

- **top-signed-out**: When unauthenticated, the top section MUST hold a Login row and a Sign up row, each only when its href was supplied, in section 0 above the tree.
- **top-signed-out-no-chrome**: When unauthenticated, the menu MUST NOT show Home, Workspaces or Recents.
- **top-signed-in-home**: When authenticated and `omitChromeRows` is not set, the top section MUST open with a Home row to the signed-in home route, marked current when that route is a same-origin path equal to the pathname.
- **omit-chrome-rows**: With `omitChromeRows` set, a signed-in menu MUST drop the Home row, the Workspaces flyout and the Help row, and MUST keep Login and Sign up when signed out.
- **workspaces-flyout**: When authenticated, chrome rows are not omitted and the workspaces context holds at least one workspace, the menu MUST show an indented Workspaces flyout listing each workspace with its label, href and current flag.
- **workspaces-no-placeholder**: While workspaces are loading, failed or empty, the menu MUST show no Workspaces flyout and no placeholder row.
- **help-row**: Unless `omitChromeRows` is set, the menu MUST show a Help row in section 0 for every auth state, linking to the help site's root for the current environment, marked current when the current site is `hub-help`.
- **recents-flyout**: When authenticated and at least one place is recorded, the menu MUST show a Recents flyout described "Where you just were", headed in the family section so no divider falls between it and the first site, listing the places newest first.
- **recents-hidden**: The menu MUST NOT show Recents when signed out or when no place is recorded.
- **recents-row**: A Recents row MUST carry its recorded label, description and url, MUST be marked current when its url equals the pathname, and MUST fall back to the hub icon when its icon key maps to nothing.
- **nav-links-collapsed**: At a viewport of 768px or narrower, the menu MUST list the host's own `navLinks` as rows, and above 768px it MUST omit them entirely rather than hide them.
- **nav-links-home-dedupe**: The host's navigation rows MUST exclude the Home destination only when signed in, so a signed-out phone visitor keeps that link.

Search command and trailing control:

- **help-command**: Typing "help" in any letter case MUST surface a command row labelled "Help", an em dash with spaces around it, then "about the sites", with the shortcut hint "overview".
- **help-command-action**: Selecting that command MUST close the menu and then open the shared family-overview popover.
- **overview-guard**: Opening the overview MUST do nothing when the popover element is missing or already open, and MUST swallow an error from an unsupported popover.
- **overview-escape**: An overview opened this way MUST close on the Escape key, and MUST remove its key and toggle listeners once it is closed.
- **trailing-gear**: When authenticated, the command row MUST show the settings gear when `onSettings` or `settingsHref` is supplied, with `onSettings` winning over `settingsHref`.
- **trailing-gear-signed-out**: When unauthenticated, the command row MUST NOT show the settings gear.
- **trailing-help-button**: When no gear is shown and `omitHelpButton` is not set, the command row MUST show a "?" button named "About the Agentic Developer family" that closes the menu without restoring focus and opens the overview.
- **trailing-none**: With `omitHelpButton` set and no gear, the command row MUST have no trailing control.
- **help-button-target-size**: NEEDS REVIEW: Not implemented in source. The "?" button and the gear carry the class `adh-site-switcher__help`, which `adh-site.css` sizes only by a 1rem icon plus 0.15rem of padding on each side (about 21px at a 16px root), with no minimum width or height. Whether that meets the target size the platform design language requires is a decision the source cannot make; a design ruling against the WCAG 2.1 target guidance would settle it.

Localization:

- **localized-labels**: NEEDS REVIEW: Not implemented in source. Every menu string in these files is a literal: Login, Sign up, Home, Workspaces, Recents, Help, the placeholder, the empty label, the command label, the button name and the hub fallback title. No resource lookup or locale is named. A decision on whether the header is localized, with the string catalog it would use, would settle it.

Recents store:

- **recents-record**: `recordRecent` MUST put the place first with a numeric timestamp and MUST leave the list holding at most 10 places, evicting the oldest. It returns nothing; callers read the list through `readRecents` or `useRecents`.
- **recents-dedupe**: Recording a url already present MUST move that place to the front with its new fields and MUST NOT duplicate it.
- **recents-clear**: `clearRecents` MUST empty the list and the persisted copy.
- **recents-persist-key**: The store MUST persist its list as JSON under the key `adh:recents` in `localStorage`.
- **recents-validate**: Reading storage MUST return the empty list for server rendering, a missing value, unparseable JSON or a non-array, and MUST keep only entries whose `url` and `label` are strings and whose `ts` is a number.
- **recents-storage-failure**: A storage read or write failure MUST be swallowed, the in-memory list MUST still reflect the change, and the menu MUST still render.
- **recents-stable-snapshot**: The store MUST return the same list reference until a real change, so a subscribed component does not re-render in a loop.
- **recents-cross-tab**: A `storage` event for the Recents key, or with no key, MUST reload the list and notify subscribers, and an event for another key MUST be ignored.
- **recents-ssr-empty**: `useRecents` MUST yield the empty list during server render and the first client paint, then follow writes.
- **recents-single-copy**: The store MUST be imported by its package subpath so one copy of its module state serves both the recorder and the menu.


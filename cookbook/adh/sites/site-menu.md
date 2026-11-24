---
id: f2d56415-ac36-4a27-bee5-b447c4186513
title: "SiteMenu"
type: recipe
version: 1.3.0
status: review
language: en
created: 2026-07-05
modified: 2026-11-23
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The header's site-switcher menu: a config-driven family tree with an auth-aware top section, a Recents flyout, and a route-based marketing or workspace choice."
platforms:
  - typescript
  - web
tags:
  - chrome
  - navigation
  - site-menu
  - recents
  - ui
ingredients:
  - 21cbbc1c-38a0-4e7a-8ca0-06e2f29429f5
depends-on: []
related:
  - 21cbbc1c-38a0-4e7a-8ca0-06e2f29429f5
  - 4d0e04ff-39eb-472c-93a0-8070f1b64a6a
  - 8fa7aaae-df62-44ea-b10c-182f3094ed9f
references:
  - agenticdeveloperhub://docs/deep-linking-foundation
approved-by: ""
approved-date: ""
---

# SiteMenu

## Overview

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

## Ingredients

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

## Integration Requirements

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

## Layout

```
SIGNED OUT, ANY SITE OFF THE HUB'S   SIGNED IN, /home AND WORKSPACE ROUTES (hub)
WORKSPACE ROUTES (MarketingSiteMenu) (WorkspaceMenu replaces the site menu)
──────────────────                   ─────────────────────────────────────────
[search: Search sites, or browse     (a different component; see dispatch-workspace-swap)
 topics]                [? or gear]

SIGNED IN, `/` AND OTHER MARKETING ROUTES (MarketingSiteMenu)
SIGNED IN OR OUT, SATELLITE SITES    WorkspaceSiteMenu, signed in
─────────────────────────────────    ──────────────────────────────
[search ........................]    [search ........................]  [gear]
                                     (host nav rows, phone only)
(host nav rows, phone only)          [Home]   Home
[LogIn]    Login   (signed out)        [Boxes] Workspaces        flyout
[UserPlus] Sign up (signed out)      [Help]   Help
── section 0 / 1 divider ──          [History] Recents           flyout
[Bot]      Bitbag                    ── section 0 / 1 divider ──
[Hexagon]  Hub                       Bitbag, Messages, Hub (flyout),
[UsersRound] Dev Team                Organizations, Learn (flyout),
[ChefHat]  Cookbook                  Plan (header), Build (header),
[Wrench]   SDK                       Personas, Products, Hire (flyouts)
[UserCircle] Persona Registry        ── divider, admins only ──
── section 2 divider ──              Admin (flyout)
[CircleHelp] Help
[Mail]     Contact
── divider ──                        ── divider ──
   studio wordmark (footer)             studio wordmark (footer)
```

- Section 0 holds the auth top section and the Help row. Section 1 (`FLEET_SECTION`) holds Recents and the family tree. Section 2 holds the help block in the marketing tree and the Admin block in the workspace tree.
- Section 3 holds the host's own navigation rows (phone only), so a divider falls between them and the top section. A signed-out visitor on a hub workspace path sees `WorkspaceSiteMenu` with Login and Sign up above the family tree.
- The marketing tree omits Home, Workspaces and the chrome Help row, so a signed-in visitor on `/` sees the family rows and the Help and Contact block only, plus Recents when one exists.
- Row icons come from `menu-icons`; the glyph per site is listed there, not here.

## Shared State

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

## Integration Test Vectors

Tests live in `packages/web/packages/adh/src/header/__tests__/`. A vector with no test named is derived from the source alone.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| T1 | shared-base, marketing-tree, workspace-tree | Render `MarketingSiteMenu` then `WorkspaceSiteMenu` on the hub and open each (siteMenuVectors.test, T1) | Each has a Bitbag row and a Hub row, and neither has a Reference row |
| T2 | top-signed-out, top-signed-out-no-chrome | `WorkspaceSiteMenu`, signed out, with login and sign-up hrefs, one recent recorded (siteMenuVectors.test, T2) | The first two rows are Login and Sign up, above Bitbag; no Home and no Recents |
| T3 | top-signed-in-home, workspaces-flyout, recents-flyout | Signed in with workspaces and a recent, then signed out (siteMenuVectors.test, T3) | Signed in adds Home, Workspaces and Recents; signed out has none of them; every other row is identical |
| T4 | inline-row | A config with a leaf row followed by an `inline` row (siteMenuVectors.test, T4) | The inline row renders indented under its parent, always visible, with no flyout |
| T5 | row-icon-label-description, icon-single-source | Render a row; resolve `community` and `narratives` (siteMenuVectors.test, T5) | The icon precedes the label; Community resolves to `Users`, Narratives to `ScrollText` |
| T6 | workspaces-flyout | Open Workspaces with three workspaces (siteMenuVectors.test, T6) | The flyout lists all three, each linking to its home |
| T7 | recents-flyout, recents-hidden | Zero recents, then three (siteMenuVectors.test, T7) | Hidden at zero; three rows newest first otherwise |
| T8 | recents-record, recents-dedupe | Record 11 distinct urls, then re-record the oldest kept (recents.test, T9) | Ten kept, the oldest evicted, the re-recorded place first |
| T9 | recents-persist-key, recents-validate | Record a place, reload the module (recents.test, T11) | The list survives the reload from `adh:recents` |
| T10 | navigate-same-origin | Choose a recent (siteMenuVectors.test, T10) | The router navigates to its url |
| T11 | trigger-accessible-name, entry-order, open-shortcut | Open from the trigger with the keyboard, arrow, open and close a flyout, press Escape (siteMenuVectors.test, T12) | The selection moves, the flyout opens and closes, focus returns to the trigger |
| T12 | omit-chrome-rows, trailing-gear-signed-out, trailing-help-button, trailing-none, marketing-overrides | `MarketingSiteMenu`, signed in, with `onSettings` (marketingSiteMenu.test, "shows the short tree and no settings gear") | Bitbag and Persona Registry shown; no Messages, Organizations, Learn, Plan, Personas, Products or Hire; no "User settings" gear, no "?" button, no Home; one Help row, as a link, and a Contact row |
| T13 | marketing-no-admin | `MarketingSiteMenu` on the hub with `userIsAdmin` (marketingSiteMenu.test, "shows an admin no Admin block") | No Admin row |
| T14 | marketing-no-site-branch, marketing-tree | `MarketingSiteMenu` as an admin on hub, toolkit, cookbook and hub-help (marketingSiteMenu.test, the each-site case) | On every site exactly one each of Bitbag, Hub, Dev Team, Cookbook, SDK, Persona Registry, Help and Contact; no Products, Home or Admin |
| T15 | dispatch-marketing-route | `SiteMenuSwitcher` at `/`, signed in (siteMenuSwitcher.dispatch.test) | The marketing site menu renders, not the workspace menu |
| T16 | dispatch-workspace-swap | Switcher at `/home` and at `/acme/research`, signed in, with a workspaces context (siteMenuSwitcher.dispatch.test) | The workspace menu renders on both |
| T17 | dispatch-workspace-swap, dispatch-workspace-route | Switcher at `/home` on the hub, signed out, with a workspaces context (siteMenuSwitcher.dispatch.test, "keeps the site menu on a workspace route when signed out") | The workspace menu does not render; the site menu (`WorkspaceSiteMenu`) does |
| T18 | dispatch-swap-no-admin, dispatch-swap-passthrough | Switcher on the hub, signed in, as an admin; and with `onSettings` (siteMenuSwitcher.test) | The workspace menu shows no operations consoles, and the settings gear passes through |
| T19 | workspaces-no-placeholder | Signed in with workspaces loading, then failed, then empty (siteMenu.test, the Workspaces flyout cases) | Home is present; no Workspaces row and no "Loading" text in any case |
| T20 | recents-record, recents-clear | Record `/a` then `/b`; record `/a` again with a new label; clear (recents.test) | Order `/b`, `/a`; then `/a`, `/b` with the new label; then empty |
| T21 | recents-record | Record 13 places (recents.test, "caps at RECENTS_CAP") | Length 10; `/p12` first; `/p0` absent |
| T22 | recents-storage-failure, recents-validate | Storage throws on write, or holds a non-array, or entries missing `ts` (derived from `readStorage` and `writeStorage`; no test) | The in-memory list updates; reads return the empty list or only the well-formed entries; the menu renders |
| T23 | recents-cross-tab, recents-stable-snapshot | A `storage` event for `adh:recents`, then for another key (derived from `subscribe`; no test) | The first reloads and notifies; the second does nothing; the list reference is unchanged until a write |
| T24 | href-row-literal, site-row-unknown | A config with an `href` row and a `site` row whose id is unregistered (derived from `useSiteMenu`; no test) | The `href` row keeps its literal url with no wrap and is never current; the unregistered row is absent |
| T25 | navigate-no-target, navigate-guard, navigate-cross-site | Choose a row with href `#`; choose a cross-site row when the guard declines, then accepts (derived from `navigate`; no test) | Nothing happens for `#`; nothing when declined; a full-page load when accepted |
| T26 | nav-links-collapsed, nav-links-home-dedupe | 390px viewport with three `navLinks`, signed in, then signed out with one of them being the Home route; then 1024px (derived from `useHeaderLinksCollapsed` and `buildSiteNavEntries`) | At 390px the rows lead the menu, minus Home only when signed in; at 1024px none appear |
| T27 | help-command, help-command-action, overview-guard, overview-escape | Type "HELP"; select the command; Escape; select again with the overview element absent (derived from `SiteMenu`; no test) | The "overview" command appears; the popover opens and focuses; Escape closes it and removes the listeners; with no element nothing happens and nothing throws |
| T28 | trailing-gear, trailing-help-button | Signed in with both `onSettings` and `settingsHref`; signed in with neither; signed out (derived from `settingsTrailing` and `SiteMenu`; no test) | The gear is a button calling `onSettings`; the "?" button; the "?" button |
| T29 | trigger-brand-label, trigger-override, open-shortcut | Hub missing from the registry; `triggerContent` given; `siteMenuShortcut` empty (derived from `SiteMenu`; no test) | Text "Agentic Developer Hub"; the default content replaced; no chord registered |
| T30 | tree-admin-append, admin-block-shape, admin-is-not-access | `WorkspaceSiteMenu` with `userIsAdmin` true, false and undefined (derived from `SiteMenu`; no test) | An Admin flyout ending in Fleet Monitor for true; the same menu for false and undefined |
| T31 | site-row-href, route-row-href, site-row-sso | Hub, signed in, in workspace `acme`, `hubOffersFeature` returning true for `research`; then a satellite with `resolveHref` supplied (useSiteMenu.test, "in-hub reroute"; the Contact result is derived from `routeHref`, no test) | The Research row goes to `/acme/research`; Contact stays `/contact`, because `contact` is not a hub workspace segment; satellite rows are wrapped by `resolveHref` |
| T32 | icon-segment-fold, icon-missing | Resolve `/research`, a segment with no hand-written key, and an unknown key (derived from `menu-icons`; no test) | `/research` takes the research site's `FlaskConical`; the unknown key returns undefined and leaves the slot empty |
| T33 | icon-jobs, icon-single-source | Resolve `/jobs` through `menuIcon` (derived from `menu-icons`; the hub's recents-recorder test walks every hub workspace segment) | The `Workflow` glyph; not undefined |

## Edge Cases

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

## Platform Notes

- **SwiftUI**: Start from a `Menu` or a `.popover` anchored to a toolbar button, with a `List` of rows holding a `Label` (system image, title) and a secondary `Text` for the description. Nested flyouts map to nested `Menu` values or a `NavigationStack` inside the popover, since SwiftUI has no cascading hover submenu. Back the command search with `.searchable` and a filtered row model. Port Recents as an `@Observable` store persisted through `UserDefaults` with the same 10-place cap and url de-duplication, and use `@Environment(\.horizontalSizeClass)` in place of the 768px query. Bind the open chord with `.keyboardShortcut`.
- **Compose**: Start from a `DropdownMenu` or a `ModalBottomSheet` with a `LazyColumn` of `ListItem` rows (leading icon, headline, supporting text). Replace flyouts with an expandable row or a second sheet level, because Material has no cascading menu. Drive the filter from a `SearchBar` or `OutlinedTextField`, hold Recents in a `DataStore` preference with the same cap, and read `WindowSizeClass` where the web reads the 768px query. Hardware keyboards use `onPreviewKeyEvent` for the arrow, Enter and Escape handling that `NavigationPopover` supplies.
- **React/Web**: The source platform. `header/SiteMenu.tsx` is the base and owns link resolution through `useSiteMenu`, the top section, Recents and the trailing control. `header/MarketingSiteMenu.tsx` and `header/WorkspaceSiteMenu.tsx` are config-only. `header/SiteMenuSwitcher.tsx` dispatches by route through `isWorkspaceMenuRoute` in `activeMenuGroups.ts`. `header/menu-icons.ts` holds the lucide glyph map and the derived fold from `SITE_FOR_HUB_SEGMENT`. `header/recents.ts` holds the store behind `useSyncExternalStore`. Two things are specific to this build: the Recents store is imported by its own package subpath and listed `external` in both tsup configs so one copy of its module state exists, and `SiteMenu` imports the footer's overview id from a sibling module rather than the package subpath so tsup does not inline the footer entry. Keyboard behavior, `role="menuitem"`, `aria-current="page"` and the combobox search field are `NavigationPopover`'s.
- **AppKit / UIKit**: On macOS start from `NSMenu` with `NSMenuItem` rows (image and title, a submenu for each flyout) shown from an `NSPopUpButton` or a status-style button, adding a search field through `NSSearchField` in a custom view item. On iOS use `UIMenu` with `UIAction` and nested `UIMenu` children, or a `UIPopoverPresentationController` over a `UITableView` for the searchable list. Store Recents in `UserDefaults` and key the open chord with `NSMenuItem.keyEquivalent` or `UIKeyCommand`. Native menus close on selection and restore focus themselves, so the focus-handoff flag used before opening the overview has no counterpart.
- **WinUI 3**: Anchor a `Flyout` (for the searchable list) or a `MenuFlyout` to the brand `Button`, and fill it from a data-templated `ListView` or `ItemsRepeater` whose row template pairs an `IconElement` (`FontIcon` or `SymbolIcon`, resolved from one `MenuIcons` dictionary keyed by site id, route, chrome key or icon key) with a label `TextBlock` and a lower-contrast description `TextBlock`. Put an `AutoSuggestBox` at the top for the search, binding `TextChanged` to a filtered collection; its `QueryIcon` slot hosts the gear or "?" `Button`. Map each topic to a `MenuFlyoutSubItem` (or a nested `ItemsRepeater` with a left `Margin` for an inline row), set `AutomationProperties.Name` on the trigger to the brand label, a dash and "switch site", and mark the current row through a `VisualStateManager` state bound to a `IsCurrent` property. Persist Recents as a capped `List<Place>` in `ApplicationData.Current.LocalSettings` and raise a change event on write, with `AdaptiveTrigger MinWindowWidth` of 769 standing in for the 768px query. Bind the open chord with a `KeyboardAccelerator` on the trigger; arrow, Enter and Escape handling come from `MenuFlyout`, and from `ListView` with `IsItemClickEnabled` for the searchable list.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/adh/src/header/SiteMenu.tsx` | confirmed (1.3.0) |
| web | `packages/web/packages/adh/src/header/SiteMenuSwitcher.tsx` | confirmed (1.3.0) |
| web | `packages/web/packages/adh/src/header/MarketingSiteMenu.tsx` | confirmed (1.3.0) |
| web | `packages/web/packages/adh/src/header/WorkspaceSiteMenu.tsx` | confirmed (1.3.0) |
| web | `packages/web/packages/adh/src/header/menu-icons.ts` | confirmed (1.3.0) |
| web | `packages/web/packages/adh/src/header/recents.ts` | confirmed (1.3.0) |

## Design Decisions

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

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |
| [adc.check.reliability.state-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/6e64e2f2-28ad-55d5-a8ed-cee075366674) | passed | Reliability |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | passed | Reliability |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy and Data |
| [adc.check.privacy-and-data.data-retention-policy](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0c9cc813-244a-5dc1-8914-fd4710bb4943) | partial | Privacy and Data |
| [adc.check.security.server-side-authorization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/90e085e3-5112-5c02-9c10-4a2e324eeca1) | passed | Security |

separation-of-concerns passes because logic sits in `SiteMenu`, the trees in `fleetMenuGroups`, icons in `menu-icons`, persistence in `recents`, and the two menus are config only. unit-test-coverage is partial: `siteMenuVectors.test.tsx`, `recents.test.ts`, `marketingSiteMenu.test.tsx`, `siteMenuSwitcher.dispatch.test.tsx`, `siteMenuSwitcher.test.tsx`, `siteMenu.test.tsx` and `useSiteMenu.test.tsx` cover the tree, the dispatch, the store and row resolution, but the help command, the overview popover handling, the phone navigation rows, the gear and "?" button, the admin append and the storage-failure and cross-tab paths have no test here, and the settle-debounced recorder is the hub's. explicit-error-handling passes because storage failures and an unsupported popover are caught and neutralized, and a navigation the guard declines is dropped. keyboard-navigable, screen-reader-support and focus-management pass because the menu composes `NavigationPopover`, which supplies arrow, Escape and Enter handling, `role="menuitem"`, `aria-current`, a combobox search field with `aria-activedescendant`, and decorative icons marked `aria-hidden`, and because the menu releases focus deliberately before handing it to another surface. touch-target-size is partial because the trailing controls are sized by a 1rem icon and 0.15rem of padding with no minimum target; the open question on `help-button-target-size` records it. string-externalization and no-hardcoded-strings fail because every visible string is a literal and no catalog is named; the open question on `localized-labels` records it. graceful-degradation passes because a missing hub site, an unknown site id, an empty workspaces list and a storage failure each leave a working menu. state-recovery passes because Recents re-hydrate from `localStorage` after a reload. idempotent-operations passes because re-recording a url moves it to the front rather than duplicating it. data-minimization passes because a recorded place holds only a url, label, optional description and icon key, and a timestamp. data-retention-policy is partial because the list is capped at 10 with oldest-first eviction, but `clearRecents` is not called anywhere in these sources, so a sign-out relies on the menu hiding Recents rather than on deleting them. server-side-authorization passes because the menu states and implements that showing the Admin block only decides who is shown a link, and each console authorizes for itself.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-07-05 | Mike Fullerton | Initial spec: icons SSoT, inline sub-items, Hub gathering, auth top section, Recents. |
| 1.0.1 | 2026-09-24 | Mike Fullerton | Compliance section rewritten as linked checks against the compliance catalog |
| 1.0.2 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.0.3 | 2026-09-27 | Mike Fullerton | Moved into the concept grouping. |
| 1.1.0 | 2026-10-04 | Mike Fullerton | Status review; Design Decisions in triple form; WinUI 3 guidance; Reference Implementations filled; unit-test-coverage note updated for siteMenu.test.tsx. |
| 1.1.1 | 2026-10-04 | Mike Fullerton | Matches its type's shape: required fields, title heading, and only the type's own sections. |
| 1.1.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (siteMenuVectors.test.tsx, recents.test.ts, 11 of 12 vectors); unit-test-coverage now partial. Vectors T1, T3, T4, T5 and T6 rewritten to match the shipped trees. |
| 1.2.0 | 2026-11-22 | Mike Fullerton | Rewritten from source: marketing and workspace trees, dispatcher, no Workspaces placeholder, Recents store, requirements and vectors re-derived; Reference Implementations removed. |
| 1.3.0 | 2026-11-23 | Mike Fullerton | Phase 9: the jobs hub knob's menu icon (Workflow, key /jobs). |

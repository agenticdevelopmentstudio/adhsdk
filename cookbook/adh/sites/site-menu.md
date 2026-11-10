---
id: f2d56415-ac36-4a27-bee5-b447c4186513
title: "SiteMenu"
type: recipe
version: 1.1.1
status: review
language: en
created: 2026-07-05
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The platform navigation menu: an icon+label+description list with inline sub-items, an auth-conditional top section, and a Recents flyout."
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

`SiteMenu` is the platform's primary navigation menu — the popover disclosed from
the header wordmark. It renders a vertical list of rows, each `[icon] [label]
[description]`, organized into sections. It has one shared core layout used by
**both** the marketing (logged-out) and workspace (logged-in `/home`) surfaces;
only the **top section** differs by auth state.

It is chrome. The menu itself — `SiteMenu` and the `menu-icons` map — is ADH
vocabulary, and the registry-free machinery it composes (`NavigationPopover`, the
recents store) is generic; both halves now live in `@adh-sdk/adh/header`,
so the tier boundary this recipe once straddled is gone. It is built by composing that
`NavigationPopover` (surface, search, keyboard nav, flyout submenus) with a
declarative config (`MenuGroup[]`). This recipe defines the enhanced menu:
per-row **icons** from a single source of truth, a new **inline sub-item** row
kind, a **Hub** section that gathers the ecosystem's sites and tools, and an
auth-conditional **top section** that adds **Login/Sign up** when logged out and
**Home / Workspaces / Recents** when logged in. Recents records the last 10 places
the user actually landed on and deep-links back to each.

## Ingredients

| Name | Domain | Role | Required | Configuration |
|---|---|---|---|---|
| NavigationPopover | `@adh-sdk/adh/header` | Popover surface, search box, keyboard navigation, row rendering, flyout submenus | yes | Consumes `PopoverEntry[]` with icon + inline-subitem support |
| SiteWordmark | [adhsdk.ingredient.adh.sites.site-wordmark](cookbook:21cbbc1c-38a0-4e7a-8ca0-06e2f29429f5) | The header trigger that opens the menu | yes | Unchanged |
| menu-icons map | `@adh-sdk/adh/header` `menu-icons.ts` (ADH vocabulary — it is keyed by `SiteId`) | Single source of truth for every row's icon — keyed by SiteId, in-hub route path, or chrome key | yes | `MENU_ICONS` record + `menuIcon(key)` resolver |
| lucide-react icons | (library) | The icon glyphs | yes | Only icons already used elsewhere on the platform are reused where one exists |
| `useWorkspaces` | `@/api/workspaces` (hub) | Supplies the Workspaces flyout entries | yes (logged-in) | react-query; `{ slug, name, type }[]` |
| Recents store | `@adh-sdk/adh/header/recents` — import that subpath, never `./recents`; it holds module-level state and a second inlined copy would silently fork the history | Persists + reads the last 10 visited places | yes (logged-in) | localStorage, `ftd-storage` pattern |

## Integration Requirements

- **shared-core-both-menus**: The marketing and workspace menus MUST render the
  identical core section structure (the Hub section and everything below it),
  differing ONLY in the auth-conditional top section.
- **row-icon-label-description**: Every row MUST render, in order, an icon, a label,
  and (when present) a description.
- **icon-single-source**: A row's icon MUST resolve from a single source of truth —
  the `menu-icons` map (`MENU_ICONS` / `menuIcon(key)`), keyed by SiteId for site
  rows, route path for in-hub route rows, and a chrome key for the non-site rows
  (Home, Recents, Workspaces, Login, Sign up) — and MUST NOT be hard-coded at a
  render site.
- **icon-reuse-existing**: Where the platform already associates an icon with a
  thing (e.g. Community→`Users`, Persona Registry→`UserCircle`, Dev Team→
  `UsersRound`, Narratives→`ScrollText`, Ecosystems→`Network`, Research→
  `FlaskConical`), that icon MUST be reused rather than a new one invented.
- **inline-subitem-kind**: The menu MUST support an inline sub-item row — a leaf row
  rendered indented under a parent row and ALWAYS visible (not a flyout).
- **hub-parent-links-and-parents**: The "Hub" row MUST be a clickable link to the
  hub apex AND the parent of its inline sub-items.
- **hub-subitems-inventory**: Hub's inline sub-items MUST be, in order, BitBag,
  Community, Persona Registry, Toolkit, Cookbook, Dev Team, MyAgenticTeams,
  Narratives, Help; plus News, Ecosystems, Personas, Organizations, Research.
- **reference-group-removed**: The former "Reference" topic group (docs/api/mcp)
  MUST NOT appear in either menu.
- **in-hub-rows-authed-only**: The in-hub destination rows (News, Ecosystems,
  Personas, Organizations, Research) MUST be hidden when the user is not
  authenticated.
- **top-section-logged-out**: When unauthenticated, the top section MUST show
  exactly two rows — Login and Sign up — above the Hub section.
- **top-section-logged-in**: When authenticated, the top section MUST show Home
  (with an inline sub-item Workspaces) and Recents, above the Hub section.
- **workspaces-flyout**: Selecting/hovering Workspaces MUST open a flyout submenu of
  the user's workspaces from `useWorkspaces`, each labelled per
  `workspaceListLabel` and navigating to that workspace's home.
- **recents-flyout**: Recents MUST open a flyout submenu of the recorded places,
  most-recent first, capped at 10.
- **recents-settle-only**: A place MUST be recorded only after the current selection
  **settles** (no further drill-down within the debounce window), so intermediate
  drill-through steps between a list and its leaf are NOT recorded.
- **recents-deep-link**: Each recent MUST link to the deep URL of the recorded view;
  a view that is not yet URL-addressable MUST record its best available URL (the
  feature route) and MUST NOT block recording.
- **recents-dedupe-cap**: Recording a place already present MUST move it to the
  front (not duplicate it); the list MUST be capped at 10, evicting the oldest.
- **recents-persist-local**: Recents MUST persist per-device in localStorage using
  the `ftd-storage` conventions — SSR-guarded (`typeof window`), try/catch
  swallowing, an `adh:` key prefix.
- **recents-empty-hidden**: When there are no recorded places, the Recents entry
  MUST be hidden (nothing to disclose).
- **current-marked**: The row matching the current location (a site, a workspace, a
  recent) MUST be marked `current`, matching existing `NavigationPopover` behavior.
- **keyboard-accessible**: The enhanced menu MUST retain `NavigationPopover`'s full
  keyboard model (open on trigger activation, arrow navigation, flyout entry/exit,
  Escape to close, focus return).

## Layout

```
LOGGED OUT (marketing)               LOGGED IN (/home + workspace)
──────────────────────               ─────────────────────────────
[LogIn]     Login                    [Home]     Home
[UserPlus]  Sign up                    [Boxes]  Workspaces        ▸ flyout
                                     [History]  Recents           ▸ flyout
── section divider ──                ── section divider ──
[Hub icon]  Hub                      [Hub icon]  Hub
  [Bot]      BitBag                    [Bot]       BitBag
  [Users]    Community                 [Users]     Community
  [UserCircle] Persona Registry        [UserCircle] Persona Registry
  [Wrench]   Toolkit                   [Wrench]    Toolkit
  [ChefHat]  Cookbook                  [ChefHat]   Cookbook
  [UsersRound] Dev Team                [UsersRound] Dev Team
  [Sparkles] MyAgenticTeams            [Sparkles]  MyAgenticTeams
  [ScrollText] Narratives              [ScrollText] Narratives
  [CircleHelp] Help                    [CircleHelp] Help
                                       [Newspaper]  News
                                       [Network]    Ecosystems
                                       [UserCircle] Personas
                                       [Building]   Organizations
                                       [FlaskConical] Research
```

- Indentation (2 spaces) = **inline sub-item**, always visible.
- `▸` = **flyout submenu** (the existing `topic` popover disclosure).
- Row visual language is unchanged from `NavigationPopover`: label
  `adh-nav-popover__link-name`, optional description below/beside; the icon sits in
  a fixed-width leading slot, `apt-text-muted`, sized to the label line.
- Icons are lucide-react; the exact glyph per row comes from the single source of
  truth (see Integration Requirements). Icons shown above are the proposed set;
  reused-where-existing, chosen-where-absent.
- Section divider between the top (auth) section and the Hub section reuses the
  existing section-break treatment (`MenuGroup.section` boundary).

## Shared State

| State | Source | Consumer | Direction | Mechanism |
|---|---|---|---|---|
| Auth (authenticated?) | `AdhHeader` `user` → `SiteSwitcher` `authenticated` | Which top section + whether in-hub rows show | one-way | prop |
| Active route / selection | `usePathname` + workspace chrome `mergedLevels` | `current` marking; Recents recorder input | read | context + hook |
| Workspaces | `useWorkspaces()` (hub) | Workspaces flyout entries | read | react-query |
| Recents list | Recents store (localStorage) | Recents flyout entries | read/write | module store; recorder writes, menu reads |
| Recorded place | Recents recorder (settle-debounced observer of `mergedLevels`) | Recents store | write | effect + timer |

## Integration Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | shared-core-both-menus, reference-group-removed | render marketing vs workspace menu | identical Hub section; no "Reference" group in either |
| T2 | top-section-logged-out | unauthenticated | Login + Sign up above Hub; no Home/Recents |
| T3 | top-section-logged-in, in-hub-rows-authed-only | authenticated | Home/Workspaces/Recents present; News/Ecosystems/Personas/Organizations/Research visible; hidden when logged out |
| T4 | inline-subitem-kind, hub-subitems-inventory | render Hub | sub-items rendered indented, in the specified order |
| T5 | row-icon-label-description, icon-reuse-existing | render any row | icon precedes label; Community shows `Users`, Narratives shows `ScrollText` |
| T6 | workspaces-flyout | open Workspaces with 3 workspaces | flyout lists all 3, labelled + navigating to each home |
| T7 | recents-flyout, recents-empty-hidden | 0 recents / 3 recents | entry hidden at 0; lists 3 most-recent-first otherwise |
| T8 | recents-settle-only | drill list→detail→leaf within the settle window, stop at leaf | only the leaf is recorded |
| T9 | recents-dedupe-cap | record 11 distinct, then re-record #1 | 10 kept, oldest evicted; #1 moves to front |
| T10 | recents-deep-link | click a recent | navigates to that view's deep URL |
| T11 | recents-persist-local | record, reload | recents survive reload (same device) |
| T12 | keyboard-accessible | open, arrow, flyout, Escape | selection moves, flyout opens/closes, focus returns to trigger |

## Edge Cases

- **Not-yet-addressable view.** A recorded place whose view is not URL-addressable
  records the feature route; its recent reopens the feature page (label still tells
  the user what it was). As deep-linking lands, the same place records a precise URL.
- **Workspaces still loading / empty.** Workspaces flyout shows the shared `Spinner`
  while loading and the shared `EmptyState` when the user has none.
- **Recents referencing a deleted entity.** Clicking navigates to the deep URL; the
  feature renders its own not-found/empty state (recents is not authoritative and is
  not pruned server-side).
- **localStorage unavailable** (private mode / quota) — reads return `[]`, writes are
  swallowed; the menu still renders (Recents simply stays empty/hidden).
- **Logged-out device with stale recents in storage.** Recents is a logged-in-only
  section; the recorder only runs and the flyout only shows when authenticated.
- **Very long labels / descriptions** truncate with the existing row ellipsis; the
  icon slot never shrinks.

## Platform Notes

- Files: menu config `packages/web/packages/adh/src/header/MarketingSiteMenu.tsx` +
  `WorkspaceSiteMenu.tsx` (both compose the shared `hubCoreGroups.ts`); types +
  rendering `SiteMenu.tsx` (auth top section + compose) + `NavigationPopover.tsx`
  (icon slot + inline sub-item indent); icon SSoT
  `packages/web/packages/adh/src/header/menu-icons.ts`; Recents store + hook
  `packages/web/packages/adh/src/header/recents.ts`; Workspaces context
  `packages/web/packages/adh/src/header/workspaces-menu.tsx` (hub filler +
  `hub-workspaces-menu-provider.tsx`); recorder
  `websites/main/hub/src/components/workspace/recents-recorder.tsx` (in the adh repo).
- The recorder observes `WorkspaceChromeProvider.mergedLevels`
  (`frontend/src/sites/hub/src/components/workspace/workspace-chrome.tsx`) — the one
  place holding the full current selection path (with labels) for both nav models.
- Demo: `frontend/src/local/ui-showcase/app/page.tsx` — a `site-menu` topic rendering
  both auth states with seeded workspaces + recents.
- Responsive: verify via Playwright at 375 / 768 / 1440; keyboard + pointer.
- Tailwind sources: no new package boundary; icons are lucide (already a dependency
  of `@adh-sdk/adh` and externalized by it, so the host supplies the one copy).
- **WinUI 3**: Build the menu from a `Flyout`/`MenuFlyout` anchored to the wordmark button, with a `NavigationViewItem`-style row template of icon (`FontIcon`/`SymbolIcon` from a single `MenuIcons` dictionary keyed by site id, route, or chrome key), label and description `TextBlock`s. Inline sub-items map to a nested `ItemsRepeater` with a left margin; the Workspaces and Recents flyouts map to `MenuFlyoutSubItem`. Port Recents as a class holding a capped `List<Place>` persisted through `ApplicationData.Current.LocalSettings`, with a `DispatcherTimer` as the settle debounce; keyboard navigation comes from `MenuFlyout`'s built-in arrow, Escape and focus-return behavior.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/adh/src/header/SiteMenu.tsx` | unverified |
| web | `packages/web/packages/adh/src/header/SiteMenuSwitcher.tsx` | unverified |
| web | `packages/web/packages/adh/src/header/MarketingSiteMenu.tsx` | unverified |
| web | `packages/web/packages/adh/src/header/WorkspaceSiteMenu.tsx` | unverified |
| web | `packages/web/packages/adh/src/header/menu-icons.ts` | unverified |
| web | `packages/web/packages/adh/src/header/recents.ts` | unverified |

## Design Decisions

**Decision**: One shared core, two configs.
**Rationale**: The menu is already `SiteMenu` -> `NavigationPopover` driven by two `MenuGroup[]` arrays; "duplicate the layout" means extracting the shared Hub core so both configs reuse it and only the top section diverges, which avoids the copy-paste drift the two configs risk today.
**Approved**: pending

**Decision**: Icons live in one `menu-icons` map.
**Rationale**: A single co-located map (`header/menu-icons.ts`) keyed by SiteId / route path / chrome key is the one authoritative icon per entry, none inline in JSX. Chosen over hanging an `icon` field on `SiteDef`: the registry is consumed by roughly 40 sites, so an added field is a higher-blast public-shape change for no current non-menu consumer; the map can be promoted to `SiteDef` later if a card or launcher needs the same glyphs, and every row still resolves through `menuIcon(key)`.
**Approved**: pending

**Decision**: Inline sub-items are a new row kind, not the existing flyout.
**Rationale**: The existing `topic` group discloses a side flyout; inline sub-items are always-visible indented leaves. They are distinct kinds so Hub can nest visibly while Workspaces and Recents still use flyouts.
**Approved**: pending

**Decision**: Settle-based Recents, not per-view instrumentation.
**Rationale**: Recording after the selection stack settles (about 1.5s) coalesces drill-through into the final destination with one observer and no per-page hooks (see `adh/docs/ui/deep-linking-foundation.md`); it records the eventual destination, not each click.
**Approved**: pending

**Decision**: Recents persist in local storage, not a backend.
**Rationale**: Recents is inherently ephemeral and per-device and the `ftd-storage` pattern already exists for exactly this, so there is no table or migration; a cross-device sync can be added later behind the same store API.
**Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.best-practices.test-pyramid](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/203de556-83a8-5211-acaf-155c49da0eb3) | partial | Best Practices |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | failed | Internationalization |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | failed | Internationalization |
| [adc.check.platform-compliance.platform-design-language](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/cbd07fee-ca18-58a8-bb2f-0f8a6b83ac1c) | passed | Platform Compliance |
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | Platform Compliance |
| [adc.check.platform-compliance.deep-linking-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c2a477a7-bd42-5e3f-9ebd-5a64b4b63de4) | partial | Platform Compliance |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | passed | Reliability |
| [adc.check.reliability.state-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/6e64e2f2-28ad-55d5-a8ed-cee075366674) | passed | Reliability |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | passed | Reliability |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | passed | Reliability |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy and Data |
| [adc.check.privacy-and-data.data-retention-policy](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0c9cc813-244a-5dc1-8914-fd4710bb4943) | passed | Privacy and Data |
| [adc.check.performance.progress-indication](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/6ba6685b-9d35-5eb2-96e7-afbccd1e5848) | passed | Performance |

Notes: separation-of-concerns passes because the recipe composes a generic, registry-free `NavigationPopover` with an ADH-specific `MenuGroup[]` config, keeping the reusable chrome and the ADH vocabulary (`SiteMenu`, `menu-icons`) apart. unit-test-coverage is partial: `siteMenu.test.tsx` covers the Workspaces flyout (listed once loaded, absent while loading, absent on failure or empty), `recents.test.ts`, `navigationPopover.test.tsx`, and `useSiteMenu.test.tsx` cover the recents store, the keyboard/flyout mechanics, and row resolution, `useSiteMenu.test.tsx` also pins the `menu-icons` resolution, but no test file targets `MarketingSiteMenu.tsx` or `WorkspaceSiteMenu.tsx` directly (`siteMenuSwitcher.dispatch.test.tsx` mocks them), so the auth-conditional top section and the Hub inline-subitem inventory are only partly exercised. explicit-error-handling passes because the recorder's localStorage access is documented as try/catch-swallowed (recents-persist-local) and a Recents entry pointing at a deleted entity is routed to the destination feature's own not-found state rather than thrown. test-pyramid is partial because the Integration Test Vectors (T1-T12) are defined exclusively at the rendering/integration level — full-menu composition, flyouts, keyboard flows — with no unit-level vectors for isolated pieces like the icon resolver or the settle-debounce timer. screen-reader-support and semantic-markup pass because keyboard-accessible requires retaining `NavigationPopover`'s full keyboard/ARIA model, including menu roles, unchanged. keyboard-navigable passes because the enhanced menu is required to retain arrow navigation, flyout entry/exit, and Escape-to-close (T12). focus-management passes because keyboard-accessible and T12 both require focus to return to the trigger once the menu or a flyout closes. string-externalization and no-hardcoded-strings fail because every visible label (Login, Sign up, Home, Workspaces, Recents, Hub, BitBag, Community, and the rest of the Hub inventory) appears as a literal string in this recipe with no localization resource, key, or i18n library named anywhere in Overview, Ingredients, or Platform Notes. rtl-layout-support fails because nothing in the recipe addresses right-to-left mirroring for the menu's flyouts or row layout. text-expansion-tolerance fails because Edge Cases states long labels and descriptions truncate via ellipsis rather than accommodating expansion. platform-design-language and native-controls-preference pass because the menu reuses the existing `NavigationPopover` chrome rather than a bespoke implementation, per the "One shared core, two configs" Design Decision. deep-linking-support is partial because recents-deep-link requires linking to the recorded view's deep URL, but Edge Cases notes a not-yet-URL-addressable view falls back to its feature route — an explicitly open gap ("As deep-linking lands, the same place records a precise URL"). graceful-degradation passes because a localStorage failure leaves Recents empty and hidden rather than crashing, and a loading or empty Workspaces flyout shows a Spinner or EmptyState instead of blocking. data-integrity and idempotent-operations pass because recents-dedupe-cap requires re-recording an existing place to move it to the front rather than duplicate it, with the store capped at exactly 10 and oldest-eviction on overflow. state-recovery passes because recents-persist-local requires recents to survive a reload (T11). fault-tolerance passes because a recent referencing a deleted entity still navigates and lets the destination feature render its own not-found state rather than erroring. data-minimization and data-retention-policy pass because Recents is scoped to place labels and URLs only, with a fixed cap of 10 and oldest-eviction as its retention rule. progress-indication passes because the Workspaces flyout is required to show a Spinner while its data loads.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.0.0 | 2026-07-05 | Mike Fullerton | Initial spec: icons SSoT, inline sub-items, Hub gathering, auth top section, Recents. |
| 1.0.1 | 2026-09-24 | Mike Fullerton | Compliance section rewritten as linked checks against the compliance catalog |
| 1.0.2 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.0.3 | 2026-09-27 | Mike Fullerton | Moved into the concept grouping. |
| 1.1.0 | 2026-10-04 | Mike Fullerton | Status review; Design Decisions in triple form; WinUI 3 guidance; Reference Implementations filled; unit-test-coverage note updated for siteMenu.test.tsx. |
| 1.1.1 | 2026-10-04 | Mike Fullerton | Matches its type's shape: required fields, title heading, and only the type's own sections. |

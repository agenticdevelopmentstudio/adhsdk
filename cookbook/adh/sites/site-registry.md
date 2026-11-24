---
id: 9069ccf9-0357-4311-9671-91ee2793adae
title: "Site Registry"
type: ingredient
version: 1.6.1
status: review
language: en
created: 2026-09-24
modified: 2026-11-24
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Single source of truth for the ADH site family: sites, hosts, environments, hub routing, SSO origins, reserved slugs, route map, brand story, legal URLs."
platforms:
  - typescript
  - web
tags:
  - site-registry
  - adh-registry
  - multi-site
  - routing
  - sso
  - brand-story
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Site Registry

## Overview

The site registry is the single source of truth for the Agentic Developer Hub (ADH)
site family: roughly seventy independently deployed sites (`hub`, `cookbook`,
`projects`, `billing`, …) that share a header, a cross-site switcher, and a central
OAuth client. It comprises:

- **The site roster**: a closed set of every site identifier the family currently
  knows about, and one definition per site (display names, production host, which
  deploy environments exist, whether the site exposes the shared landing route,
  whether it mounts an authenticated workspace route); environment/host resolution
  for cross-site navigation; the hub's in-workspace feature-segment map; the
  workspace-slug round trip (plus the two disjoint landing-segment sets that tell a
  slug apart from a static page); a per-site build-configuration side table kept
  deliberately outside the mechanically generated part of the roster; and the
  cross-site single-sign-on (SSO) OAuth redirect allowlist.
- **The reserved-slug table**: which top-level path segments a registrant cannot
  claim as a public handle, per site.
- **The generated route map**: per-region generated route shares merged into one
  route table, feeding a "Routes" review surface and, downstream, a sitemap's
  static-segment exclusion list.
- **The legal addresses and the fleet directory**: the one hub-hosted Privacy Policy
  and Terms of Use address every site's footer links, and the directory of working
  sites a landing page's footer links, derived by removing the marketing-deck and
  placeholder fleets from the footer site list.
- **The brand story and guided tour**: a hand-authored brand-story map (brand tier,
  message-house pillar, funnel stage, and a brand-judgment "next step" per site)
  plus a separately generated, three-ring guided-tour graph merged into one
  next-step map.

All of it is pure, synchronous data and functions with no I/O beyond in-memory
lookups and one read of a local-server environment variable, read by the header, the site switcher, the footer, the hub's workspace
router, and a downstream OAuth-return-origin sync process.

## Behavioral Requirements

### Site identity and roster

- **site-id-closed-union**: The site identifier type MUST be closed, naming every
  site the family currently knows about; a value obtained from outside that closed
  set (a directory name, a command-line argument, a database column) MUST be
  validated by identifier validation or by directory-based identification before it
  can index the site roster or any table keyed by site identifier.
- **unique-site-ids**: Every entry in the site roster MUST have a unique identifier,
  and the roster MUST NOT contain an entry for the backend service itself.
- **site-def-minimum-fields**: Every site definition MUST declare `id`, `label`, and
  `prodHost`, and MUST declare `hasStaging`, `hasTesting`, and `hasHome` as explicit
  booleans (never omitted, since environment host resolution, the OAuth
  return-origin allowlist, and cross-site link construction's home-carry all branch
  on their literal `true`/`false` value).
- **workspace-route-not-derived-from-has-home**: A site definition's workspace-route
  field MUST NOT be inferred from `hasHome`; the two are independent facts about a
  site's route tree (`bitbag`, `status`, and `admin` have `hasHome: false` and no
  workspace route; `hub-help` and `personaregistry` have neither a home route nor a
  workspace route; `store` has `hasHome: false` yet a `'root'` workspace route; and
  `myagenticdevteam`, a coming-soon placeholder whose only signed-in surface is a
  gated `/home`, has `hasHome: true` and no workspace route), and a caller deriving
  one from the other risks sending a workspace switch to a route that 404s.
- **native-app-site-flag**: A site definition for a macOS native tool (`kitchen`,
  `stenographer`) MUST be marked `nativeApp`; such a site MUST remain in every roster
  that lists sites (the switcher, the footer, the overview) and MUST be absent from the
  main-family roster, the marketing-family roster, and the external set.
- **external-site-excluded-from-sso**: A site definition marked `external` MUST be
  excluded from the OAuth return-origin allowlist in every environment, because such
  a site (FishLamp Design) has no auth-callback route and never begins an ADH login.
- **admin-only-derives-admin-ids-and-drops-footer**: The admin-only id set MUST be
  exactly the identifiers of every site definition marked `adminOnly`, and every such
  entry MUST be excluded from the footer site list.
- **support-routes-in-shares**: The hub's generated route shares MUST list the hosted `/support` page in the `hub` share, the `/support` topic in the `product-admin` share, and the operator admin site's three pages, `/break-glass`, `/support-access` and `/support-grants`, in the `admin` share, each in the sorted place [route-list-per-site-is-normalized](#requirements/route-list-per-site-is-normalized) gives it.
- **ai-settings-extra-segment**: The hub-only extra segments MUST include `ai-settings`, the hub knob that holds the workspace's AI Settings (services and their models).
- **ai-settings-hub-route-line**: The hub route share MUST carry one workspace line for `ai-settings`, `/[workspace]/ai-settings/[[...path]]`, matching its one `llm-providers` workspace line, in sorted place (after `/[workspace]/admin-site/[[...path]]`). The share MUST keep its `/[workspace]/llm-providers/[[...path]]` and `/[workspace]/persona-services/[[...path]]` lines, which serve the redirects (legacy-provider-segments-redirect-only).
- **admin-share-no-ai-settings**: The admin route share MUST NOT gain an `ai-settings` line. Its `/llm-providers` line is the operator console's own provider page, whose identifier stays.
- **legacy-provider-segments-redirect-only**: `llm-providers` and `persona-services` MUST stay in the hub-only extra segments as redirect-only segments, so a stored link to either still resolves as a hub workspace segment. This module MUST NOT redirect them; the hub site does the redirect to `ai-settings`, keeping the sub-path.
- **jobs-extra-segment**: The hub-only extra segments MUST include `jobs` (phase 9), the hub knob that holds the workspace's jobs, templates and environments.
- **jobs-sub-paths-not-segments**: `jobs/templates` and `jobs/environments` MUST be sub-paths served by the `jobs` workspace line, and MUST NOT be added to the hub-only extra segments, because a workspace segment is one path segment.
- **jobs-hub-route-line**: The hub route share MUST carry one workspace line for `jobs`, `/[workspace]/jobs/[[...path]]`, in sorted place [route-list-per-site-is-normalized](#requirements/route-list-per-site-is-normalized).
- **product-admin-share-jobs**: The `product-admin` route share MUST list the site's three Jobs pages, `/jobs`, `/jobs/templates` and a template's own page `/jobs/templates/[templateId]`, in sorted place. It has no Environments page: environments belong to a job's owner, and a product admin only reads run status.
- **admin-share-no-jobs**: The admin route share MUST NOT gain a `/jobs` line: the operator's dead jobs list is a section of its AI Nodes page.
- **product-admin-site-registered**: The roster MUST define a `product-admin` site (a
  product's own admin site, phase 6) that is `adminOnly`, not `crawlable`, and has no home
  route (`hasHome` false), with `product-admin.agenticdeveloperhub.com` as its production
  host; because it is `adminOnly` it MUST be absent from the footer site list. It MUST be in
  the main-family roster, MUST sit in the console section of the family roster between
  `admin` and `builds`, and MUST be hand-rolled in the per-site build table
  (`handRolledConfig`), since its root app holds the site's own `/auth/*` route handlers.
  The one deployed app serves every product's admin site and picks the product by host, so
  the registry's host is only the default.
- **listed-sites-filter**: The listed-sites set MUST be exactly the roster entries
  whose `listed` field is not literally `false`; a `listed: false` entry MUST remain
  resolvable by site lookup and identifier validation and MUST only be excluded from
  the roster display, never from the registry itself.
- **footer-sites-filter**: The footer site list MUST be exactly the listed-sites
  entries whose `crawlable` is not `false` and whose `adminOnly` is not `true`, in
  the same order as the listed-sites set.

### Lookup and identification

- **get-site-lookup**: Site lookup by identifier MUST return the roster entry whose
  identifier equals the argument, or nothing when no such entry exists.
- **is-site-id-derived-from-sites**: Identifier validation MUST return true if and
  only if some roster entry has that identifier; it MUST be derived from the roster
  directly rather than from a second, separately maintained list, so it can never
  diverge from the identifiers the registry actually declares.
- **dir-name-strips-tld**: The directory-name derivation (used internally by
  directory-based identification) MUST derive a site's build-tree directory name by
  stripping the trailing `.<tld>` from `prodHost` (e.g. `help.agenticdeveloperhub.com`
  → `help.agenticdeveloperhub`).
- **site-id-for-dir-bare-id-first**: Directory-based identification MUST return the
  given name unchanged (as a valid site identifier) when that name is already a
  valid site identifier, before falling back to a `prodHost`-derived directory-name
  match; it MUST return nothing when the name matches neither a site identifier nor
  any site's derived directory name.

### Family groupings

- **main-marketing-ids-are-disjoint-curated-lists**: The main-family roster and the
  marketing-family roster MUST each be a hand-curated, non-overlapping list of site
  identifiers; an identifier present in one MUST NOT appear in the other, and `mcp`
  and `builds` (which have no build-tree directory anywhere) MUST appear in neither.
- **site-categories-exactly-one-membership**: Every overview site MUST appear in
  exactly one category grouping's member list, never zero and never more than one.
- **group-by-category-preserves-order-and-collects-leftovers**: Category grouping
  MUST emit groups in the categories' declared order, with members in each group's
  declared order, MUST omit any group with no matching member among the sites being
  grouped, and MUST collect every site that matches no category into a single
  trailing group labelled "More", so that a newly scaffolded site can never be
  silently dropped from a menu built on this grouping.

### Display title

- **header-title-explicit-fulllabel-wins**: Header-title derivation MUST return a
  site's `fullLabel` when it is set, taking priority over any derivation from
  `prodHost`.
- **header-title-derives-from-apex-pattern**: When `fullLabel` is absent and
  `prodHost` matches `agenticdeveloper<x>.com`, header-title derivation MUST return
  `"Agentic Developer <X>"` with `<x>` capitalized, and MUST fall back to the site's
  `label` when `prodHost` matches neither an explicit `fullLabel` nor that pattern.
- **split-title-prefix-detection**: Header-title splitting MUST split the derived
  header title into a lead of `"Agentic Developer"` and an accent of the rest when
  the header title begins with `"Agentic Developer "`, and MUST return an empty lead
  with the whole title as accent for an off-pattern brand name (for example the
  Persona Registry).

### Environment and cross-site navigation

- **detect-env-classification**: Environment detection MUST lower-case and strip any
  trailing `:<port>` before classifying a hostname, MUST classify a hostname as
  `'local'` when it is exactly `localhost`, starts with `127.`, is `::1`, or ends in
  `.local`, `.test`, or `.localhost`; MUST classify a hostname starting with
  `testing.` as `'testing'` and one starting with `staging.` as `'staging'`; and MUST
  classify every other hostname as `'production'`.
- **host-for-env-fallback**: Environment host resolution MUST resolve
  `testing.<prodHost>` when the target environment is `'testing'` and the site has a
  testing deploy; otherwise for `'testing'` it MUST fall back to `staging.<prodHost>`
  when the site has a staging deploy, and otherwise to the bare `prodHost`. For
  `'staging'` it MUST resolve `staging.<prodHost>` when the site has a staging
  deploy and otherwise the bare `prodHost`. For `'production'` and `'local'` it MUST
  always resolve the bare `prodHost`.
- **local-origin-suite-domain-priority**: Local-origin resolution MUST first check
  whether the lower-cased, port-stripped current host ends in one of the recognized
  local suite domains (`sites.localhost`, `dev.test`, `dev.local`, checked in that
  order for readability only); when it does, the target's local origin MUST be
  `https://<sub>.<suite>.<domain>` (no subdomain for `hub`) reusing the current
  host's own `<suite>` label. When the current host matches none of the recognized
  suite domains, local-origin resolution MUST fall back to
  `http://<sub>localhost<:port>`, carrying the current port when one is present.
- **carry-path-home-only**: Path carry-over MUST return the target's landing path
  (`/`) for any path other than `/home` or a path starting with `/home/`; for the
  path `/home` it MUST return `/home` when the target exposes a home route and `/`
  otherwise; for a deeper `/home/*` path it MUST return the same path with a
  `#site-switch` marker appended (so the target's not-found page knows to walk the
  path up), or `/` when the target has no home route at all.
- **build-site-href-env-aware**: Cross-site link construction MUST classify the
  current environment via environment detection; for `'local'` and a target the local
  server runs it MUST return the local origin concatenated with the carried path; for
  every other case it MUST return `https://<resolved environment host>` concatenated
  with the carried path.
- **local-sites-list-limits-local-hops**: When the current environment is `'local'` and
  the `NEXT_PUBLIC_LOCAL_SITES` environment variable is a non-empty comma-separated
  list of site identifiers (each entry trimmed), cross-site link construction and the
  cross-site URL builder MUST resolve a target whose identifier is not in that list to
  its production host, `https://<prodHost>` followed by the path, and MUST resolve a
  target in that list to its local origin.
- **local-sites-unset-means-all**: When `NEXT_PUBLIC_LOCAL_SITES` is unset or empty, the
  local-server check MUST treat every site as served, so every local hop resolves to a
  local origin (the full local suite).
- **local-sites-read-per-call**: The local-server check MUST read
  `NEXT_PUBLIC_LOCAL_SITES` on each call, spelled out in full as
  `process.env.NEXT_PUBLIC_LOCAL_SITES`, and MUST NOT cache the value at module load.

### Cross-Site SSO Origin Allowlist (security-relevant)

- **sso-return-origins-partitioned-by-env**: The return-origin list MUST return, for
  `env === 'production'`, the bare `https://<prodHost>` origin of every roster entry
  that is neither external nor `nativeApp`; for `env === 'staging'`, only the
  `https://staging.<prodHost>` origin of every such entry with a staging deploy; for
  `env === 'testing'`, only the `https://testing.<prodHost>` origin of every such entry
  with a testing deploy.
- **sso-origins-grant-nothing-by-themselves**: A caller MUST NOT treat membership in the
  return-origin list as a grant of sign-in return or cross-origin access; the backend
  no longer trusts this list for either, and its one reader uses the list to decide
  which origins a client still holds are retired sites (an origin the list does not
  name is dropped rather than moved to an application).
- **sso-external-exclusion-fail-closed**: An origin belonging to a site marked external
  MUST NOT appear in the return-origin list's result for any environment, on a
  fail-closed basis: an origin that cannot complete an ADH login has no legitimate
  reason to be a legal `return` target, so the absence is deliberate rather than an
  oversight to fill in.
- **sso-native-app-exclusion-fail-closed**: An origin belonging to a site marked
  `nativeApp` MUST NOT appear in the return-origin list's result for any environment,
  even though its testing-deploy flag is true (a native-app site has production and
  testing deploys and no staging deploy), because such a site has no ADH backend and no
  auth-callback route.

### Hub in-workspace feature routing

- **hub-feature-segment-default-is-site-id**: The hub feature-segment map MUST map a
  routed site's identifier to the hub's own feature segment for that site's
  implementation; the default mapping is a site's own identifier, and every entry
  that maps to a different segment MUST do so for a stated reason: the hub already
  routed that feature under a different name before the site existed (`messages` to
  `messaging`, `teamregistry` to `teams`), the site's implementation lives under
  another feature (`authentication` to `tokens`, `messaging` to `integrations`,
  `ecosystems` to `products`), or the site is a copy of another (`hub-sdk` to
  `toolkit`).
- **hub-feature-segment-many-to-one-allowed**: Two or more site identifiers MAY map
  to the same feature-segment value when the hub renders one pane for both; exactly
  three such aliases exist (`ecosystems` and `products` to `'products'`, `messaging`
  and `integrations` to `'integrations'`, `hub-sdk` and `toolkit` to `'toolkit'`), any
  other duplicate segment is drift, and segment lookup by site identifier MUST return
  the shared segment for either identifier.
- **site-for-hub-segment-tiebreak**: The reverse feature-segment lookup MUST resolve
  a segment shared by more than one site to the site whose own identifier equals
  that segment when one exists (for example `'products'` resolves to the `products`
  site, not `ecosystems`); when no site's identifier equals the segment, it MUST
  resolve to whichever site's mapping was declared first in the feature-segment map.
- **hub-workspace-segments-is-the-full-union**: The full workspace-segment set MUST
  be exactly the union of every value in the feature-segment map and every entry in
  the hub-only extra segments, so a caller answering "is this second path segment a
  hub workspace feature?" never has to consult the two source lists separately.
- **hub-extra-segments-have-no-registry-site**: An entry in the hub-only extra
  segments MUST name a hub workspace feature with no corresponding registry site (a
  hub-only knob, such as an ecosystem's member list, the persona-data management
  surface, or the workspace's `ai-settings` and `jobs`; a product knob with a row on the product rail, such as `roles`,
  `signup-list`, `sets`, or `admin-site`; or a bespoke rail route such as `email-signup`); a feature that is some site's own implementation MUST be keyed in the
  feature-segment map by that site's identifier instead.

### Workspace routing

- **workspace-href-single-shape**: Workspace-link construction MUST return nothing
  when the slug is falsy (including the empty string) or when the target has no
  workspace route; otherwise it MUST return exactly `/<slug>`, the one route shape
  every site with a workspace route mounts today.
- **workspace-slug-root-sites-only**: Workspace-slug parsing MUST return nothing
  immediately when the site's workspace root is not the template root (which
  includes every hub-shaped site, i.e. the hub's own workspace root, and every site
  with no workspace route at all); it MUST NOT attempt to parse a slug out of a
  hub-shaped site's path using the template root's landing-segment set.
- **workspace-slug-excludes-landing-segments**: For a site whose workspace root is
  the template root, workspace-slug parsing MUST take the first non-empty path
  segment and return it as the slug unless that segment is a member of the
  landing-segment set, in which case it MUST return nothing, including for the
  empty-path case, which resolves to no first segment and therefore also nothing.
- **landing-and-hub-segment-sets-are-answer-specific**: The landing-segment set MUST
  be consulted only for a template-root site's first path segment, and the hub's own
  route-segment set MUST be consulted only for the hub's own first path segment; a
  caller MUST NOT answer one site's question from the other set, since the two sets
  name different words (the hub serves `/login`, `/explore`, `/settings`, which no
  template site does, and does not serve a template site's own words such as
  `/guidelines` or `/forum`).

### Per-site build configuration

- **build-fields-outside-scaffold-region**: None of the per-site build
  configuration's field names (`legacyHomePaths`, `extraRedirects`,
  `requiresBackendUrl`, `handRolledConfig`) MUST ever appear inside the roster's
  mechanically generated region; they MUST live only in the hand-written build
  configuration table outside that region, because a field written inside the
  generated region is silently dropped the next time the region is regenerated.
- **site-build-config-default-empty**: Build-configuration lookup MUST return a
  site's build configuration entry when one exists, and MUST return an empty
  result, never nothing and never a thrown error, for any site with no entry,
  since most sites need no per-site build behavior at all.
- **cookbook-and-hub-excluded-from-site-build**: `cookbook` and `hub` MUST NOT carry
  `legacyHomePaths`, `extraRedirects`, or `requiresBackendUrl` entries in the build
  configuration table; their redirect data derives from site-local modules this
  registry cannot import, and stamping a frozen copy here would recreate the drift
  those modules exist to prevent.

### Reserved slugs

- **reserved-slug-per-site-lookup**: Reserved-slug lookup MUST look up the given
  site's entry in the reserved-slug table and return true when the normalized slug
  (trimmed and lower-cased) is a member of that site's list, and false when it is
  not.
- **reserved-slug-unknown-site-fail-open**: Reserved-slug lookup MUST return false,
  never true and never throw, when the given site has no entry in the reserved-slug
  table; this fail-open behavior is a documented precondition, not a gap, at least
  one real caller passes a raw, unvalidated database column value that cannot be
  statically confirmed as a known site identifier, and that caller's own validation
  is pinned to fail open rather than reject a write for a site this registry has
  never heard of.
- **reserved-slug-normalization**: Both reserved-slug lookup and the cross-site
  reserved-slug check MUST normalize their slug argument by trimming whitespace and
  lower-casing before comparing against a reserved list, so `" Admin "` and `"admin"`
  are treated identically.
- **reserved-slug-anywhere-is-a-cross-site-or**: The cross-site reserved-slug check
  MUST return true when ANY site named in the reserved-slug table reserves the
  normalized slug, computed as the logical OR across every site's list; it MUST NOT
  answer from a single site's list alone, even on the day every list happens to be
  textually identical, because the lists are declared per-site specifically so they
  can diverge later.

- **reserved-slugs-cover-static-directories**: Each reserved-slug list MUST contain the
  name of every static top-level directory of its site's application tree, including
  that site's own entry prefix, so that a registrant is never handed a name a page of
  the site already answers for.
- **reserved-slugs-name-legal-paths**: The universal reserved list MUST contain
  `privacy-policy` and `terms-of-use`, the permanent legal paths, in addition to
  `privacy` and `terms`.
- **reserved-slugs-name-jobs**: The universal reserved list MUST contain `jobs` (phase 9), so the
  word the hub serves as a workspace feature is never handed out as a slug.

### Legal addresses

- **legal-paths-fixed**: The privacy policy path MUST be `/privacy-policy` and the terms
  of use path MUST be `/terms-of-use`.
- **legal-urls-are-hub-production**: The privacy policy URL and the terms of use URL MUST
  each be the production URL builder applied to the `hub` site and the matching legal
  path, so every site links one absolute address on the hub's production host
  regardless of the environment the linking site runs in.

### Fleet directory

- **fleet-ids-read-from-route-shares**: The marketing-fleet identifier list and the
  placeholder-fleet identifier list MUST each equal the key list of their generated
  route share, and MUST NOT be derived from the main-family or marketing-family
  rosters (the marketing-family roster still holds `research`, `docs`, and `registry`).
- **fleets-share-no-site**: A site identifier MUST NOT appear in both the marketing
  fleet and the placeholder fleet.
- **directory-sites-is-footer-less-fleets**: The directory site list MUST equal the
  footer site list, in the same order, with every marketing-fleet and
  placeholder-fleet site removed and no other site removed.

### Generated route map

- **site-route-shares-is-the-sole-roster**: The route shares MUST be the only place
  a route share is registered; adding a new region MUST be done by adding one
  share, and no other source may add a share the merged route map draws from.
- **site-routes-merges-all-shares**: The merged route map MUST be the shallow merge
  of every route share, in the shares' own declared order.
- **route-shares-keyed-only-to-family-sites**: Every identifier present across all
  route shares MUST be a valid site identifier that is a member of the main-family
  roster or the marketing-family roster; a route map MUST NOT name a site outside
  that union.
- **route-shares-are-pairwise-disjoint**: A site identifier MUST NOT appear as a key in
  more than one route share; each site's routes are owned by exactly one region's
  generator.
- **route-list-per-site-is-normalized**: Every non-empty route list inside a share
  MUST consist of absolute paths (each beginning with `/`), sorted, and free of
  duplicates.

### Brand story and guided tour

- **site-stories-total-map**: The brand-story map MUST assign exactly one brand
  story (a `tier`, a `pillar`, a `funnelStage`, and a `nextStep`) to every site
  identifier, and to no identifier outside that set; the mapping's own type MUST
  make omitting a newly scaffolded site's story a build-time error rather than a
  silent gap.
- **exactly-one-masterbrand**: Exactly one brand-story entry MUST have
  `tier: 'masterbrand'`, and it MUST be `hub`.
- **next-step-never-self-referential**: A brand-story entry's `nextStep` MUST NOT equal
  its own site identifier.
- **next-step-chains-converge-on-hub**: Following any site's `nextStep` chain
  repeatedly MUST eventually reach `hub`, for every site in the brand-story map;
  whatever door a visitor entered the family through, the brand story MUST lead back
  to the platform.
- **funnel-stage-never-empty**: Every funnel-stage value (`discover`, `learn`,
  `build`, `ship`, `adopt`) MUST be the `funnelStage` of at least one brand-story
  entry.
- **next-step-distinct-from-tour-graph**: A brand story's `nextStep` MUST be read as
  the hand-authored brand-story cross-link only; it MUST NOT be treated as
  interchangeable with an edge in the merged guided-tour graph, since the two are
  separate, independently maintained edge sets over the same site identifiers that
  happen to agree for many sites but are not guaranteed to.
- **tour-rings-are-separately-generated-and-merged**: Each of the three tour rings
  MUST be generated and maintained independently (each owned by a different region's
  own manifest), and the merged guided-tour graph MUST be their merge in a fixed
  order; a site identifier MUST NOT be declared as a key in more than one ring,
  since a collision is absorbed silently by the merge rather than caught at build
  time.
- **tour-ring-may-be-empty**: A tour ring (for example the main ring, which has
  carried no entries since 2026-08-31) legitimately being empty MUST be treated as a
  real, renderable state, "this region's generator has not populated its ring
  yet", not as an error condition.
- **get-site-story-direct-lookup**: Brand-story lookup MUST return a site's
  brand-story entry directly, with no fallback and no transformation, for any valid
  site identifier.

### Persona and cross-site URL helpers

- **persona-and-registry-paths-percent-encode-slugs**: The persona and registry path
  builders MUST percent-encode every slug segment they place into a path, since a
  slug is untrusted, registrant-supplied text placed directly into a URL path.
- **persona-profile-url-resolves-current-env**: The persona profile URL builder MUST
  resolve the persona registry's current-environment absolute URL via the cross-site
  URL builder, using the current environment's hostname when one is available and an
  empty string otherwise (this concept is also evaluated in a context with no
  ambient page/window, so it MUST NOT read that hostname from any global page state
  directly).
- **site-url-falls-back-to-bare-path**: The cross-site URL builder MUST return the
  path unchanged when the given site identifier resolves to no known site (via site
  lookup), rather than throwing or returning a malformed URL.
- **site-prod-url-ignores-current-environment**: The production URL builder MUST
  always resolve `https://<prodHost><path>` regardless of the caller's current
  environment, since it exists specifically as the deterministic server-rendered
  default computed before the client's own hostname is known.
- **site-home-path-fallback**: The home-path fallback MUST return `/home` when the
  site's `hasHome` is `true`, and `/` otherwise.

## Appearance

Not applicable: this is the site family's data registry and routing-resolution module, not a visual component.

## States

Not applicable: this is the site family's data registry and routing-resolution module, not a visual component.

## Accessibility

Not applicable: this is the site family's data registry and routing-resolution module, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| site-registry-001 | detect-env-classification | Classifying hosts `agenticdeveloperhub.com`, `testing.agenticdeveloperhub.com`, `staging.admin.agenticdeveloperhub.com`, `admin.localhost` (traced to `registry.test.ts`'s "classifies production hosts", "classifies testing / staging by leading label", and "classifies local hosts (localhost, 127.*, *.local, *.test, *.localhost, ports)") | `'production'`, `'testing'`, `'staging'`, `'local'` respectively |
| site-registry-002 | host-for-env-fallback, build-site-href-env-aware | Building a cross-site link to the `mcp` site (no testing deploy) from host `testing.agenticdeveloperhub.com`, path `/` (traced to "falls back testing → staging when the target lacks a testing env") | `'https://staging.mcp.agenticdeveloperhub.com/'` |
| site-registry-003 | carry-path-home-only | Building a cross-site link to `hub` from host `agenticdeveloperhub.com`, path `/home/foo` (traced to "carries deep /home routes with the up-walk marker") | `'https://agenticdeveloperhub.com/home/foo#site-switch'` |
| site-registry-004 | carry-path-home-only | Building a cross-site link to `hub-help` (no home route) from host `agenticdeveloperhub.com`, path `/home` (traced to "sends /home to root for sites without a /home route") | `'https://help.agenticdeveloperhub.com/'` |
| site-registry-005 | local-origin-suite-domain-priority | Building a cross-site link to `cookbook` from host `localhost`, path `/home` (traced to "resolves to a local origin from local dev (bare localhost, no port)") | `'http://cookbook.localhost/home'` |
| site-registry-006 | sso-return-origins-partitioned-by-env, sso-external-exclusion-fail-closed | Computing the return-origin list for `'production'` (traced to "production = every ADH app site as a bare-host origin (no env prefix)" and "never allows an external link-out origin, in any env") | Includes `https://<prodHost>` for every site that is neither external nor `nativeApp`; never includes `fishlamp`'s, `fishlampdesign`'s, `kitchen`'s, or `stenographer`'s origin |
| site-registry-007 | sso-return-origins-partitioned-by-env | Computing the return-origin list for `'testing'` (traced to "testing = only sites with a testing deploy, prefixed testing.") | Includes exactly the `https://testing.<prodHost>` origin of every non-excluded site with a testing deploy, and no others |
| site-registry-008 | sso-return-origins-partitioned-by-env | Computing the return-origin list for `'staging'` (traced to "staging = every staging-deploy site, prefixed staging.") | Includes exactly the `https://staging.<prodHost>` origin of every non-excluded site with a staging deploy, and no others |
| site-registry-009 | workspace-href-single-shape | Building the workspace link for slug `'acme'`, for every site with a workspace route, including the two sites whose workspace once nested under a different shape (traced to "builds `/<slug>` for every site with a workspace, including the two that once differed") | `'/acme'` for every one of them |
| site-registry-010 | workspace-href-single-shape | Building the workspace link for an empty slug (traced to "returns undefined for an empty slug rather than minting `//`") | Nothing |
| site-registry-011 | workspace-slug-root-sites-only | Parsing a workspace slug from path `/acme` on the hub, whose workspace root is the hub shape (traced to "refuses the hub rather than parsing it with the template's landing set") | Nothing |
| site-registry-012 | workspace-slug-excludes-landing-segments | Parsing a workspace slug from path `/guidelines` on `cookbook`, where `'guidelines'` is a member of the landing-segment set (traced to "returns null on a landing path, so nothing public is carried as a workspace") | Nothing |
| site-registry-013 | workspace-slug-excludes-landing-segments | Parsing a workspace slug from path `/home` on `cookbook` (traced to "returns null on `/home`, which is the redirect signal and carries no slug") | Nothing |
| site-registry-014 | landing-and-hub-segment-sets-are-answer-specific | Every real static top-level route of every template-root site, compared against the landing-segment set; the hub's own static top-level routes compared against the hub's own route-segment set (traced to "covers every static top-level route of every 'root' site" and "equals the hub's static top-level routes, in both directions") | Both comparisons match exactly, in both directions |
| site-registry-015 | site-for-hub-segment-tiebreak | Resolving the site owning hub segment `'products'`, which both `ecosystems` and `products` map to in the feature-segment map (traced to "names the documented winner for each shared segment, and the site itself for the rest") | The `products` site (not `ecosystems`) |
| site-registry-016 | build-fields-outside-scaffold-region | The raw roster source text inside its mechanically generated region (traced to `build-fields.test.ts`'s "keeps build fields out of the scaffold-managed region") | Contains none of `legacyHomePaths`, `extraRedirects`, `requiresBackendUrl`, `handRolledConfig` |
| site-registry-017 | site-build-config-default-empty | Sites in the build configuration table with `requiresBackendUrl` set (traced to "marks exactly the five backend-fronting sites as requiring a backend url") | Exactly `['billing', 'bitbag', 'narratives', 'personaregistry', 'projects']` |
| site-registry-018 | reserved-slug-unknown-site-fail-open | Checking whether `'anything'` is reserved for `hub`, which has no entry in the reserved-slug table (traced to `reserved-slugs.test.ts`'s documented unknown-site case) | `false` |
| site-registry-019 | reserved-slug-anywhere-is-a-cross-site-or | Checking whether a slug is reserved anywhere, with a reservation temporarily injected on one site only, then removed (traced to "is the OR across sites, not one site's list") | `true` while the injected reservation exists |
| site-registry-020 | route-shares-keyed-only-to-family-sites, route-shares-are-pairwise-disjoint | The identifier set across all route shares (traced to `siteRoutes.test.ts`'s "keys only registry family sites, so the SiteId typing stays honest" and "gives every site to exactly one share") | Every identifier is a member of the main-family or marketing-family roster; no identifier repeated across two shares, and the merged map holds exactly the sum of the shares' keys |
| site-registry-021 | route-list-per-site-is-normalized | Every non-empty route list in every share (traced to "lists absolute, sorted, deduplicated paths per site") | Every path begins with `/`; each site's list is sorted and contains no duplicate |
| site-registry-022 | site-stories-total-map, next-step-never-self-referential | The brand-story map's keys against the site identifier set, and every entry's `nextStep` against its own identifier (traced to `story.test.ts`'s "covers every registered site (and nothing else)" and "never points a next step at the site itself") | Key sets match exactly; no entry's `nextStep` equals its own identifier |
| site-registry-023 | next-step-chains-converge-on-hub | Every site's `nextStep` chain, followed repeatedly (traced to "every next-step chain converges on the hub") | Every chain reaches `hub` |
| site-registry-024 | tour-rings-are-separately-generated-and-merged | The three tour rings' key sets (traced to `tour-region.test.ts`'s ring-disjointness assertions) | Pairwise disjoint; every edge names a real site identifier on both ends; no self-pointing edge |
| site-registry-025 | sso-native-app-exclusion-fail-closed, native-app-site-flag | Computing the return-origin list for each of `'production'`, `'staging'`, and `'testing'`, and listing the `nativeApp` sites (traced to `registry.test.ts`'s "never allows a native-app site origin, in any env" and "keeps native-app sites out of the ADH app rosters") | `nativeApp` sites are exactly `['kitchen', 'stenographer']`; neither origin appears in any environment; neither id is in the main-family or marketing-family roster |
| site-registry-026 | local-sites-list-limits-local-hops | Building a link to `cookbook` from host `hub-site-menu2.sites.localhost`, path `/`, with `NEXT_PUBLIC_LOCAL_SITES` set to `hub` (traced to "local hops to a site the local server does not run go to the production host") | `'https://agenticdevelopercookbook.com/'` |
| site-registry-027 | local-sites-list-limits-local-hops | Building a link to `cookbook` from the same host, with `NEXT_PUBLIC_LOCAL_SITES` set to `hub, cookbook` (traced to "stay local for a site on the list") | `'https://cookbook.hub-site-menu2.sites.localhost/'` |
| site-registry-028 | local-sites-unset-means-all | Building a link to `cookbook` from the same host, with `NEXT_PUBLIC_LOCAL_SITES` set to the empty string (traced to "stay local for every site when the list is unset (the full suite)") | `'https://cookbook.hub-site-menu2.sites.localhost/'` |
| site-registry-029 | local-sites-list-limits-local-hops | Calling the cross-site URL builder for `cookbook`, path `/x`, from the same host, with the list set to `hub` (traced to "go to the production host") | `'https://agenticdevelopercookbook.com/x'` |
| site-registry-030 | fleets-share-no-site, fleet-ids-read-from-route-shares | The marketing-fleet and placeholder-fleet identifier lists (traced to `fleets.test.ts`'s "are both read off a populated route share" and "share no site") | Both lists are non-empty; their intersection is empty |
| site-registry-031 | directory-sites-is-footer-less-fleets | The directory site list against the footer site list less both fleets (traced to "is FOOTER_SITES in the same order, less only those fleets", "links no marketing deck and no placeholder", and "keeps the working sites") | Same identifiers in the same order; contains `hub`, `bitbag`, `research`, `shipr`, and `fishlamp` |
| site-registry-032 | legal-paths-fixed, legal-urls-are-hub-production | The two legal paths and the two legal URLs (derived from `legal.ts`; no test in this package exercises it) | `'/privacy-policy'`, `'/terms-of-use'`, `'https://agenticdeveloperhub.com/privacy-policy'`, `'https://agenticdeveloperhub.com/terms-of-use'` |
| site-registry-033 | reserved-slugs-cover-static-directories, reserved-slugs-name-legal-paths | For every reserving site whose application directory is present, every static segment on disk checked against the reserved list (traced to `reserved-slugs.test.ts`'s "reserves every static segment its app/ dir actually has"); the universal list checked for the legal paths (derived from `reserved-slugs.ts`) | Every on-disk segment is reserved; `privacy-policy` and `terms-of-use` are reserved |
| site-registry-034 | reserved-slug-normalization, reserved-slug-per-site-lookup | Checking `'Tour'` and `'TOUR'` against the `registries` list, and `'fishlamp'` against the `registries` list (traced to "is case-insensitive" and "does not reserve an ordinary slug") | `true` for both `'Tour'` and `'TOUR'`; `false` for `'fishlamp'` |
| site-registry-035 | hub-workspace-segments-is-the-full-union, hub-extra-segments-have-no-registry-site | Whether every hub-only extra segment is a member of the full workspace-segment set (traced to "contributes every segment to HUB_WORKSPACE_SEGMENTS") | Every extra segment, including `roles`, `signup-list`, `sets`, and `email-signup`, is a member |
| site-registry-036 | site-id-closed-union, is-site-id-derived-from-sites | Calling identifier validation on a real site id and on a directory name that is not a site (traced to `build-fields.test.ts`'s "isSiteId accepts a real id and rejects a directory that is not a site") | `true` for the real id; `false` for the non-site directory name |
| site-registry-037 | unique-site-ids, site-def-minimum-fields | The roster's identifiers, labels, and production hosts (traced to `registry.test.ts`'s "has unique ids and excludes the backend" and "every site has a label and a production host") | No identifier repeats; no entry names the backend service; every entry has a non-empty label and production host |
| site-registry-038 | workspace-route-not-derived-from-has-home | Each site's workspace-route field compared with the route tree of its site folder (traced to "workspaceRoute matches the route tree for every site folder", and, for the sites no route tree in the checkout decides, to the unconditional "workspaceRoute and hasHome are pinned literally for the sites no route tree here decides") | Every field matches its route tree, independent of `hasHome`; `bitbag`, `status`, and `admin` have no workspace route; `myagenticdevteam` has `hasHome: true` and no workspace route |
| site-registry-039 | external-site-excluded-from-sso | Listing the sites marked external, then computing the return-origin list for each environment (traced to "never allows an external link-out origin, in any env") | External sites are exactly `['fishlamp', 'fishlampdesign']`; neither host appears in any environment's list |
| site-registry-040 | admin-only-derives-admin-ids-and-drops-footer | The footer site list against the admin-only id set (traced to "drops the admin-only consoles, which stay on the roster" and "lists admin + status but still hides the unlisted registry entries") | No admin-only id appears in the footer site list; every admin-only id is in the admin-only id set |
| site-registry-041 | listed-sites-filter | Looking up a site registered with `listed: false`, then checking the listed-sites set (traced to "keeps the folded sites registered but out of the switcher") | The lookup returns the entry; the listed-sites set omits it |
| site-registry-042 | footer-sites-filter | The footer site list for the `mcp` site, which is not crawlable (traced to "excludes the non-HTML mcp endpoint and the delisted sites, but keeps the content sites") | `mcp` is absent; the remaining entries keep the listed-sites order |
| site-registry-043 | get-site-lookup | Looking up `hub`, then looking up an identifier for no site (derived from source; `getSite('hub')` is exercised by "splitSiteTitle splits the brand lead from the accent") | The `hub` entry; nothing for the unknown identifier |
| site-registry-044 | dir-name-strips-tld, site-id-for-dir-bare-id-first | Directory-based identification of a domain-shaped folder, of a bare site id, and of a name matching neither (traced to `registry.test.ts`'s "maps a domain-shaped folder to its id", "still answers for a bare id", and "is undefined for anything that is not a site") | The matching site id; the bare id unchanged; nothing |
| site-registry-045 | main-marketing-ids-are-disjoint-curated-lists | The main-family and marketing-family rosters (traced to "every family id is a real registry site, with no dupes or cross-family overlap") | Every id is a real site; no duplicate; no id in both rosters; `mcp` and `builds` in neither |
| site-registry-046 | site-categories-exactly-one-membership | The category member lists against the overview sites (traced to "covers every overview site exactly once (no orphans, no dupes)") | Each overview site appears in exactly one category |
| site-registry-047 | group-by-category-preserves-order-and-collects-leftovers | Grouping the overview sites by category (traced to "mirrors the site menu: same labels, same order..."; the trailing group named "More" is derived from source, with no test) | Groups in declared order with members in declared order; a site matching no category lands in the trailing "More" group |
| site-registry-048 | header-title-explicit-fulllabel-wins, header-title-derives-from-apex-pattern | Header-title derivation for `hub`, which has a `fullLabel`; and for a site with no `fullLabel` whose host is `agenticdeveloper<x>.com` (the second case is derived from source; no test pins it) | `'Agentic Developer Hub'`; `'Agentic Developer <X>'` with `<x>` capitalized |
| site-registry-049 | split-title-prefix-detection | Splitting the header title of `hub` (traced to `registry-characterisation.test.ts`'s "splitSiteTitle splits the brand lead from the accent") | Lead `'Agentic Developer'`, accent `'Hub'`; an off-pattern brand name such as the Persona Registry gives an empty lead (derived from source) |
| site-registry-050 | local-sites-read-per-call | Building the same link three times with `NEXT_PUBLIC_LOCAL_SITES` stubbed to `hub`, then `hub, cookbook`, then the empty string (traced to the three cases in "local hops to a site the local server does not run") | Production host, then local origin, then local origin: each call reflects the value at call time |
| site-registry-051 | sso-origins-grant-nothing-by-themselves | A site's production origin appearing in the return-origin list (derived from the source comment on `ssoReturnOrigins`; no test pins it) | Appearance means only that the origin names a real, current site; no sign-in return or cross-origin access is derived from it |
| site-registry-052 | hub-feature-segment-default-is-site-id, hub-feature-segment-many-to-one-allowed | Every entry of the feature-segment map, including `ecosystems` and `products` (traced to "maps only real registry sites, to bare feature segments (one site per segment, except the documented products alias)" and "names the documented winner for each shared segment, and the site itself for the rest") | Every key is a real site; the only shared segments are `products` (`ecosystems`, `products`), `integrations` (`integrations`, `messaging`), and `toolkit` (`hub-sdk`, `toolkit`); `products` resolves to `products` and `integrations` to `integrations` |
| site-registry-053 | cookbook-and-hub-excluded-from-site-build | The build table's entries carrying `legacyHomePaths` (traced to `build-fields.test.ts`'s "marks exactly the eight registry-owned legacy-home-path sites") | Exactly `dashboards`, `ecosystems`, `knowledgebases`, `narratives`, `personabuilder`, `projects`, `research`, `teamregistry`; neither `cookbook` nor `hub` |
| site-registry-054 | site-route-shares-is-the-sole-roster, site-routes-merges-all-shares | The merged route map against every share file on disk (traced to `siteRoutes.test.ts`'s "merges every share file that exists on disk") | The merged map holds exactly the union of every share's keys and routes |
| site-registry-055 | exactly-one-masterbrand | Counting brand-story entries whose tier is `masterbrand` (traced to `story.test.ts`'s "has exactly one masterbrand, and it is the hub") | Exactly one entry, for `hub` |
| site-registry-056 | funnel-stage-never-empty | The funnel stage of every brand-story entry (traced to "leaves no funnel stage empty") | Each of `discover`, `learn`, `build`, `ship`, `adopt` is held by at least one entry |
| site-registry-057 | next-step-distinct-from-tour-graph, tour-ring-may-be-empty | The merged tour graph's rings, including the main ring (traced to `tour-region.test.ts`'s "is a walk that is actually turned on, in every ring that owns one"; no test compares brand `nextStep` with tour edges) | The empty main ring is accepted as a valid state; brand `nextStep` and tour edges are read as separate maps |
| site-registry-058 | get-site-story-direct-lookup | Brand-story lookup for every registered site (traced to "covers every registered site (and nothing else)") | The entry stored for that identifier, unchanged |
| site-registry-059 | persona-and-registry-paths-percent-encode-slugs, persona-profile-url-resolves-current-env | Building a persona profile URL and each registry path from a handle containing reserved characters (traced to "personaProfileUrl percent-encodes the slug onto the persona registry" and "every registry path helper percent-encodes its handle") | Each handle is percent-encoded as the whole path; the URL lands on the persona registry site in the current environment |
| site-registry-060 | site-url-falls-back-to-bare-path | The cross-site URL builder for an identifier that is not a site, path `/x`, host `agenticdeveloperhub.com` (traced to "siteUrl falls through to the raw path for an unknown id") | `'/x'` |
| site-registry-061 | site-prod-url-ignores-current-environment | The production URL builder for `hub`, path `/` (traced to "siteProdUrl is host-independent and always https") | `'https://agenticdeveloperhub.com/'` |
| site-registry-062 | site-home-path-fallback | The home path for `hub` (traced to "siteHomePath is /home only for sites that expose one") | `'/home'` when `hasHome` is true; `'/'` otherwise |
| site-registry-063 | product-admin-site-registered | The `product-admin` site's definition, the main-family roster, the footer list and the family roster's tail (traced to "registers the product admin site: its folder, not crawlable, admin-gated, a main app") | Its production host is `product-admin.agenticdeveloperhub.com`; the directory name `product-admin.agenticdeveloperhub` identifies it; it is not crawlable; it is in the admin-only ids and the main-family roster and not in the footer list; the roster ends `status`, `admin`, `product-admin`, `builds` |
| site-registry-064 | support-routes-in-shares | The `hub`, `product-admin` and `admin` route shares | `/support` is in the first two, `/break-glass`, `/support-access` and `/support-grants` are in `admin`, and the website generator's `--check` reports no drift |
| site-registry-065 | ai-settings-extra-segment | The hub-only extra segments and the hub workspace segments, for `ai-settings` (traced to `registry.test.ts`'s "lists ai-settings among the hub extra feature segments") | The extra-segments list contains `ai-settings`, and it is a hub workspace segment |
| site-registry-066 | legacy-provider-segments-redirect-only | The hub-only extra segments, for `llm-providers` and `persona-services` (traced to "keeps llm-providers and persona-services, which redirect to it until Cleanup"; that test checks the extra-segments list only, and every extra segment is a hub workspace segment by construction) | The extra-segments list still contains both, and both are still hub workspace segments |
| site-registry-067 | ai-settings-hub-route-line | The `hub` route share | It contains `/[workspace]/ai-settings/[[...path]]` in sorted place, still contains the `llm-providers` and `persona-services` workspace lines, and has no `/ai-settings`, and the website generator's `--check` reports no drift |
| site-registry-068 | admin-share-no-ai-settings | The `admin` route share | It still has `/llm-providers` and has no `/ai-settings` |
| site-registry-069 | jobs-extra-segment, jobs-sub-paths-not-segments | The hub-only extra segments and the hub workspace segments | `jobs` is in both; neither contains `jobs/templates`, `jobs/environments`, `templates` or `environments` |
| site-registry-070 | jobs-hub-route-line | The `hub` route share | It contains `/[workspace]/jobs/[[...path]]` in sorted place, and the website generator's `--check` reports no drift |
| site-registry-071 | product-admin-share-jobs | The `product-admin` route share | It contains `/jobs`, `/jobs/templates` and `/jobs/templates/[templateId]` in sorted place, and the product admin rail's test still finds every rail href in the share |
| site-registry-072 | admin-share-no-jobs | The `admin` route share | It has no `/jobs` line |
| site-registry-073 | reserved-slugs-name-jobs, reserved-slug-normalization | Checking `'jobs'` and `' Jobs '` against the `registries` list, and `'jobs'` with the cross-site check | `true` for all three |
## Edge Cases

- **Null and empty input** (MUST): Building the workspace link for an empty slug
  returns nothing rather than minting `//` (workspace-href-single-shape). Parsing a
  workspace slug for an empty path resolves the path to `/`, whose first segment is
  empty, and therefore returns nothing. The cross-site URL builder, for a site
  identifier not present in the roster, returns the given path unmodified rather than
  throwing. An unset or empty `NEXT_PUBLIC_LOCAL_SITES` means every site is served
  locally (local-sites-unset-means-all). A blank or unknown site passed to reserved-slug
  lookup answers false (reserved-slug-unknown-site-fail-open).
- **Boundary values** (MUST): A site with no testing deploy and no staging deploy (a
  production-only site) resolves to its bare `prodHost` from every non-local
  environment, because environment host resolution's two-level fallback ends on the
  bare host, never on nothing. A site definition with neither a workspace route nor a
  home route is a valid, fully supported shape (an operations console such as `admin`,
  `status`, or `bitbag`), so the absence of both is not itself an inconsistency to
  flag. Nor is a home route without a workspace route (`myagenticdevteam`, a
  coming-soon placeholder whose only signed-in surface is a gated `/home`): a home
  route never implies a workspace route. A site marked `nativeApp` carries a true testing-deploy flag
  yet is excluded from every return-origin list, so the flags
  alone never decide membership.
- **Concurrent access** (not applicable): This registry is synchronous and stateless.
  Every value is computed once when the registry loads and every operation is a pure
  function over that data, with no shared mutable state written at runtime, so there
  is no interleaving for two callers reading the site roster, the merged route map, or
  the merged guided-tour graph at once to race against. The one runtime input, the
  local-sites environment variable, is read per call and never written here.
- **Error states, a shared hub feature segment with no clear owner** (SHOULD): The
  reverse feature-segment lookup's tie-break (site-for-hub-segment-tiebreak) resolves
  deterministically by "does the site's own identifier equal the segment," but a
  future segment shared by two sites where neither site's identifier equals the
  segment resolves to whichever site's feature-segment entry was declared first in
  source order; a new shared segment SHOULD therefore be given an owner whose
  identifier equals it. This is a documented convention, not an oversight.
- **Error states, a route share whose generator has not run yet in this checkout**
  (MUST): A region's generated route share can legitimately be empty in a checkout
  whose own region generator has not run yet. A dedicated check's own fill-expectation
  table names `main` as the one region currently expected to be empty, and any other
  region going empty without an entry in that table is what the "has every share
  filled in" check exists to catch. An empty share contributes no fleet members, so a
  fleet whose share is empty yields an empty fleet list.
- **Error states, a local hop to a site the local server does not run** (MUST): With
  `NEXT_PUBLIC_LOCAL_SITES` naming only some sites, a hop to a site off the list
  resolves to its production host rather than to a local host nothing answers
  (local-sites-list-limits-local-hops).
- **Offline or disconnected state** (not applicable): Every part of this component
  performs only synchronous, local computation over in-memory constants and one
  environment-variable read; none of it makes a network request.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| The site roster | list of site definitions | fixed at build time | The whole family roster; not caller-configurable at runtime, a new site is added by editing the registry (its mechanically generated region for the mechanically-added fields, or the hand-authored part directly). |
| The hostname (environment detection, the cross-site URL builder, the persona profile URL builder) | string | caller-supplied; the persona profile URL builder defaults to the current environment's hostname when available, else an empty string | The current request/browser host, used to resolve which deploy environment and, for local dev, which suite the caller is on. |
| The current hostname / path (cross-site link construction) | string | caller-supplied; required | The visitor's current host and path, used to resolve the target site's href in the same environment and to decide whether `/home` is carried. |
| `NEXT_PUBLIC_LOCAL_SITES` (environment variable) | comma-separated list of site identifiers | unset, meaning every site is served locally | The site identifiers the local server actually runs; a local hop to any other site resolves to its production host. |
| The recognized local suite domains | fixed list of strings (internal constant) | `['sites.localhost', 'dev.test', 'dev.local']` | The domain suffixes recognized as a local-suite host; not caller-configurable. |
| The environment (the OAuth return-origin allowlist) | one of `'production'`, `'staging'`, `'testing'` | caller-supplied; required | Which deploy environment's OAuth-return-origin allowlist to compute. |
| The build configuration table | optional build configuration entry per site identifier | fixed at build time | Per-site build behavior flags read by the shared build-configuration package; not caller-configurable at runtime. |

## Deep Linking

Not applicable: this component defines no URL scheme, route handler, or navigation target of its own. It is the data other code reads to build one; the two legal paths are names the hub mounts, not routes this component serves.

## Localization

Each site definition carries hardcoded English `label`, `fullLabel`, `shortLabel`,
and `description` strings for every site (for example `"The Agentic Developer Hub"`,
`"Recipes & patterns"`), and header-title derivation's `"Agentic Developer <X>"`
title is built from the same hardcoded English convention. None of these strings is
routed through any localization or string-catalog layer in this component; a
translated build of the switcher, footer, or header would need its own separate
string source, since this registry supplies only the one, English, copy.

## Accessibility Options

Not applicable: this component has no UI of its own, so it responds to no Reduce
Motion, Increase Contrast, or Differentiate Without Color setting.

## Feature Flags

Not applicable: no part of this component declares or reads a feature-flag key. A site definition's `featured` field is a display-order marker for the switcher, not a feature gate, and nothing renders it today. `NEXT_PUBLIC_LOCAL_SITES` is a local-server setting documented under Configuration, not a flag.

## Analytics

Not applicable: no part of this component emits an analytics or event-tracking call.

## Privacy

- **Data collected**: This component reads and returns only site metadata (ids,
  labels, hosts, environment flags, route lists, brand-story classifications) that
  is itself source-controlled configuration, not user data. The persona and registry
  path builders accept a caller-supplied slug (a public handle a registrant chose)
  and percent-encode it into a path; no credential, token, or other secret value is
  read or handled anywhere in this component. The legal URLs are fixed public addresses.
- **Storage**: This component persists nothing at runtime; every value is either a
  constant computed once at load or the result of a pure function with no side
  effect.
- **Transmission**: Not applicable: this component performs no networking of its
  own. The return-origin list's output is consumed by a separate process elsewhere;
  that transmission is outside this component.
- **Retention**: Not applicable: nothing here is retained beyond the lifetime of
  the process that loaded the registry.

## Logging

Not applicable: no part of this component makes a logging call of any kind; every
function either returns a computed value or returns a documented fallback (nothing,
an empty result, or the input path unchanged) with no side channel.

## Platform Notes

- **SwiftUI**: No SwiftUI dependency exists in the source. A SwiftUI consumer would
  typically expose the registry's derived collections (the listed-sites set, the
  footer site list, the directory site list, category grouping's output) as plain
  `let` properties on an `@Observable` view model computed once at init, since none of
  the underlying data changes during a running process. The local-sites setting would
  come from `ProcessInfo.processInfo.environment`.
- **Compose**: A Kotlin port would model the site identifier type as a `sealed
  interface` or `enum class` rather than a string-literal union (closer to identifier
  validation's narrowing contract than TypeScript's own union erasure), a site
  definition and a brand story as `data class`es, and the derived `Set` and `Map`
  constants (the landing-segment set, the full workspace-segment set, the merged
  guided-tour graph, the fleet lists) as `kotlinx.collections.immutable` structures
  built once at object-initialization time, mirroring this module's compute-once-at-load
  pattern. The local-sites setting would come from `System.getenv`.
- **React/Web**: This is the source. The implementation lives under
  `packages/web/packages/adh-registry/src/sites/`: `registry.ts`, `reserved-slugs.ts`,
  `legal.ts`, `fleets.ts`, `story.ts`, the `routes.*.generated.ts` shares, and
  the hand-written `routes.generated.ts`, which declares `SITE_ROUTE_SHARES` and merges its values with
  `Object.assign` into `SITE_ROUTES`. `registry.ts` declares the `SiteId` union and
  the `SiteDef` shape (including the `nativeApp`, `featured`, `listed`, and
  `publicWorkspaceSegment` fields), the `SITES` array, environment and host resolution
  (`detectEnv`, `hostForEnv`, `localOrigin`, `servedLocally`, `buildSiteHref`,
  `siteUrl`), the hub's feature-segment map (`HUB_FEATURE_SEGMENT`,
  `SITE_FOR_HUB_SEGMENT`, `HUB_EXTRA_FEATURE_SEGMENTS`, `HUB_WORKSPACE_SEGMENTS`), the
  workspace-slug round trip (`siteWorkspaceHref` and `siteWorkspaceSlug` plus
  `SITE_LANDING_SEGMENTS` and `HUB_ROUTE_SEGMENTS`), the per-site build table
  (`SITE_BUILD` and `siteBuildConfig`) kept outside the file's `<gen:sites>` region, and
  `ssoReturnOrigins`. The phase-6 `product-admin` site is one `SITES` row (`adminOnly`,
  `crawlable: false`), one `SITE_BUILD` entry (`handRolledConfig: true`), one entry in
  `MAIN_SITE_IDS`, one `SITE_STORIES` entry in `story.ts` (a `chapter` of the `backend`
  pillar, like `admin`), and `admin-site` in `HUB_EXTRA_FEATURE_SEGMENTS`, which phase 8 extends with `ai-settings` (keeping `llm-providers` and `persona-services` as redirect-only segments, with a source comment beside them saying they redirect until Cleanup), and the `hub` share in `routes.hub.generated.ts` carries its `/[workspace]/ai-settings/[[...path]]` line;
  phase 9 adds `jobs` to `HUB_EXTRA_FEATURE_SEGMENTS` (its `templates` and `environments` pages are sub-paths of the one `/[workspace]/jobs/[[...path]]` line), `/jobs`, `/jobs/templates` and `/jobs/templates/[templateId]` to the `product-admin` share, and `jobs` to the `UNIVERSAL` reserved list; its
  `devDependencies` carry `@adh-sdk/product-admin` for the one test that holds that
  package's rail equal to the site's share of the route table. `reserved-slugs.ts` holds `RESERVED_SLUGS`, `isReservedSlug`, and
  `isReservedSlugAnywhere`. The support routes of
  **support-routes-in-shares** sit in `routes.hub.generated.ts` and are written in the
  SDK by hand, because the generator runs only in the website, which proves them with
  the generator's `--check`. `legal.ts` holds the privacy and terms paths and URLs.
  `fleets.ts` holds `MARKETING_FLEET_SITE_IDS`, `PLACEHOLDER_FLEET_SITE_IDS`, and
  `DIRECTORY_SITES`. `story.ts` holds `SITE_STORIES`, `getSiteStory`, and the three
  generated rings `TOUR_MAIN`, `TOUR_MARKETING`, and `TOUR_PLACEHOLDER` merged by object
  spread into `SITE_TOUR_NEXT`. A site's build-tree directory name is a Next.js
  app-router folder derived by `dirNameOf`; a site's workspace route is a Next.js
  `app/[workspace]` dynamic route. `servedLocally` reads
  `process.env.NEXT_PUBLIC_LOCAL_SITES` spelled out in full, because Next inlines a
  `process.env.NEXT_PUBLIC_*` reference only where the literal text appears.
  `personaProfileUrl` reads the current hostname from
  `globalThis.location?.hostname ?? ''` rather than `window`, because this file is also
  type-checked in a backend build with no DOM library. The files are pure TypeScript
  with no React import, consumed by React components (the header, switcher, and footer)
  elsewhere in the same web packages; a caller re-implementing this in another JS or TS
  codebase should keep the same pure-data, pure-function shape rather than folding any of
  it into a component or a hook, since several exports (`ssoReturnOrigins`, the route
  shares) are consumed by non-React code that would break if the logic moved into a
  component. Nothing in the module uses `async` or `Promise`, and the only runtime input
  is the environment variable.
- **AppKit / UIKit**: These are TypeScript and web sources with no Apple-framework
  dependency. A macOS or iOS port would model a site definition and a brand story as
  `Codable` `struct`s, the site roster and the brand-story map as `static let` constants
  (loaded from a bundled JSON or a generated Swift file rather than re-typed by hand),
  and environment detection, cross-site link construction, and the return-origin list as
  pure functions over `URLComponents` and `String`, with no `NSObject` subclassing
  needed anywhere. Kitchen and Stenographer, the two `nativeApp` sites, are themselves
  macOS tools, so a port inside them would use the legal URLs as plain `URL` constants
  opened with `NSWorkspace` or `UIApplication`.
- **WinUI 3**: A .NET port would model the site identifier type as an `enum`, a site
  definition and a brand story as `record`s (immutable by default, matching this
  module's `readonly` shape), and the derived set and map constants as `FrozenSet<string>`
  and `FrozenDictionary<TKey, TValue>` built once in a static constructor. Environment
  detection, host resolution, and local-origin resolution become pure `static` methods
  over `Uri` and `string`, and the local-sites setting is read with
  `Environment.GetEnvironmentVariable` on each call. `System.Text.Json` would
  deserialize the roster if it shipped as a generated JSON asset, and that asset, if
  packaged with the app, would be read once at startup with `Windows.Storage` (for
  example `StorageFile.GetFileFromApplicationUriAsync`) inside a `Task`-returning
  `async` initializer, which is the one place this port differs from the source, where
  every export is synchronous. `HttpClient` is not needed, since nothing here performs a
  network call, and `ObservableCollection` and `INotifyPropertyChanged` are not needed,
  since no value changes after process start; a view model that binds the footer
  directory can expose a plain `IReadOnlyList<SiteDef>`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/adh-registry/src/sites/` | confirmed (1.6.1) |

## Design Decisions

**Decision**: The per-site build configuration fields (`legacyHomePaths`,
`extraRedirects`, `requiresBackendUrl`, `handRolledConfig`) live in a separate build
configuration table below the roster's mechanically generated region, rather than as
optional fields on a site definition inside that region.
**Rationale**: Most roster entries live inside the scaffolded region, which the
scaffolding tool regenerates wholesale from a fixed template blind to any field not
in that template. A hand-authored field written on a roster entry inside the region
would be silently dropped, with no error and no failing test, the next time the tool
regenerates it. Keeping the data in a table physically outside the region makes that
impossible rather than merely discouraged. Applies to the web implementation, where
the roster has a scaffolded region at all.
**Approved**: pending

**Decision**: A site's workspace-route field records only whether a site mounts a
workspace route and, for the two roots that exist ("root" and "hub"), which root,
not the historical per-site nested shape (`/home/<slug>`, `/<slug>/home`) that an
earlier rollout once required.
**Rationale**: Every site that mounts a workspace route now mounts the identical
`/<slug>` shape; the remaining distinction is not the URL shape but which set of
static top-level segments (the landing-segment set vs. the hub's own route-segment
set) tells a slug apart from a page on that root, which is exactly what the
two-valued field, plus the two segment sets, needs to express.
**Approved**: pending

**Decision**: The return-origin list is computed fresh from the staging-deploy,
testing-deploy, external, and `nativeApp` flags on every call rather than cached, and
it excludes external and `nativeApp` sites in every environment.
**Rationale**: The computation has no side effect, so recomputing is safe. The
exclusions are fail-closed on purpose: an origin that cannot complete an ADH login has
no reason to be a legal `return` target, and a `nativeApp` site's testing flag
is true (it is deployed) so the flags alone would list it. The list's one reader drops
any origin the list does not name as a retired site, so listing an origin that is
not a live ADH login site would keep it alive; the exclusion is kept absolute.
**Approved**: pending

**Decision**: The marketing-fleet and placeholder-fleet identifier lists are read off
their generated route shares, not off the marketing-family roster.
**Rationale**: The marketing-family roster names the ids whose app once sat under the
old marketing folder, before the fleets split into repos, and it still holds
`research`, `docs`, and `registry`; a build tool parses it by name, so it cannot change.
The route share is kept equal to what each fleet's repo actually deploys, so reading it
cannot drift from the deployed fleet.
**Approved**: pending

**Decision**: A local hop to a site the local server does not run goes to that site's
production host, and the list of served sites is read from an environment variable on
each call.
**Rationale**: A local server that runs only the hub used to emit sibling links to
hosts nothing answered, so those menu rows led nowhere. The production host is the
address the visitor meant. The variable is read per call and written out in full
because the web framework inlines a public environment reference only where its
literal text appears.
**Approved**: pending

**Decision**: The legal URLs are built once with the production URL builder on the hub,
and every site links those absolute URLs instead of a `/privacy` or `/terms` of its own.
**Rationale**: One address never moves, so it can be given to an app store, a payment
processor, or an SMS carrier. A production URL, not a current-environment one, keeps the
address identical in every environment and every render.
**Approved**: pending

**Decision**: The merged guided-tour graph's three rings (the main ring, the
marketing ring, the placeholder ring) are three separately generated constants
merged by a plain object spread, rather than one map with regions spliced in place.
**Rationale**: Each ring is generated by a different region's own tooling, and those
regions cannot see each other's site trees. A single generated map would be
overwritten wholesale by whichever region's generator ran last, silently deleting
every other region's entries, a failure mode that still compiles, still satisfies
every test assertion about the entries it kept, and simply drops the other rings out
of the guided tour with nothing anywhere reporting it. Three separately-owned
constants, each with its own generated-region markers, make that specific failure
structurally impossible; the cost is that a compile-time duplicate-key check cannot
see a site claimed by two rings at once, which is why a dedicated test asserts the
three key sets are pairwise disjoint. Applies to the web implementation's
generated-constant mechanism specifically; any implementation adopting per-region
generation inherits the same trade-off.
**Approved**: pending

**Decision**: The route shares, the roster of generated per-region route shares
merged into the route map, is stated exactly once, as the shares' own key list,
with no restating of the region names or the share count in prose comments above it.
**Rationale**: A prose paragraph restating "there are N shares, owned by these
regions" drifts from the list it describes every time a share is added or removed,
because nothing forces the two to change together; this specific paragraph was
rewritten at five consecutive splits and was still wrong at the sixth. Deriving
every test case from the list itself, and saying nothing else in prose, removes the
second copy that could drift.
**Approved**: pending

**Decision**: When `ai-settings` replaces the hub segments `llm-providers` and
`persona-services`, the two old segments stay in the hub-only extra segments as
redirect-only segments, and the hub site, not this registry, does the redirect to
`ai-settings`. They are removed in a later cleanup, once no link uses them.
**Rationale**: Stored links and bookmarks still point at the old segments. Dropping
them from the list now would stop those links resolving as hub workspace segments, so
they would fail before any redirect could run. The registry says which segments
resolve; the hub site is where the request lands, so the redirect sits there, next to
the page it sends the reader to.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |

`separation-of-concerns` passes because each concern lives in its own file: site identity and routing in `registry.ts`, slug reservation in `reserved-slugs.ts`, the legal addresses in `legal.ts`, the fleet directory in `fleets.ts`, the generated route map in the thirteen `routes.*.generated.ts` shares plus the hand-written merge in `routes.generated.ts`, and brand-story and tour data in `story.ts`. Per-site build-only data sits in its own `SITE_BUILD` table outside the scaffolded region, so scaffolding, build configuration, and routing data cannot clobber each other's regeneration. `unit-test-coverage` is partial: `registry.test.ts`, `registry-characterisation.test.ts`, `siteRoutes.test.ts`, `story.test.ts`, `tour-region.test.ts`, `fleets.test.ts`, `sites/__tests__/reserved-slugs.test.ts`, and `sites/__tests__/build-fields.test.ts` cover environment classification and fallback, the local-sites list, the workspace-slug round trip, the return-origin list per environment including the `nativeApp` exclusion, the scaffold-region isolation invariant, the reserved-slug contract, the route-share invariants, the fleet directory, and the brand-story and tour invariants, but no test imports `legal.ts`, so the legal paths and URLs have no coverage. The phase 8 segment rules (`ai-settings-extra-segment` and `legacy-provider-segments-redirect-only`) are covered by `registry.test.ts`'s "AI Settings segment (phase 8)" block. `no-hardcoded-strings` fails: every `SiteDef`'s `label`, `fullLabel`, `shortLabel`, and `description` is a literal English string with no localization or string-catalog indirection (see Localization above), and `siteHeaderTitle`'s `"Agentic Developer <X>"` derivation is built from the same hardcoded convention, so a translated presentation of the switcher, footer, or header cannot be produced from this file alone.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.6.1 | 2026-11-24 | Mike Fullerton | workspace-route-not-derived-from-has-home names myagenticdevteam: hasHome true, no workspace route |
| 1.6.0 | 2026-11-23 | Mike Fullerton | Phase 9: jobs hub segment and route line (templates and environments are sub-paths), the product admin Jobs pages in its share, jobs in the universal reserved list. |
| 1.5.0 | 2026-11-23 | Mike Fullerton | Phase 8: added ai-settings-extra-segment, ai-settings-hub-route-line, admin-share-no-ai-settings and legacy-provider-segments-redirect-only, and the Design Decision that keeps the old segments redirect-only until a later cleanup |
| 1.4.0 | 2026-11-23 | Mike Fullerton | Phase 7: consented support access |
| 1.3.0 | 2026-11-23 | Mike Fullerton | Phase 6: the product-admin site (admin-gated, hand-rolled build, main family) and the admin-site hub segment |
| 1.2.0 | 2026-11-22 | Mike Fullerton | Added legal paths and URLs, fleet directory, nativeApp sites, local-sites list; SSO list now excludes nativeApp and grants nothing by itself. |
| 1.1.1 | 2026-10-04 | Mike Fullerton | Inverted prohibitions (none/neither/no X MUST) restated as MUST NOT. |
| 1.1.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to adh/sites/. |
| 1.0.1 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.0.0 | 2026-09-24 | Mike Fullerton | Initial creation |

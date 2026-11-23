---
id: 2cb51edd-84c5-448a-a5dc-134d3f8b6c1c
title: "Product Admin Site"
type: ingredient
status: review
language: en
summary: "The product admin site's feature layer: the users pane, the page list, the manager's Admin site page, the totals pane and the rule for which hub pages move to the site."
platforms:
  - typescript
  - web
tags:
  - product-admin
  - hub
  - ui
depends-on:
  - 2eff6ca4-5479-44b3-8636-04e455009a10
  - 150bf00e-6c6b-4f91-a323-d307ebd5700d
  - 3ea9329e-5acc-4c43-b5ce-bb8c50570104
version: 2.0.0
created: 2026-11-23
modified: 2026-11-23
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
related: []
references: []
---
# Product Admin Site

## Overview

This is the feature layer of a product's admin site (phase 6). A product's own admins sign in to a separate host, the product admin site, and manage the people of that one product. The hub's managers set the site up from the Admin site page of the product's workspace. The data calls are in the product admin client ([adhsdk.ingredient.adh.hub.product-admin.product-admin-client](cookbook:150bf00e-6c6b-4f91-a323-d307ebd5700d)); the sign-in is the product admin session in the authentication client ([adhsdk.ingredient.data.services.auth.auth-client](cookbook:3ea9329e-5acc-4c43-b5ce-bb8c50570104)); the people panes it reuses are the ecosystem configuration panes and the ecosystem invitation panes. This recipe covers what ties them into a site: the page list, the users pane, the manager's Admin site page and the rule for which hub pages move to the site.

The pieces:

- `@adh-sdk/product-admin` (`packages/web/packages/features/product-admin/src/`): `ProductUsersPane` and `PRODUCT_ADMIN_TOPICS`. The barrel is a client module; the topic list is also published at `@adh-sdk/product-admin/topics` so a server module can read it.
- `@adh-sdk/ecosystem-config`: `AdminSitePane` (the manager's page: the site's host, and the product's admins) and `ProductTotalsPane` (the eight figures, shown on the site's Totals page).
- `@adh-sdk/adh-products` (`topics.ts`, `ProductsFeature.tsx`): the Admin site topic row and `visibleProductTopics`, which hides the hub's people pages once a site carries them.
- `@adh-sdk/ecosystems`: the requests, pending and invites panes take `hideAdminRecords`.
- `@adh-sdk/site-registry`: the `product-admin` site and the `admin-site` hub segment (see the site registry recipe).

## Behavioral Requirements

### Pages

- **topics-list**: `PRODUCT_ADMIN_TOPICS` MUST list nine pages in this order, with these ids and paths: users (`/users`), requests, pending, invites, roles, signup-list, sets, totals and support (`/support`, labeled "Support"), each with a label and an `href` of `/` plus its id. The ids are unique.
- **topics-importable-server-side**: the topic list MUST be importable without the client barrel, through `@adh-sdk/product-admin/topics`.

### Users pane

- **users-roster**: `ProductUsersPane` MUST list the customers of the product it is given, one page at a time, and MUST show each customer's name or email, roles, storage and whether they are paused.
- **users-search-paging**: a search MUST restart at the first page; paging forward MUST pass the last page's `nextCursor`, and paging back MUST return to the page before, kept as a stack of cursors, never recomputed. A later page that comes back empty (its last person was deleted) MUST step back a page, and MUST NOT say there are no users.
- **users-confirm-writes**: pause, unpause, quota change and delete MUST each wait for the person's confirmation in an alert dialog, and MUST send nothing when it is cancelled.
- **users-quota-gb**: the quota is entered in GB and MUST be refused, without a request, when it is above the product default (`DEFAULT_QUOTA_BYTES`, 5 GB). The pane says so.
- **users-admin-protected**: when the backend refuses a pause or delete with `admin_seat_protected`, the pane MUST say that admins cannot be paused or deleted here; any other refusal MUST be shown as the backend says it.

### Admin site page (manager)

- **admin-site-pane**: `AdminSitePane` MUST show, for the selected product, the site's current host with a form that sets it up, changes it, or removes it; MUST say so when no product is selected; and MUST show the backend's sentence when a host is refused. A removal takes the site down at once, so it MUST wait for the manager's confirmation in a destructive alert dialog, and MUST send nothing when it is cancelled.
- **admin-site-admins**: the page MUST list the holders of the `admin` role, read on the ecosystem target, and MUST add an admin as a sign-up list entry carrying the admin role's id. An address already on the list MUST keep the set its entry grants; only the role changes. After the write the Sign-up list page's cached list MUST be read again, and no other list. An address that is not an email MUST be refused without a request.
- **totals-pane**: `ProductTotalsPane` MUST show the eight totals (customers, new in 7 and 30 days, active in 7 and 30 days, storage, pending invitations, pending requests) for the product it is given, and MUST say when it is loading and when it could not load. When the totals carry `jobsByStatus`, it MUST also show the product's background jobs as one count for each status, and MUST show nothing for jobs when the map is empty or absent.

### Support page

- **support-page**: the Support page MUST render `SupportGrantsPane` ([adhsdk.ingredient.adh.hub.support.support-panes](cookbook:2eff6ca4-5479-44b3-8636-04e455009a10)) for the product it is given, at `/support`, and MUST be listed in `PRODUCT_ADMIN_TOPICS` (see **topics-list**).
- **support-step-up**: when the Support page's request, or the opening of a live grant, is refused as `step_up_required`, the page MUST send the admin through `stepUp('/support')` of the product admin session ([adhsdk.ingredient.data.services.auth.auth-client](cookbook:3ea9329e-5acc-4c43-b5ce-bb8c50570104)) and bring them back to `/support`; the site's own sign-in route carries `prompt=login` and `max_age=600` on that second pass.
- **support-switch-off**: when the backend answers the grants read with 404 (consented access is off), the page MUST say that support access is not available instead of showing an error.

### Which pages move

- **admin-site-topic**: the product topic list MUST carry an `admin-site` row labeled "Admin site", for the `users` feature, that renders `AdminSitePane` with the help key `ecosystems/admin-site`.
- **visible-topics**: `visibleProductTopics(topics, site, routed)` MUST remove the `admin-site` row when the `product_admin_site` switch is off; MUST keep every row when it is on and no site exists yet; and MUST, when it is on and a site exists, remove roles, signup-list and sets and narrow the Users row (`invitations`) to its Email Signup and Authentication members (`ADMIN_SITE_KEPT_USERS_MEMBERS`, through the row's `members`), which the admin site has no page for. While the site is not known (`site` undefined: the read is in flight, or failed with no answer) it MUST keep every row but `admin-site`, and MUST keep `admin-site` too when the URL names it (`routed`), so a deep link or reload opens it.
- **run-at-admin-site**: `runAtAdminSite(topicId, site)` MUST answer true exactly when the switch is on, a site exists and the topic is invitations, roles, signup-list or sets: the question a host that answers one topic at a time (the hub's `/<slug>/<topic>` routes, where `invitations` is the roster alone) asks.
- **hide-admin-records**: the requests, pending and invites panes MUST take `hideAdminRecords`, which hides the developer's admin records: the panes MUST get neither notes slot and show no notes, no entity history and no "Admin notes" action. Without it the panes mount the notes editor and offer Admin notes.

## Appearance

The users pane is a searchable table with a Previous and Next pager; each row has its actions. The Admin site page is a form for the host above a list of admins with an add field. The totals page is a grid of eight stat cards. The text of each comes from the panes; the look is the shared UI kit's.

## States

- **Users pane**: loading, loaded, empty, and failed; a row is paused or active.
- **Admin site page**: no product selected, no site (the form sets one up), a site (the form changes or removes it), and a refused host.
- **Totals**: loading, loaded and failed.

The Support page has four states: loading, loaded (grants listed), failed (the backend's message), and not available (the grants read answered 404 because consented access is off). A step-up refusal is not a state of the page: it leaves the page through the sign-in redirect and returns to `/support`.
## Accessibility

Not applicable beyond the shared UI kit: the panes use its table, form, dialog and stat card components and add no focus handling of their own.

## Conformance Test Vectors

Vectors marked with a test name are asserted in `features/product-admin/src/__tests__/`, `features/ecosystem-config/src/AdminSitePane.test.tsx`, `features/ecosystem-config/src/ProductTotalsPane.test.tsx` and `features/adh-products/src/__tests__/topics.test.tsx`. The others follow from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| product-admin-site-001 | topics-list | `PRODUCT_ADMIN_TOPICS` (test: "names the nine pages in rail order, ids unique") | Nine rows in the order above, the last `support` with `/support`, unique ids |
| product-admin-site-002 | users-roster | The pane given a product, over a roster of customers (test: "lists the roster for the product it is given, with roles, storage and paused") | One row each, with roles, storage and the paused mark |
| product-admin-site-003 | users-search-paging | Next, then Previous; then a search (tests: "pages forward by the cursor and back again", "searches from the first page") | The next page is read by the cursor, Previous returns to the first; a search reads from the first page |
| product-admin-site-004 | users-confirm-writes | Pause chosen and confirmed; then chosen and cancelled (tests: "pauses only after the confirmation", "sends nothing when the confirmation is cancelled") | One pause request; then none |
| product-admin-site-005 | users-confirm-writes | Unpause on a paused customer (test: "unpauses a paused user") | The pause is lifted |
| product-admin-site-006 | users-quota-gb | A quota of 2 GB, then 6 GB (test: "sets a quota in GB, and refuses one above the default") | The first is sent in bytes; the second is refused with no request |
| product-admin-site-007 | users-admin-protected | A pause answered 422 `admin_seat_protected`; then another refusal (tests: "says admins cannot be paused or deleted here on the backend's 422", "shows any other refusal as the backend says it") | The first shows the admins sentence; the second shows the backend's message |
| product-admin-site-008 | admin-site-pane | No product; then a host set; then a refused host; then remove (tests: "says so when no product is selected", "sets a site up at a host", "shows the backend's sentence when the host is refused", "removes a site only after the confirmation") | The note; a site put; the backend's sentence; a site removal |
| product-admin-site-009 | admin-site-admins | The admin role's holders; then an address added; then a non-email (tests: "lists the admin role's holders, read on the ecosystem target", "adds an admin as a sign-up list entry carrying the admin role", "refuses an address that is not an email, and sends nothing") | The holders listed; an entry put with the admin role; no request for the bad address |
| product-admin-site-010 | totals-pane | A product with totals; then loading and failed (tests: "shows each figure, read for the product it is given", "says it is loading, and says when it could not load") | The eight figures; the loading and failed notes |
| product-admin-site-011 | visible-topics | The four switch and site combinations (tests: "switch off, no site: every pane but the Admin site row", "switch off, a site: still every pane but the Admin site row", "switch on, no site yet: every pane, and the Admin site row to set one up", "switch on and a site: the people rows leave for the site, the Admin site row stays") | As the requirement states; Users stays, narrowed |
| product-admin-site-012 | admin-site-topic | The product topic list | An `admin-site` row for the `users` feature |
| product-admin-site-014 | users-search-paging | Page two's last person deleted (test: "steps back a page when a later page comes back empty, and never says there are no users") | The first page is read again; no "No users yet." |
| product-admin-site-015 | admin-site-pane | Remove, then cancel (tests: "removes a site only after the confirmation", "sends nothing when the removal is cancelled") | The removal is sent only once confirmed; none when cancelled |
| product-admin-site-016 | admin-site-admins | An address already listed with a set (test: "keeps the set of an address already on the sign-up list, and changes only its role") | The entry is put with the admin role and its own set |
| product-admin-site-017 | visible-topics | The site not known yet, with and without the URL naming Admin site; then a known switch-off naming it (tests: "not known yet: every pane, and no Admin site row unless the URL names it", "a known switch-off drops the Admin site row even when the URL names it") | As the requirement states |
| product-admin-site-018 | visible-topics | Switch on and a site (test: "switch on and a site: Users keeps Email Signup and Authentication, and nothing else") | The Users row carries members `email-signup` and `auth` |
| product-admin-site-019 | run-at-admin-site | Each moved topic and four others, with each switch and site state (test: "runAtAdminSite: the moved topics, only with the switch on and a site") | True for the moved topics with the switch on and a site; false otherwise |
| product-admin-site-013 | hide-admin-records | Each of the three panes given `hideAdminRecords`, then not (tests: "mounts the notes editor and offers Admin notes by default", "mounts no notes editor and offers no Admin notes when set") | Set: no notes editor, no history, no Admin notes; unset: all three |
| product-admin-site-020 | support-page, support-step-up | The Support page for a product; a request refused as `step_up_required` | `SupportGrantsPane` renders for the product; `stepUp('/support')` is called |
| product-admin-site-021 | totals-pane | Totals carrying `jobsByStatus` of `{ failed: 2, done: 9 }`, then an empty map | One count for each status; then no jobs line |
| product-admin-site-022 | support-switch-off | The grants read answered 404 | A note that support access is not available, no error |
## Edge Cases

- **No product selected (MUST)**: the Admin site page and the totals page say so and make no request.
- **A site that cannot be set (MUST)**: a host another product's site uses, or a product with its own admin application, is refused by the backend with a sentence; the page shows it.
- **Switch on, no site (MUST)**: no page leaves the hub, so the manager keeps every page until the site is set up.
- **Site not known yet, or its read failed (MUST)**: every page stays, and Admin site stays only when the URL names it.
- **Switch on and a site (MUST)**: Users ▸ Email Signup and Users ▸ Authentication stay on the hub; the admin site has no page for them.
- **A cancelled confirmation (MUST NOT)**: nothing is sent.
- **Quota above the default (MUST NOT send)**: refused before any request.
- **A step-up refusal (MUST)**: a request or an opening refused as `step_up_required` MUST send the admin through `stepUp('/support')` and back to `/support`, with no error shown.
- **Support access off (MUST)**: a 404 on the grants read MUST show the not-available note and no request form.
## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `ecosystemId` | string | none, required | The product's ecosystem uuid every pane reads for. |
| `caller` | `"manager"` or `"product_admin"` | `manager` | Which seat is using the roles, sign-up list and sets panes; see the ecosystem configuration recipe. |
| `hideAdminRecords` | boolean | false | On the requests, pending and invites panes, hides the notes, history and Admin notes action. |
| `{ enabled, hasSite }` (`AdminSiteRailState`) | object or undefined | none | The input to `visibleProductTopics` and `runAtAdminSite`: the `product_admin_site` switch and whether a site exists; undefined while the site is not known. |

## Deep Linking

The pages are `/users`, `/requests`, `/pending`, `/invites`, `/roles`, `/signup-list`, `/sets`, `/totals` and `/support` on the admin site's own host. On the hub the page is the product's `admin-site` topic, under the `admin-site` hub segment.

## Localization

Strings are written in English in the panes; the help article for the Admin site page is the key `ecosystems/admin-site` in `help.en.json`.

## Accessibility Options

Not applicable beyond the shared UI kit's behavior.

## Feature Flags

- **`product_admin_site`**: the backend switch, read as `enabled` from the admin site answer. Off hides the Admin site row; on shows it, and with a site hides the moved pages.

The Support page depends on the backend's `consented_access` switch, which the page reads only as a 404 on the grants read (see **support-switch-off**); it never reads the switch itself.
## Analytics

Not applicable: the panes emit no event.

## Privacy

The users pane shows customers' emails, names, roles and storage to the product's own admins only. The roster is existence, not content. Who may read it is the backend's decision, made per request.
- **Consented support access**: the Support page lets a product admin, once a customer approves, read that customer's content in a read-only viewer. The customer grants it, for a length they were told, every read is logged, and the backend requires a second factor from a recent sign-in for each request and opening.
## Logging

Not applicable: no file contains a log call.

## Platform Notes

- **SwiftUI**: A table with a cursor stack for paging and a confirmation dialog for each write; the topic list is a static array.
- **Compose**: A lazy list, a cursor stack in the view model and an alert dialog per write.
- **React/Web**: The source platform. `packages/web/packages/features/product-admin/src/` holds `ProductUsersPane.tsx` and `topics.ts`; `packages/web/packages/features/ecosystem-config/src/` holds `AdminSitePane.tsx` and `ProductTotalsPane.tsx`; `packages/web/packages/features/adh-products/src/topics.ts` and `ProductsFeature.tsx` hold the Admin site row and `visibleProductTopics`. The package's `sideEffects` and `exports` publish the `./topics` entry beside the barrel.
- **AppKit / UIKit**: As SwiftUI, with a table view and an alert per write.
- **WinUI 3**: A data grid and a content dialog per write.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/features/product-admin/src/` | confirmed (1.0.1) |
| web | `packages/web/packages/features/ecosystem-config/src/AdminSitePane.tsx` | confirmed (1.0.1) |
| web | `packages/web/packages/features/ecosystem-config/src/ProductTotalsPane.tsx` | confirmed (1.0.1) |
| web | `packages/web/packages/features/adh-products/src/topics.ts` | confirmed (1.0.1) |
| web | `packages/web/packages/features/ecosystems/src/EcosystemInvitationPanes.tsx` | confirmed (1.0.1) |

## Design Decisions

**Decision**: The product's admins are managed on the Admin site page, and the hub's people pages leave once a site exists.
**Rationale**: The phase 6 design puts the product's own admins on their own host; showing the same pages on the hub would make two places to do one thing.
**Approved**: pending

**Decision**: An admin is added as a sign-up list entry carrying the admin role, not through a new route.
**Rationale**: The sign-up list already grants a role on first sign-in, so the admin seat needs no route of its own.
**Approved**: pending

**Decision**: The topic list has its own `./topics` export.
**Rationale**: The barrel is a client module; a server module must be able to read the list without it.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |

The panes keep the data calls in the client and the page list in a plain module, so separation of concerns passes. Unit-test coverage is partial: the pages' routing inside the products feature is not asserted.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 2.0.0 | 2026-11-23 | Mike Fullerton | Phase 7: consented support access |
| 1.0.1 | 2026-11-23 | Mike Fullerton | Admin site removal confirmed; adding an admin keeps a listed address's set and refreshes the Sign-up list; an emptied later Users page steps back; Users keeps Email Signup and Authentication once a site is up; a routed Admin site row is kept while the site is unknown; runAtAdminSite |
| 1.0.0 | | | Initial creation |

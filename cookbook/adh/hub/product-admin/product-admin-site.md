---
id: 2cb51edd-84c5-448a-a5dc-134d3f8b6c1c
title: "Product Admin Site"
type: ingredient
status: review
language: en
summary: "The product admin site's feature layer: the users pane, the page list, the manager's Product site page, the totals pane, the Support and Jobs pages, and the rule for which hub pages move to the site."
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
version: 3.0.0
created: 2026-11-23
modified: 2026-11-26
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
related: []
references: []
---
# Product Admin Site

## Overview

This is the feature layer of a product's admin console (phase 6) and the manager's Product site page that switches it on (product sites phase 5). A product's own admins sign in to the admin console under `/admin` on the product's own site (`<handle>.agenticdeveloperhub.com`, the `product-sites` site), and manage the people of that one product. Every product is given that site when it is made, and the hub's managers see its address, rename its handle and switch the console on from the Product site page of the product's workspace. The data calls for the console are in the product admin client ([adhsdk.ingredient.adh.hub.product-admin.product-admin-client](cookbook:150bf00e-6c6b-4f91-a323-d307ebd5700d)); the site's own handle, address and console switch are in the product site client ([adhsdk.ingredient.adh.hub.product-sites.product-site-client](cookbook:1f689c5f-818d-4c64-918f-73bb9ec0be32)); the sign-in is the product admin session in the authentication client ([adhsdk.ingredient.data.services.auth.auth-client](cookbook:3ea9329e-5acc-4c43-b5ce-bb8c50570104)); the people panes it reuses are the ecosystem configuration panes and the ecosystem invitation panes. This recipe covers what ties them into a site: the page list, the users pane, the manager's Product site page and the rule for which hub pages move to the console.

The pieces:

- `@adh-sdk/product-admin` (`packages/web/packages/features/product-admin/src/`): `ProductUsersPane` and `PRODUCT_ADMIN_TOPICS`. The barrel is a client module; the topic list is also published at `@adh-sdk/product-admin/topics` so a server module can read it.
- `@adh-sdk/ecosystem-config`: `ProductSitePane` (the manager's page: the product's address and its two links, the handle and its rename, the `/admin` console switch, the product's admins and its totals) and `ProductTotalsPane` (the eight figures, shown on the console's Totals page and at the foot of the Product site page).
- `@adh-sdk/adh-products` (`topics.ts`, `ProductsFeature.tsx`): the Product site topic row, `visibleProductTopics` and `runAtProductSite`, which hide the hub's people pages once the product's console is live.
- `@adh-sdk/ecosystems`: the requests, pending and invites panes take `hideAdminRecords`.
- `@adh-sdk/jobs` ([adhsdk.ingredient.adh.hub.jobs](cookbook:0bcb370d-a44f-48a8-a313-0266c2f86e51), phase 9): `JobStatusPane` and `JobTemplatesPane`, shown on the site's Jobs pages.
- `@adh-sdk/site-registry`: the `product-sites` site (a wildcard site; the console's pages are its `/admin/*` share) and the `product-site` hub segment (see the site registry recipe).

## Behavioral Requirements

### Pages

- **topics-list**: `PRODUCT_ADMIN_TOPICS` MUST list ten pages in this order, with these ids and paths: users (`/admin/users`), requests, pending, invites, roles, signup-list, sets, jobs (`/admin/jobs`, labeled "Jobs"), totals and support (`/admin/support`, labeled "Support"), each with a label and an `href` of `/admin/` plus its id: the console lives under `/admin` on the product's own site (the `product-sites` site), and no href is under the console's auth routes, `/admin/auth`. The ids are unique.
- **topics-importable-server-side**: the topic list MUST be importable without the client barrel, through `@adh-sdk/product-admin/topics`.

### Users pane

- **users-roster**: `ProductUsersPane` MUST list the customers of the product it is given, one page at a time, and MUST show each customer's name or email, roles, storage and whether they are paused.
- **users-search-paging**: a search MUST restart at the first page; paging forward MUST pass the last page's `nextCursor`, and paging back MUST return to the page before, kept as a stack of cursors, never recomputed. A later page that comes back empty (its last person was deleted) MUST step back a page, and MUST NOT say there are no users.
- **users-confirm-writes**: pause, unpause, quota change and delete MUST each wait for the person's confirmation in an alert dialog, and MUST send nothing when it is cancelled.
- **users-quota-gb**: the quota is entered in GB and MUST be refused, without a request, when it is above the product default (`DEFAULT_QUOTA_BYTES`, 5 GB). The pane says so.
- **users-admin-protected**: when the backend refuses a pause or delete with `admin_seat_protected`, the pane MUST say that admins cannot be paused or deleted here; any other refusal MUST be shown as the backend says it.

### Product site page (manager)

- **product-site-pane**: `ProductSitePane` MUST say so, and make no request for the site, when no product is selected. For a product it MUST read the product's site and show: its address (`primaryOrigin`) with two links, "Sign-in and sign-up" at `<address>/login` and "Admin console" at `<address>/admin`, each with a copy button, the console's link marked "Not turned on" while `adminEnabled` is false; its handle with a Rename action; and the `/admin` console switch. It MUST name the product in its intro when the host passes the product's name, and otherwise show the host's own blurb. While the site loads it MUST say so, and when the read fails it MUST say it could not load the product site with the backend's sentence; the admins and totals sections stay either way.
- **product-site-no-base-domain**: when the site's `primaryOrigin` is null (the server has no product sites base domain), the pane MUST say the address is not configured and show the handle, and MUST show no links.
- **product-site-rename**: Rename MUST open the handle field and a warning that the old address stops working and nothing redirects from it, naming both the old and the new address. Sending the rename MUST wait for the manager's confirmation in a warning-tone alert dialog and MUST send nothing when it is cancelled; the confirm sends `{ handle }` with the handle trimmed and lower-cased. An unchanged or empty handle MUST NOT be sendable. A refusal (400 for a malformed or reserved handle, 409 for another product's) MUST show the backend's sentence under the field and keep the field open with the draft; a success MUST close the field on the new handle.
- **product-site-console-switch**: the "Admin console at /admin" switch MUST send `{ adminEnabled }` and show the answer; a refusal (409 `product_sites_unconfigured`, no base domain) MUST show the backend's sentence. Its help MUST say which of three states the console is in: off (the hub runs the users, roles, sign-up list and sets), on and live (the admins run them at the console's address and those rows have left the hub's rail), or on and not answering yet (the hub still runs them).
- **product-site-admins**: the page MUST list the holders of the `admin` role, read on the ecosystem target, and MUST add an admin as a sign-up list entry carrying the admin role's id, saying the person becomes an admin the first time they sign in to the console with that address. An address already on the list MUST keep the set its entry grants; only the role changes. After the write the Sign-up list page's cached list MUST be read again, and no other list. An address that is not an email MUST be refused without a request. A product with no admin role MUST be told so.
- **totals-pane**: `ProductTotalsPane` MUST show the eight totals (customers, new in 7 and 30 days, active in 7 and 30 days, storage, pending invitations, pending requests) for the product it is given, and MUST say when it is loading and when it could not load. It MUST also show the product's background jobs from `jobsByStatus`: a "Jobs" total, the sum of the statuses, then one count for each status in name order; when the map is empty it shows "Jobs" as 0 and no status count.

### Support page

- **support-page**: the Support page MUST render `SupportGrantsPane` ([adhsdk.ingredient.adh.hub.support.support-panes](cookbook:2eff6ca4-5479-44b3-8636-04e455009a10)) for the product it is given, at `/admin/support`, and MUST be listed in `PRODUCT_ADMIN_TOPICS` (see [topics-list](#requirements/topics-list)).
- **support-step-up**: when the Support page's request for access, or its revoke of a grant, is refused as `step_up_required`, the page MUST send the admin through `stepUp` of the product admin session ([adhsdk.ingredient.data.services.auth.auth-client](cookbook:3ea9329e-5acc-4c43-b5ce-bb8c50570104)) with the page's own path and bring them back to it (the pane's `returnPath` defaults to `/support`; the product site passes `/admin/support`), with no error shown; the sign-in parameters of that second pass are the authentication client's.
- **support-switch-off**: when the backend answers the grants read with 404 (consented access is off), the page MUST say that support access is not available instead of showing an error, and MUST NOT show the request form.

### Jobs pages

- **jobs-pages**: the Jobs row (phase 9) MUST open `/admin/jobs`, which renders `JobStatusPane` ([adhsdk.ingredient.adh.hub.jobs](cookbook:0bcb370d-a44f-48a8-a313-0266c2f86e51)) for the product it is given; `/admin/jobs/templates` MUST render `JobTemplatesPane`. Both are reached from the Jobs row's own topics, `jobsProductAdminTopics`, so the rail keeps one Jobs row and does not list `/admin/jobs/templates`.
- **jobs-status-no-content**: the `/admin/jobs` page MUST show only run status, never a run's inputs, outputs or logs; reading those needs a support grant (see [support-page](#requirements/support-page)).

### Which pages move

- **product-site-topic**: the product topic list MUST carry a `product-site` row labeled "Product site", placed after Sets, that names no catalog feature, so the feature manager always draws it (every product is given an address when it is made), and that renders `ProductSitePane` with the product's name and the help key `ecosystems/product-site`. The old topic id `admin-site` MUST still reach it, through `PRODUCT_TOPIC_ALIASES`.
- **visible-topics**: `visibleProductTopics(topics, site)` MUST keep every row while the site is not known (`site` undefined: the read is in flight, or failed with no answer) and while the console is not live (`consoleLive` false: off, or on and not answering yet). When the console is live it MUST remove roles, signup-list and sets and narrow the Users row (`invitations`) to its Email Signup and Authentication members (`CONSOLE_KEPT_USERS_MEMBERS`, through the row's `members`), which the console has no page for. The Product site row is never removed.
- **run-at-product-site**: `runAtProductSite(topicId, site)` MUST answer true exactly when the site is known, its console is live and the topic is one of `CONSOLE_MOVED_TOPIC_IDS` (invitations, roles, signup-list, sets): the question a host that answers one topic at a time (the hub's `/<slug>/<topic>` routes, where `invitations` is the roster alone) asks.
- **hide-admin-records**: the requests, pending and invites panes MUST take `hideAdminRecords`, which hides the developer's admin records: the panes MUST get neither notes slot and show no notes, no entity history and no "Admin notes" action. Without it the panes mount the notes editor and offer Admin notes.

## Appearance

The users pane is a searchable table with a Previous and Next pager; each row has its actions. The Product site page stacks the address with its two links, the handle with its rename warning, the console switch, the list of admins with an add field, and the totals. The totals page is a grid of stat cards: the eight totals, a Jobs total and one card per job status. The text of each comes from the panes; the look is the shared UI kit's.

## States

- **Users pane**: loading, loaded, empty, and failed; a row is paused or active.
- **Product site page**: no product selected; loading; failed to load; no base domain (address not configured); a site, with the console off, on and live, or on and not answering yet; the handle field closed, or open with the rename warning; and a refused handle or switch.
- **Totals**: loading, loaded and failed.

The Support page has four states: loading, loaded (grants listed), failed (the backend's message), and not available (the grants read answered 404 because consented access is off). A step-up refusal is not a state of the page: it leaves the page through the sign-in redirect and returns to `/support`.

The Jobs pages (phase 9) take their states from `JobStatusPane` and `JobTemplatesPane`: loading, loaded, empty (no runs, or no templates), failed (the backend's message), and not available (a 404 while the `jobs_feature` switch is off).
## Accessibility

Not applicable beyond the shared UI kit: the panes use its table, form, dialog and stat card components and add no focus handling of their own.

## Conformance Test Vectors

Vectors marked with a test name are asserted in `features/product-admin/src/__tests__/`, `features/ecosystem-config/src/ProductSitePane.test.tsx`, `features/ecosystem-config/src/ProductTotalsPane.test.tsx`, `features/adh-products/src/__tests__/topics.test.tsx` and `features/support-access/src/__tests__/SupportGrantsPane.test.tsx`. The others follow from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| product-admin-site-001 | topics-list | `PRODUCT_ADMIN_TOPICS` (test: "names the ten pages in rail order, ids unique") | Ten rows in the order above, `jobs` with `/admin/jobs` between `sets` and `totals`, the last `support` with `/admin/support`, unique ids |
| product-admin-site-002 | users-roster | The pane given a product, over a roster of customers (test: "lists the roster for the product it is given, with roles, storage and paused") | One row each, with roles, storage and the paused mark |
| product-admin-site-003 | users-search-paging | Next, then Previous; then a search (tests: "pages forward by the cursor and back again", "searches from the first page") | The next page is read by the cursor, Previous returns to the first; a search reads from the first page |
| product-admin-site-004 | users-confirm-writes | Pause chosen and confirmed; then chosen and cancelled (tests: "pauses only after the confirmation", "sends nothing when the confirmation is cancelled") | One pause request; then none |
| product-admin-site-005 | users-confirm-writes | Unpause on a paused customer (test: "unpauses a paused user") | The pause is lifted |
| product-admin-site-006 | users-quota-gb | A quota of 2 GB, then 6 GB (test: "sets a quota in GB, and refuses one above the default") | The first is sent in bytes; the second is refused with no request |
| product-admin-site-007 | users-admin-protected | A pause answered 422 `admin_seat_protected`; then another refusal (tests: "says admins cannot be paused or deleted here on the backend's 422", "shows any other refusal as the backend says it") | The first shows the admins sentence; the second shows the backend's message |
| product-admin-site-008 | product-site-pane | No product; then a site with the console off; then on and live; then on and not live yet; then the load error (tests: "says so when no product is selected", "switch off: the address, its two links, the console marked not turned on, and the off sentence", "switch on and live: no not-turned-on mark, and the on sentence names the console's address", "switch on but not live yet: says the hub still runs the four rows", "shows the load error") | The note; the address, its two links and the Not turned on mark with the off sentence; no mark and the on sentence naming the console; the not-live sentence; the load error |
| product-admin-site-009 | product-site-admins | The admin role's holders; then an address added; then a non-email (tests: "lists the admin role's holders, read on the ecosystem target", "adds an admin as a sign-up list entry carrying the admin role", "refuses an address that is not an email, and sends nothing") | The holders listed; an entry put with the admin role; no request for the bad address |
| product-admin-site-010 | totals-pane | A product with totals; then loading and failed (tests: "shows each figure, read for the product it is given", "says it is loading, and says when it could not load") | The eight figures; the loading and failed notes |
| product-admin-site-011 | visible-topics | The site not known, the console not live, and the console live (tests: "not known yet: every pane, the Product site row among them", "console not live: every pane, the Product site row among them", "console live: the people rows leave for the console, the Product site row stays") | As the requirement states; Users stays, narrowed, once live |
| product-admin-site-012 | product-site-topic | The product topic list, and the aliases (tests: "gives every row but Settings and Product site exactly one", "send a retired row or member to the group that holds it now") | A `product-site` row with no catalog feature; `admin-site` aliases to `product-site` |
| product-admin-site-013 | hide-admin-records | Each of the three panes given `hideAdminRecords`, then not (tests: "mounts the notes editor and offers Admin notes by default", "mounts no notes editor and offers no Admin notes when set") | Set: no notes editor, no history, no Admin notes; unset: all three |
| product-admin-site-014 | users-search-paging | Page two's last person deleted (test: "steps back a page when a later page comes back empty, and never says there are no users") | The first page is read again; no "No users yet." |
| product-admin-site-015 | product-site-rename | A rename confirmed, then cancelled, then the unchanged handle (tests: "rename: the warning names both addresses, and the confirm sends the handle", "a cancelled rename confirm sends nothing", "the unchanged handle cannot be renamed") | The warning names both addresses and the confirm sends the handle; no request when cancelled; the unchanged handle cannot be sent |
| product-admin-site-016 | product-site-admins | An address already listed with a set (test: "keeps the set of an address already on the sign-up list, and changes only its role") | The entry is put with the admin role and its own set |
| product-admin-site-017 | product-site-console-switch, product-site-no-base-domain | The switch turned on; a refusal for want of a base domain; a site with no address (tests: "turning the console on sends adminEnabled and shows the answer", "a console refused for want of a base domain shows the backend's sentence", "with no base domain: says the address is not configured, and shows no links") | `{ adminEnabled }` is sent and the answer shown; the backend's sentence shows; the address is said to be not configured and no link shows |
| product-admin-site-018 | visible-topics | Console live (test: "console live: Users keeps Email Signup and Authentication, and nothing else") | The Users row carries members `email-signup` and `auth` |
| product-admin-site-019 | run-at-product-site | Each moved topic and four others, with each site state (test: "runAtProductSite: the moved topics, only while the console is live") | True for the moved topics while the console is live; false otherwise |
| product-admin-site-020 | support-page, support-step-up | The Support page for a product; a request refused as `step_up_required`, then a revoke refused the same way (test, for the request: "sends a step_up_required refusal through stepUp('/support')"; the revoke follows from the source) | `SupportGrantsPane` renders for the product; each refusal calls `stepUp` with the pane's `returnPath` (`/support` by default, `/admin/support` on the product site), which returns there, and no error is shown |
| product-admin-site-021 | totals-pane | Totals carrying `jobsByStatus` of `{ failed: 2, done: 9 }`, then an empty map | A "Jobs" total of 11, then "Jobs done" 9 and "Jobs failed" 2; then "Jobs" 0 and no status count |
| product-admin-site-022 | support-switch-off | The grants read answered 404 (test: "says support access is off when the grants read answers 404") | A note that support access is not available, no error and no request form |
| product-admin-site-023 | jobs-pages | The `/admin/jobs` and `/admin/jobs/templates` pages for a product (derived from the phase 9 design; the site's e2e `jobs.spec.ts`) | `/admin/jobs` mounts `JobStatusPane` and `/admin/jobs/templates` mounts `JobTemplatesPane`, each for that product; the rail has one Jobs row |
| product-admin-site-024 | jobs-status-no-content | The `/admin/jobs` page over a product with a failed run | The run's status and error code show; no input, output or log is requested or shown |
| product-admin-site-025 | topics-list | Every `PRODUCT_ADMIN_TOPICS` href (test: "keeps every page under /admin and off the console's auth routes") | Each starts with `/admin/` and none with `/admin/auth` |
## Edge Cases

- **No product selected (MUST)**: the Product site page and the totals page say so and make no request.
- **A handle or switch that cannot be set (MUST)**: a taken or reserved handle, or a console switched on with no base domain on the server, is refused by the backend with a sentence; the page shows it and keeps the draft.
- **Console on, not live yet (MUST)**: no page leaves the hub, so the manager keeps every page until the console answers; the Product site page says so.
- **Site not known yet, or its read failed (MUST)**: every page stays, the Product site row among them.
- **Console live (MUST)**: Users ▸ Email Signup and Users ▸ Authentication stay on the hub; the console has no page for them.
- **A cancelled confirmation (MUST NOT)**: nothing is sent, for a pause, a quota change, a delete or a rename.
- **Quota above the default (MUST NOT send)**: refused before any request.
- **A step-up refusal (MUST)**: a request or a revoke refused as `step_up_required` is handled as [support-step-up](#requirements/support-step-up) says.
- **A product with no runs (MUST)**: `/admin/jobs` says there are no runs yet, and is not an error.
- **Jobs off (MUST)**: a 404 from an `/admin/jobs` read while the `jobs_feature` switch is off says Jobs is not available, as the Jobs ingredient's switch-off-404 says.
- **Support access off (MUST)**: a 404 on the grants read is handled as [support-switch-off](#requirements/support-switch-off) says.
## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `ecosystemId` | string | none, required | The product's ecosystem uuid every pane reads for. |
| `caller` | `"manager"` or `"product_admin"` | `manager` | Which seat is using the roles, sign-up list and sets panes; see the ecosystem configuration recipe. |
| `hideAdminRecords` | boolean | false | On the requests, pending and invites panes, hides the notes, history and Admin notes action. |
| `{ consoleLive }` (`ProductSiteRailState`) | object or undefined | none | The input to `visibleProductTopics` and `runAtProductSite`: whether the product's `/admin` console is live (on and answering at the product's address); undefined while the site is not known. |
| `ecosystemId`, `productName`, `help` | string, string, node | `ecosystemId` required | `ProductSitePane`'s inputs: the product, its name for the pane's sentences, and the blurb shown when there is no name. |

## Deep Linking

The pages are `/admin/users`, `/admin/requests`, `/admin/pending`, `/admin/invites`, `/admin/roles`, `/admin/signup-list`, `/admin/sets`, `/admin/jobs` (with `/admin/jobs/templates` beneath it), `/admin/totals` and `/admin/support` on the product's own host (`<handle>.agenticdeveloperhub.com`), where `/` is the product's own page. On the hub the manager's page is the product's `product-site` topic, under the `product-site` hub segment (`/<workspace>/product-site`); the old `admin-site` topic id is aliased to it.

## Localization

Strings are written in English in the panes; the help article for the Product site page is the key `ecosystems/product-site` in `help.en.json`.

## Accessibility Options

Not applicable beyond the shared UI kit's behavior.

## Feature Flags

- **`product_admin_site`**: the backend switch, folded by the backend into the site's `consoleLive` (the switch is on and the product's console is on with a login registration). The pane and the rail never read the switch itself: `consoleLive` false keeps every hub page, and true hides the moved pages. The Product site row is drawn either way.

The Support page depends on the backend's `consented_access` switch, which the page reads only as a 404 on the grants read (see **support-switch-off**); it never reads the switch itself.
## Analytics

Not applicable: the panes emit no event.

## Privacy

The users pane shows customers' emails, names, roles and storage to the product's own admins only. The roster is existence, not content. Who may read it is the backend's decision, made per request.
- **Consented support access**: the Support page lets a product admin, once a customer approves, read that customer's content in a read-only viewer. The customer grants it, for a length they were told, every read is logged, and the backend requires a second factor from a recent sign-in for each request and opening.
- **Jobs status only**: the `/admin/jobs` page shows a product's run status, never a run's inputs, outputs or logs ([jobs-status-no-content](#requirements/jobs-status-no-content)); reading those needs a support grant.

## Logging

Not applicable: no file contains a log call.

## Platform Notes

- **SwiftUI**: A table with a cursor stack for paging and a confirmation dialog for each write; the topic list is a static array.
- **Compose**: A lazy list, a cursor stack in the view model and an alert dialog per write.
- **React/Web**: The source platform. `packages/web/packages/features/product-admin/src/` holds `ProductUsersPane.tsx` and `product-admin-topics.ts`; `packages/web/packages/features/ecosystem-config/src/` holds `ProductSitePane.tsx` (which draws its console switch with `SettingRow`, exported from `ClientAuthFields.tsx`, and its rename confirm with `AlertModal`'s `warning` tone) and `ProductTotalsPane.tsx`; `packages/web/packages/features/adh-products/src/topics.ts` and `ProductsFeature.tsx` hold the Product site row, `visibleProductTopics` and `runAtProductSite`, and `ProductsFeature.tsx` reads `useProductSite` from `@adh-sdk/data/product-sites` to feed them. The hub's own route is `/[workspace]/product-site`, in the hub website's ecosystem topic panels. The `/admin/jobs` and `/admin/jobs/templates` pages mount `JobStatusPane` and `JobTemplatesPane` from `packages/web/packages/features/jobs/` (phase 9). The page routes themselves live in the hub website's product-sites app, under `app/admin/`. The package's `sideEffects` and `exports` publish the `./topics` entry beside the barrel.
- **AppKit / UIKit**: As SwiftUI, with a table view and an alert per write.
- **WinUI 3**: A data grid and a content dialog per write.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/features/product-admin/src/` | confirmed (3.0.0) |
| web | `packages/web/packages/features/ecosystem-config/src/ProductTotalsPane.tsx` | confirmed (3.0.0) |
| web | `packages/web/packages/features/adh-products/src/topics.ts` | confirmed (3.0.0) |
| web | `packages/web/packages/features/ecosystems/src/EcosystemInvitationPanes.tsx` | confirmed (3.0.0) |
| web | `packages/web/packages/features/ecosystem-config/src/ProductSitePane.tsx` | confirmed (3.0.0) |

## Design Decisions

**Decision**: The product's admins are managed on the Product site page, and the hub's people pages leave only once the product's console is live.
**Rationale**: Every product has a site from the day it is made, so the move cannot wait on a site existing; it waits on the console answering, because a page moved off the hub before the console can serve it would leave the manager with nowhere to run those people.
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
| 3.0.0 | 2026-11-26 | Mike Fullerton | The manager's Admin site page becomes the Product site page: address, handle rename, console switch, admins; the rail follows consoleLive |
| 2.2.0 | 2026-11-26 | Mike Fullerton | The console under /admin on each product's own site (the product-sites site): every topic href under /admin, the Jobs and Support pages' paths |
| 2.1.0 | 2026-11-23 | Mike Fullerton | Phase 9: a Jobs row between Sets and Totals (ten pages); /jobs renders JobStatusPane and /jobs/templates JobTemplatesPane, status only. |
| 2.0.0 | 2026-11-23 | Mike Fullerton | Phase 7: consented support access |
| 1.0.1 | 2026-11-23 | Mike Fullerton | Admin site removal confirmed; adding an admin keeps a listed address's set and refreshes the Sign-up list; an emptied later Users page steps back; Users keeps Email Signup and Authentication once a site is up; a routed Admin site row is kept while the site is unknown; runAtAdminSite |
| 1.0.0 | | | Initial creation |

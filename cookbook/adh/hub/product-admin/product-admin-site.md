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
version: 3.1.0
created: 2026-11-23
modified: 2026-11-27
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
- `@adh-sdk/ecosystem-config`: `ProductSitePane` (the manager's page: the product's address and its two links, the handle and its rename, the `/admin` console switch, its custom domains while the `product_custom_domains` switch is on, the product's admins and its totals), `ProductDomainsSection` (the Custom domain section of that page, product sites phase 8) and `ProductTotalsPane` (the eight figures, shown on the console's Totals page and at the foot of the Product site page).
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
- **product-site-subdomain**: the handle field's suffix and the address a rename would give MUST be built from the site's `subdomainOrigin`, never from `primaryOrigin`, which is the custom domain once one is primary. The rename warning's old address MUST be `subdomainOrigin`, or the handle when it is null, and its new address the subdomain for the new handle, or the new handle when there is no base domain. When a custom domain is primary the warning MUST add "<primary host> stays the primary address."
- **product-site-also-at**: the Address group MUST keep `primaryOrigin` for its sign-in and admin console links and the console switch's help, and when `primaryOrigin` differs from `subdomainOrigin` it MUST add the line "Also at <subdomainOrigin>."
- **totals-pane**: `ProductTotalsPane` MUST show the eight totals (customers, new in 7 and 30 days, active in 7 and 30 days, storage, pending invitations, pending requests) for the product it is given, and MUST say when it is loading and when it could not load. It MUST also show the product's background jobs from `jobsByStatus`: a "Jobs" total, the sum of the statuses, then one count for each status in name order; when the map is empty it shows "Jobs" as 0 and no status count.

### Custom domain section (manager)

- **domains-section-placement**: `ProductSitePane` MUST render `ProductDomainsSection` for every product it shows, after the admin console section. The section MUST read `useProductDomains` of the product site client ([adhsdk.ingredient.adh.hub.product-sites.product-site-client](cookbook:1f689c5f-818d-4c64-918f-73bb9ec0be32)).
- **domains-section-hidden**: while the list loads, and when it answers a 404 that `productDomainsAvailable` reads as the `product_custom_domains` switch being off, the section MUST render nothing at all, no heading, so a product without the switch never flashes one. Any other failure of a list never loaded MUST show the "Custom domain" heading and `ErrorText` "Couldn't load the custom domains: <message>" with the human message ([domains-messages](#requirements/domains-messages)). A failed refetch of a list already loaded MUST keep rendering that list and MUST show `ErrorText` "Couldn't refresh the custom domains: <message>" under the intro; a refetch answering the switch-off 404 still hides the whole section.
- **domains-section-loaded**: once loaded the section MUST be a `FieldGroup` "Custom domain" holding, in order: the intro "<Name> can also answer at a domain you own. Its sign-in, admin console and support pages then work there too, and once the domain is verified you can make it <name>'s primary address." (the name from `wordsFor`), one box per domain, the add field when it is shown, and the guidance list.
- **domains-add**: the add field MUST be a mono `Input` with placeholder `app.example.com` and `aria-label` "Domain", and an "Add domain" button disabled while the trimmed value is empty or an add is in flight; Enter submits. It MUST be shown while the product has fewer than five domains and none is verified. A success MUST clear the field; a refusal MUST show its human message under the field as `ErrorText`.
- **domains-guidance**: under the boxes the section MUST always show a `List` of three items: use a subdomain such as app.example.com rather than the bare domain (one CNAME record, which every DNS provider supports; a bare domain needs an A record); on Cloudflare set the record to DNS only (the grey cloud), since the orange cloud stands in front of the domain and it can't be verified; and passkeys and security keys don't work on a custom domain, because a passkey belongs to one domain, so a customer who signs in with one there is asked for another way to sign in.
- **domains-box**: each domain MUST be a bordered box with a globe icon, the host in mono and its badges, then the text for its state, then its records table when the state shows one, then its buttons, as this table says:

  | Status | Badges | Text | Records | Buttons |
  |---|---|---|---|---|
  | pending | Pending (`orange`) | "Added <when>. Waiting for the records below." and the check line | yes | Check now, Remove |
  | pending with `error` | Pending (`orange`) | "Added <when>. The last check found a problem: <error>. <Name> answers at <host> only once it is verified." and the check line | yes | Check now, Remove |
  | verified | Verified (`success`) | "<Name> answers at https://<host>. Verified <when>. Its primary address is still <primary host>.", the primary host being that of the site's `primaryOrigin` (another custom domain when one is primary), or the subdomain's when there is none | no | Make primary, Remove |
  | verified and primary | Verified (`success`), Primary (`accent`) | "<host> is <name>'s primary address. Customers sign in there, the admin console signs in there, and support emails link there. <subdomain host> still works.", both hosts in mono | no | Remove |
  | failed | Failed (`error`) | "The records below were not found within 7 days of adding the domain on <date>, so it is no longer checked by itself. Create them and choose Check now, or remove the domain.", then the error when there is one; when the window restarted (see [domains-failed-window](#requirements/domains-failed-window)) "within 7 days of <start date>, when it last went back to waiting" in place of "within 7 days of adding the domain on <date>" | yes | Check now, Remove |
  | removing | Removing (`neutral`) | "Being removed. If this stays, choose Remove again." | no | Remove |

- **domains-live-region**: each box's state sentence MUST be its only live region (`role="status"`), so a Check now outcome is announced; the check line MUST follow it in the same paragraph but outside that region, so its once-a-minute tick is never announced.
- **domains-check-line**: a pending box's check line MUST read "Last checked <relative>; it is checked again every 10 minutes until <expiresAt date>.", and with a null `checkedAt` "It is checked every 10 minutes until <date>." The relative time MUST be read against a clock the section reads again once a minute (an interval cleared on unmount), so it ages while the page is open, and a `checkedAt` after that clock (clock skew) MUST be read as now, never as a time to come.
- **domains-failed-window**: a failed box's 7 days MUST be counted from `expiresAt` minus 7 days, not from `createdAt`: the backend starts a fresh 7 days on a demotion and on a Check now of a failed row. When that start falls on `createdAt`'s day the sentence names the day the domain was added; otherwise it names the start day, "when it last went back to waiting".
- **domains-demoted**: a pending domain with an `error` (the 6-hourly re-check found a verified domain no longer pointing at Vercel, and moved it back to pending) MUST name the problem and MUST NOT say it is waiting for the records; its expiry date is the fresh one the backend set.
- **domains-records**: a records table MUST have the columns Type, Name and Value, every name and value in mono with a `CopyButton` whose `getText` returns exactly the API string, with no trimming and no trailing dot added. Its last row is the ownership TXT `_adh-challenge.<host>` with `adh-domain-verification=<token>`, as the API answers it, and under the table the section MUST say "The TXT record named _adh-challenge proves the domain is yours." The table's lead MUST be "Create these records at the DNS provider for <parent>:", where the parent is the DNS zone the records give: the host itself when there is an `A` record named `@` (the host is its own apex); the host minus `<name>.` when there is a `CNAME` whose name `<name>` is the labels left of the apex (`app` on `app.example.co.uk` gives `example.co.uk`, `a.b` on `a.b.example.com` gives `example.com`); and only with neither, the host minus its first label, or the host itself when it has two labels.
- **domains-check**: Check now MUST call `useCheckProductDomain`, show busy and stay disabled while it runs, and show a refusal's human message under the box; the answer replaces the row, so the badges and text follow.
- **domains-make-primary**: Make primary MUST call `useSetPrimaryProductDomain` with `primary: true`; the answer replaces the list, and a refusal shows under the box. No button sends `primary: false`.
- **domains-remove**: Remove MUST open an `AlertModal` with `tone="error"` and `confirmVariant="destructive"`, titled "Remove <host>?". Its description MUST be, for the primary, "<Name> stops answering at <host> at once, and <subdomainOrigin> becomes its primary address again. Links to the custom domain stop working.", and otherwise "<Name> stops answering at <host> at once." The confirm, "Remove", MUST be busy while the remove runs, and nothing MUST be sent when the modal is cancelled. A refusal MUST show under the box after the modal closes.
- **domains-times**: absolute times MUST be `toLocaleString` with day, month, hour and minute ("19 Nov, 14:05") and relative ones `Intl.RelativeTimeFormat`, each rendered as a text node.
- **domains-text-only**: every API string (the host, each record's name and value, `error`) MUST be rendered as a React text child, never through `dangerouslySetInnerHTML`; the only link built from the API is the verified host's `https://<host>`, and only for a verified row.
- **domains-messages**: one function, `domainErrorMessage(err, words)`, MUST map each refusal to the section's human message: `product_domain_invalid` "That isn't a domain name <name> can use. Enter one such as app.example.com."; `product_domain_local` "That name only works on a local network. Enter a public domain such as app.example.com."; `product_domain_ours` "That domain belongs to the hub. Enter a domain you own."; `product_domain_limit` "<Name> already has five domains, the most it can have. Remove one to add another."; `product_domain_taken` "Another product already uses that domain."; `product_domain_taken_elsewhere` "That domain is in use on another Vercel account, so it can't be added here."; `product_domain_vercel_unavailable` "The domain service didn't answer. Try again in a minute."; `product_domains_rate_limited` "Too many tries in the last hour. Try again later."; `product_domains_unconfigured` "Custom domains aren't set up on this server yet."; `product_domain_not_verified` "That domain isn't verified yet, so it can't be the primary address."; `product_domain_primary_race` "Another change to the primary address happened at the same time. Try again."; `product_domain_not_found` "That domain was already removed." (and the list is read again); an HTTP 403 "Only the product's managers can change its domains." Any other refusal MUST fall back to the backend's sentence, then to "Something went wrong. Try again."

### Support page

- **support-page**: the Support page MUST render `SupportGrantsPane` ([adhsdk.ingredient.adh.hub.support.support-panes](cookbook:2eff6ca4-5479-44b3-8636-04e455009a10)) for the product it is given, at `/admin/support`, and MUST be listed in `PRODUCT_ADMIN_TOPICS` (see [topics-list](#requirements/topics-list)).
- **support-step-up**: when the Support page's request for access, or its revoke of a grant, is refused as `step_up_required`, the page MUST send the admin through `stepUp` of the product admin session ([adhsdk.ingredient.data.services.auth.auth-client](cookbook:3ea9329e-5acc-4c43-b5ce-bb8c50570104)) with the page's own path and bring them back to it (the pane's `returnPath` defaults to `/support`; the product site passes `/admin/support`), with no error shown; the sign-in parameters of that second pass are the authentication client's.
- **support-switch-off**: when the backend answers the grants read with 404 (consented access is off), the page MUST say that support access is not available instead of showing an error, and MUST NOT show the request form.

### Jobs pages

- **jobs-pages**: the Jobs row (phase 9) MUST open `/admin/jobs`, which renders `JobStatusPane` ([adhsdk.ingredient.adh.hub.jobs](cookbook:0bcb370d-a44f-48a8-a313-0266c2f86e51)) for the product it is given; `/admin/jobs/templates` MUST render `JobTemplatesPane`. Both are reached from the Jobs row's own topics, `jobsProductAdminTopics`, so the rail keeps one Jobs row and does not list `/admin/jobs/templates`.
- **jobs-status-no-content**: the `/admin/jobs` page MUST show only run status, never a run's inputs, outputs or logs; reading those needs a support grant (see [support-page](#requirements/support-page)).

### Which pages move

- **product-site-topic**: the product topic list MUST carry a `product-site` row labeled "Product site", placed after Sets, that names no catalog feature, so the feature manager always draws it (every product is given an address when it is made), and that renders `ProductSitePane` with the product's name and the help key `ecosystems/product-site`. The old topic id `admin-site` MUST still reach it, through `PRODUCT_TOPIC_ALIASES`.
- **visible-topics**: `visibleProductTopics(topics, site)` MUST keep every row while the site is not known (`site` undefined: the read is in flight, or failed with no answer) and while the console is not live (`consoleLive` false: off, or on and not answering yet). When the console is live it MUST remove roles, signup-list and sets and narrow the Users row (`invitations`) to its Email Signup and Authentication members (`CONSOLE_KEPT_USERS_MEMBERS`, through the row's `members`), which the console has no page for. The Product site row is never removed, and it is drawn only for an ecosystem of type `product` (the row names `types: ["product"]`), because only a product has a product site and the backend answers 404 for any other type.
- **run-at-product-site**: `runAtProductSite(topicId, site)` MUST answer true exactly when the site is known, its console is live and the topic is one of `CONSOLE_MOVED_TOPIC_IDS` (invitations, roles, signup-list, sets): the question a host that answers one topic at a time (the hub's `/<slug>/<topic>` routes, where `invitations` is the roster alone) asks.
- **hide-admin-records**: the requests, pending and invites panes MUST take `hideAdminRecords`, which hides the developer's admin records: the panes MUST get neither notes slot and show no notes, no entity history and no "Admin notes" action. Without it the panes mount the notes editor and offer Admin notes.

## Appearance

The users pane is a searchable table with a Previous and Next pager; each row has its actions. The Product site page stacks the address with its two links, the handle with its rename warning, the console switch, the list of admins with an add field, and the totals. The totals page is a grid of stat cards: the eight totals, a Jobs total and one card per job status. The text of each comes from the panes; the look is the shared UI kit's.

## States

- **Users pane**: loading, loaded, empty, and failed; a row is paused or active.
- **Product site page**: no product selected; loading; failed to load; no base domain (address not configured); a site, with the console off, on and live, or on and not answering yet; the handle field closed, or open with the rename warning; and a refused handle or switch.
- **Custom domain section**: hidden (loading, or the switch off); failed to load; loaded with no domain, or with domain boxes each pending, pending with an error, verified, verified and primary, failed or removing; the add field shown or not; a check, primary change or remove in flight; the remove confirmation open; and a refusal under the field or a box.
- **Totals**: loading, loaded and failed.

The Support page has four states: loading, loaded (grants listed), failed (the backend's message), and not available (the grants read answered 404 because consented access is off). A step-up refusal is not a state of the page: it leaves the page through the sign-in redirect and returns to `/support`.

The Jobs pages (phase 9) take their states from `JobStatusPane` and `JobTemplatesPane`: loading, loaded, empty (no runs, or no templates), failed (the backend's message), and not available (a 404 while the `jobs_feature` switch is off).
## Accessibility

Not applicable beyond the shared UI kit: the panes use its table, form, dialog and stat card components and add no focus handling of their own. The Custom domain section adds one live region per domain box, the state sentence alone ([domains-live-region](#requirements/domains-live-region)).
## Conformance Test Vectors

Vectors marked with a test name are asserted in `features/product-admin/src/__tests__/`, `features/ecosystem-config/src/ProductSitePane.test.tsx`, `features/ecosystem-config/src/ProductTotalsPane.test.tsx`, `features/ecosystem-config/src/ProductDomainsSection.test.tsx` (vectors 026 to 035, written from the phase 8 design), `features/adh-products/src/__tests__/topics.test.tsx` and `features/support-access/src/__tests__/SupportGrantsPane.test.tsx`. The others follow from the source.

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
| product-admin-site-026 | domains-section-hidden | The list answered 404 `not_found`; then still loading; then a 500 | Nothing rendered, no "Custom domain" heading; nothing; the heading and the error message |
| product-admin-site-027 | domains-box, domains-check-line | One domain in each status: pending with `checkedAt`, pending with a null `checkedAt`, verified, verified and primary, failed, removing | Each box shows the badges, text and buttons of its row in the table; the two check lines read as written |
| product-admin-site-028 | domains-demoted | A pending domain with `error` "the domain's DNS no longer points at Vercel" | The text names that problem and does not say "Waiting for the records below" |
| product-admin-site-029 | domains-records | A pending domain for `app.example.com` with a CNAME row and the `_adh-challenge.app.example.com` TXT row | The lead names `example.com`; the TXT row is last and the ownership sentence is under the table; each copy button copies the exact name or value |
| product-admin-site-030 | domains-add | An add with an empty field; then `app.example.com` added; then an add refused with `product_domain_limit` | The button is disabled; the field clears on success; the limit message shows under the field |
| product-admin-site-031 | domains-add | A product with a verified domain; then one with five pending domains | No add field in either |
| product-admin-site-032 | domains-remove | Remove on the primary, then on another domain, then cancelled | The primary's description names the subdomain origin becoming the primary again; the other's names only the host; nothing is sent when cancelled |
| product-admin-site-033 | domains-messages | Each refusal code in the table, an HTTP 403, an unknown code with a sentence, and one with no sentence | Each code's message; the managers message; the backend's sentence; "Something went wrong. Try again." |
| product-admin-site-034 | domains-text-only | A domain whose `error` holds `<b>bad</b>` | The markup shows as text; no `b` element is rendered |
| product-admin-site-035 | domains-check, domains-make-primary | Check now answered `verified`; then Make primary | The box becomes verified; a `PATCH` with `{ primary: true }` and the boxes follow the answered list |
| product-admin-site-036 | product-site-subdomain, product-site-also-at | A site whose `primaryOrigin` is `https://app.example.com` and `subdomainOrigin` is `https://jots.<base>`, then a rename opened | The handle's suffix is the subdomain's; the links use the custom domain with "Also at https://jots.<base>."; the warning names the subdomain addresses and says app.example.com stays the primary address |
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
- **Custom domains off (MUST)**: a 404 `not_found` on the domain list hides the Custom domain section entirely, as [domains-section-hidden](#requirements/domains-section-hidden) says.
- **A demoted domain (MUST)**: a verified domain the re-check moved back to pending shows the problem it found, and the Address group moves back to the subdomain because `primaryOrigin` does.
- **A remove left half done (MUST)**: a domain left `removing` says so and keeps its Remove button.
- **A custom domain is primary (MUST)**: the handle's suffix and the rename warning name the subdomain, which a rename changes, never the custom domain, which it does not.
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

- **`product_admin_site`**: the backend switch, folded by the backend into the site's `consoleLive` (the switch is on and the product's console is on with a login registration). The pane and the rail never read the switch itself: `consoleLive` false keeps every hub page, and true hides the moved pages. The Product site row is drawn either way, but only for an ecosystem of type `product` (the `types` gate).

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
| web | `packages/web/packages/features/ecosystem-config/src/ProductDomainsSection.tsx` | planned |

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
| 3.1.0 | 2026-11-27 | Mike Fullerton | Phase 8: the Custom domain section (ProductDomainsSection) and its human messages; the handle suffix and rename warning read subdomainOrigin; Also at the subdomain |
| 3.0.0 | 2026-11-26 | Mike Fullerton | The manager's Admin site page becomes the Product site page: address, handle rename, console switch, admins; the rail follows consoleLive |
| 2.2.0 | 2026-11-26 | Mike Fullerton | The console under /admin on each product's own site (the product-sites site): every topic href under /admin, the Jobs and Support pages' paths |
| 2.1.0 | 2026-11-23 | Mike Fullerton | Phase 9: a Jobs row between Sets and Totals (ten pages); /jobs renders JobStatusPane and /jobs/templates JobTemplatesPane, status only. |
| 2.0.0 | 2026-11-23 | Mike Fullerton | Phase 7: consented support access |
| 1.0.1 | 2026-11-23 | Mike Fullerton | Admin site removal confirmed; adding an admin keeps a listed address's set and refreshes the Sign-up list; an emptied later Users page steps back; Users keeps Email Signup and Authentication once a site is up; a routed Admin site row is kept while the site is unknown; runAtAdminSite |
| 1.0.0 | | | Initial creation |

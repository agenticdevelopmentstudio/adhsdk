---
id: 2eff6ca4-5479-44b3-8636-04e455009a10
title: "Support Panes"
type: ingredient
status: draft
language: en
summary: "Panes for consented support access: the customer's, the product admin's with a read-only viewer, and the operator's."
platforms:
  - typescript
  - web
tags:
  - support
  - panes
  - ui
depends-on:
  - 059c2877-d705-4ff4-b649-554fdafcfaaa
  - 3ea9329e-5acc-4c43-b5ce-bb8c50570104
version: 1.1.0
created: 2026-11-23
modified: 2026-11-23
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
related: []
references: []
---
# Support Panes

## Overview

These are the panes of consented support access. A customer, or a hub user, sees who asked to look at their content, approves or refuses, ends a grant and reads the log of what was read. A product's admin asks for a grant, and once it is approved opens a read-only viewer. An operator sees every grant, asks on a person's behalf, uses break-glass in an emergency, and reads the whole log. The data calls and the grant rules are in the support client ([adhsdk.ingredient.adh.hub.support.support-client](cookbook:059c2877-d705-4ff4-b649-554fdafcfaaa)); the step-up is the product admin session in the authentication client ([adhsdk.ingredient.data.services.auth.auth-client](cookbook:3ea9329e-5acc-4c43-b5ce-bb8c50570104)).

The pieces:

- `@adh-sdk/support-access` (`packages/web/packages/features/support-access/src/`, a new package): `SupportAccessPane` (customer and hub user), `GrantCard`, `AccessLogList`, `SupportGrantsPane` (product admin), `SupportViewer` and `AdminGrantCard` (the card of a grant for a product admin or an operator, reused by the operator panes).
- `@adh-sdk/adh-admin` (`packages/web/packages/features/adh-admin/src/panes/`): `SupportGrantsAdminPane`, `BreakGlassPane` and `SupportAccessLogPane`, registered as the operator site's panes `support-grants`, `break-glass` and `support-access`.
- The hub's settings topic `support-access` (`topics.ts`, `registry.tsx` and `UserSettingsOverlay.tsx` in `packages/web/packages/adh/src/settings/`), which renders `SupportAccessPane side="account"` for the signed-in hub user and is hidden when the grants read answers 404.

## Behavioral Requirements

### The person's pane

- **pane-grants**: `SupportAccessPane({ side })` MUST list the caller's grants, pending first, then live, then ended (newest request first within each); MUST show for each the grantee's name and role, the reason and the length asked for; MUST offer approve and deny on a pending grant, revoke on a live one, and nothing on an ended one, which is shown greyed with why it ended (Revoked, Denied, Lapsed or Expired). A grant with `consent` of `break_glass` MUST be marked "Emergency access" and say it was opened without asking.
- **pane-log**: under each approved grant the pane MUST show the read log (`AccessLogList`) grouped by table and day, as a sentence ("Ana from Support viewed your notes, 3 times on Tuesday"; "once" and "twice" for one and two, and "today" or "yesterday" for those days), never one line for each row read. It MUST page with `nextCursor` through a "Show more" button, regrouping over everything loaded.
- **pane-actions**: approve, deny and revoke MUST send the call of the client for the pane's `side` (`useDecideSupportGrant(side)`), and MUST leave the list and the log to refresh themselves by the invalidation the client's write hooks perform. A refusal MUST be shown as the backend words it.
- **pane-hidden-when-off**: when the grants read is refused with a 404 (applying `isSupportOff` to that read alone, so a refused viewer table is not mistaken for it), the pane MUST render nothing and the settings tab MUST be hidden.
- **settings-tab**: the hub's settings MUST list a "Support access" topic with the id `support-access` (in `topics.ts`), rendering `SupportAccessPane side="account"`, with its icon (a life buoy), description and the endpoint `/v1/account/support/grants` in `packages/web/packages/adh/src/settings/registry.tsx`. `useSettingsTopics` hides the topic when the account grants read answers 404, and shows it while that read is in flight or has failed any other way; `UserSettingsOverlay` takes its topics from it. A topic asked for while it is hidden (by `/settings/support-access`, or the overlay left on it when the read answers 404) MUST show the default topic instead of an empty pane; `visibleTopicId(topics, id)` in `registry.tsx` is that rule, and both `SettingsTab` and `UserSettingsOverlay` apply it.

### The product admin's pane

- **request-form**: `SupportGrantsPane({ ecosystemId })` MUST offer a customer picker over the roster (`useProductCustomers`, narrowed by a search box), a reason of 10 to 500 characters (counted trimmed) and a length of 1 to 168 hours (7 days) as a whole number, default 24 hours, and MUST refuse, without a request, no customer chosen or a reason or length outside those bounds. A customer chosen and then filtered out of the list by the search counts as no customer chosen: the request only ever goes to a customer the picker shows.
- **step-up-redirect**: when the request, or a revoke, is refused as `step_up_required` (read from the error's code or its body), the pane MUST call `stepUp(returnPath)`, default `/support`, from the product admin session (or the `onStepUp` prop, which overrides it), and MUST NOT show the refusal as an error. With neither a session nor `onStepUp`, it MUST say to sign in again with the second factor. Opening a grant is not step-up gated; a refused viewer read is shown in place.
- **grant-list**: the pane MUST list the product's grants, live first, then pending, then ended, with each one's state, and MUST offer open and revoke on a live grant. While the grants read answers 404 the pane MUST say support access is not turned on for the product.
- **viewer-open**: a live grant MUST open `SupportViewer` (the Open button), which offers the tables of `SUPPORT_CONTENT_TABLES` in a picker, pages one table's rows with Previous and Next, and shows one row (read by its `id`; a table whose rows have no `id` shows in the table only). When the page's `hasMore` is true but its `nextCursor` is null (more rows, and no `id` on the last to page from), the viewer MUST say the table has more rows than it can page through, rather than end as if the table did.
- **viewer-read-only**: `SupportViewer` MUST render no control that edits, creates or deletes a row, and MUST show a row's fields as text (a cell cut at 80 characters; the row view shows the whole value). A table the backend refuses (404) is shown as unavailable, and a grant that has ended (403) as no longer live.

### The operator panes

- **operator-grants**: `SupportGrantsAdminPane` MUST list all grants (`/v1/system/support_grants`) with a filter by status and by consent, break-glass grants apart from consented ones, paged with Previous and Next; MUST offer a request on behalf of a target (a customer, with the product's ecosystem id, or a hub user; ids as uuids; reason and length as in [request-form](#requirements/request-form)) and revoke on a live grant; and MUST show a revoked break-glass grant in red. A refused request is shown as the backend words it, and a `step_up_required` refusal as an instruction to sign in again with a second factor, since the operator console has no step-up redirect.
- **break-glass-form**: `BreakGlassPane` MUST ask for the target (a customer or a hub user, by uuid), the product for a customer, a reason of 10 to 500 characters (counted trimmed), an attestation of at least 40 characters (counted trimmed), a case or ticket reference of at most 500 characters and a length of 1 to 4 hours (default 1), MUST say that a second factor (aal 2, from a sign-in in the last ten minutes) is required, and MUST refuse a reason outside its bounds, a short attestation, a missing reference or a length outside the bounds without a request.
- **log-pane**: `SupportAccessLogPane` MUST list the read log of one grant (`/v1/system/support_access`), newest first, with each read's time, method and path, paged with Previous and Next. The backend reads it one grant at a time, so the pane MUST ask for a grant id (a uuid) first and read nothing before one is applied.
- **pane-ids**: the three panes MUST be registered in `adminPanes.ts` and the topics in `adminTopics.ts` with the ids `support-grants`, `break-glass` and `support-access` (labeled "Support Grants", "Break Glass" and "Support Access Log"), and `index.ts` MUST export them.

### The topic and the route

- **product-admin-topic**: `PRODUCT_ADMIN_TOPICS` MUST carry a `support` entry labeled "Support" with the `href` `/support` (in `features/product-admin/src/product-admin-topics.ts`), and MUST stay importable server-side.
- **route-share**: `/support` MUST be in the `hub` share (the hosted page) and in the `product-admin` share of `SITE_ROUTES_HUB` in `adh-registry/src/sites/routes.hub.generated.ts`.

## Appearance

Panes use the shared pane layout, card and list components. A grant is a card with the grantee's name and role, the reason, the length and a state badge: on the person's pane "Waiting for you", "Can view now" or why it ended (Revoked, Denied, Lapsed, Expired); on a product admin's or operator's, "Waiting for consent", "Live" or why it ended. A break-glass grant carries an extra badge ("Emergency access" on the person's pane, "Break-glass" on the others), and a revoked one is red on the operator site; the operator list shows break-glass grants apart from consented ones. The log is a list of sentences under its grant. The viewer is a plain table with an Open button for each row that has an id and no edit actions.
## States

| State | Behaviour |
|---|---|
| Loading | A plain "Loading…" line in the list, the log and the viewer (for each page). |
| Empty | "No one has asked to see your content" on the person's pane; "No grants yet." for a product admin, "No grants." for an operator, "Nothing has been viewed yet." for a log, "No rows." for a table. |
| Error | The backend's message as error text ("Couldn't load support access: ..." on the person's pane), with no retry control. A 403 `step_up_required` is not an error on the product admin's pane. |
| Switch off | The person's pane renders nothing; its settings tab is hidden. A product admin's or operator's pane says support access is not turned on. |
| Pending, live, ended | The card's badge and the actions it offers. |

## Accessibility

Each action is a button with a name that includes the grantee ("Approve Ana's request"). A state is shown in words as well as colour. The log sentences are a list named for the grantee ("What Ana viewed"). The viewer's table has header cells and each row's Open button is named for its row ("Open row 12"), so the row view is reachable by keyboard.

## Conformance Test Vectors

Vectors are asserted in `src/__tests__/SupportAccessPane.test.tsx` and `SupportGrantsPane.test.tsx` under `features/support-access`, and in `breakGlassPane.test.tsx`, `supportAccessLogPane.test.tsx` and `supportGrantsAdminPane.test.tsx` under `features/adh-admin/src/__tests__/`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| support-panes-001 | pane-grants | One pending, one live and one ended grant | Pending first; approve and deny on the first, revoke on the second, no action on the third |
| support-panes-002 | pane-actions | Approve pressed on `side="account"` | The decision is called with the grant's id and `approve`; the client POSTs `/v1/account/support/grants/{id}/approve` |
| support-panes-003 | pane-log | Three reads of notes on one day | One sentence naming the table and "3 times" ("Ben from Support viewed your notes, 3 times today") |
| support-panes-004 | pane-hidden-when-off | The grants read answered 404 | The pane renders nothing |
| support-panes-005 | request-form | A reason of nine characters; a length of 192 hours (eight days) | No request is sent; the form shows the message |
| support-panes-006 | step-up-redirect | The request refused as `step_up_required` | `stepUp('/support')` is called and no error is shown (also when read from the refusal's body; `onStepUp` overrides it) |
| support-panes-007 | viewer-read-only | A live grant opened to a table | The rows are shown and no edit, create or delete control exists (only Open, Previous and Next) |
| support-panes-008 | operator-grants | A revoked break-glass grant | The row is red |
| support-panes-009 | break-glass-form | An attestation of 39 characters | No request is sent |
| support-panes-010 | product-admin-topic, route-share | The topic list and the route share | A `support` entry with `/support`; the `/support` line in each share |
| support-panes-011 | settings-tab | The hub settings registry | A `support-access` topic with its endpoint `/v1/account/support/grants`, hidden on a 404 |
| support-panes-012 | grant-list | A product with one live and one ended grant | Both listed with their states, live first; open and revoke only on the live one |
| support-panes-013 | viewer-open | A live grant opened | The tables of `SUPPORT_CONTENT_TABLES` are offered; one table pages its rows (Next, Previous) and one row opens |
| support-panes-014 | log-pane, pane-ids | The log pane with a grant id applied, and with none; the registries | Only that grant's reads, newest first, and nothing read before an id is applied; the three ids present in `adminPanes.ts` and `adminTopics.ts` and exported |
| support-panes-015 | break-glass-form | The form open | It says a second factor is required, and refuses a missing reference |
## Edge Cases

- **A lapsed request (MUST)**: a request undecided for seven days shows as ended ("Lapsed"), with no approve button.
- **A grant ending while open (MUST)**: when a viewer read is refused because the grant has ended (403), the viewer says "This grant is no longer live." and offers no next page.
- **Break-glass on a person who is also a customer (MUST)**: the grant keeps the break-glass mark (it follows the grant's `consent`) in every list that shows it.
- **No second factor (MUST)**: a product admin without one is sent by the backend's refusal through the step-up redirect (`/auth/signin` with `prompt=login` and `max_age=600`); what the sign-in does after that, including enrolment, is the sign-in's, not the pane's.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `side` | `"customer"` or `"account"` | none, required | Which routes `SupportAccessPane` calls. |
| `ecosystemId` | string | none, required | The product `SupportGrantsPane` asks for grants in. |
| `returnPath` | string | `/support` | Where `SupportGrantsPane`'s step-up sign-in comes back to. |
| `onStepUp` | function | the product admin session's `stepUp` | Overrides the step-up of `SupportGrantsPane`. |
| `help` | node | none | Help content for each operator pane's title. |
| Length | hours | 24 (1 for break-glass) | Default request length; whole hours, bounds 1 to 168 (consented), 1 to 4 (break-glass). |
| Reason | characters | none | 10 to 500. |
| Attestation | characters | none | At least 40, counted trimmed. |
| Reference | characters | none | Required for break-glass; at most 500. |

## Deep Linking

The product admin's Support topic opens at `/support`, and the step-up returns the person there. The hosted page for an emailed link is a website page, not part of this component.

## Localization

The strings (headings, button names, state badges, the log sentences with their counts and days) are English literals in the components; none goes through a localization layer yet. The read count has its own words ("once", "twice", "N times") and the day is named as a person says it ("today", "yesterday", the weekday, then the date), using the browser's locale only for a grant's time. A port MUST localize every string and use plural forms for the read count.
## Accessibility Options

The panes follow the shared reduced-motion and contrast settings; nothing here animates.

## Feature Flags

Not applicable: the panes read no flag. The backend's `consented_access` switch is seen as a 404, which hides the person's pane and tab.

## Analytics

Not applicable: the panes emit no event.

## Privacy

- **Data collected**: None by the panes. They show a customer's rows only to a product admin holding a live grant, and only in the viewer.
- **Storage**: None. The viewer's rows live in React Query's memory cache and MUST NOT be written to storage or the URL.
- **Transmission**: Through the support client only.
- **Retention**: None.

## Logging

Not applicable: the panes log nothing.

## Platform Notes

- **SwiftUI**: Port each pane as a view over the same client, keeping the viewer free of edit controls.
- **Compose**: Use screens over the same repository and a read-only table.
- **React/Web**: The source platform: `packages/web/packages/features/support-access/` (a workspace package named `@adh-sdk/support-access`) and `packages/web/packages/features/adh-admin/src/panes/`. The `adh` package's `dist/` is rebuilt and committed after a change to its settings.
- **AppKit / UIKit**: As SwiftUI.
- **WinUI 3**: A page for each pane over the same client.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/features/support-access/` | confirmed (1.1.0) |
| web | `packages/web/packages/features/adh-admin/src/panes/BreakGlassPane.tsx` | confirmed (1.1.0) |
| web | `packages/web/packages/features/adh-admin/src/panes/SupportAccessLogPane.tsx` | confirmed (1.1.0) |
| web | `packages/web/packages/features/adh-admin/src/panes/SupportGrantsAdminPane.tsx` | confirmed (1.1.0) |
| web | `packages/web/packages/features/adh-admin/src/panes/supportTarget.tsx` | confirmed (1.1.0) |
| web | `packages/web/packages/adh/src/settings/registry.tsx` | confirmed (1.1.0) |
| web | `packages/web/packages/adh/src/settings/topics.ts` | confirmed (1.1.0) |

## Design Decisions

**Decision**: The customer's pane is one component for customers and hub users, chosen by `side`.
**Rationale**: The two views use the same routes under different prefixes, so one pane and one set of tests serve both.
**Approved**: pending

**Decision**: The viewer shows rows as text and has no edit controls at all.
**Rationale**: A grant is read-only in the design; a control that could never succeed would only mislead.
**Approved**: pending

**Decision**: The product admin pane starts the step-up (through the session's `stepUp` or an `onStepUp` prop) and the data client only recognises it (`isStepUpRequired`).
**Rationale**: Navigation belongs to the session provider; the pane decides where to return to.
**Approved**: pending

**Decision**: The strings are English literals in the components for now, with no localization layer.
**Rationale**: No hub pane is localized yet, so these follow the rest; the debt is paid when the hub adopts a localization layer, and **Localization** says what a port must do meanwhile.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |

The code is written. The panes hold no data rules (those are in the support client), and each pane has tests beside it. Both checks stay partial: no coverage figure has been measured, and the ingredient has not been confirmed check by check against the code.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.0 | 2026-11-23 | Mike Fullerton | Matches the code: operator filters and log pane, customer search, step-up on request and revoke, viewer paging, settings tab, break-glass bounds, English-literals decision |
| 1.0.0 | | | Initial creation |

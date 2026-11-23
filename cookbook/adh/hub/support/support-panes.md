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
version: 1.0.0
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

These are the panes of consented support access (phase 7). A customer, or a hub user, sees who asked to look at their content, approves or refuses, ends a grant and reads the log of what was read. A product's admin asks for a grant, and once it is approved opens a read-only viewer. An operator sees every grant, asks on a person's behalf, uses break-glass in an emergency, and reads the whole log. The data calls and the grant rules are in the support client ([adhsdk.ingredient.adh.hub.support.support-client](cookbook:059c2877-d705-4ff4-b649-554fdafcfaaa)); the step-up is the product admin session in the authentication client ([adhsdk.ingredient.data.services.auth.auth-client](cookbook:3ea9329e-5acc-4c43-b5ce-bb8c50570104)).

The pieces:

- `@adh-sdk/support-access` (`packages/web/packages/features/support-access/src/`, a new package): `SupportAccessPane` (customer and hub user), `GrantCard`, `AccessLogList`, `SupportGrantsPane` (product admin) and `SupportViewer`.
- `@adh-sdk/adh-admin` (`packages/web/packages/features/adh-admin/src/panes/`): `SupportGrantsAdminPane`, `BreakGlassPane` and `SupportAccessLogPane`, registered as the operator site's panes `support-grants`, `break-glass` and `support-access`.
- The hub's settings topic `support-access` (in `adh/src/settings/`), which renders `SupportAccessPane` for the signed-in hub user.

## Behavioral Requirements

### The person's pane

- **pane-grants**: `SupportAccessPane({ side })` MUST list the caller's grants, pending first, then live, then ended; MUST show for each the grantee's name and role, the reason and the length asked for; MUST offer approve and deny on a pending grant, revoke on a live one, and nothing on an ended one, which is shown greyed. A grant with `consent` of `break_glass` MUST be marked as such.
- **pane-log**: under each grant the pane MUST show the read log grouped by table and day, as a sentence ("Ana from Support viewed your notes, 3 times on Tuesday"), never one line for each row read. It MUST page with `nextCursor`.
- **pane-actions**: approve, deny and revoke MUST send the call of the client for the pane's `side`, and MUST leave the list to refresh itself by the invalidation the client's write hooks perform. A refusal MUST be shown as the backend words it.
- **pane-hidden-when-off**: when the grants read is refused with a 404 (applying `isSupportOff` to that read alone, so a refused viewer table is not mistaken for it), the pane MUST render nothing and the settings tab MUST be hidden.
- **settings-tab**: the hub's settings MUST list a "Support access" topic with the id `support-access`, rendering `SupportAccessPane side="account"`, with its icon, description and the endpoint `/v1/account/support` in `packages/web/packages/adh/src/settings/registry.tsx`.

### The product admin's pane

- **request-form**: `SupportGrantsPane({ ecosystemId })` MUST offer a customer picker over the roster (`productAdminApi.customers`), a reason of 10 to 500 characters and a length of 1 hour to 7 days, default 24 hours, and MUST refuse, without a request, a reason or length outside those bounds.
- **step-up-redirect**: when the request, or the opening of a grant, is refused as `step_up_required`, the pane MUST call `stepUp('/support')` from the product admin session, and MUST NOT show the refusal as an error.
- **grant-list**: the pane MUST list the product's grants with each one's state, and MUST offer revoke on a live grant.
- **viewer-open**: a live grant MUST open `SupportViewer`, which lists the tables of `SUPPORT_CONTENT_TABLES`, pages one table's rows and shows one row.
- **viewer-read-only**: `SupportViewer` MUST render no control that edits, creates or deletes a row, and MUST show a row's fields as text. A table the backend refuses is shown as unavailable.

### The operator panes

- **operator-grants**: `SupportGrantsAdminPane` MUST list all grants with a filter by product, state and grantee, MUST offer a request on behalf of a target and revoke, and MUST show a revoked break-glass grant in red.
- **break-glass-form**: `BreakGlassPane` MUST ask for the target, the product, a reason, an attestation of at least 40 characters, a case or ticket reference and a length of 1 to 4 hours, MUST say that a second factor is required, and MUST refuse a short attestation, a missing reference or a length outside the bounds without a request.
- **log-pane**: `SupportAccessLogPane` MUST list the read log, filterable by grant, newest first.
- **pane-ids**: the three panes MUST be registered in `adminPanes.ts` and the topics in `adminTopics.ts` with the ids `support-grants`, `break-glass` and `support-access`, and `index.ts` MUST export them.

### The topic and the route

- **product-admin-topic**: `PRODUCT_ADMIN_TOPICS` MUST carry a `support` entry labeled "Support" with the `href` `/support`, and MUST stay importable server-side.
- **route-share**: the hosted `/support` page MUST be in the `hub` route share and `/support` in the `product-admin` share of `routes.hub.generated.ts`.

## Appearance

Panes use the shared pane layout, card and list components. A grant is a card with the grantee's name and role, the reason, the length and a state badge: pending, live or ended. A break-glass grant carries an extra mark, and a revoked one is red on the operator site. The log is a list of sentences under its grant. The viewer is a plain table with no row actions.

## States

| State | Behaviour |
|---|---|
| Loading | The list shows the shared loading state; the viewer shows it for each page. |
| Empty | "No one has asked to see your content" on the person's pane; "No grants yet" for a product admin. |
| Error | The backend's message, in the shared error state, with retry. A 403 `step_up_required` is not an error here. |
| Switch off | The person's pane renders nothing; its settings tab is hidden. |
| Pending, live, ended | The card's badge and the actions it offers. |

## Accessibility

Each action is a button with a name that includes the grantee ("Approve Ana's request"). A state is shown in words as well as colour. The log sentences are a list. The viewer's table has header cells and the row view is reachable by keyboard.

## Conformance Test Vectors

Vectors are to be asserted in `src/__tests__/SupportAccessPane.test.tsx` and `SupportGrantsPane.test.tsx` under `features/support-access`, and beside each operator pane in `features/adh-admin`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| support-panes-001 | pane-grants | One pending, one live and one ended grant | Pending first; approve and deny on the first, revoke on the second, no action on the third |
| support-panes-002 | pane-actions | Approve pressed on `side="account"` | A `POST` of `/v1/account/support/grants/{id}/approve` |
| support-panes-003 | pane-log | Three reads of notes on one day | One sentence naming the table and "3 times" |
| support-panes-004 | pane-hidden-when-off | The grants read answered 404 | The pane renders nothing |
| support-panes-005 | request-form | A reason of nine characters; a length of eight days | No request is sent; each field shows its message |
| support-panes-006 | step-up-redirect | The request refused as `step_up_required` | `stepUp('/support')` is called and no error is shown |
| support-panes-007 | viewer-read-only | A live grant opened to a table | The rows are shown and no edit, create or delete control exists |
| support-panes-008 | operator-grants | A revoked break-glass grant | The row is red |
| support-panes-009 | break-glass-form | An attestation of 39 characters | No request is sent |
| support-panes-010 | product-admin-topic, route-share | The topic list and the route share | A `support` entry with `/support`; the `/support` line in each share |
| support-panes-011 | settings-tab | The hub settings registry | A `support-access` topic with its endpoint, hidden on a 404 |
| support-panes-012 | grant-list | A product with one live and one ended grant | Both listed with their states; revoke only on the live one |
| support-panes-013 | viewer-open | A live grant opened | The tables of `SUPPORT_CONTENT_TABLES` are listed; one table pages its rows and one row opens |
| support-panes-014 | log-pane, pane-ids | The log pane filtered by one grant; the registries | Only that grant's reads, newest first; the three ids present in `adminPanes.ts` and `adminTopics.ts` and exported |
| support-panes-015 | break-glass-form | The form open | It says a second factor is required, and refuses a missing reference |
## Edge Cases

- **A lapsed request (MUST)**: a request undecided for seven days shows as ended, with no approve button.
- **A grant ending while open (MUST)**: when the viewer's next page is refused because the grant has ended, the viewer says so and stops paging.
- **Break-glass on a person who is also a customer (MUST)**: the grant keeps the break-glass mark in every list that shows it.
- **No second factor (MUST)**: a product admin without one is sent by the backend's refusal through the step-up redirect, which leads to enrolment on sign-in.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `side` | `"customer"` or `"account"` | none, required | Which routes `SupportAccessPane` calls. |
| `ecosystemId` | string | none, required | The product `SupportGrantsPane` asks for grants in. |
| Length | hours | 24 | Default request length; bounds 1 to 168 (consented), 1 to 4 (break-glass). |
| Reason | characters | none | 10 to 500. |
| Attestation | characters | none | At least 40. |

## Deep Linking

The product admin's Support topic opens at `/support`, and the step-up returns the person there. The hosted page for an emailed link is a website page, not part of this component.

## Localization

All strings (headings, button names, state badges, the log sentences with their counts and days) go through the SDK's localization, with plural forms for the read count.

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
- **React/Web**: The source platform: `packages/web/packages/features/support-access/` (a workspace package named `@adh-sdk/support-access`, tooling copied from `features/product-admin`) and `packages/web/packages/features/adh-admin/src/panes/`. The `adh` package's `dist/` is rebuilt and committed after a change to its settings.
- **AppKit / UIKit**: As SwiftUI.
- **WinUI 3**: A page for each pane over the same client.

## Design Decisions

**Decision**: The customer's pane is one component for customers and hub users, chosen by `side`.
**Rationale**: The two views use the same routes under different prefixes, so one pane and one set of tests serve both.
**Approved**: pending

**Decision**: The viewer shows rows as text and has no edit controls at all.
**Rationale**: A grant is read-only in the design; a control that could never succeed would only mislead.
**Approved**: pending

**Decision**: The product admin pane starts the step-up and the data client only recognises it.
**Rationale**: Navigation belongs to the session provider; the pane decides where to return to.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |

The panes are not written yet, so both checks are partial until the code lands and the ingredient is confirmed against it.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | | | Initial creation |

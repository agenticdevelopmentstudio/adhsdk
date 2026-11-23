
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


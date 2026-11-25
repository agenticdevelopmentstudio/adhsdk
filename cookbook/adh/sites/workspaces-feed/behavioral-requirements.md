
- **menu-context-contract**: The workspaces-menu context MUST carry
  `workspaces` (rows of `id`, `label`, `href` and optional `current`) and
  `loading`, and MAY carry `error`, `select`, `selectStaysOnPage` and
  `everyRoute`.
- **menu-context-absent**: Reading the workspaces-menu context with no
  provider mounted MUST return `null`, so the menu hides its workspace rows.
- **feed-sign-in-signal**: The feed MUST count the visitor as signed in
  exactly when the stored token has a subject.
- **feed-reads-every-row**: The feed MUST read rows through the every-row
  read state, enabled only while signed in, so no request fires without a
  subject.
- **feed-default-mode**: The switch mode MUST default to `preference`.
- **feed-error-gated**: `error` MUST be `true` only while signed in and the
  read has failed.
- **feed-rows-resolved**: Each row MUST carry the row's composite id as
  `id` and the list-label helper's answer as `label`.
- **preference-rows**: In preference mode the rows MUST be the
  non-team rows, one per slug (first per slug), in the backend's order.
- **preference-current**: In preference mode the current row MUST be the one
  whose slug is the stored preference when that slug is among the rows (the
  browser's cached preference before the server's answer is in), else, once
  the server's preference has settled or the preference wait has run out
  (preference-wait-bounded), the individual row.
- **preference-current-waits**: In preference mode, while signed in, the
  server's preference has not settled, the preference names none of the
  rows and the preference wait has not run out, NO row MUST be current.
- **preference-wait-bounded**: In preference mode the wait on the server's
  preference MUST run out 3000 ms after it begins with no answer; the
  individual row is then current while the preference still reads
  unsettled, and a preference that answers later naming one of the rows
  MUST become current.
- **preference-wait-afresh**: In preference mode a wait that begins again
  (signing back in, the subject changing straight to another user, a
  settled preference dropping back to unsettled) MUST be timed afresh from
  its start, never counted as already run out.
- **preference-href-hub**: In preference mode each row's `href` MUST open
  that workspace (`/<slug>`) on the hub, built from the request host when
  one is known and from the hub's production URL otherwise.
- **preference-pick-records**: In preference mode a pick MUST record the
  picked row's slug as the preference and MUST NOT navigate.
- **preference-stays-on-page**: In preference mode `selectStaysOnPage` MUST
  be `true`.
- **preference-every-route**: In preference mode `everyRoute` MUST be `true`
  while signed in and absent otherwise.
- **preference-loading**: In preference mode `loading` MUST be `true` only
  while signed in, unless the read has failed with no rows to show, and
  either the read is loading or the current row waits on the server's
  preference (preference-current-waits). Rows a failed background refetch
  kept still count as rows to show.
- **preference-enables-preference**: The preference read state MUST be
  enabled only in preference mode while signed in.
- **route-rows**: In route mode the rows MUST be every row, teams included,
  one per slug (first per slug), in the backend's order, each with `href`
  `/<slug>`.
- **route-current**: In route mode the current row MUST be the one whose
  slug equals the URL path's first segment, and no row MUST be current when
  that segment is no row's slug.
- **route-loading**: In route mode `loading` MUST be `true` while there is
  no subject or the read is loading.
- **route-no-every-route**: In route mode `everyRoute` and
  `selectStaysOnPage` MUST be absent.
- **route-pick-registered**: In route mode a pick MUST map the row's id to
  its slug over the kept rows and call the switch registered at pick time
  with that slug, or push `/<slug>` when none is registered; an id with no
  kept row MUST do nothing.
- **route-registrar-provided**: The route-switch registrar MUST be provided
  only in route mode; anywhere else registering is a no-op.
- **route-register-hook**: The register hook MUST hand the registrar the
  route's switch on mount and whenever the switch changes, and `null` on
  unmount, before paint.
- **route-registration-no-render**: A registration MUST NOT re-render the
  provider or change the `select` the menu holds.
- **feed-entry-isolated**: The feed MUST be published as its own entry
  (`@adh-sdk/adh/header/workspaces-feed`), not through the header barrel,
  and MUST reach the menu context through the package path
  `@adh-sdk/adh/header`.



These are the panes of consented support access (phase 7). A customer, or a hub user, sees who asked to look at their content, approves or refuses, ends a grant and reads the log of what was read. A product's admin asks for a grant, and once it is approved opens a read-only viewer. An operator sees every grant, asks on a person's behalf, uses break-glass in an emergency, and reads the whole log. The data calls and the grant rules are in the support client ([adhsdk.ingredient.adh.hub.support.support-client](cookbook:059c2877-d705-4ff4-b649-554fdafcfaaa)); the step-up is the product admin session in the authentication client ([adhsdk.ingredient.data.services.auth.auth-client](cookbook:3ea9329e-5acc-4c43-b5ce-bb8c50570104)).

The pieces:

- `@adh-sdk/support-access` (`packages/web/packages/features/support-access/src/`, a new package): `SupportAccessPane` (customer and hub user), `GrantCard`, `AccessLogList`, `SupportGrantsPane` (product admin) and `SupportViewer`.
- `@adh-sdk/adh-admin` (`packages/web/packages/features/adh-admin/src/panes/`): `SupportGrantsAdminPane`, `BreakGlassPane` and `SupportAccessLogPane`, registered as the operator site's panes `support-grants`, `break-glass` and `support-access`.
- The hub's settings topic `support-access` (in `adh/src/settings/`), which renders `SupportAccessPane` for the signed-in hub user.


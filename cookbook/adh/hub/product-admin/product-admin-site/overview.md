
This is the feature layer of a product's admin site (phase 6). A product's own admins sign in to a separate host, the product admin site, and manage the people of that one product. The hub's managers set the site up from the Admin site page of the product's workspace. The data calls are in the product admin client ([adhsdk.ingredient.adh.hub.product-admin.product-admin-client](cookbook:150bf00e-6c6b-4f91-a323-d307ebd5700d)); the sign-in is the product admin session in the authentication client ([adhsdk.ingredient.data.services.auth.auth-client](cookbook:3ea9329e-5acc-4c43-b5ce-bb8c50570104)); the people panes it reuses are the ecosystem configuration panes and the ecosystem invitation panes. This recipe covers what ties them into a site: the page list, the users pane, the manager's Admin site page and the rule for which hub pages move to the site.

The pieces:

- `@adh-sdk/product-admin` (`packages/web/packages/features/product-admin/src/`): `ProductUsersPane` and `PRODUCT_ADMIN_TOPICS`. The barrel is a client module; the topic list is also published at `@adh-sdk/product-admin/topics` so a server module can read it.
- `@adh-sdk/ecosystem-config`: `AdminSitePane` (the manager's page: the site's host, and the product's admins) and `ProductTotalsPane` (the eight figures, shown on the site's Totals page).
- `@adh-sdk/adh-products` (`topics.ts`, `ProductsFeature.tsx`): the Admin site topic row and `visibleProductTopics`, which hides the hub's people pages once a site carries them.
- `@adh-sdk/ecosystems`: the requests, pending and invites panes take `hideAdminRecords`.
- `@adh-sdk/jobs` ([adhsdk.ingredient.adh.hub.jobs](cookbook:0bcb370d-a44f-48a8-a313-0266c2f86e51), phase 9, not yet written): `JobStatusPane` and `JobTemplatesPane`, shown on the site's Jobs pages.
- `@adh-sdk/site-registry`: the `product-admin` site and the `admin-site` hub segment (see the site registry recipe).


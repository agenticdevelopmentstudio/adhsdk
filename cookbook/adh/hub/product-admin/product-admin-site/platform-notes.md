
- **SwiftUI**: A table with a cursor stack for paging and a confirmation dialog for each write; the topic list is a static array.
- **Compose**: A lazy list, a cursor stack in the view model and an alert dialog per write.
- **React/Web**: The source platform. `packages/web/packages/features/product-admin/src/` holds `ProductUsersPane.tsx` and `product-admin-topics.ts`; `packages/web/packages/features/ecosystem-config/src/` holds `AdminSitePane.tsx` and `ProductTotalsPane.tsx`; `packages/web/packages/features/adh-products/src/topics.ts` and `ProductsFeature.tsx` hold the Admin site row and `visibleProductTopics`. The `/admin/jobs` and `/admin/jobs/templates` pages mount `JobStatusPane` and `JobTemplatesPane` from `packages/web/packages/features/jobs/` (phase 9). The page routes themselves live in the hub website's product-sites app, under `app/admin/`. The package's `sideEffects` and `exports` publish the `./topics` entry beside the barrel.
- **AppKit / UIKit**: As SwiftUI, with a table view and an alert per write.
- **WinUI 3**: A data grid and a content dialog per write.


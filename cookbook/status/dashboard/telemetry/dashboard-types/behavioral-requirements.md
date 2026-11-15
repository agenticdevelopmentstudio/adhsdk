
### Constants

- **ranges-list**: `ANALYTICS_RANGES` MUST be exactly `"24h"`, `"7d"`, `"30d"`, in that order, and `AnalyticsRange` MUST be derived from it.
- **dimensions-list**: `DIMENSIONS` MUST be exactly `"country"`, `"device"`, `"browser"`, `"referrer"`, in that order.
- **vercel-breakdowns-list**: `VERCEL_BREAKDOWNS` MUST be exactly `"countries"`, `"referrers"`, `"paths"`, `"devices"`, in that order.
- **vitals-list**: `VITALS` MUST be exactly `"lcp"`, `"inp"`, `"cls"`, `"fcp"`, in that order.
- **vital-rating-values**: A vital rating MUST be one of `"good"`, `"fair"` or `"poor"`; a missing rating is `null`, not a fourth value.
- **breakdown-topics**: A breakdown topic MUST be one of `"pages"`, `"countries"`, `"referrers"`, `"devices"` or `"browsers"`.

### Sections

- **section-shape**: Every section MUST be typed with `data`, `error` and `updatedAt`, each nullable, and a response MUST be typed with one section for each name in its section-data type (`DashboardSections` maps every name to a `DashboardSection` of that name's data).
- **analytics-sections**: The analytics sections MUST be `traffic`, `dimensions`, `paths`, `vitals`, `health` and `vercel`.
- **errors-sections**: The errors sections MUST be `issues`, `sites`, `detail` and `runtime`.

### Envelope

- **envelope-common**: Both responses MUST be typed with `generatedAt` (a timestamp string), `refreshing` (a boolean), `configured` (a flag per source) and `views`.
- **analytics-envelope**: The analytics response MUST carry its `range` and `configured` flags for `posthog` and `vercel`.
- **errors-envelope**: The errors response MUST carry `refreshingSources` with a flag each for `glitchtip` and `posthog`, and `refreshing` MUST be true when either is true; `configured` MUST carry flags for `glitchtip`, `posthog` and `vercel`.

### Errors

- **runtime-window**: The runtime report's `window` MUST be typed as the literal `"24h"`.

### Parity

- **mirror-parity**: The web copy MUST stay mutually assignable with the server's types for the two responses, the runtime report and both views; a renamed field, changed nullability or changed union member MUST fail the type check.
- **mirror-constants**: The four constant lists MUST equal the server's lists, in value and order.
- **types-only**: Apart from the four lists, the module MUST hold only types and interfaces and MUST NOT run code at load beyond defining those lists.


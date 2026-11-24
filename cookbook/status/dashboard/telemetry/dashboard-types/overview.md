
Dashboard Wire Types is the typed contract for the two dashboard responses the status server sends: the analytics dashboard (`GET /analytics/dashboard`) and the errors dashboard (`GET /errors/dashboard`). It holds no behavior except four constant lists. Everything else is a shape: what a client may rely on being present, nullable or a list.

The source is a hand-kept mirror of the server's own dashboard types file. The web package has the server only as a development dependency and cannot import its types at run time, so it keeps a copy. A drift test (`dashboard-types-parity.test.ts`) fails when the two copies disagree.

A response has three parts:

- **Envelope** — `generatedAt`, `refreshing`, which sources are `configured`, and (errors only) which sources are still refreshing.
- **Sections** — the raw data per source, each wrapped as a section that keeps its last good answer next to the latest failure (`DashboardSection`).
- **Views** — what the pages draw, already joined, sorted, thresholded and rated by the server. The pages only lay them out.

The constant lists are the analytics ranges (`ANALYTICS_RANGES`), the breakdown dimensions (`DIMENSIONS`), the Vercel breakdowns (`VERCEL_BREAKDOWNS`) and the web vitals (`VITALS`). The dashboard queries recipe consumes the responses, and the formatting module, Dashboard Formatting ([adhsdk.ingredient.status.dashboard.lib.dashboard-format](cookbook:c861465b-50c8-49d1-93cc-00d9e062ad5f)), consumes `AnalyticsRange`, `Vital` and the site list. For number and time wording see Format ([adhsdk.ingredient.status.dashboard.logic.format](cookbook:564c6102-e100-41ad-9c92-14606a33c394)).


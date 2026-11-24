
This module holds the dashboard's two cached reads of the status backend's dashboard routes, plus the rule that sets how often they poll. It exports three things:

- **the analytics-dashboard read** — takes an analytics range (`"24h"`, `"7d"` or `"30d"`) and an optional options object, requests `/analytics/dashboard?range=<range>` and returns the read result typed as the analytics dashboard response.
- **the errors-dashboard read** — takes an optional options object, requests `/errors/dashboard` and returns the read result typed as the errors dashboard response.
- **the poll-interval function** (`dashboardPollMs`) — takes a body, or `undefined`, and returns `5000` when the body's `refreshing` flag is true and `60000` otherwise.

Both routes answer at once with whatever the backend already has and keep refreshing behind the response, so the dashboard watches them fill in: it polls quickly while the body says `refreshing`, then at the board's usual pace. Both reads send their request through the dashboard's injected API client (see status-web-api ([adhsdk.ingredient.status.dashboard.api](cookbook:eb7e9eeb-86f3-4053-827a-ea259833c6ad))) and share one request helper that throws on a non-ok response. The response shapes come from the dashboard wire-type mirror ([adhsdk.ingredient.status.dashboard.telemetry.dashboard-types](cookbook:e8f3cd4d-e208-49db-a500-24d6f7b978f9)). Compare the sibling read that does not poll, status-web-hooks-use-uptime ([adhsdk.ingredient.status.dashboard.state.uptime](cookbook:e322fd0c-1552-4bd9-b129-3c809af3a972)).

Consumers: the board shell calls each read with `enabled` set from the open topic, so only the visible topic fetches and polls; the analytics view and the errors view call the same reads with no options, sharing the cache entry the board shell filled.


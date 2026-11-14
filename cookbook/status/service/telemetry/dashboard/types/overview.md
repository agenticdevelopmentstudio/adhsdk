
`types.ts` declares the wire shapes of the two telemetry dashboard endpoints: `GET /analytics/dashboard` (`AnalyticsDashboardResponse`) and `GET /errors/dashboard` (`ErrorsDashboardResponse`). It also gathers the names a client needs in one place: it re-exports the range, dimension, vercel-breakdown and vital constants and the view types from `views.ts`, and the runtime-error types from `../types`.

The file holds only interfaces, type re-exports and three value re-exports. It has no behavior. The contract it states is the JSON that `dashboard-set.ts` builds and the routes in `routes/telemetry-dashboards.ts` send.

The web client `status-web` keeps a hand-written mirror in `telemetry/dashboard-types.ts`, because it has the server only as a devDependency. The test `dashboard-types-parity.test.ts` holds the mirror to this file. A recipe-following port to another platform carries the same obligation: its model types must stay equal to these.

Each endpoint answers with a set of cached sections, each in the shape `DashboardSection` from the sectioned-dashboard recipe (`data`, `error`, `updatedAt`), plus a derived `views` object.


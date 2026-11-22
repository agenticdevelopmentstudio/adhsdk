
Two files declare the wire types for the session daemon's usage endpoints, each in an extension of the `Sessions` namespace. `InsightsDTOs.swift` covers the `/insights/*` HTTP endpoints; `GraphSnapshotDTO.swift` covers the `/visualization/graph` endpoint. Both files state the same wire rule in their opening comment: "Snake-case JSON on the wire; camelCase Swift on this side." There are thirteen types, all `public struct`, all `Codable` and `Sendable`, each with immutable `let` fields and a public memberwise initializer that assigns its arguments and does nothing else:

| Type | File | Endpoint that returns it | Role |
|------|------|--------------------------|------|
| `InsightsSummaryDTO` | `InsightsDTOs.swift` | `/insights/summary` | Summary card values at the top of the Insights dashboard |
| `EventsPerDayDTO` | `InsightsDTOs.swift` | `/insights/events-per-day` (array) | One row of the events-per-day stacked bar chart |
| `ToolUsageDTO` | `InsightsDTOs.swift` | `/insights/tools` (array) | One row of the tool usage bar chart |
| `ProjectActivityDTO` | `InsightsDTOs.swift` | `/insights/projects` (array) | One row of the top-projects bar chart |
| `SessionsPerDayDTO` | `InsightsDTOs.swift` | `/insights/sessions-per-day` (array) | One row of the sessions-per-day line chart |
| `DailyMetricDTO` | `InsightsDTOs.swift` | `/insights/daily-metrics` (array) | One rolled-up daily statistic from the `daily_metric` table |
| `CacheMissCauseDTO` | `InsightsDTOs.swift` | nested in `CacheMissesDTO.causes` | One row of the cache-miss cause histogram |
| `CacheMissModelDTO` | `InsightsDTOs.swift` | nested in `CacheMissesDTO.models` | Cache-miss totals for one (model, TTL) pair |
| `SystemPromptDeltaDTO` | `InsightsDTOs.swift` | nested in `CacheMissesDTO.systemPromptDeltas` | How many characters the system prompt moved on a `system_prompt_changed` miss |
| `CacheMissesDTO` | `InsightsDTOs.swift` | `/insights/cache-misses` | What prompt-cache misses cost, and why they happened |
| `GraphSnapshotDTO` | `GraphSnapshotDTO.swift` | `/visualization/graph` | Full graph snapshot rendered by the Visualization window |
| `GraphNodeDTO` | `GraphSnapshotDTO.swift` | nested in `GraphSnapshotDTO.nodes` | One node in the force-directed graph |
| `GraphLinkDTO` | `GraphSnapshotDTO.swift` | nested in `GraphSnapshotDTO.links` | One edge between two nodes |

The types carry no logic. The values in them are computed by `DaemonDatabase` (`insightsSummary`, `eventsPerDay`, `toolUsage`, `projectActivity`, `sessionsPerDay`, `dailyMetrics`, `cacheMisses` and `graphSnapshot` in `Database/Daemon/Usage`) and served by `UsageRoutes`, which encodes each through `RouteResponse.json`, the snake_case wire encoder described in Route Response ([adhsdk.ingredient.foundation.routing.route-response](cookbook:6a645c72-4525-4b96-9df4-85abecfacd27)). This recipe specifies the shapes and the meaning the doc comments give each field, so a port of the daemon or of a client reads and writes the same JSON. The file comments still call these "the stenographer `/insights/*` HTTP endpoints" and "the stenographer `/visualization/graph` endpoint"; the routes are now the shared `UsageRoutes` set any session daemon mounts.


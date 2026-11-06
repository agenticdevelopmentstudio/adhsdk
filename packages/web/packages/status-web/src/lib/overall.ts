// The portfolio rollup `GET /status` publishes as `overall` (status-server monitor/overall.ts
// owns the rule). Type only; read-types-parity.test.ts holds it to the server's union.
export type OverallStatus = "operational" | "degraded" | "major_outage" | "unknown";

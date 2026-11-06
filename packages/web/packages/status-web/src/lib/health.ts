// An endpoint's health, as the server classifies it (status-server monitor/health.ts owns
// the rule). Type only — the client renders the verdict and never judges a probe itself.
// read-types-parity.test.ts holds this mirror to the server's union.
export type HealthStatus = "healthy" | "degraded" | "down";

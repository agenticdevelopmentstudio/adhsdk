// The deploy vocabulary as TYPES ONLY. status-server's monitor/deploy-status.ts owns every
// rule over it — the provider phase mappings, `combinedStatus`, what counts as in flight,
// and the demotion of an unconfirmed in-flight phase (served as `/live`'s
// `effectiveStatus`). deploy-status-parity.test.ts holds these unions to the server's.

export type DeployStatus = "success" | "failed" | "building" | "queued" | "canceled" | "unknown";

// Two platform-independent lifecycles. `buildPhase = null` → the platform reports
// no build lifecycle (Cloudflare Workers list only already-live deployments).
// `unknown` is TERMINAL: an in-flight phase the backend could not re-confirm for
// its expiry window, so it stopped asserting it. Like `canceled` it is the
// ABSENCE of a verdict — never good or bad.
export type BuildPhase = "queued" | "building" | "built" | "failed" | "canceled" | "unknown";
export type DeployPhase = "none" | "deploying" | "deployed" | "failed" | "unknown";

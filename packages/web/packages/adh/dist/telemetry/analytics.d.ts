import { type AnalyticsProps } from '@adh-sdk/analytics';
/** The explicit allowlist of instrumented event names — one source of truth. */
export declare const EVENT_HTTP_REQUEST = "http_request";
/** Property bag for a custom event — scalars only (no nested objects/PII). */
export type EventProps = AnalyticsProps;
/** Called by TelemetryProvider once PostHog has been initialized. */
export declare function setPosthogReady(ready: boolean): void;
/**
 * Capture a custom analytics event. No-ops (beyond an optional dev console line) unless
 * PostHog initialized. NEVER throws — telemetry must not affect the instrumented path.
 */
export declare function captureEvent(name: string, props: EventProps): void;
export { markRetriedRequest, consumeRetriedFlag } from '@adh-sdk/adh/telemetry/retry';
//# sourceMappingURL=analytics.d.ts.map
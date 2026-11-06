import { describe, it, expect } from "vitest";
import type * as server from "@adh-sdk/status-server/types";
import type * as web from "../types";
import type * as live from "./live-types";
import type * as telemetry from "../telemetry/types";
import type { HealthStatus } from "./health";
import type { OverallStatus } from "./overall";

// DRIFT GUARD for the read API. ../types.ts and ./live-types.ts mirror status-server's
// monitor/types.ts and monitor/live-types.ts by hand (the server is only a devDependency).
// Every verdict the dashboard shows now arrives as a field on these shapes, so a field the
// server added, renamed or made nullable on one side only would leave the board rendering
// `undefined` with no compile error — `pnpm test` transpiles without typechecking. These
// assertions only compile while both sides agree.

/** Mutual assignability: a renamed field, a nullability or a union member stops this being true. */
type Exact<A, B> = [A] extends [B] ? ([B] extends [A] ? true : never) : never;

const readsAgree: [
  Exact<server.HealthStatus, HealthStatus>,
  Exact<server.OverallStatus, OverallStatus>,
  Exact<server.ServiceStatusDTO, web.ServiceStatusDTO>,
  Exact<server.EndpointCounts, web.EndpointCounts>,
  Exact<server.StatusResponse, web.StatusResponse>,
  Exact<server.UptimeTone, web.UptimeTone>,
  Exact<server.UptimeResponse, web.UptimeResponse>,
  Exact<server.DeploymentDTO, web.DeploymentDTO>,
  Exact<server.HistoryResponse, web.HistoryResponse>,
  Exact<server.IntegrationCheck, web.IntegrationCheck>,
  Exact<server.SelfCheckView, web.SelfCheckView>,
  Exact<server.IntegrationsResponse, web.IntegrationsResponse>,
] = [true, true, true, true, true, true, true, true, true, true, true, true];

const liveAgrees: [
  Exact<server.LiveServiceDTO, live.LiveServiceDTO>,
  Exact<server.LiveDeploymentDTO, live.LiveDeploymentDTO>,
  Exact<server.LiveFreshness, live.LiveFreshness>,
  Exact<server.PlatformSummary, live.PlatformSummary>,
  Exact<server.StaleMonitorsView, live.StaleMonitorsView>,
  Exact<server.LiveSnapshot, live.LiveSnapshot>,
] = [true, true, true, true, true, true];

const telemetryAgrees: [
  Exact<server.ErrorDTO, telemetry.ErrorDTO>,
  Exact<server.AnalyticsMetricDTO, telemetry.AnalyticsMetricDTO>,
  Exact<server.ErrorsSummary, telemetry.ErrorsSummary>,
  Exact<server.TelemetrySnapshot, telemetry.TelemetrySnapshot>,
] = [true, true, true, true];

describe("read API type parity (web mirrors server)", () => {
  it("compiles only while the read contracts agree", () => {
    expect([...readsAgree, ...liveAgrees, ...telemetryAgrees].every(Boolean)).toBe(true);
  });
});

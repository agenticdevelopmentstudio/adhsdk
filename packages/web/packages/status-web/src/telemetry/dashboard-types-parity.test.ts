import { describe, expect, it } from "vitest";
import {
  ANALYTICS_RANGES as SERVER_RANGES,
  DIMENSIONS as SERVER_DIMENSIONS,
  VERCEL_BREAKDOWNS as SERVER_VERCEL_BREAKDOWNS,
  VITALS as SERVER_VITALS,
} from "@adh-sdk/status-server/dashboard-types";
import type * as server from "@adh-sdk/status-server/dashboard-types";
import { ANALYTICS_RANGES, DIMENSIONS, VERCEL_BREAKDOWNS, VITALS } from "./dashboard-types";
import type * as web from "./dashboard-types";

// DRIFT GUARD. dashboard-types.ts is a hand mirror of status-server's, because this package only
// has the server as a devDependency. The type half only compiles while both sides agree, so it is
// a typecheck that catches drift: `pnpm test` transpiles without checking types.

/** Mutual assignability: a renamed field, a nullability or a union member stops this being true. */
type Exact<A, B> = [A] extends [B] ? ([B] extends [A] ? true : never) : never;

export const responsesAgree: [
  Exact<server.AnalyticsDashboardResponse, web.AnalyticsDashboardResponse>,
  Exact<server.ErrorsDashboardResponse, web.ErrorsDashboardResponse>,
  Exact<server.RuntimeErrorsReport, web.RuntimeErrorsReport>,
  Exact<server.AnalyticsViews, web.AnalyticsViews>,
  Exact<server.ErrorsViews, web.ErrorsViews>,
] = [true, true, true, true, true];

describe("dashboard types", () => {
  it("offer the same ranges", () => {
    expect([...ANALYTICS_RANGES]).toEqual([...SERVER_RANGES]);
  });

  it("name the same breakdowns and vitals", () => {
    expect([...DIMENSIONS]).toEqual([...SERVER_DIMENSIONS]);
    expect([...VERCEL_BREAKDOWNS]).toEqual([...SERVER_VERCEL_BREAKDOWNS]);
    expect([...VITALS]).toEqual([...SERVER_VITALS]);
  });
});

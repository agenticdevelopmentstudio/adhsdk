import { describe, expect, it } from "vitest";
import {
  ANALYTICS_RANGES as SERVER_RANGES,
  DIMENSIONS as SERVER_DIMENSIONS,
  VERCEL_BREAKDOWNS as SERVER_VERCEL_BREAKDOWNS,
  VITALS as SERVER_VITALS,
} from "@adh-sdk/status-server/dashboard-types";
import type * as server from "@adh-sdk/status-server/dashboard-types";
import * as webModule from "./dashboard-types";
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
  it("dtypes-001 dash-types-001 offer the same ranges", () => {
    expect([...ANALYTICS_RANGES]).toEqual([...SERVER_RANGES]);
  });

  it("dtypes-002 dash-types-002 name the same breakdowns and vitals", () => {
    expect([...DIMENSIONS]).toEqual([...SERVER_DIMENSIONS]);
    expect([...VERCEL_BREAKDOWNS]).toEqual([...SERVER_VERCEL_BREAKDOWNS]);
    expect([...VITALS]).toEqual([...SERVER_VITALS]);
  });

  it("dtypes-003 dash-types-003 the five responses are mutually assignable, and the check rejects a mismatch", () => {
    expect(responsesAgree).toEqual([true, true, true, true, true]);
    // Negative control: Exact must yield `never` for differing types, so this line only compiles with the directive.
    // @ts-expect-error the types differ, so Exact is never and `true` is not assignable
    const mismatch: Exact<{ a: 1 }, { a: 2 }> = true;
    void mismatch;
  });

  it("dtypes-015 the analytics sections are exactly the six named", () => {
    const names: [Exact<keyof web.AnalyticsSectionData, "traffic" | "dimensions" | "paths" | "vitals" | "health" | "vercel">] = [true];
    expect(names).toEqual([true]);
    const sections: web.DashboardSections<web.AnalyticsSectionData> = {
      traffic: { data: null, error: null, updatedAt: null },
      dimensions: { data: null, error: null, updatedAt: null },
      paths: { data: null, error: null, updatedAt: null },
      vitals: { data: null, error: null, updatedAt: null },
      health: { data: null, error: null, updatedAt: null },
      vercel: { data: null, error: null, updatedAt: null },
    };
    expect(Object.keys(sections).sort()).toEqual(["dimensions", "health", "paths", "traffic", "vercel", "vitals"]);
  });

  it("dtypes-016 the errors sections are exactly the four named", () => {
    const names: [Exact<keyof web.ErrorsSectionData, "issues" | "sites" | "detail" | "runtime">] = [true];
    expect(names).toEqual([true]);
  });

  it("dtypes-017 both responses carry generatedAt, refreshing, configured and views", () => {
    const common: [
      Exact<Pick<web.AnalyticsDashboardResponse, "generatedAt" | "refreshing" | "configured" | "views">["generatedAt"], string>,
      Exact<Pick<web.ErrorsDashboardResponse, "generatedAt" | "refreshing" | "configured" | "views">["refreshing"], boolean>,
    ] = [true, true];
    expect(common).toEqual([true, true]);
  });

  it("dtypes-025 dash-types-014 only the four lists exist at run time", () => {
    expect(Object.keys(webModule).sort()).toEqual(["ANALYTICS_RANGES", "DIMENSIONS", "VERCEL_BREAKDOWNS", "VITALS"]);
  });

  it("dtypes-012 the runtime report window is the literal 24h", () => {
    const w: [Exact<web.RuntimeErrorsReport["window"], "24h">] = [true];
    expect(w).toEqual([true]);
  });

  it("dtypes-018 the analytics response carries range and configured flags for posthog and vercel", () => {
    const c: [Exact<web.AnalyticsDashboardResponse["configured"], { posthog: boolean; vercel: boolean }>, Exact<web.AnalyticsDashboardResponse["range"], web.AnalyticsRange>] = [true, true];
    expect(c).toEqual([true, true]);
  });

  it("dtypes-009 the errors envelope carries refreshingSources flags for glitchtip and posthog", () => {
    const c: [Exact<web.ErrorsDashboardResponse["refreshingSources"], { glitchtip: boolean; posthog: boolean }>] = [true];
    expect(c).toEqual([true]);
  });
});

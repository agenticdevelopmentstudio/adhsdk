import { describe, expect, it } from "vitest";
import { ANALYTICS_RANGES as SERVER_RANGES } from "@agentic-toolkit/status-server/dashboard-types";
import type * as server from "@agentic-toolkit/status-server/dashboard-types";
import { ANALYTICS_RANGES } from "./dashboard-types";
import type * as web from "./dashboard-types";

// DRIFT GUARD. dashboard-types.ts is a hand mirror of status-server's, because this package only
// has the server as a devDependency. The type half only compiles while both sides agree, so it is
// a typecheck that catches drift: `pnpm test` transpiles without checking types.

/** Mutual assignability: a renamed field, a nullability or a union member stops this being true. */
type Exact<A, B> = [A] extends [B] ? ([B] extends [A] ? true : never) : never;

export const responsesAgree: [
  Exact<server.AnalyticsDashboardResponse, web.AnalyticsDashboardResponse>,
  Exact<server.ErrorsDashboardResponse, web.ErrorsDashboardResponse>,
] = [true, true];

describe("dashboard types", () => {
  it("offer the same ranges", () => {
    expect([...ANALYTICS_RANGES]).toEqual([...SERVER_RANGES]);
  });
});

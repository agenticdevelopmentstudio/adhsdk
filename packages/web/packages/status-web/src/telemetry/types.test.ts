import { describe, expect, it } from "vitest";
import { withKnownAnalytics, type AnalyticsMetricDTO, type TelemetrySnapshot } from "./types";

const metric = { metric: "pageviews", value: 42 } as unknown as AnalyticsMetricDTO;
const snap = (over: Partial<TelemetrySnapshot>): TelemetrySnapshot => ({ generatedAt: "t", errors: [], analytics: [], ...over });

describe("withKnownAnalytics", () => {
  it("keeps the known analytics while the backend has none to give yet", () => {
    const merged = withKnownAnalytics(snap({ analyticsPending: true }), snap({ analytics: [metric] }));
    expect(merged.analytics).toEqual([metric]);
  });

  it("takes an answered empty list as the answer", () => {
    expect(withKnownAnalytics(snap({}), snap({ analytics: [metric] })).analytics).toEqual([]);
  });

  it("leaves a pending snapshot alone when nothing is known", () => {
    const live = snap({ analyticsPending: true });
    expect(withKnownAnalytics(live, null)).toBe(live);
  });
});

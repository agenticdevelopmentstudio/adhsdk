// @vitest-environment jsdom
// The insight API layer at the `authedJson` boundary: every report builds the
// documented URL and query string, every price-table write sends the documented
// method and body, and a write invalidates every insight read (a rate change
// re-prices all of them).
import { beforeEach, describe, expect, it, vi } from "vitest";
import type { ReactNode } from "react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { renderHook, waitFor } from "@testing-library/react";

const { authedJson, listAllV1 } = vi.hoisted(() => ({ authedJson: vi.fn(), listAllV1: vi.fn() }));
vi.mock("../http", () => ({ authedJson, listAllV1 }));

import {
  INSIGHT_QUERY_KEY,
  insightApi,
  useBreakdown,
  useBreakdownDetail,
  useCreateFixedCost,
  useCreateRate,
  useDeleteFixedCost,
  useDeleteRate,
  useFixedCosts,
  useInsightItems,
  useInsightOverview,
  useRates,
  useRunRate,
  useUpdateFixedCost,
  useUpdateRate,
} from "../insight";

const range = { from: "2026-09-01", to: "2026-09-30" };
const KEY = "0b7c1b1e-7a3f-4c1e-9a55-2f1d2c3b4a59";

beforeEach(() => {
  authedJson.mockReset();
  listAllV1.mockReset();
});

function harness() {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  const wrapper = ({ children }: { children: ReactNode }) => (
    <QueryClientProvider client={client}>{children}</QueryClientProvider>
  );
  return { client, wrapper };
}

describe("insightApi reports", () => {
  beforeEach(() => authedJson.mockResolvedValue({}));

  it("run rate: the month as a query param", async () => {
    await insightApi.runRate("2026-09");
    expect(authedJson).toHaveBeenCalledWith("/api/v1/usage/insights/run_rate?month=2026-09");
  });

  it("items: the range", async () => {
    await insightApi.items(range);
    expect(authedJson).toHaveBeenCalledWith(
      "/api/v1/usage/insights/items?from=2026-09-01&to=2026-09-30",
    );
  });

  it("overview: the range, with the interval only when given", async () => {
    await insightApi.overview(range, "week");
    expect(authedJson).toHaveBeenLastCalledWith(
      "/api/v1/usage/insights/overview?from=2026-09-01&to=2026-09-30&interval=week",
    );
    await insightApi.overview(range);
    expect(authedJson).toHaveBeenLastCalledWith(
      "/api/v1/usage/insights/overview?from=2026-09-01&to=2026-09-30",
    );
  });

  it("breakdown: range, dimension, and only the paging/sort params that are set", async () => {
    await insightApi.breakdown({ ...range, by: "organization" });
    expect(authedJson).toHaveBeenLastCalledWith(
      "/api/v1/usage/insights/breakdown?from=2026-09-01&to=2026-09-30&by=organization",
    );
    await insightApi.breakdown({ ...range, by: "persona", sort: "estimated", limit: 25, offset: 50 });
    expect(authedJson).toHaveBeenLastCalledWith(
      "/api/v1/usage/insights/breakdown?from=2026-09-01&to=2026-09-30&by=persona&sort=estimated&limit=25&offset=50",
    );
  });

  it("breakdown detail: dimension and key in the path, range in the query", async () => {
    await insightApi.breakdownDetail("user", KEY, range);
    expect(authedJson).toHaveBeenCalledWith(
      `/api/v1/usage/insights/breakdown?from=2026-09-01&to=2026-09-30&by=user&key=${KEY}`,
    );
  });
});

describe("insightApi price tables", () => {
  it("lists walk the /v1 list envelope to its end", async () => {
    const rate = { id: "r1" };
    listAllV1.mockResolvedValueOnce([rate]);
    await expect(insightApi.rates()).resolves.toEqual([rate]);
    expect(listAllV1).toHaveBeenLastCalledWith("/api/v1/usage/rates");

    const cost = { id: "f1" };
    listAllV1.mockResolvedValueOnce([cost]);
    await expect(insightApi.fixedCosts()).resolves.toEqual([cost]);
    expect(listAllV1).toHaveBeenLastCalledWith("/api/v1/usage/fixed_costs");
  });

  it("rates: POST, PATCH by id, DELETE by id", async () => {
    authedJson.mockResolvedValue({});
    const body = {
      category: "llm" as const,
      provider: "anthropic",
      sku: "claude-x",
      quantity_key: "input_tokens",
      micros_per_unit: "3",
    };
    await insightApi.createRate(body);
    expect(authedJson).toHaveBeenLastCalledWith("/api/v1/usage/rates", {
      method: "POST",
      body: JSON.stringify(body),
    });
    await insightApi.updateRate("r1", { micros_per_unit: "2.5" });
    expect(authedJson).toHaveBeenLastCalledWith("/api/v1/usage/rates/r1", {
      method: "POST",
      body: JSON.stringify({ micros_per_unit: "2.5" }),
    });
    await insightApi.deleteRate("r1");
    expect(authedJson).toHaveBeenLastCalledWith("/api/v1/usage/rates/r1", { method: "DELETE" });
  });

  it("fixed costs: POST, PATCH by id, DELETE by id", async () => {
    authedJson.mockResolvedValue({});
    const body = {
      provider: "railway",
      label: "Hosting",
      monthly_micros: 20_000_000,
      effective_from: "2026-09-01",
    };
    await insightApi.createFixedCost(body);
    expect(authedJson).toHaveBeenLastCalledWith("/api/v1/usage/fixed_costs", {
      method: "POST",
      body: JSON.stringify(body),
    });
    await insightApi.updateFixedCost("f1", { effective_to: null });
    expect(authedJson).toHaveBeenLastCalledWith("/api/v1/usage/fixed_costs/f1", {
      method: "POST",
      body: JSON.stringify({ effective_to: null }),
    });
    await insightApi.deleteFixedCost("f1");
    expect(authedJson).toHaveBeenLastCalledWith("/api/v1/usage/fixed_costs/f1", {
      method: "DELETE",
    });
  });
});

// Explicit row types: each hook returns its own result type, which a bare tuple array would
// unify into one (and then reject the other rows).
type QueryRow = [name: string, hook: () => { isSuccess: boolean }, url: string];
type MutationRow = [
  name: string,
  hook: () => { mutateAsync: (vars: never) => Promise<unknown> },
  vars: unknown,
];

describe("query hooks", () => {
  beforeEach(() => {
    authedJson.mockResolvedValue({});
    listAllV1.mockResolvedValue([]);
  });

  it.each<QueryRow>([
    ["useRunRate", () => useRunRate("2026-09"), "/api/v1/usage/insights/run_rate?month=2026-09"],
    [
      "useInsightItems",
      () => useInsightItems(range),
      "/api/v1/usage/insights/items?from=2026-09-01&to=2026-09-30",
    ],
    [
      "useInsightOverview",
      () => useInsightOverview(range, "month"),
      "/api/v1/usage/insights/overview?from=2026-09-01&to=2026-09-30&interval=month",
    ],
    [
      "useBreakdown",
      () => useBreakdown({ ...range, by: "ecosystem", sort: "requests" }),
      "/api/v1/usage/insights/breakdown?from=2026-09-01&to=2026-09-30&by=ecosystem&sort=requests",
    ],
    [
      "useBreakdownDetail",
      () => useBreakdownDetail("organization", KEY, range),
      `/api/v1/usage/insights/breakdown?from=2026-09-01&to=2026-09-30&by=organization&key=${KEY}`,
    ],
    ["useRates", () => useRates(), "/api/v1/usage/rates"],
    ["useFixedCosts", () => useFixedCosts(), "/api/v1/usage/fixed_costs"],
  ])("%s fetches its URL under the insight key", async (_name, hook, url) => {
    const { client, wrapper } = harness();
    const { result } = renderHook(hook, { wrapper });
    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    // The two price-table lists walk the /v1 envelope; every report is one authed read.
    const reader = url === "/api/v1/usage/rates" || url === "/api/v1/usage/fixed_costs" ? listAllV1 : authedJson;
    expect(reader).toHaveBeenCalledWith(url);
    const keys = client.getQueryCache().getAll().map((q) => q.queryKey);
    expect(keys).toHaveLength(1);
    expect(keys[0]!.slice(0, INSIGHT_QUERY_KEY.length)).toEqual([...INSIGHT_QUERY_KEY]);
  });

  it("useBreakdownDetail stays idle until a key is chosen", () => {
    const { wrapper } = harness();
    const { result } = renderHook(() => useBreakdownDetail("user", undefined, range), { wrapper });
    expect(result.current.fetchStatus).toBe("idle");
    expect(authedJson).not.toHaveBeenCalled();
  });
});

describe("mutation hooks invalidate every insight read", () => {
  beforeEach(() => authedJson.mockResolvedValue({}));

  it.each<MutationRow>([
    ["useCreateRate", () => useCreateRate(), { category: "llm", provider: "p", sku: "s", quantity_key: "k", micros_per_unit: "1" }],
    ["useUpdateRate", () => useUpdateRate(), { id: "r1", changes: { note: "n" } }],
    ["useDeleteRate", () => useDeleteRate(), "r1"],
    ["useCreateFixedCost", () => useCreateFixedCost(), { provider: "p", label: "l", monthly_micros: 1, effective_from: "2026-09-01" }],
    ["useUpdateFixedCost", () => useUpdateFixedCost(), { id: "f1", changes: { label: "l" } }],
    ["useDeleteFixedCost", () => useDeleteFixedCost(), "f1"],
  ])("%s", async (_name, hook, vars) => {
    const { client, wrapper } = harness();
    const spy = vi.spyOn(client, "invalidateQueries");
    const { result } = renderHook(hook, { wrapper });
    // Each hook takes its own variables; the table pairs them by row.
    await result.current.mutateAsync(vars as never);
    expect(spy).toHaveBeenCalledWith({ queryKey: INSIGHT_QUERY_KEY });
  });
});

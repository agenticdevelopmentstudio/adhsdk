// @vitest-environment jsdom
// The operator-access hook at the `listV1Page` boundary: each filter becomes its own query key
// beside the window's `limit`/`starting_after`, blanks are left off, and wire rows map camelCase.
import { createElement, type ReactNode } from "react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { cleanup, renderHook, waitFor } from "@testing-library/react";

const { listV1Page } = vi.hoisted(() => ({ listV1Page: vi.fn() }));
// `withV1Query` is pure, so the real one builds the URLs under test; only the network is replaced.
vi.mock("../http", async (importOriginal) => ({
  ...(await importOriginal<typeof import("../http")>()),
  listV1Page,
}));

import {
  operatorAccessUrl,
  useOperatorAccess,
  type OperatorAccessFilters,
} from "../admin";

const OP = "11111111-1111-4111-8111-111111111111";
const ECO = "22222222-2222-4222-8222-222222222222";

const wire = (over: Record<string, unknown> = {}) => ({
  id: "row-1",
  object: "system.operator_access",
  at: "2026-11-21 10:00:00.123+00",
  operator_account_id: OP,
  token_id: null,
  method: "GET",
  path: "/v1/ecosystems",
  route: "/v1/ecosystems",
  target_ecosystem_id: ECO,
  request_id: "req-1",
  ip: "127.0.0.1",
  user_agent: "vitest",
  ...over,
});

beforeEach(() => {
  listV1Page.mockReset();
  listV1Page.mockResolvedValue({ data: [], hasMore: false });
});
afterEach(cleanup);

function run(filters?: OperatorAccessFilters) {
  const client = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
  const wrapper = ({ children }: { children: ReactNode }) =>
    createElement(QueryClientProvider, { client }, children);
  return renderHook(() => useOperatorAccess(filters), { wrapper });
}

/** The query of the one URL the hook asked for. */
async function requested(): Promise<URLSearchParams> {
  await waitFor(() => expect(listV1Page).toHaveBeenCalled());
  const url = String(listV1Page.mock.calls[0]?.[0]);
  expect(url.startsWith("/api/v1/system/operator_access?")).toBe(true);
  return new URLSearchParams(url.slice(url.indexOf("?") + 1));
}

describe("operatorAccessUrl", () => {
  it("is the bare collection with no filters", () => {
    expect(operatorAccessUrl()).toBe("/api/v1/system/operator_access");
  });

  it("drops blank filters rather than sending empty keys", () => {
    expect(
      operatorAccessUrl({
        operatorAccountId: " ",
        targetEcosystemId: "",
        from: undefined,
      }),
    ).toBe("/api/v1/system/operator_access");
  });
});

describe("useOperatorAccess", () => {
  it("asks for the newest 100 with no filter keys", async () => {
    run();
    const q = await requested();
    expect(q.get("limit")).toBe("100");
    expect(q.has("starting_after")).toBe(false);
    expect(q.has("after")).toBe(false);
    for (const k of [
      "operator_account_id",
      "target_ecosystem_id",
      "from",
      "to",
    ]) {
      expect(q.has(k)).toBe(false);
    }
  });

  it.each([
    [{ operatorAccountId: OP }, "operator_account_id", OP],
    [{ targetEcosystemId: ECO }, "target_ecosystem_id", ECO],
    [{ from: "2026-11-01T00:00:00.000Z" }, "from", "2026-11-01T00:00:00.000Z"],
    [{ to: "2026-11-21T00:00:00.000Z" }, "to", "2026-11-21T00:00:00.000Z"],
  ] as const)("sends %o as %s", async (filters, key, value) => {
    run(filters);
    const q = await requested();
    expect(q.get(key)).toBe(value);
    expect(q.get("limit")).toBe("100");
  });

  it("sends every filter together", async () => {
    run({
      operatorAccountId: OP,
      targetEcosystemId: ECO,
      from: "2026-11-01T00:00:00.000Z",
      to: "2026-11-21T00:00:00.000Z",
    });
    const q = await requested();
    expect(q.get("operator_account_id")).toBe(OP);
    expect(q.get("target_ecosystem_id")).toBe(ECO);
    expect(q.get("from")).toBe("2026-11-01T00:00:00.000Z");
    expect(q.get("to")).toBe("2026-11-21T00:00:00.000Z");
  });

  it("maps the wire rows onto the camelCase event, keeping nulls as null", async () => {
    listV1Page.mockResolvedValue({
      data: [
        wire(),
        wire({
          id: "row-2",
          token_id: "tok",
          route: null,
          target_ecosystem_id: null,
          request_id: null,
          ip: null,
          user_agent: null,
        }),
      ],
      hasMore: true,
    });
    const { result } = run();
    await waitFor(() => expect(result.current.rows).toHaveLength(2));
    expect(result.current.rows[0]).toEqual({
      id: "row-1",
      at: "2026-11-21 10:00:00.123+00",
      operatorAccountId: OP,
      tokenId: null,
      method: "GET",
      path: "/v1/ecosystems",
      route: "/v1/ecosystems",
      targetEcosystemId: ECO,
      requestId: "req-1",
      ip: "127.0.0.1",
      userAgent: "vitest",
    });
    expect(result.current.rows[1]).toMatchObject({
      tokenId: "tok",
      route: null,
      targetEcosystemId: null,
      requestId: null,
      ip: null,
      userAgent: null,
    });
    expect(result.current.hasMore).toBe(true);
  });

  it("asks for the next page after the last row held, keeping the filters", async () => {
    listV1Page.mockResolvedValueOnce({ data: [wire()], hasMore: true });
    listV1Page.mockResolvedValueOnce({
      data: [wire({ id: "row-2" })],
      hasMore: false,
    });
    const { result } = run({ operatorAccountId: OP });
    await waitFor(() => expect(result.current.rows).toHaveLength(1));
    result.current.loadMore();
    await waitFor(() => expect(result.current.rows).toHaveLength(2));
    const url = String(listV1Page.mock.calls[1]?.[0]);
    const q = new URLSearchParams(url.slice(url.indexOf("?") + 1));
    expect(q.get("starting_after")).toBe("row-1");
    expect(q.get("operator_account_id")).toBe(OP);
    expect(q.has("after")).toBe(false);
  });
});

// @vitest-environment jsdom
import { afterEach, describe, expect, it, vi } from "vitest";
import { createElement, type ReactNode } from "react";
import { act, renderHook, waitFor } from "@testing-library/react";
import { QueryClient, QueryClientProvider, useQuery } from "@tanstack/react-query";
import { StatusApiProvider, createStatusApiClient } from "../api/client";
import { dashboardPollMs, useAnalyticsDashboard, useErrorsDashboard } from "./use-dashboards";

type Stub = ReturnType<typeof vi.fn>;

function setup(fetchStub: Stub | null) {
  const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  const client = fetchStub
    ? createStatusApiClient({ fetch: fetchStub as unknown as typeof fetch })
    : undefined;
  const wrapper = ({ children }: { children: ReactNode }) =>
    createElement(
      QueryClientProvider,
      { client: queryClient },
      client ? createElement(StatusApiProvider, { client }, children) : children,
    );
  return { wrapper, queryClient };
}

// Plain response doubles rather than `Response`: a real body stream resolves outside the fake
// timers, which would leave a polled read stuck mid-flight.
const answer = (status: number, text: string): Response =>
  ({
    ok: status >= 200 && status < 300,
    status,
    json: async () => JSON.parse(text),
  }) as unknown as Response;
const ok = (body: unknown): Response => answer(200, JSON.stringify(body));
const failing = (status: number, body: string): Response => answer(status, body);
const settledBody = { refreshing: false };
const fillingBody = { refreshing: true };

/** A stub answering each call from a queue, repeating the last answer once it runs out. */
function queued(...answers: Array<() => Response | Promise<Response>>): Stub {
  let i = 0;
  return vi.fn(async () => answers[Math.min(i++, answers.length - 1)]());
}

async function advance(ms: number): Promise<void> {
  await act(async () => {
    await vi.advanceTimersByTimeAsync(ms);
  });
}

function setVisibility(state: "hidden" | "visible"): void {
  Object.defineProperty(document, "visibilityState", { value: state, configurable: true });
  act(() => {
    document.dispatchEvent(new Event("visibilitychange", { bubbles: true }));
  });
}

afterEach(() => {
  vi.useRealTimers();
  vi.unstubAllGlobals();
  Object.defineProperty(document, "visibilityState", { value: "visible", configurable: true });
});

describe("use-dashboards", () => {
  it("dash-001 polls every 5000 ms while the body is refreshing", () => {
    expect(dashboardPollMs({ refreshing: true })).toBe(5000);
  });

  it("dash-002 polls every 60000 ms once the body has settled", () => {
    expect(dashboardPollMs({ refreshing: false })).toBe(60000);
  });

  it("dash-003 polls every 60000 ms with no data", () => {
    expect(dashboardPollMs(undefined)).toBe(60000);
  });

  it("dash-004 keeps the old body on a failed refetch and drops the poll to 60000 ms", async () => {
    vi.useFakeTimers();
    const f = queued(
      () => ok(fillingBody),
      () => failing(502, "<html>Bad Gateway</html>"),
    );
    const { wrapper } = setup(f);
    const { result } = renderHook(() => useErrorsDashboard(), { wrapper });
    await advance(0);
    expect(result.current.data).toEqual(fillingBody);
    expect(result.current.isError).toBe(false); // read now, so the result tracks the error flag
    await advance(5000); // the filling poll fires and fails
    await advance(10); // let the result notify
    expect(f).toHaveBeenCalledTimes(2);
    expect(result.current.isError).toBe(true);
    expect(result.current.data).toEqual(fillingBody);
    await advance(54_000); // 54s after the failure: not the 5s pace
    expect(f).toHaveBeenCalledTimes(2);
    await advance(7000); // past 60s after the failure
    expect(f).toHaveBeenCalledTimes(3);
  });

  it("dash-005 reads the analytics dashboard for a range through the default client", async () => {
    const f = vi.fn(async () => ok(settledBody));
    vi.stubGlobal("fetch", f);
    const { wrapper } = setup(null);
    const { result } = renderHook(() => useAnalyticsDashboard("7d"), { wrapper });
    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(f).toHaveBeenCalledTimes(1);
    expect(f).toHaveBeenCalledWith("/api/analytics/dashboard?range=7d", undefined);
    expect(result.current.data).toEqual(settledBody);
  });

  it("dash-006 reads the errors dashboard and caches it under errors-dashboard", async () => {
    const f = vi.fn(async () => ok(settledBody));
    const { wrapper, queryClient } = setup(f);
    const { result } = renderHook(() => useErrorsDashboard(), { wrapper });
    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(f).toHaveBeenCalledTimes(1);
    expect(f).toHaveBeenCalledWith("/api/errors/dashboard", undefined);
    expect(queryClient.getQueryData(["errors-dashboard"])).toEqual(settledBody);
  });

  it("dash-007 issues no fetch while disabled, even after 60 seconds", async () => {
    vi.useFakeTimers();
    const f = vi.fn(async () => ok(settledBody));
    const { wrapper } = setup(f);
    renderHook(() => useAnalyticsDashboard("7d", { enabled: false }), { wrapper });
    renderHook(() => useErrorsDashboard({ enabled: false }), { wrapper });
    await advance(0);
    expect(f).not.toHaveBeenCalled();
    await advance(60_000);
    expect(f).not.toHaveBeenCalled();
  });

  it("dash-008 keeps the previous range's body while the next range loads", async () => {
    let release: (r: Response) => void = () => {};
    const f = queued(
      () => ok({ refreshing: false, range: "24h" }),
      () => new Promise<Response>((resolve) => (release = resolve)),
    );
    const { wrapper } = setup(f);
    const { result, rerender } = renderHook(
      ({ range }: { range: "24h" | "7d" }) => useAnalyticsDashboard(range),
      { wrapper, initialProps: { range: "24h" } },
    );
    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(result.current.isPlaceholderData).toBe(false);
    rerender({ range: "7d" });
    await waitFor(() => expect(f).toHaveBeenCalledTimes(2));
    expect(result.current.data).toEqual({ refreshing: false, range: "24h" });
    expect(result.current.isPlaceholderData).toBe(true);
    await act(async () => {
      release(ok({ refreshing: false, range: "7d" }));
    });
    await waitFor(() => expect(result.current.isPlaceholderData).toBe(false));
    expect(result.current.data).toEqual({ refreshing: false, range: "7d" });
  });

  it("dash-009 carries the nested error message of a non-ok response", async () => {
    const f = vi.fn(async () => failing(500, '{"error":{"message":"Unauthorized"}}'));
    const { wrapper } = setup(f);
    const { result } = renderHook(() => useErrorsDashboard(), { wrapper });
    await waitFor(() => expect(result.current.isError).toBe(true));
    expect(result.current.error?.message).toBe("Unauthorized");
  });

  it("dash-010 carries the plain-string error message of a non-ok response", async () => {
    const f = vi.fn(async () => failing(500, '{"error":"invalid range"}'));
    const { wrapper } = setup(f);
    const { result } = renderHook(() => useAnalyticsDashboard("7d"), { wrapper });
    await waitFor(() => expect(result.current.isError).toBe(true));
    expect(result.current.error?.message).toBe("invalid range");
  });

  it("dash-011 falls back to the status when the body has no message", async () => {
    const html = setup(vi.fn(async () => failing(502, "<html>Bad Gateway</html>")));
    const a = renderHook(() => useErrorsDashboard(), { wrapper: html.wrapper });
    await waitFor(() => expect(a.result.current.isError).toBe(true));
    expect(a.result.current.error?.message).toBe("status 502");

    const empty = setup(vi.fn(async () => failing(500, '{"error":{}}')));
    const b = renderHook(() => useErrorsDashboard(), { wrapper: empty.wrapper });
    await waitFor(() => expect(b.result.current.isError).toBe(true));
    expect(b.result.current.error?.message).toBe("status 500");
  });

  it("dash-012 errors with the JSON parse rejection on a 200 that is not JSON", async () => {
    const f = vi.fn(async () => answer(200, "not json"));
    const { wrapper } = setup(f);
    const { result } = renderHook(() => useErrorsDashboard(), { wrapper });
    await waitFor(() => expect(result.current.isError).toBe(true));
    expect(result.current.error).toBeInstanceOf(SyntaxError);
  });

  it("dash-013 surfaces a network failure unchanged", async () => {
    const failure = new TypeError("Failed to fetch");
    const f = vi.fn(async () => {
      throw failure;
    });
    const { wrapper } = setup(f);
    const { result } = renderHook(() => useAnalyticsDashboard("7d"), { wrapper });
    await waitFor(() => expect(result.current.isError).toBe(true));
    expect(result.current.error).toBe(failure);
  });

  it("dash-014 sends one request for two callers of the same range under one cache", async () => {
    const f = vi.fn(async () => ok(settledBody));
    const { wrapper } = setup(f);
    const a = renderHook(() => useAnalyticsDashboard("30d"), { wrapper });
    const b = renderHook(() => useAnalyticsDashboard("30d"), { wrapper });
    await waitFor(() => expect(a.result.current.isSuccess).toBe(true));
    await waitFor(() => expect(b.result.current.isSuccess).toBe(true));
    expect(f).toHaveBeenCalledTimes(1);
  });

  it("dash-015 returns to 5000 ms on its own after an error recovers", async () => {
    vi.useFakeTimers();
    const f = queued(
      () => ok(fillingBody),
      () => failing(502, "bad"),
      () => ok(fillingBody),
    );
    const { wrapper } = setup(f);
    const { result } = renderHook(() => useErrorsDashboard(), { wrapper });
    await advance(0);
    expect(f).toHaveBeenCalledTimes(1);
    expect(result.current.isError).toBe(false); // read now, so the result tracks the error flag
    await advance(5000); // filling pace: second call fails
    await advance(10); // let the result notify
    expect(f).toHaveBeenCalledTimes(2);
    expect(result.current.isError).toBe(true);
    await advance(59_000); // error pace: still waiting
    expect(f).toHaveBeenCalledTimes(2);
    await advance(1_500); // third call succeeds with refreshing: true
    await advance(10);
    expect(f).toHaveBeenCalledTimes(3);
    expect(result.current.isError).toBe(false);
    await advance(5000); // back on the filling pace with no caller action
    expect(f).toHaveBeenCalledTimes(4);
  });

  it("dash-016 refetches the analytics dashboard when the window regains focus", async () => {
    const f = vi.fn(async () => ok(settledBody));
    const { wrapper } = setup(f);
    const { result } = renderHook(() => useAnalyticsDashboard("7d"), { wrapper });
    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(f).toHaveBeenCalledTimes(1);
    setVisibility("hidden");
    setVisibility("visible");
    await waitFor(() => expect(f).toHaveBeenCalledTimes(2));
    expect(f.mock.calls[1][0]).toBe("/api/analytics/dashboard?range=7d");
  });

  it("dash-017 refetches the errors dashboard when the window regains focus", async () => {
    const f = vi.fn(async () => ok(settledBody));
    const { wrapper } = setup(f);
    const { result } = renderHook(() => useErrorsDashboard(), { wrapper });
    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(f).toHaveBeenCalledTimes(1);
    setVisibility("hidden");
    setVisibility("visible");
    await waitFor(() => expect(f).toHaveBeenCalledTimes(2));
    expect(f.mock.calls[1][0]).toBe("/api/errors/dashboard");
  });

  it("dash-018 shows no previous data to a fresh errors caller under a cleared cache", async () => {
    let release: (r: Response) => void = () => {};
    const f = queued(
      () => ok({ refreshing: false, n: 1 }),
      () => new Promise<Response>((resolve) => (release = resolve)),
    );
    const { wrapper, queryClient } = setup(f);
    const first = renderHook(() => useErrorsDashboard(), { wrapper });
    await waitFor(() => expect(first.result.current.isSuccess).toBe(true));
    first.unmount();
    queryClient.clear();
    const second = renderHook(() => useErrorsDashboard(), { wrapper });
    await waitFor(() => expect(f).toHaveBeenCalledTimes(2));
    expect(second.result.current.data).toBeUndefined();
    expect(second.result.current.isPlaceholderData).toBe(false);
    await act(async () => {
      release(ok({ refreshing: false, n: 2 }));
    });
    await waitFor(() => expect(second.result.current.data).toEqual({ refreshing: false, n: 2 }));
  });

  it("dash-019 returns the plain read result with the parsed body", async () => {
    const f = vi.fn(async () => ok(settledBody));
    const { wrapper } = setup(f);
    const plain = renderHook(
      () => useQuery({ queryKey: ["plain"], queryFn: async () => settledBody }),
      { wrapper },
    );
    await waitFor(() => expect(plain.result.current.isSuccess).toBe(true));
    for (const hook of [() => useAnalyticsDashboard("7d"), () => useErrorsDashboard()]) {
      const { result } = renderHook(hook, { wrapper });
      await waitFor(() => expect(result.current.isSuccess).toBe(true));
      expect(result.current.data).toEqual(settledBody);
      expect(Object.keys(result.current).sort()).toEqual(Object.keys(plain.result.current).sort());
    }
  });

  it("dash-020 starts one fetch and polling when enabled switches on", async () => {
    vi.useFakeTimers();
    const f = vi.fn(async () => ok(settledBody));
    const { wrapper } = setup(f);
    const { rerender } = renderHook(
      ({ enabled }: { enabled: boolean }) => useErrorsDashboard({ enabled }),
      { wrapper, initialProps: { enabled: false } },
    );
    await advance(0);
    expect(f).not.toHaveBeenCalled();
    rerender({ enabled: true });
    await advance(0);
    expect(f).toHaveBeenCalledTimes(1);
    await advance(60_000);
    expect(f).toHaveBeenCalledTimes(2);
  });
});

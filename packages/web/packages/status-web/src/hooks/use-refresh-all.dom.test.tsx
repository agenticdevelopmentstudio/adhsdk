// @vitest-environment jsdom
import { afterEach, describe, expect, it, vi } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import type { ReactElement, ReactNode } from "react";
import { act, cleanup, render, renderHook } from "@testing-library/react";
import { QueryClient, QueryClientProvider, useQuery } from "@tanstack/react-query";
import { useRefreshAll } from "./use-refresh-all";

afterEach(cleanup);

function Watch({ queryKey, fn }: { queryKey: string[]; fn: () => Promise<number> }): null {
  useQuery({ queryKey, queryFn: fn });
  return null;
}

describe("useRefreshAll", () => {
  it("refetches only what is on screen, and leaves the self-polling queries to themselves", async () => {
    const client = new QueryClient({ defaultOptions: { queries: { staleTime: Infinity } } });
    const onScreen = vi.fn(async () => 1);
    const cached = vi.fn(async () => 1);
    const dashboard = vi.fn(async () => 1);
    // A range the visitor opened earlier and left: cached, with no observer any more.
    await client.prefetchQuery({ queryKey: ["analytics-dashboard", "7d"], queryFn: cached });
    await client.prefetchQuery({ queryKey: ["uptime-old"], queryFn: cached });

    let refresh = (): void => {};
    function Board(): ReactElement {
      refresh = useRefreshAll(3_600_000).refreshAll;
      return (
        <>
          <Watch queryKey={["uptime"]} fn={onScreen} />
          <Watch queryKey={["errors-dashboard"]} fn={dashboard} />
        </>
      );
    }
    render(
      <QueryClientProvider client={client}>
        <Board />
      </QueryClientProvider>,
    );
    await vi.waitFor(() => expect(onScreen).toHaveBeenCalledTimes(1));
    await vi.waitFor(() => expect(dashboard).toHaveBeenCalledTimes(1));
    cached.mockClear();

    await act(async () => {
      refresh();
    });
    await vi.waitFor(() => expect(onScreen).toHaveBeenCalledTimes(2));
    expect(dashboard).toHaveBeenCalledTimes(1);
    expect(cached).not.toHaveBeenCalled();
  });
});

describe("useRefreshAll conformance vectors", () => {
  function setup(intervalMs?: number) {
    const client = new QueryClient({ defaultOptions: { queries: { staleTime: Infinity, retry: false } } });
    const wrapper = ({ children }: { children: ReactNode }): ReactElement => (
      <QueryClientProvider client={client}>{children}</QueryClientProvider>
    );
    return { client, wrapper, intervalMs };
  }
  /** Mount observers for the given keys (each enabled unless `enabled: false`), settle the first fetch. */
  async function mountQueries(
    client: QueryClient,
    specs: { key: unknown[]; fn: () => Promise<unknown>; enabled?: boolean }[],
  ): Promise<void> {
    function Many(): null {
      for (const s of specs) {
        // eslint-disable-next-line react-hooks/rules-of-hooks -- specs is a fixed list per mount
        useQuery({ queryKey: s.key as string[], queryFn: s.fn, enabled: s.enabled ?? true });
      }
      return null;
    }
    render(
      <QueryClientProvider client={client}>
        <Many />
      </QueryClientProvider>,
    );
    await act(async () => {});
  }

  afterEach(() => {
    vi.useRealTimers();
  });

  it("refresh-all-001 default interval is 60 seconds and does not fire immediately", () => {
    vi.useFakeTimers();
    const { client, wrapper } = setup();
    const spy = vi.spyOn(client, "refetchQueries").mockResolvedValue(undefined);
    renderHook(() => useRefreshAll(), { wrapper });
    expect(spy).not.toHaveBeenCalled();
    vi.advanceTimersByTime(59_999);
    expect(spy).toHaveBeenCalledTimes(0);
    vi.advanceTimersByTime(1);
    expect(spy).toHaveBeenCalledTimes(1);
  });

  it("refresh-all-002 fires once per interval", () => {
    vi.useFakeTimers();
    const { client, wrapper } = setup();
    const spy = vi.spyOn(client, "refetchQueries").mockResolvedValue(undefined);
    renderHook(() => useRefreshAll(1000), { wrapper });
    vi.advanceTimersByTime(3000);
    expect(spy).toHaveBeenCalledTimes(3);
  });

  it("refresh-all-003 skips the live entries and refetches the rest", async () => {
    const { client } = setup();
    const fns = { live: vi.fn(async () => 1), liveX: vi.fn(async () => 1), uptime: vi.fn(async () => 1), integrations: vi.fn(async () => 1) };
    await mountQueries(client, [
      { key: ["live"], fn: fns.live },
      { key: ["live", "x"], fn: fns.liveX },
      { key: ["uptime"], fn: fns.uptime },
      { key: ["integrations"], fn: fns.integrations },
    ]);
    Object.values(fns).forEach((f) => f.mockClear());
    await refreshOnce(client);
    await vi.waitFor(() => expect(fns.uptime).toHaveBeenCalledTimes(1));
    expect(fns.integrations).toHaveBeenCalledTimes(1);
    expect(fns.live).not.toHaveBeenCalled();
    expect(fns.liveX).not.toHaveBeenCalled();
  });

  async function refreshOnce(client: QueryClient): Promise<void> {
    let refresh = (): void => {};
    function Driver(): null {
      refresh = useRefreshAll(3_600_000).refreshAll;
      return null;
    }
    render(
      <QueryClientProvider client={client}>
        <Driver />
      </QueryClientProvider>,
    );
    await act(async () => {
      refresh();
    });
  }

  it("refresh-all-004 only an exact first key segment 'live' is excluded", async () => {
    const { client } = setup();
    const a = vi.fn(async () => 1);
    const b = vi.fn(async () => 1);
    await mountQueries(client, [
      { key: ["live-history"], fn: a },
      { key: ["history", "live"], fn: b },
    ]);
    a.mockClear();
    b.mockClear();
    await refreshOnce(client);
    await vi.waitFor(() => expect(a).toHaveBeenCalledTimes(1));
    expect(b).toHaveBeenCalledTimes(1);
  });

  it("refresh-all-005 a query whose only observer is disabled is not refetched", async () => {
    const { client } = setup();
    const fn = vi.fn(async () => 1);
    client.setQueryData(["config-status"], 1);
    await mountQueries(client, [{ key: ["config-status"], fn, enabled: false }]);
    await refreshOnce(client);
    expect(fn).not.toHaveBeenCalled();
  });

  it("refresh-all-006 a query with one disabled and one enabled observer is refetched", async () => {
    const { client } = setup();
    const fn = vi.fn(async () => 1);
    await mountQueries(client, [
      { key: ["configure-data"], fn, enabled: false },
      { key: ["configure-data"], fn, enabled: true },
    ]);
    fn.mockClear();
    await refreshOnce(client);
    await vi.waitFor(() => expect(fn).toHaveBeenCalledTimes(1));
  });

  it("refresh-all-007 refreshAll is fire-and-forget and a rejection lands on the query", async () => {
    const { client } = setup();
    let fail = false;
    await mountQueries(client, [
      {
        key: ["uptime"],
        fn: async () => {
          if (fail) throw new Error("boom");
          return 1;
        },
      },
    ]);
    fail = true;
    let refresh = (): void => {};
    let returned: unknown = "unset";
    function Driver(): null {
      refresh = useRefreshAll(3_600_000).refreshAll;
      return null;
    }
    render(
      <QueryClientProvider client={client}>
        <Driver />
      </QueryClientProvider>,
    );
    await act(async () => {
      returned = refresh();
    });
    expect(returned).toBeUndefined();
    await vi.waitFor(() => expect(client.getQueryState(["uptime"])?.status).toBe("error"));
    expect((client.getQueryState(["uptime"])?.error as Error).message).toBe("boom");
  });

  it("refresh-all-008 one query's failure does not stop another's refresh", async () => {
    const { client } = setup();
    let round = 0;
    await mountQueries(client, [
      { key: ["a"], fn: async () => (round === 0 ? 0 : 1) },
      {
        key: ["b"],
        fn: async () => {
          if (round > 0) throw new Error("b failed");
          return 0;
        },
      },
    ]);
    round = 1;
    await refreshOnce(client);
    await vi.waitFor(() => expect(client.getQueryData(["a"])).toBe(1));
    await vi.waitFor(() => expect(client.getQueryState(["b"])?.status).toBe("error"));
  });

  it("refresh-all-009 unmounting stops the interval", () => {
    vi.useFakeTimers();
    const { client, wrapper } = setup();
    const spy = vi.spyOn(client, "refetchQueries").mockResolvedValue(undefined);
    const { unmount } = renderHook(() => useRefreshAll(1000), { wrapper });
    unmount();
    vi.advanceTimersByTime(5000);
    expect(spy).toHaveBeenCalledTimes(0);
  });

  it("refresh-all-010 changing the interval restarts the timer", () => {
    vi.useFakeTimers();
    const { client, wrapper } = setup();
    const spy = vi.spyOn(client, "refetchQueries").mockResolvedValue(undefined);
    const { rerender } = renderHook(({ ms }) => useRefreshAll(ms), { initialProps: { ms: 1000 }, wrapper });
    vi.advanceTimersByTime(500);
    expect(spy).toHaveBeenCalledTimes(0);
    rerender({ ms: 2000 });
    vi.advanceTimersByTime(1999);
    expect(spy).toHaveBeenCalledTimes(0);
    vi.advanceTimersByTime(1);
    expect(spy).toHaveBeenCalledTimes(1);
  });

  it("refresh-all-011 refreshAll is stable across renders; the wrapper object is fresh", () => {
    const { wrapper } = setup();
    const { result, rerender } = renderHook(() => useRefreshAll(), { wrapper });
    const first = result.current;
    rerender();
    expect(result.current.refreshAll).toBe(first.refreshAll);
    expect(result.current).not.toBe(first);
  });

  it("refresh-all-012 refetchQueries gets one argument holding the active filter and the predicate", () => {
    const { client, wrapper } = setup();
    const spy = vi.spyOn(client, "refetchQueries").mockResolvedValue(undefined);
    const { result } = renderHook(() => useRefreshAll(3_600_000), { wrapper });
    result.current.refreshAll();
    expect(spy).toHaveBeenCalledTimes(1);
    expect(spy.mock.calls[0]).toHaveLength(1);
    expect(Object.keys(spy.mock.calls[0][0] as object).sort()).toEqual(["predicate", "type"]);
    expect((spy.mock.calls[0][0] as { type: string }).type).toBe("active");
  });

  it("refresh-all-013 each mount runs its own timer", () => {
    vi.useFakeTimers();
    const { client, wrapper } = setup();
    const spy = vi.spyOn(client, "refetchQueries").mockResolvedValue(undefined);
    renderHook(() => useRefreshAll(1000), { wrapper });
    renderHook(() => useRefreshAll(1000), { wrapper });
    vi.advanceTimersByTime(1000);
    expect(spy).toHaveBeenCalledTimes(2);
  });

  it("refresh-all-014 the module is marked client-only", () => {
    const source = readFileSync(resolve(process.cwd(), "src/hooks/use-refresh-all.ts"), "utf8");
    expect(source.split("\n")[0].trim()).toBe('"use client";');
  });
});

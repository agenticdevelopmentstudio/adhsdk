// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from "vitest";
import { act, cleanup, render, waitFor } from "@testing-library/react";
import { QueryClient, QueryClientProvider, useQuery } from "@tanstack/react-query";
import type { ReactElement, ReactNode } from "react";
import { createStatusApiClient, StatusApiProvider } from "../api/client";
import { useUptime } from "./use-uptime";
// @ts-expect-error vite raw import; read as text to check the directive
import source from "./use-uptime.ts?raw";

// The REAL hook, the REAL client; only the transport (`fetch`) is faked.
const EMPTY = { services: [], days: 90 };
const json = (status: number, body: unknown) => () =>
  Promise.resolve(new Response(JSON.stringify(body), { status }));

const mockFetch = (impl: (url: string, init?: RequestInit) => Promise<Response>) =>
  vi.fn(impl as unknown as typeof fetch);

function newClient(): QueryClient {
  return new QueryClient({ defaultOptions: { queries: { retry: false } } });
}

type Result = ReturnType<typeof useUptime>;

function mount(opts: {
  fetch?: typeof fetch;
  basePath?: string;
  days?: number;
  withDays?: boolean;
  consumers?: number;
  client?: QueryClient;
}) {
  const out: { current?: Result; all: Result[] } = { all: [] };
  const qc = opts.client ?? newClient();
  const api = opts.fetch ? createStatusApiClient({ basePath: opts.basePath, fetch: opts.fetch }) : undefined;
  function Probe({ days }: { days?: number }): ReactElement | null {
    out.current = opts.withDays === false ? useUptime() : useUptime(days);
    return null;
  }
  function Extra({ days }: { days?: number }): ReactElement | null {
    out.all.push(useUptime(days));
    return null;
  }
  const tree = (days?: number): ReactNode => (
    <QueryClientProvider client={qc}>
      {api ? (
        <StatusApiProvider client={api}>
          <Probe days={days} />
          {Array.from({ length: opts.consumers ?? 0 }, (_, i) => (
            <Extra key={i} days={days} />
          ))}
        </StatusApiProvider>
      ) : (
        <Probe days={days} />
      )}
    </QueryClientProvider>
  );
  const view = render(tree(opts.days));
  return { out, qc, rerender: (days?: number) => view.rerender(tree(days)) };
}

async function failure(fetchImpl: () => Promise<Response>): Promise<Error> {
  const { out } = mount({ fetch: vi.fn(fetchImpl) as unknown as typeof fetch, days: 90 });
  await waitFor(() => expect(out.current?.isError).toBe(true));
  return out.current!.error as Error;
}

afterEach(() => {
  cleanup();
  vi.unstubAllGlobals();
  vi.useRealTimers();
});

describe("useUptime", () => {
  it("use-uptime-001 defaults to 90 days, always fetches, and calls the default client with no options", async () => {
    const f = mockFetch(json(200, EMPTY));
    vi.stubGlobal("fetch", f);
    const { out } = mount({ withDays: false });
    await waitFor(() => expect(out.current?.data).toEqual(EMPTY));
    expect(f).toHaveBeenCalledTimes(1);
    expect(f.mock.calls[0]?.[0]).toBe("/api/uptime?days=90");
    expect(f.mock.calls[0]?.[1]).toBeUndefined();
  });

  it("use-uptime-002 passes the body through in the order sent, nulls intact", async () => {
    const body = {
      services: [
        { slug: "b", name: "B", uptimePercent: null, totalChecks: 0, daily: [] },
        {
          slug: "a",
          name: "A",
          uptimePercent: 99.5,
          totalChecks: 200,
          daily: [{ day: "2026-09-23", status: "degraded", uptimePercent: 99 }],
        },
      ],
      days: 90,
    };
    const { out } = mount({ fetch: vi.fn(json(200, body)) as unknown as typeof fetch, days: 90 });
    await waitFor(() => expect(out.current?.data).toEqual(body));
    expect(out.current?.data?.services[0]?.slug).toBe("b");
    expect(out.current?.data?.services[0]?.uptimePercent).toBeNull();
    expect(out.current?.data?.days).toBe(90);
  });

  it("use-uptime-003 resolves the request against an overriding client's base path", async () => {
    const f = mockFetch(json(200, EMPTY));
    const { out } = mount({ fetch: f, basePath: "/proxy", days: 30 });
    await waitFor(() => expect(out.current?.data).toBeDefined());
    expect(f.mock.calls[0]?.[0]).toBe("/proxy/uptime?days=30");
  });

  it("use-uptime-004 interpolates days by plain string conversion", async () => {
    const f = mockFetch(json(200, EMPTY));
    const { out } = mount({ fetch: f, days: 1.5 });
    await waitFor(() => expect(out.current?.data).toBeDefined());
    expect(f.mock.calls[0]?.[0]).toBe("/api/uptime?days=1.5");
  });

  it("use-uptime-005 reports `uptime <status>` for a non-ok response and drops the body detail", async () => {
    const e = await failure(json(401, { error: "unauthorized" }));
    expect(e.message).toBe("uptime 401");
    expect(e.message).not.toContain("unauthorized");
  });

  it("use-uptime-006 surfaces the JSON parse error for a 200 with a non-JSON body", async () => {
    const e = await failure(() => Promise.resolve(new Response("not json", { status: 200 })));
    expect(e).toBeInstanceOf(SyntaxError);
  });

  it("use-uptime-007 passes a network failure through unchanged", async () => {
    const boom = new TypeError("Failed to fetch");
    const e = await failure(() => Promise.reject(boom));
    expect(e).toBe(boom);
  });

  it("use-uptime-008 does not poll on a timer", async () => {
    vi.useFakeTimers({ toFake: ["setTimeout", "setInterval", "clearTimeout", "clearInterval"] });
    const f = mockFetch(json(200, EMPTY));
    const { out } = mount({ fetch: f, days: 90 });
    await act(async () => {
      await vi.advanceTimersByTimeAsync(0);
    });
    expect(out.current?.data).toEqual(EMPTY);
    expect(f).toHaveBeenCalledTimes(1);
    await act(async () => {
      await vi.advanceTimersByTimeAsync(600_000);
    });
    expect(f).toHaveBeenCalledTimes(1);
  });

  it("use-uptime-009 keys the cache by days and serves the cached window on return", async () => {
    const f = mockFetch((url) => json(200, { services: [], days: Number(String(url).split("=")[1]) })());
    const { out, rerender } = mount({ fetch: f, days: 90 });
    await waitFor(() => expect(out.current?.data?.days).toBe(90));
    rerender(30);
    await waitFor(() => expect(out.current?.data?.days).toBe(30));
    expect(f.mock.calls.map((c) => c[0])).toEqual(["/api/uptime?days=90", "/api/uptime?days=30"]);
    rerender(90);
    // The 90-day entry is still cached: data is there at once, with no loading state.
    expect(out.current?.data?.days).toBe(90);
    expect(out.current?.isLoading).toBe(false);
  });

  it("use-uptime-010 adds no Content-Type header", async () => {
    const f = mockFetch(json(200, EMPTY));
    const { out } = mount({ fetch: f, days: 90 });
    await waitFor(() => expect(out.current?.data).toBeDefined());
    expect(f.mock.calls[0]?.[1]).toBeUndefined();
  });

  it("use-uptime-011 shares one request between two consumers under one cache", async () => {
    const f = mockFetch(
      () =>
        new Promise<Response>((res) =>
          setTimeout(() => res(new Response(JSON.stringify(EMPTY), { status: 200 })), 20),
        ),
    );
    const { out } = mount({ fetch: f, days: 90, consumers: 1 });
    await waitFor(() => expect(out.current?.data).toEqual(EMPTY));
    expect(f).toHaveBeenCalledTimes(1);
    expect(out.all[out.all.length - 1]?.data).toBe(out.current?.data);
  });

  it("use-uptime-012 returns the raw read result, loading before the stub resolves", async () => {
    let release!: (r: Response) => void;
    const f = mockFetch(() => new Promise<Response>((res) => (release = res)));
    const ref: { current?: Record<string, unknown> } = {};
    const qc = newClient();
    function Reference(): ReactElement | null {
      ref.current = useQuery({ queryKey: ["reference"], queryFn: () => 1 }) as unknown as Record<string, unknown>;
      return null;
    }
    const { out } = mount({ fetch: f, days: 90, client: qc });
    render(
      <QueryClientProvider client={qc}>
        <Reference />
      </QueryClientProvider>,
    );
    expect(out.current?.isLoading).toBe(true);
    expect(out.current?.data).toBeUndefined();
    expect(Object.keys(out.current!).sort()).toEqual(Object.keys(ref.current!).sort());
    release(new Response(JSON.stringify(EMPTY), { status: 200 }));
    await waitFor(() => expect(out.current?.data).toEqual(EMPTY));
  });

  it("use-uptime-013 is marked for client execution only", () => {
    expect((source as string).trimStart().startsWith('"use client"')).toBe(true);
  });
});

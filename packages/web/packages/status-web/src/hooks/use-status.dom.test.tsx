// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from "vitest";
import { act, cleanup, render, waitFor } from "@testing-library/react";
import { QueryClient, QueryClientProvider, focusManager } from "@tanstack/react-query";
import type { ReactElement, ReactNode } from "react";
import { createStatusApiClient, StatusApiProvider } from "../api/client";
import { useStatus } from "./use-status";
// @ts-expect-error vite raw import; read as text to check the directive
import source from "./use-status.ts?raw";

// The REAL hook, the REAL client; only the transport (`fetch`) is faked.
const BODY = { overall: "operational", services: [], checkedAt: "2026-09-24T00:00:00Z" };
const json = (status: number, body: unknown) => () =>
  Promise.resolve(new Response(JSON.stringify(body), { status }));
const text = (status: number, body: string) => () => Promise.resolve(new Response(body, { status }));

const mockFetch = (impl: (url: string, init?: RequestInit) => Promise<Response>) =>
  vi.fn(impl as unknown as typeof fetch);

function newClient(): QueryClient {
  return new QueryClient({ defaultOptions: { queries: { retry: false } } });
}

type Result = ReturnType<typeof useStatus>;

function mount(opts: { fetch: typeof fetch; basePath?: string; client?: QueryClient; consumers?: number }) {
  const out: { current?: Result; all: Result[] } = { all: [] };
  const qc = opts.client ?? newClient();
  const api = createStatusApiClient({ basePath: opts.basePath, fetch: opts.fetch });
  function Probe(): ReactElement | null {
    out.current = useStatus();
    return null;
  }
  function Extra(): ReactElement | null {
    out.all.push(useStatus());
    return null;
  }
  const Wrap = ({ children }: { children: ReactNode }) => (
    <QueryClientProvider client={qc}>
      <StatusApiProvider client={api}>{children}</StatusApiProvider>
    </QueryClientProvider>
  );
  const view = render(
    <Wrap>
      <Probe />
      {Array.from({ length: opts.consumers ?? 0 }, (_, i) => (
        <Extra key={i} />
      ))}
    </Wrap>,
  );
  return { out, qc, view };
}

async function failure(fetchImpl: () => Promise<Response>): Promise<Error> {
  const { out } = mount({ fetch: vi.fn(fetchImpl) as unknown as typeof fetch });
  await waitFor(() => expect(out.current?.isError).toBe(true));
  return out.current!.error as Error;
}

afterEach(() => {
  cleanup();
  vi.unstubAllGlobals();
});

describe("useStatus", () => {
  it("use-status-001 requests /api/status once with the default client and caches under status", async () => {
    const f = mockFetch(json(200, BODY));
    vi.stubGlobal("fetch", f);
    const qc = newClient();
    const out: { current?: Result } = {};
    function Probe(): ReactElement | null {
      out.current = useStatus();
      return null;
    }
    render(
      <QueryClientProvider client={qc}>
        <Probe />
      </QueryClientProvider>,
    );
    await waitFor(() => expect(out.current?.data).toEqual(BODY));
    expect(f).toHaveBeenCalledTimes(1);
    expect(f.mock.calls[0]?.[0]).toBe("/api/status");
    expect(out.current?.error).toBeNull();
    expect(qc.getQueryData(["status"])).toEqual(BODY);
  });

  it("use-status-002 surfaces the body's error detail as the message", async () => {
    const e = await failure(json(503, { error: "database unavailable" }));
    expect(e).toBeInstanceOf(Error);
    expect(e.message).toBe("database unavailable");
  });

  it("use-status-003 falls back to `status <code>` when the body has no detail", async () => {
    expect((await failure(json(503, {}))).message).toBe("status 503");
  });

  it("use-status-004 swallows a non-JSON error body and falls back to the status", async () => {
    const e = await failure(text(502, "Bad Gateway"));
    expect(e.message).toBe("status 502");
    expect(e).not.toBeInstanceOf(SyntaxError);
  });

  it("use-status-005 treats an empty error string as no detail", async () => {
    expect((await failure(json(500, { error: "" }))).message).toBe("status 500");
  });

  it("use-status-006 coerces a non-string error detail to [object Object]", async () => {
    expect((await failure(json(500, { error: { message: "x" } }))).message).toBe("[object Object]");
  });

  it("use-status-007 passes a network failure through unchanged", async () => {
    const boom = new TypeError("Failed to fetch");
    const e = await failure(() => Promise.reject(boom));
    expect(e).toBe(boom);
  });

  it("use-status-008 surfaces the JSON parse error for a 200 with a non-JSON body", async () => {
    const e = await failure(text(200, "not json"));
    expect(e).toBeInstanceOf(SyntaxError);
    expect(e.message.startsWith("status ")).toBe(false);
  });

  it("use-status-009 resolves the request against an overriding client's base path", async () => {
    const f = mockFetch(json(200, BODY));
    const { out } = mount({ fetch: f, basePath: "/proxy" });
    await waitFor(() => expect(out.current?.data).toEqual(BODY));
    expect(f.mock.calls[0]?.[0]).toBe("/proxy/status");
  });

  it("use-status-010 shares one request between two consumers under one cache", async () => {
    const f = mockFetch(
      () =>
        new Promise<Response>((res) =>
          setTimeout(() => res(new Response(JSON.stringify(BODY), { status: 200 })), 20),
        ),
    );
    const { out } = mount({ fetch: f, consumers: 1 });
    await waitFor(() => expect(out.current?.data).toEqual(BODY));
    expect(f).toHaveBeenCalledTimes(1);
    const last = out.all[out.all.length - 1];
    expect(last?.data).toBe(out.current?.data);
  });

  it("use-status-011 refetches once when the application regains focus", async () => {
    const f = mockFetch(json(200, BODY));
    const { out } = mount({ fetch: f });
    await waitFor(() => expect(out.current?.data).toEqual(BODY));
    expect(f).toHaveBeenCalledTimes(1);
    act(() => {
      focusManager.setFocused(false);
      focusManager.setFocused(true);
    });
    await waitFor(() => expect(f).toHaveBeenCalledTimes(2));
    expect(f.mock.calls[1]?.[0]).toBe("/api/status");
    focusManager.setFocused(undefined);
  });

  it("use-status-012 throws an error carrying only a message", async () => {
    const e = await failure(json(503, { error: "db down" }));
    expect(e.message).toBe("db down");
    expect("status" in e).toBe(false);
    expect("body" in e).toBe(false);
  });

  it("use-status-013 returns the raw read result whose data is the status payload", async () => {
    const body = {
      overall: "operational",
      checkedAt: "2026-09-24T00:00:00Z",
      services: [{ slug: "web", name: "Web", status: "healthy" }],
    };
    const { out } = mount({ fetch: vi.fn(json(200, body)) as unknown as typeof fetch });
    await waitFor(() => expect(out.current?.data).toEqual(body));
    expect(out.current?.data?.services).toEqual(body.services);
    expect(out.current?.data?.checkedAt).toBe(body.checkedAt);
    // The raw react-query result, not an adapted shape.
    expect(typeof out.current?.refetch).toBe("function");
    expect(out.current?.isLoading).toBe(false);
    expect(out.current?.error).toBeNull();
  });

  it("use-status-014 is marked for client execution only", () => {
    expect((source as string).trimStart().startsWith('"use client"')).toBe(true);
  });
});

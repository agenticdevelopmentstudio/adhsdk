// @vitest-environment jsdom
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import type { ReactNode } from "react";
import { cleanup, renderHook, waitFor } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { StatusApiProvider } from "../api/client";
import { useResponseHistory } from "./use-response-history";

const BODY = { hours: 24, points: [120, null, 95] };
const json = (body: unknown, status = 200): Response => new Response(JSON.stringify(body), { status });

let fetchMock: ReturnType<typeof vi.fn>;

function wrapperFor(client: QueryClient, basePath?: string) {
  return ({ children }: { children: ReactNode }) => (
    <QueryClientProvider client={client}>
      <StatusApiProvider basePath={basePath}>{children}</StatusApiProvider>
    </QueryClientProvider>
  );
}
const newClient = (): QueryClient => new QueryClient({ defaultOptions: { queries: { retry: false } } });

beforeEach(() => {
  fetchMock = vi.fn(async () => json(BODY));
  vi.stubGlobal("fetch", fetchMock);
});
afterEach(() => {
  cleanup();
  vi.useRealTimers();
  vi.unstubAllGlobals();
});

describe("useResponseHistory", () => {
  it("use-response-history-001 fetches /api/response-history?hours=24 once, no init, no buckets", async () => {
    const { result } = renderHook(() => useResponseHistory(24), { wrapper: wrapperFor(newClient()) });
    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(fetchMock).toHaveBeenCalledWith("/api/response-history?hours=24", undefined);
    expect(String(fetchMock.mock.calls[0][0])).not.toContain("buckets");
  });

  it("use-response-history-002 returns the body with the null kept in position", async () => {
    const { result } = renderHook(() => useResponseHistory(24), { wrapper: wrapperFor(newClient()) });
    await waitFor(() => expect(result.current.data).toEqual(BODY));
    expect(result.current.data?.points[1]).toBeNull();
  });

  it("use-response-history-003 joins a custom base path", async () => {
    const { result } = renderHook(() => useResponseHistory(168), { wrapper: wrapperFor(newClient(), "/proxy") });
    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(fetchMock.mock.calls[0][0]).toBe("/proxy/response-history?hours=168");
  });

  it("use-response-history-004 interpolates a fractional hours value as-is", async () => {
    const { result } = renderHook(() => useResponseHistory(1.5), { wrapper: wrapperFor(newClient()) });
    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(fetchMock.mock.calls[0][0]).toBe("/api/response-history?hours=1.5");
  });

  it("use-response-history-005 a non-ok status becomes 'response-history N' without the body detail", async () => {
    fetchMock.mockResolvedValue(json({ error: "unauthorized" }, 401));
    const { result } = renderHook(() => useResponseHistory(24), { wrapper: wrapperFor(newClient()) });
    await waitFor(() => expect(result.current.isError).toBe(true));
    expect(result.current.error?.message).toBe("response-history 401");
    expect(result.current.error?.message).not.toContain("unauthorized");
  });

  it("use-response-history-006 a body that is not JSON surfaces the parse failure", async () => {
    fetchMock.mockResolvedValue(new Response("not json", { status: 200 }));
    const { result } = renderHook(() => useResponseHistory(24), { wrapper: wrapperFor(newClient()) });
    await waitFor(() => expect(result.current.isError).toBe(true));
    expect(result.current.error).toBeInstanceOf(SyntaxError);
  });

  it("use-response-history-007 a network failure surfaces as the error", async () => {
    const boom = new TypeError("network down");
    fetchMock.mockRejectedValue(boom);
    const { result } = renderHook(() => useResponseHistory(24), { wrapper: wrapperFor(newClient()) });
    await waitFor(() => expect(result.current.isError).toBe(true));
    expect(result.current.error).toBe(boom);
  });

  it("use-response-history-008 polls every 60 seconds and not sooner", async () => {
    vi.useFakeTimers();
    renderHook(() => useResponseHistory(24), { wrapper: wrapperFor(newClient()) });
    await vi.advanceTimersByTimeAsync(0);
    expect(fetchMock).toHaveBeenCalledTimes(1);
    await vi.advanceTimersByTimeAsync(59_999);
    expect(fetchMock).toHaveBeenCalledTimes(1);
    await vi.advanceTimersByTimeAsync(1);
    expect(fetchMock).toHaveBeenCalledTimes(2);
    expect(fetchMock.mock.calls[1][0]).toBe("/api/response-history?hours=24");
  });

  it("use-response-history-009 keys the cache by hours", async () => {
    fetchMock.mockImplementation(async (url: string) => {
      const hours = Number(new URL(url, "http://x").searchParams.get("hours"));
      return json({ hours, points: [hours] });
    });
    const { result, rerender } = renderHook(({ h }) => useResponseHistory(h), {
      initialProps: { h: 24 },
      wrapper: wrapperFor(newClient()),
    });
    await waitFor(() => expect(result.current.data?.hours).toBe(24));
    rerender({ h: 720 });
    await waitFor(() => expect(result.current.data?.hours).toBe(720));
    expect(fetchMock).toHaveBeenCalledTimes(2);
    rerender({ h: 24 });
    expect(result.current.data).toEqual({ hours: 24, points: [24] });
  });

  it("use-response-history-010 adds no Content-Type header", async () => {
    const { result } = renderHook(() => useResponseHistory(24), { wrapper: wrapperFor(newClient()) });
    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    const init = fetchMock.mock.calls[0][1] as RequestInit | undefined;
    expect(init?.headers).toBeUndefined();
  });

  it("use-response-history-011 two consumers on one cache share one request", async () => {
    const client = newClient();
    const a = renderHook(() => useResponseHistory(24), { wrapper: wrapperFor(client) });
    const b = renderHook(() => useResponseHistory(24), { wrapper: wrapperFor(client) });
    await waitFor(() => expect(a.result.current.data).toEqual(BODY));
    await waitFor(() => expect(b.result.current.data).toEqual(BODY));
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it("use-response-history-012 the module is marked client-only", () => {
    const source = readFileSync(resolve(process.cwd(), "src/hooks/use-response-history.ts"), "utf8");
    expect(source.split("\n")[0].trim()).toBe('"use client";');
  });
});

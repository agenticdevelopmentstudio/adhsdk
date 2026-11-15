// @vitest-environment jsdom
import { describe, it, expect, vi } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { createElement, type ReactNode } from "react";
import { renderHook, waitFor } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { StatusApiProvider, createStatusApiClient } from "../api/client";
import { useHistory } from "./use-history";

function setup(fetchStub: ReturnType<typeof vi.fn>, basePath?: string) {
  const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  const client = createStatusApiClient({ basePath, fetch: fetchStub as unknown as typeof fetch });
  const wrapper = ({ children }: { children: ReactNode }) =>
    createElement(QueryClientProvider, { client: queryClient }, createElement(StatusApiProvider, { client }, children));
  return { wrapper };
}
const body = { service: "api", hours: 24, checks: [] };
const okFetch = () => vi.fn(async () => ({ ok: true, status: 200, json: async () => body }));

describe("useHistory", () => {
  it("use-history-001 makes no request without a slug and stays pending/idle", async () => {
    const f = okFetch();
    const { wrapper } = setup(f);
    const { result } = renderHook(() => useHistory(null), { wrapper });
    await new Promise((r) => setTimeout(r, 30));
    expect(f).not.toHaveBeenCalled();
    expect(result.current.status).toBe("pending");
    expect(result.current.fetchStatus).toBe("idle");
    expect(result.current.data).toBeUndefined();
  });
  it("use-history-002 makes no request for an empty slug", async () => {
    const f = okFetch();
    const { wrapper } = setup(f);
    renderHook(() => useHistory(""), { wrapper });
    await new Promise((r) => setTimeout(r, 30));
    expect(f).not.toHaveBeenCalled();
  });
  it("use-history-003 requests the 24 hour window with no added options", async () => {
    const f = okFetch();
    const { wrapper } = setup(f);
    const { result } = renderHook(() => useHistory("api"), { wrapper });
    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(f).toHaveBeenCalledTimes(1);
    expect(f).toHaveBeenCalledWith("/api/history?service=api&hours=24", undefined);
    expect(result.current.data).toEqual(body);
  });
  it("use-history-004 encodes the slug", async () => {
    const f = okFetch();
    const { wrapper } = setup(f);
    const { result } = renderHook(() => useHistory("a b/c&d"), { wrapper });
    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(f.mock.calls[0][0]).toBe("/api/history?service=a%20b%2Fc%26d&hours=24");
  });
  it("use-history-005 resolves against the configured base path", async () => {
    const f = okFetch();
    const { wrapper } = setup(f, "/proxy");
    const { result } = renderHook(() => useHistory("web"), { wrapper });
    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(f.mock.calls[0][0]).toBe("/proxy/history?service=web&hours=24");
  });
  it("use-history-006 a non-ok status becomes `history <status>` without the body detail", async () => {
    const f = vi.fn(async () => ({ ok: false, status: 503, json: async () => ({ error: "down for maintenance" }) }));
    const { wrapper } = setup(f);
    const { result } = renderHook(() => useHistory("api"), { wrapper });
    await waitFor(() => expect(result.current.isError).toBe(true));
    expect((result.current.error as Error).message).toBe("history 503");
    expect((result.current.error as Error).message).not.toContain("maintenance");
  });
  it("use-history-007 a body that is not JSON surfaces the parse failure", async () => {
    const parseError = new SyntaxError("Unexpected token o in JSON");
    const f = vi.fn(async () => ({ ok: true, status: 200, json: async () => { throw parseError; } }));
    const { wrapper } = setup(f);
    const { result } = renderHook(() => useHistory("api"), { wrapper });
    await waitFor(() => expect(result.current.isError).toBe(true));
    expect(result.current.error).toBe(parseError);
  });
  it("use-history-008 a network failure surfaces as the query error", async () => {
    const netError = new TypeError("Failed to fetch");
    const f = vi.fn(async () => { throw netError; });
    const { wrapper } = setup(f);
    const { result } = renderHook(() => useHistory("api"), { wrapper });
    await waitFor(() => expect(result.current.isError).toBe(true));
    expect(result.current.error).toBe(netError);
  });
  it("use-history-009 keys the cache by slug", async () => {
    const f = okFetch();
    const { wrapper } = setup(f);
    const { result, rerender } = renderHook(({ s }: { s: string }) => useHistory(s), { wrapper, initialProps: { s: "a" } });
    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    rerender({ s: "b" });
    await waitFor(() => expect(f).toHaveBeenCalledTimes(2));
    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(f.mock.calls.map((c) => c[0])).toEqual([
      "/api/history?service=a&hours=24",
      "/api/history?service=b&hours=24",
    ]);
    rerender({ s: "a" });
    expect(result.current.data).toEqual(body);
    expect(result.current.isPending).toBe(false);
  });
  it("use-history-010 adds no Content-Type header", async () => {
    const f = okFetch();
    const { wrapper } = setup(f);
    const { result } = renderHook(() => useHistory("api"), { wrapper });
    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(f.mock.calls[0][1]).toBeUndefined();
  });
  it("use-history-011 the module is marked client-only", () => {
    const src = readFileSync(resolve(__dirname, "use-history.ts"), "utf8");
    expect(src.split("\n")[0]).toBe('"use client";');
  });
});

// @vitest-environment jsdom
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import type { ReactNode } from "react";
import { cleanup, renderHook, waitFor } from "@testing-library/react";
import { QueryClient, QueryClientProvider, focusManager } from "@tanstack/react-query";
import { StatusApiProvider } from "../api/client";
import { useIntegrations } from "./use-integrations";
import { useRefreshAll } from "./use-refresh-all";

const BODY = { generatedAt: "2026-09-24T00:00:00Z", overall: "ok", checks: [] };
const json = (body: unknown, status = 200): Response => new Response(JSON.stringify(body), { status });

let fetchMock: ReturnType<typeof vi.fn>;

function wrapperFor(client: QueryClient, basePath?: string) {
  return ({ children }: { children: ReactNode }) => (
    <QueryClientProvider client={client}>
      <StatusApiProvider basePath={basePath}>{children}</StatusApiProvider>
    </QueryClientProvider>
  );
}
const newClient = (staleTime?: number): QueryClient =>
  new QueryClient({ defaultOptions: { queries: { retry: false, ...(staleTime === undefined ? {} : { staleTime }) } } });

beforeEach(() => {
  fetchMock = vi.fn(async () => json(BODY));
  vi.stubGlobal("fetch", fetchMock);
});
afterEach(() => {
  cleanup();
  vi.useRealTimers();
  vi.unstubAllGlobals();
});

describe("useIntegrations", () => {
  it("use-integrations-001 requests /api/integrations once with no init and returns the body", async () => {
    const { result } = renderHook(() => useIntegrations(), { wrapper: wrapperFor(newClient()) });
    await waitFor(() => expect(result.current.data).toEqual(BODY));
    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(fetchMock).toHaveBeenCalledWith("/api/integrations", undefined);
  });

  it("use-integrations-002 joins a custom base path", async () => {
    const { result } = renderHook(() => useIntegrations(), { wrapper: wrapperFor(newClient(), "/proxy") });
    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(fetchMock.mock.calls[0][0]).toBe("/proxy/integrations");
  });

  it("use-integrations-003 a non-ok status becomes 'status N' without the body detail", async () => {
    fetchMock.mockResolvedValue(json({ error: "upstream down" }, 502));
    const { result } = renderHook(() => useIntegrations(), { wrapper: wrapperFor(newClient()) });
    await waitFor(() => expect(result.current.isError).toBe(true));
    expect(result.current.error?.message).toBe("status 502");
    expect(result.current.error?.message).not.toContain("upstream down");
  });

  it("use-integrations-004 a body that is not JSON surfaces the parse failure", async () => {
    fetchMock.mockResolvedValue(new Response("not json", { status: 200 }));
    const { result } = renderHook(() => useIntegrations(), { wrapper: wrapperFor(newClient()) });
    await waitFor(() => expect(result.current.isError).toBe(true));
    expect(result.current.error).toBeInstanceOf(SyntaxError);
  });

  it("use-integrations-005 a network failure surfaces as the error", async () => {
    const boom = new TypeError("network down");
    fetchMock.mockRejectedValue(boom);
    const { result } = renderHook(() => useIntegrations(), { wrapper: wrapperFor(newClient()) });
    await waitFor(() => expect(result.current.isError).toBe(true));
    expect(result.current.error).toBe(boom);
  });

  it("use-integrations-006 two consumers on one cache share one request", async () => {
    const client = newClient();
    const a = renderHook(() => useIntegrations(), { wrapper: wrapperFor(client) });
    const b = renderHook(() => useIntegrations(), { wrapper: wrapperFor(client) });
    await waitFor(() => expect(a.result.current.data).toEqual(BODY));
    await waitFor(() => expect(b.result.current.data).toEqual(BODY));
    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(a.result.current.data).toEqual(b.result.current.data);
  });

  it("use-integrations-007 refetches when the runtime regains focus", async () => {
    const { result } = renderHook(() => useIntegrations(), { wrapper: wrapperFor(newClient(0)) });
    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(fetchMock).toHaveBeenCalledTimes(1);
    focusManager.setFocused(false);
    focusManager.setFocused(true);
    await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(2));
    expect(fetchMock.mock.calls[1][0]).toBe("/api/integrations");
    focusManager.setFocused(undefined);
  });

  it("use-integrations-008 is refetched by Refresh All on its shared interval", async () => {
    vi.useFakeTimers();
    renderHook(
      () => {
        useRefreshAll(1000);
        return useIntegrations();
      },
      { wrapper: wrapperFor(newClient(Infinity)) },
    );
    await vi.advanceTimersByTimeAsync(0);
    expect(fetchMock).toHaveBeenCalledTimes(1);
    await vi.advanceTimersByTimeAsync(1000);
    expect(fetchMock).toHaveBeenCalledTimes(2);
    expect(fetchMock.mock.calls[1][0]).toBe("/api/integrations");
  });

  it("use-integrations-009 adds no Content-Type header", async () => {
    const { result } = renderHook(() => useIntegrations(), { wrapper: wrapperFor(newClient()) });
    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    const init = fetchMock.mock.calls[0][1] as RequestInit | undefined;
    expect(init?.headers).toBeUndefined();
  });

  it("use-integrations-010 keeps the optional check fields exactly as sent", async () => {
    const body = {
      ...BODY,
      checks: [{ id: "cf", missingEnv: ["CLOUDFLARE_ACCOUNT_ID"], unreachable: true, correlated: true }],
    };
    fetchMock.mockResolvedValue(json(body));
    const { result } = renderHook(() => useIntegrations(), { wrapper: wrapperFor(newClient()) });
    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    const check = result.current.data?.checks[0] as unknown as Record<string, unknown>;
    expect(check.missingEnv).toEqual(["CLOUDFLARE_ACCOUNT_ID"]);
    expect(check.unreachable).toBe(true);
    expect(check.correlated).toBe(true);
  });

  it("use-integrations-011 the module is marked client-only", () => {
    const source = readFileSync(resolve(process.cwd(), "src/hooks/use-integrations.ts"), "utf8");
    expect(source.split("\n")[0].trim()).toBe('"use client";');
  });
});

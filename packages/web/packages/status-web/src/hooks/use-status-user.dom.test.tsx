// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from "vitest";
import { cleanup, render, renderHook, waitFor } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import type { ReactElement, ReactNode } from "react";
import { useStatusUser } from "./useStatusUser";
import { fetchStatusUser, STATUS_AUTH_QUERY_KEY, useStatusUser as useStatusSession, type StatusUser } from "../header-auth";
import { createStatusApiClient } from "../api/client";

type Transport = (url: string, init?: RequestInit) => Promise<Response>;
const mockFetch = (impl: Transport) => vi.fn(impl as unknown as typeof fetch);
const U: StatusUser = { email: "a@b.c", displayName: "A", role: "admin" };
const meOf = (user: unknown) => async (): Promise<Response> => Response.json({ user });
const wrapper = (qc: QueryClient) =>
  function Wrap({ children }: { children: ReactNode }): ReactElement {
    return <QueryClientProvider client={qc}>{children}</QueryClientProvider>;
  };

afterEach(() => {
  cleanup();
  vi.useRealTimers();
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

describe("fetchStatusUser (the shared request function)", () => {
  const api = createStatusApiClient();
  it("use-status-user-001 resolves the user from a definitive 200", async () => {
    await expect(fetchStatusUser(api, mockFetch(meOf(U)))).resolves.toEqual(U);
  });
  it("use-status-user-002 resolves null from a definitive signed-out 200", async () => {
    await expect(fetchStatusUser(api, mockFetch(meOf(null)))).resolves.toBeNull();
  });
  it("use-status-user-003 throws on a 5xx", async () => {
    await expect(fetchStatusUser(api, mockFetch(async () => Response.json({}, { status: 500 })))).rejects.toThrow(/HTTP 500/);
  });
  it("use-status-user-004 propagates a network failure", async () => {
    await expect(
      fetchStatusUser(
        api,
        mockFetch(async () => {
          throw new TypeError("fetch failed");
        }),
      ),
    ).rejects.toThrow(/fetch failed/);
  });
});

describe("useStatusUser (adapter)", () => {
  it("use-status-user-005 issues exactly one GET to /api/auth/me with no body", async () => {
    const f = mockFetch(meOf(U));
    vi.stubGlobal("fetch", f);
    const { result } = renderHook(() => useStatusUser(), { wrapper: wrapper(new QueryClient()) });
    await waitFor(() => expect(result.current).toEqual(U));
    expect(f).toHaveBeenCalledTimes(1);
    expect(f.mock.calls[0]![0]).toBe("/api/auth/me");
    expect(f.mock.calls[0]![1]).toBeUndefined();
  });

  it("use-status-user-006 returns null while pending, and the bare user (no loading flag) after", async () => {
    vi.stubGlobal("fetch", mockFetch(meOf(U)));
    const { result } = renderHook(() => useStatusUser(), { wrapper: wrapper(new QueryClient()) });
    expect(result.current).toBeNull();
    await waitFor(() => expect(result.current).toEqual(U));
    expect(result.current).not.toHaveProperty("isPending");
  });

  it("use-status-user-007 keeps the last-known user through every failed retry", async () => {
    vi.useFakeTimers();
    const f = mockFetch(async () => new Response("", { status: 503 }));
    vi.stubGlobal("fetch", f);
    const qc = new QueryClient();
    qc.setQueryData(STATUS_AUTH_QUERY_KEY, U);
    const seen: Array<StatusUser | null> = [];
    renderHook(
      () => {
        const u = useStatusUser();
        seen.push(u);
        return u;
      },
      { wrapper: wrapper(qc) },
    );
    void qc.refetchQueries({ queryKey: STATUS_AUTH_QUERY_KEY });
    await vi.advanceTimersByTimeAsync(20_000);
    expect(f).toHaveBeenCalledTimes(4);
    expect(qc.getQueryState(STATUS_AUTH_QUERY_KEY)?.status).toBe("error");
    expect(seen.every((u) => u === U)).toBe(true);
  });

  it("use-status-user-008 retries 3 times on 502, then returns null with no error exposed", async () => {
    vi.useFakeTimers();
    const f = mockFetch(async () => new Response("", { status: 502 }));
    vi.stubGlobal("fetch", f);
    const qc = new QueryClient();
    const { result } = renderHook(() => useStatusUser(), { wrapper: wrapper(qc) });
    await vi.advanceTimersByTimeAsync(20_000);
    expect(f).toHaveBeenCalledTimes(4);
    expect(qc.getQueryState(STATUS_AUTH_QUERY_KEY)?.status).toBe("error");
    expect(result.current).toBeNull();
  });

  it("use-status-user-009 shares one request and one cache key with the session state", async () => {
    const f = mockFetch(meOf(U));
    vi.stubGlobal("fetch", f);
    const qc = new QueryClient();
    const { result } = renderHook(() => ({ adapter: useStatusUser(), session: useStatusSession() }), { wrapper: wrapper(qc) });
    await waitFor(() => expect(result.current.adapter).toEqual(U));
    expect(result.current.session.user).toBe(result.current.adapter);
    expect(qc.getQueryData(STATUS_AUTH_QUERY_KEY)).toEqual(U);
    expect(f).toHaveBeenCalledTimes(1);
  });

  it("use-status-user-010 stays fresh for 60 s: no refetch at 30 s, a background refetch at 61 s", async () => {
    vi.useFakeTimers();
    const f = mockFetch(meOf(U));
    vi.stubGlobal("fetch", f);
    const qc = new QueryClient();
    const Probe = (): null => {
      useStatusUser();
      return null;
    };
    const tree = (n: number): ReactElement => (
      <QueryClientProvider client={qc}>
        {Array.from({ length: n }, (_, i) => (
          <Probe key={i} />
        ))}
      </QueryClientProvider>
    );
    const view = render(tree(1));
    await vi.advanceTimersByTimeAsync(0);
    expect(f).toHaveBeenCalledTimes(1);
    await vi.advanceTimersByTimeAsync(30_000);
    view.rerender(tree(2));
    await vi.advanceTimersByTimeAsync(0);
    expect(f).toHaveBeenCalledTimes(1);
    await vi.advanceTimersByTimeAsync(31_000);
    view.rerender(tree(3));
    await vi.advanceTimersByTimeAsync(0);
    expect(f).toHaveBeenCalledTimes(2);
  });

  it("use-status-user-011 treats a 200 without a user field as signed out", async () => {
    vi.stubGlobal("fetch", mockFetch(async () => Response.json({})));
    const { result } = renderHook(() => useStatusUser(), { wrapper: wrapper(new QueryClient()) });
    await waitFor(() => expect(vi.mocked(fetch)).toHaveBeenCalled());
    await waitFor(() => expect(result.current).toBeNull());
    await expect(fetchStatusUser(createStatusApiClient(), mockFetch(async () => Response.json({})))).resolves.toBeNull();
  });

  it("use-status-user-012 throws a missing-client error without a query provider", () => {
    vi.spyOn(console, "error").mockImplementation(() => {});
    expect(() => renderHook(() => useStatusUser())).toThrow(/No QueryClient/);
  });

  it("use-status-user-013 returns the body as sent without validating role", async () => {
    const odd = { email: "x@y.z", role: "superuser" };
    vi.stubGlobal("fetch", mockFetch(meOf(odd)));
    const { result } = renderHook(() => useStatusUser(), { wrapper: wrapper(new QueryClient()) });
    await waitFor(() => expect(result.current).toEqual(odd));
    expect(result.current?.role).toBe("superuser");
  });

  it.skip("use-status-user-014 is unavailable in a server-only rendering context (jsdom cannot host a server component boundary)", () => {});
});

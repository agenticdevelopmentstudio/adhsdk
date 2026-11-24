// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from "vitest";
import { act, cleanup, render, waitFor } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import type { ReactElement, ReactNode } from "react";
import { createStatusApiClient, StatusApiProvider } from "./api/client";
import {
  STATUS_AUTH_QUERY_KEY,
  useStatusHeaderAuth,
  useStatusUser,
  type StatusHeaderAuthState,
  type StatusUser,
} from "./header-auth";

// The REAL hooks and the REAL client; only the transport (`fetch`) is faked.
type Transport = (url: string, init?: RequestInit) => Promise<Response>;
const mockFetch = (impl: Transport) => vi.fn(impl as unknown as typeof fetch);
const meOf = (user: StatusUser | null) => async () => Response.json({ user });
const pending = () => new Promise<Response>(() => {});

function mountWith<T>(useHook: () => T, transport: typeof fetch, qc = new QueryClient()) {
  const out: { current?: T; all: T[] } = { all: [] };
  // `fetchStatusUser` reads the platform fetch (the session query passes no transport),
  // while logout goes through the client's own — so the one fake serves both.
  vi.stubGlobal("fetch", transport);
  const api = createStatusApiClient({ fetch: transport });
  function Probe(): ReactElement | null {
    out.current = useHook();
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
    </Wrap>,
  );
  return { out, qc, view, Wrap };
}

afterEach(() => {
  cleanup();
  vi.useRealTimers();
  vi.unstubAllGlobals();
});

describe("useStatusHeaderAuth", () => {
  it("status-web-src-010 signed out and still loading: spinner state with login/signup links", () => {
    const { out } = mountWith(useStatusHeaderAuth, mockFetch(pending));
    expect(out.current).toEqual({
      user: null,
      authLoading: true,
      loginHref: "/login",
      signupHref: "/signup",
    });
  });

  it("status-web-src-011 signed out and loaded: no spinner", async () => {
    const { out } = mountWith(useStatusHeaderAuth, mockFetch(meOf(null)));
    await waitFor(() => expect(out.current?.authLoading).toBe(false));
    expect(out.current).toEqual({
      user: null,
      authLoading: false,
      loginHref: "/login",
      signupHref: "/signup",
    });
  });

  it("status-web-src-012 signed in: name, onLogout, and no spinner or login keys", async () => {
    const { out } = mountWith(
      useStatusHeaderAuth,
      mockFetch(meOf({ email: "a@b.c", displayName: "Ann", role: "viewer" })),
    );
    await waitFor(() => expect(out.current?.user).not.toBeNull());
    const state = out.current as StatusHeaderAuthState;
    expect(state.user).toEqual({ name: "Ann" });
    expect(typeof state.onLogout).toBe("function");
    expect(Object.keys(state).sort()).toEqual(["onLogout", "user"]);
  });

  it("status-web-src-013 an empty display name falls back to the email", async () => {
    const { out } = mountWith(
      useStatusHeaderAuth,
      mockFetch(meOf({ email: "a@b.c", displayName: "", role: "viewer" })),
    );
    await waitFor(() => expect(out.current?.user).not.toBeNull());
    expect(out.current?.user?.name).toBe("a@b.c");
  });

  it("status-web-src-014 a null display name falls back to the email", async () => {
    const { out } = mountWith(
      useStatusHeaderAuth,
      mockFetch(meOf({ email: "a@b.c", displayName: null, role: "admin" })),
    );
    await waitFor(() => expect(out.current?.user).not.toBeNull());
    expect(out.current?.user?.name).toBe("a@b.c");
  });
});

describe("onLogout", () => {
  const user: StatusUser = { email: "a@b.c", displayName: "Ann", role: "viewer" };
  const hrefs: string[] = [];

  function stubLocation(): void {
    hrefs.length = 0;
    vi.stubGlobal("location", {
      get href() {
        return hrefs.at(-1) ?? "http://localhost/";
      },
      set href(v: string) {
        hrefs.push(v);
      },
    });
  }

  async function signedIn(logout: Transport) {
    const transport = mockFetch((url, init) => (url.endsWith("/auth/me") ? meOf(user)() : logout(url, init)));
    const mounted = mountWith(useStatusHeaderAuth, transport);
    await waitFor(() => expect(mounted.out.current?.onLogout).toBeDefined());
    return { ...mounted, transport };
  }

  it("status-web-src-015 POSTs /api/auth/logout then navigates to /", async () => {
    stubLocation();
    const { out, transport } = await signedIn(async () => new Response(null, { status: 200 }));
    out.current!.onLogout!();
    await waitFor(() => expect(hrefs).toEqual(["/"]));
    const posts = transport.mock.calls.filter(([, init]) => (init as RequestInit | undefined)?.method === "POST");
    expect(posts).toHaveLength(1);
    expect(posts[0]![0]).toBe("/api/auth/logout");
  });

  it("status-web-src-016 a 500 still navigates to /, throws nothing, and does not invalidate the session", async () => {
    stubLocation();
    const { out, qc } = await signedIn(async () => new Response("{}", { status: 500 }));
    const invalidate = vi.spyOn(qc, "invalidateQueries");
    expect(() => out.current!.onLogout!()).not.toThrow();
    await waitFor(() => expect(hrefs).toEqual(["/"]));
    expect(invalidate).not.toHaveBeenCalled();
    expect(qc.getQueryData(STATUS_AUTH_QUERY_KEY)).toEqual(user);
  });

  it("status-web-src-017 a rejected logout still navigates to / and the rejection goes unhandled", async () => {
    stubLocation();
    const boom = new TypeError("logout failed");
    const { out } = await signedIn(async () => {
      throw boom;
    });
    // Vitest fails the run on an unhandled rejection; this test asserts that one is
    // raised, so it takes the process listeners over for its duration.
    const saved = process.listeners("unhandledRejection");
    process.removeAllListeners("unhandledRejection");
    const seen: unknown[] = [];
    process.on("unhandledRejection", (reason) => seen.push(reason));
    try {
      expect(() => out.current!.onLogout!()).not.toThrow();
      await waitFor(() => expect(hrefs).toEqual(["/"]));
      await waitFor(() => expect(seen).toContain(boom));
    } finally {
      process.removeAllListeners("unhandledRejection");
      for (const l of saved) process.on("unhandledRejection", l);
    }
  });
});

describe("useStatusUser", () => {
  const user: StatusUser = { email: "a@b.c", displayName: "Ann", role: "viewer" };

  it("status-web-src-018 keeps the cached user when every refetch attempt fails", async () => {
    vi.useFakeTimers();
    const transport = mockFetch(async () => new Response("{}", { status: 503 }));
    const qc = new QueryClient();
    qc.setQueryData(STATUS_AUTH_QUERY_KEY, user);
    const { out } = mountWith(useStatusUser, transport, qc);
    expect(transport).not.toHaveBeenCalled(); // fresh within the 60s staleness window
    await act(async () => {
      void qc.invalidateQueries({ queryKey: STATUS_AUTH_QUERY_KEY });
      await vi.advanceTimersByTimeAsync(10_000);
    });
    expect(transport).toHaveBeenCalledTimes(4);
    expect(qc.getQueryState(STATUS_AUTH_QUERY_KEY)?.status).toBe("error");
    expect(out.current).toEqual({ user, isPending: false });
  });

  it("status-web-src-019 two consumers mounting together issue one /auth/me request", async () => {
    const transport = mockFetch(meOf(user));
    const qc = new QueryClient();
    vi.stubGlobal("fetch", transport);
    const api = createStatusApiClient({ fetch: transport });
    const seen: Array<ReturnType<typeof useStatusUser>> = [];
    function Consumer(): ReactElement | null {
      seen.push(useStatusUser());
      return null;
    }
    render(
      <QueryClientProvider client={qc}>
        <StatusApiProvider client={api}>
          <Consumer />
          <Consumer />
        </StatusApiProvider>
      </QueryClientProvider>,
    );
    await waitFor(() => expect(seen.at(-1)?.user).toEqual(user));
    expect(transport).toHaveBeenCalledTimes(1);
  });

  it("status-web-src-020 a first load that always fails is attempted 4 times, then settles in error", async () => {
    vi.useFakeTimers();
    const transport = mockFetch(async () => new Response("{}", { status: 503 }));
    const qc = new QueryClient();
    const { out } = mountWith(useStatusUser, transport, qc);
    await act(async () => {
      await vi.advanceTimersByTimeAsync(10_000);
    });
    expect(transport).toHaveBeenCalledTimes(4);
    expect(qc.getQueryState(STATUS_AUTH_QUERY_KEY)?.status).toBe("error");
    expect(out.current).toEqual({ user: null, isPending: false });
  });
});

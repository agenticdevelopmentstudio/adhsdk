// @vitest-environment jsdom
import { describe, it, expect, beforeEach, afterEach, vi, type Mock } from "vitest";
import { type ReactNode } from "react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { act, cleanup, render, waitFor } from "@testing-library/react";
import { useLiveSnapshot, __resetStoreForTests, subscribeLiveFrames, POLL_INTERVAL_MS, type LiveSnapshotStore } from "./use-live-snapshot";
import { liveSnapshot } from "../lib/live-snapshot.fixture";
// @ts-expect-error vite raw import; read as text to check the directive
import source from "./use-live-snapshot.ts?raw";

// --- a controllable EventSource stand-in (jsdom has none) ---------------------
class MockEventSource {
  static instances: MockEventSource[] = [];
  static readonly CONNECTING = 0;
  static readonly OPEN = 1;
  static readonly CLOSED = 2;
  readonly CONNECTING = 0;
  readonly OPEN = 1;
  readonly CLOSED = 2;
  url: string;
  readyState = 0;
  private handlers: Record<string, Array<(e: MessageEvent) => void>> = {};
  constructor(url: string) {
    this.url = url;
    MockEventSource.instances.push(this);
  }
  addEventListener(type: string, cb: (e: MessageEvent) => void): void {
    (this.handlers[type] ||= []).push(cb);
  }
  removeEventListener(): void {}
  close(): void {
    this.readyState = 2;
  }
  // test drivers
  fire(type: string, data?: string): void {
    for (const cb of this.handlers[type] ?? []) cb({ data } as MessageEvent);
  }
  open(): void {
    this.readyState = 1;
    this.fire("open");
  }
  fail(closed: boolean): void {
    if (closed) this.readyState = 2;
    this.fire("error");
  }
}

function installFetch(opts: { liveHangs?: boolean; liveRejects?: boolean; checkRan?: boolean } = {}): Mock {
  const json = (body: unknown) =>
    new Response(JSON.stringify(body), { status: 200, headers: { "content-type": "application/json" } });
  const fn = vi.fn(async (input: RequestInfo | URL) => {
    const url = String(input);
    if (url.includes("/api/live/check")) return json({ ok: true, ran: opts.checkRan ?? true });
    if (opts.liveRejects) throw new Error("network");
    if (opts.liveHangs) return new Promise<Response>(() => {}); // never resolves
    return json(liveSnapshot({ generatedAt: "2026-01-01T00:00:00.000Z" }));
  });
  globalThis.fetch = fn as unknown as typeof fetch;
  return fn;
}

function mountStore() {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  const wrapper = ({ children }: { children: ReactNode }) => (
    <QueryClientProvider client={qc}>{children}</QueryClientProvider>
  );
  const ref: { current: LiveSnapshotStore | null } = { current: null };
  function Probe(): null {
    ref.current = useLiveSnapshot();
    return null;
  }
  const view = render(<Probe />, { wrapper });
  return { ref, unmount: view.unmount };
}

const stream = () => MockEventSource.instances.at(-1)!;

describe("useLiveSnapshot — SSE wiring (jsdom + mock EventSource)", () => {
  beforeEach(() => {
    MockEventSource.instances = [];
    (globalThis as unknown as { EventSource: unknown }).EventSource = MockEventSource;
    window.localStorage?.clear(); // jsdom may not provide localStorage; the hook tolerates its absence
    installFetch({ liveHangs: true }); // isolate SSE from the poll unless a test says otherwise
  });
  afterEach(() => {
    // Unmount every probe first: a still-mounted one re-renders into the NEXT test's
    // (fresh) store through the shared default client and pollutes it.
    cleanup();
    __resetStoreForTests();
    vi.useRealTimers();
  });

  it("use-live-snapshot-005 opens the stream and folds a pushed snapshot into the store", async () => {
    const { ref } = mountStore();
    expect(stream().url).toBe("/api/live/stream");

    const pushed = liveSnapshot({
      generatedAt: "2030-01-01T00:00:00.000Z",
      services: [
        // a real DTO so the snapshot is non-trivial; only the marker is asserted
        { slug: "s", group: "G", name: "Svc", environment: "production", status: "healthy", responseTimeMs: 12, statusCode: 200, url: "https://x", error: null, dnsOk: true, downSince: null },
      ] as never,
    });
    act(() => {
      stream().open();
      stream().fire("snapshot", JSON.stringify(pushed));
    });

    await waitFor(() => expect(ref.current!.snapshot?.generatedAt).toBe("2030-01-01T00:00:00.000Z"));
    expect(ref.current!.snapshot?.services).toHaveLength(1);
  });

  it("use-live-snapshot-006 drives the countdown off the backend schedule frame", async () => {
    const { ref } = mountStore();
    act(() => {
      stream().open();
      stream().fire("schedule", JSON.stringify({ nextCheckAt: "2030-06-01T00:00:00.000Z" }));
    });
    await waitFor(() => expect(ref.current!.nextPollAt).toBe(Date.parse("2030-06-01T00:00:00.000Z")));
  });

  it("use-live-snapshot-007 refresh() POSTs /api/live/check and shows the spinner until a fresh snapshot lands", async () => {
    const fetchMock = installFetch({ checkRan: true }); // poll resolves so isFetching settles
    const { ref } = mountStore();
    act(() => stream().open());
    await waitFor(() => expect(ref.current!.polling).toBe(false)); // initial poll settled, nothing pending

    act(() => {
      ref.current!.refresh();
    });
    // The POST fires synchronously before the IIFE's first await.
    expect(fetchMock).toHaveBeenCalledWith("/api/live/check", { method: "POST" });
    expect(ref.current!.polling).toBe(true); // spinner on while awaiting the check's result

    // A snapshot built AFTER the click clears the spinner; an earlier one would not.
    act(() => stream().fire("snapshot", JSON.stringify(liveSnapshot({ generatedAt: new Date(Date.now() + 5_000).toISOString() }))));
    await waitFor(() => expect(ref.current!.polling).toBe(false));
  });

  it("use-live-snapshot-008 keeps the spinner up for the WHOLE detached cycle, not just 12s", async () => {
    // POST /api/live/check now returns as soon as the cycle STARTS (runNowDetached);
    // the fresh snapshot arrives later, over SSE. The safety backstop must therefore
    // outlast a real manual full sync (the backend's cycle budget is ~2-3 min) —
    // at the old 12s it fired on every check, telling the user "done" while the
    // providers were still being polled.
    installFetch({ checkRan: true });
    const { ref } = mountStore();
    act(() => stream().open());
    await waitFor(() => expect(ref.current!.polling).toBe(false)); // initial poll settled

    // Fake timers BEFORE the click, so the safety timeout refresh() schedules is the
    // one we advance (installing them afterwards would leave it on the real clock and
    // make this assertion vacuous). Microtasks still run, so the POST settles.
    vi.useFakeTimers();
    try {
      act(() => {
        ref.current!.refresh();
      });
      await act(async () => {
        await Promise.resolve();
        await Promise.resolve();
      });
      expect(ref.current!.polling).toBe(true);

      act(() => {
        vi.advanceTimersByTime(60_000); // a minute into a cycle that legitimately runs longer
      });
      expect(ref.current!.polling).toBe(true); // still checking — do NOT claim it finished

      // The cycle completes and pushes its snapshot: THAT is what ends the check.
      act(() => stream().fire("snapshot", JSON.stringify(liveSnapshot({ generatedAt: new Date(Date.now() + 90_000).toISOString() }))));
      expect(ref.current!.polling).toBe(false);
    } finally {
      vi.useRealTimers();
    }
  });

  it("use-live-snapshot-009 does not slam a stale /live refetch the instant the detached check is accepted", async () => {
    // Pre-detach, the POST resolved only after the cycle finished, so an immediate
    // refetch was guaranteed fresh. Now it would fetch the PRE-cycle snapshot —
    // pure waste that can't advance the check. The fallback client re-reads on its
    // own cadence (and via the safety backstop) instead.
    const fetchMock = installFetch({ checkRan: true });
    const { ref } = mountStore();
    // No stream opened: this is the polling-fallback client.
    await waitFor(() => expect(ref.current!.polling).toBe(false));
    fetchMock.mockClear();

    act(() => {
      ref.current!.refresh();
    });
    await waitFor(() => expect(fetchMock).toHaveBeenCalledWith("/api/live/check", { method: "POST" }));
    await act(async () => {
      await Promise.resolve();
    });

    const liveCalls = fetchMock.mock.calls.filter((c) => String(c[0]).includes("/api/live") && !String(c[0]).includes("/check"));
    expect(liveCalls).toHaveLength(0);
  });

  it("use-live-snapshot-010 recreates the EventSource after a PERMANENT (readyState CLOSED) failure", () => {
    vi.useFakeTimers();
    mountStore();
    expect(MockEventSource.instances).toHaveLength(1);

    act(() => stream().fail(true)); // non-200 → CLOSED, browser would NOT auto-retry
    act(() => {
      vi.advanceTimersByTime(3_000); // STREAM_REOPEN_MS
    });
    expect(MockEventSource.instances).toHaveLength(2); // we recreated it ourselves
  });

  it("use-live-snapshot-011 does NOT recreate on a transient (CONNECTING) error — the browser auto-retries", () => {
    vi.useFakeTimers();
    mountStore();
    act(() => stream().fail(false)); // readyState stays CONNECTING
    act(() => {
      vi.advanceTimersByTime(10_000);
    });
    expect(MockEventSource.instances).toHaveLength(1); // no extra connection created
  });

  it("use-live-snapshot-012 a check that did not run re-reads /live once and clears the spinner", async () => {
    const fetchMock = installFetch({ checkRan: false });
    const { ref } = mountStore();
    // No stream opened: the poll is the only feed.
    await waitFor(() => expect(ref.current!.polling).toBe(false));
    fetchMock.mockClear();

    act(() => {
      ref.current!.refresh();
    });
    await waitFor(() => expect(fetchMock).toHaveBeenCalledWith("/api/live/check", { method: "POST" }));
    await waitFor(() => expect(ref.current!.polling).toBe(false));
    const liveGets = fetchMock.mock.calls.filter((c) => String(c[0]) === "/api/live");
    expect(liveGets).toHaveLength(1);
  });

  it("use-live-snapshot-013 a failing /live read marks the feed offline and disconnected", async () => {
    globalThis.fetch = vi.fn(async () => new Response("down", { status: 503 })) as unknown as typeof fetch;
    const { ref } = mountStore();
    // The hook's own `retry: 1` (1s backoff) keeps the query fetching, hence not "offline", first.
    await waitFor(() => expect(ref.current!.offline).toBe(true), { timeout: 5_000 });
    expect(ref.current!.disconnected).toBe(true);
    expect(ref.current!.offlineDetail).toBe("live 503");
  });

  it("use-live-snapshot-014 a successful read clears the error; disconnected stays asserted through the retry", async () => {
    let mode: "fail" | "hang" | "ok" = "fail";
    let release: (r: Response) => void = () => {};
    const okBody = () => new Response(JSON.stringify(liveSnapshot({ generatedAt: "2026-01-01T00:00:00.000Z" })), { status: 200 });
    globalThis.fetch = vi.fn(async (): Promise<Response> => {
      if (mode === "fail") return new Response("down", { status: 503 });
      if (mode === "hang") return new Promise<Response>((res) => { release = res; });
      return okBody();
    }) as unknown as typeof fetch;
    const { ref } = mountStore();
    await waitFor(() => expect(ref.current!.offline).toBe(true), { timeout: 5_000 });

    mode = "hang";
    act(() => ref.current!.reconnect());
    // In flight: offline flaps false, disconnected does not.
    await waitFor(() => expect(ref.current!.offline).toBe(false));
    expect(ref.current!.disconnected).toBe(true);
    expect(ref.current!.offlineDetail).toBe("live 503");

    await act(async () => {
      release(okBody());
    });
    await waitFor(() => expect(ref.current!.disconnected).toBe(false));
    expect(ref.current!.offlineDetail).toBeNull();
  });

  it("use-live-snapshot-015 blind follows the snapshot's blind flag, false before any snapshot", async () => {
    const { ref } = mountStore();
    expect(ref.current!.blind).toBe(false);
    act(() => {
      stream().open();
      stream().fire("snapshot", JSON.stringify(liveSnapshot({ generatedAt: "2030-01-01T00:00:00.000Z", blind: true })));
    });
    await waitFor(() => expect(ref.current!.blind).toBe(true));
    act(() => stream().fire("snapshot", JSON.stringify(liveSnapshot({ generatedAt: "2030-01-02T00:00:00.000Z", blind: false }))));
    await waitFor(() => expect(ref.current!.blind).toBe(false));
  });

  it("use-live-snapshot-016 a snapshot built before the check updates the snapshot but keeps the spinner", async () => {
    installFetch({ checkRan: true });
    const { ref } = mountStore();
    act(() => stream().open());
    await waitFor(() => expect(ref.current!.polling).toBe(false));

    act(() => {
      ref.current!.refresh();
    });
    await act(async () => {
      await Promise.resolve();
      await Promise.resolve();
    });
    const earlier = new Date(Date.now() - 60_000).toISOString();
    act(() => stream().fire("snapshot", JSON.stringify(liveSnapshot({ generatedAt: earlier }))));
    expect(ref.current!.snapshot?.generatedAt).toBe(earlier);
    expect(ref.current!.polling).toBe(true);
  });

  it("use-live-snapshot-017 a malformed snapshot frame is dropped silently", () => {
    const { ref } = mountStore();
    const cb = vi.fn();
    const off = subscribeLiveFrames(cb);
    try {
      act(() => {
        stream().open();
        stream().fire("snapshot", "{not json");
      });
      expect(ref.current!.snapshot).toBeNull();
      expect(cb).not.toHaveBeenCalled();
    } finally {
      off();
    }
  });

  it("use-live-snapshot-018 the same snapshot from stream and poll is ingested once", async () => {
    installFetch(); // poll returns generatedAt 2026-01-01T00:00:00.000Z
    const { ref } = mountStore();
    const cb = vi.fn();
    const off = subscribeLiveFrames(cb);
    try {
      await waitFor(() => expect(ref.current!.snapshot).not.toBeNull());
      act(() => {
        stream().open();
        stream().fire("snapshot", JSON.stringify(liveSnapshot({ generatedAt: "2026-01-01T00:00:00.000Z" })));
      });
      expect(cb).toHaveBeenCalledTimes(1);
    } finally {
      off();
    }
  });

  it("use-live-snapshot-019 two hooks under one client share one ref-counted stream", () => {
    const a = mountStore();
    const b = mountStore();
    expect(MockEventSource.instances).toHaveLength(1);
    a.unmount();
    expect(stream().readyState).not.toBe(MockEventSource.CLOSED);
    b.unmount();
    expect(stream().readyState).toBe(MockEventSource.CLOSED);
  });

  it("use-live-snapshot-020 without a stream nextPollAt estimates last success plus the poll interval", async () => {
    installFetch();
    const before = Date.now();
    const { ref } = mountStore();
    await waitFor(() => expect(ref.current!.nextPollAt).not.toBeNull());
    const after = Date.now();
    const next = ref.current!.nextPollAt!;
    expect(next).toBeGreaterThanOrEqual(before + POLL_INTERVAL_MS);
    expect(next).toBeLessThanOrEqual(after + POLL_INTERVAL_MS);
  });

  it("use-live-snapshot-021 the module is marked client-only", () => {
    expect((source as string).trimStart().startsWith('"use client"')).toBe(true);
  });
});

import { describe, it, expect, vi, afterEach } from "vitest";
import { fetchGlitchtipIssues, glitchtipFetcher, mapIssues, MAX_PAGES, PAGE_LIMIT } from "../src/telemetry/fetchers/glitchtip";

// The fetcher's CONTRACT with `errorsStore`, which is the only thing that makes the store's
// sweep safe. The store reads "absent from this set" as "resolved upstream", so it depends
// on two claims this file makes and nothing else can check: `ok` means the poll really
// answered, and `complete` means the answer was the whole set. Both used to be wrong in the
// same direction — toward a confident empty answer — which is the direction that mass-
// resolves the errors table and pages an all-clear in the middle of a live incident.

const ENV = {
  GLITCHTIP_URL: "https://glitchtip.example/",
  GLITCHTIP_API_TOKEN: "tok",
  GLITCHTIP_ORG: "adh",
};

function issue(id: string) {
  return { id, title: `boom ${id}`, project: { slug: "adh" }, level: "error", count: 1 };
}

/** Stub `fetch` with one canned response. Returns the URL it was called with. */
function stubFetch(body: unknown, init: { ok?: boolean; status?: number } = {}) {
  const calls: string[] = [];
  vi.stubGlobal("fetch", async (url: string) => {
    calls.push(url);
    return { ok: init.ok ?? true, status: init.status ?? 200, headers: new Headers(), json: async () => body };
  });
  return calls;
}

/** GlitchTip's Link header, byte for byte: it stringifies a Python set, so the value opens
 *  with `{'` and the two rels arrive in either order. A strict RFC 8288 parser reads this
 *  as no links at all. */
function linkHeader(next: { cursor: string; results: boolean; origin?: string }): string {
  const origin = next.origin ?? "https://glitchtip.example";
  const url = `${origin}/api/0/organizations/adh/issues/?cursor=${encodeURIComponent(next.cursor)}&limit=100&query=is%3Aunresolved`;
  return `{'<${origin}/api/0/x>; rel="previous"; results="false"; cursor="p"', '<${url}>; rel="next"; results="${next.results}"; cursor="${next.cursor}"'}`;
}

interface StubPage {
  issues?: unknown;
  link?: string;
  status?: number;
}

/** Stub `fetch` with a sequence of pages, the last repeating. Returns the URLs asked for. */
function stubPages(pages: StubPage[]) {
  const calls: string[] = [];
  vi.stubGlobal("fetch", async (url: string) => {
    const page = pages[Math.min(calls.length, pages.length - 1)]!;
    calls.push(url);
    const status = page.status ?? 200;
    const headers = new Headers(page.link ? { Link: page.link } : {});
    return { ok: status < 400, status, headers, json: async () => page.issues ?? [] };
  });
  return calls;
}

const fullPage = (prefix: string) => Array.from({ length: PAGE_LIMIT }, (_, i) => issue(`${prefix}${i}`));

afterEach(() => {
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

describe("glitchtipFetcher — is this answer usable", () => {
  it("no-ops green when unconfigured, so nothing is ever polled or swept", async () => {
    const r = await glitchtipFetcher({}).fetch();
    expect(r).toMatchObject({ ok: true, items: [] });
  });

  it("reports a short page as COMPLETE", async () => {
    stubFetch([issue("a"), issue("b")]);
    const r = await glitchtipFetcher(ENV).fetch();
    expect(r.ok).toBe(true);
    expect(r.complete).toBe(true);
    expect(r.items.map((i) => i.issueKey)).toEqual(["a", "b"]);
  });

  // A FULL page with no way forward is presumed truncated. Sweeping on it would resolve every
  // issue past the page edge and the next poll would reopen them — a project whose issues
  // straddle the boundary flapping open/closed every cycle, forever.
  it("reports a FULL page with no next link as incomplete", async () => {
    stubFetch(Array.from({ length: PAGE_LIMIT }, (_, i) => issue(`i${i}`)));
    const r = await glitchtipFetcher(ENV).fetch();
    expect(r.ok).toBe(true);
    expect(r.complete).toBe(false);
  });

  it("starts at PAGE_LIMIT unresolved issues and stops when there is nothing more", async () => {
    const calls = stubFetch([]);
    await glitchtipFetcher(ENV).fetch();
    expect(calls).toEqual([
      `https://glitchtip.example/api/0/organizations/adh/issues/?query=is:unresolved&limit=${PAGE_LIMIT}`,
    ]);
  });

  // THE one that matters. A 200 whose body is not a list — an error envelope, a
  // maintenance page, an auth-proxy interstitial, a `{results:[…]}` wrapper — is a FAILED
  // poll, not an empty one. It used to return `ok: true, items: []`, which is exactly the
  // value that tells a reconciling store "GlitchTip has nothing unresolved".
  it.each([
    [{ detail: "Authentication credentials were not provided." }],
    [{ results: [{ id: "a" }] }],
    ["<html>maintenance</html>"],
    [null],
  ])("treats a non-array 200 body as a failed poll: %s", async (body) => {
    vi.spyOn(console, "warn").mockImplementation(() => {});
    stubFetch(body);
    expect(await glitchtipFetcher(ENV).fetch()).toMatchObject({ ok: false, items: [] });
  });

  it("treats an HTTP error as a failed poll", async () => {
    vi.spyOn(console, "warn").mockImplementation(() => {});
    stubFetch([], { ok: false, status: 502 });
    expect(await glitchtipFetcher(ENV).fetch()).toMatchObject({ ok: false, items: [] });
  });

  it("treats a thrown fetch as a failed poll", async () => {
    vi.spyOn(console, "warn").mockImplementation(() => {});
    vi.stubGlobal("fetch", async () => {
      throw new Error("ECONNREFUSED");
    });
    expect(await glitchtipFetcher(ENV).fetch()).toMatchObject({ ok: false, items: [] });
  });
});

// The fix for the permanently-red panel. Production holds 137 unresolved issues; one page
// of 100 reported `complete: false` on every poll, so `errorsStore` never swept and the
// table could only ever grow.
describe("glitchtipFetcher — walks every page", () => {
  it("follows the cursor to the end, re-reads page 1, and reports the whole set as complete", async () => {
    const calls = stubPages([
      { issues: fullPage("a"), link: linkHeader({ cursor: "c1:0:0", results: true }) },
      { issues: [issue("last")], link: linkHeader({ cursor: "c2:0:0", results: false }) },
      { issues: fullPage("a") },
    ]);
    const r = await glitchtipFetcher(ENV).fetch();
    expect(r.ok).toBe(true);
    expect(r.complete).toBe(true);
    expect(r.items).toHaveLength(PAGE_LIMIT + 1);
    expect(calls).toHaveLength(3);
    expect(calls[1]).toContain("cursor=c1%3A0%3A0");
    expect(calls[2]).not.toContain("cursor=");
  });

  // An issue that fires between the page-1 and page-2 requests jumps to the top of the list,
  // onto the page already read. Without the re-read it is missing from a "complete" answer, so
  // the store resolves it and the next poll reopens it: a flap with an alert each way.
  it("picks up an issue that moved to page 1 while the walk was on later pages", async () => {
    stubPages([
      { issues: fullPage("a"), link: linkHeader({ cursor: "c1", results: true }) },
      { issues: [issue("b")], link: linkHeader({ cursor: "c2", results: false }) },
      { issues: [issue("mover"), ...fullPage("a").slice(0, PAGE_LIMIT - 1)] },
    ]);
    const r = await glitchtipFetcher(ENV).fetch();
    expect(r.complete).toBe(true);
    expect(r.items.map((i) => i.issueKey)).toContain("mover");
  });

  it("is ok but INCOMPLETE when the re-read of page 1 fails", async () => {
    vi.spyOn(console, "warn").mockImplementation(() => {});
    stubPages([
      { issues: fullPage("a"), link: linkHeader({ cursor: "c1", results: true }) },
      { issues: [issue("b")], link: linkHeader({ cursor: "c2", results: false }) },
      { status: 503 },
    ]);
    const r = await glitchtipFetcher(ENV).fetch();
    expect(r).toMatchObject({ ok: true, complete: false });
    expect(r.items).toHaveLength(PAGE_LIMIT + 1);
  });

  it("trusts an explicit results=false on a page that happens to be exactly full", async () => {
    stubPages([{ issues: fullPage("a"), link: linkHeader({ cursor: "c1", results: false }) }]);
    const r = await glitchtipFetcher(ENV).fetch();
    expect(r.complete).toBe(true);
  });

  // The token goes on every page request, so the next URL is REBUILT from our own base. A
  // header is provider data; a proxy or a misconfigured GlitchTip must not be able to name
  // where the bearer token is sent.
  it("never sends a request to an origin named by the Link header", async () => {
    const calls = stubPages([
      { issues: fullPage("a"), link: linkHeader({ cursor: "c1", results: true, origin: "https://evil.example" }) },
      { issues: [] },
    ]);
    await glitchtipFetcher(ENV).fetch();
    expect(calls).toHaveLength(2);
    expect(calls.every((u) => u.startsWith("https://glitchtip.example/"))).toBe(true);
  });

  it("is ok but INCOMPLETE when a cursor repeats, rather than looping", async () => {
    const calls = stubPages([{ issues: fullPage("a"), link: linkHeader({ cursor: "same", results: true }) }]);
    const r = await glitchtipFetcher(ENV).fetch();
    expect(r).toMatchObject({ ok: true, complete: false });
    expect(calls).toHaveLength(2);
  });

  it("is ok but INCOMPLETE past the page cap", async () => {
    let n = 0;
    const calls: string[] = [];
    vi.stubGlobal("fetch", async (url: string) => {
      calls.push(url);
      n += 1;
      const page = n;
      return {
        ok: true,
        status: 200,
        headers: new Headers({ Link: linkHeader({ cursor: `c${page}`, results: true }) }),
        json: async () => fullPage(`p${page}-`),
      };
    });
    const r = await glitchtipFetcher(ENV).fetch();
    expect(r).toMatchObject({ ok: true, complete: false });
    expect(calls).toHaveLength(MAX_PAGES);
  });

  // A partial walk reported as ok+complete would sweep every issue on the unread pages; one
  // reported as failed would throw away the pages that answered and flag GlitchTip unreachable.
  it.each([
    ["an HTTP error", { status: 502 }],
    ["a non-array body", { issues: { detail: "nope" } }],
  ])("keeps the pages already read, INCOMPLETE, when a later page returns %s", async (_, page) => {
    vi.spyOn(console, "warn").mockImplementation(() => {});
    stubPages([{ issues: fullPage("a"), link: linkHeader({ cursor: "c1", results: true }) }, page]);
    const r = await glitchtipFetcher(ENV).fetch();
    expect(r).toMatchObject({ ok: true, complete: false });
    expect(r.items).toHaveLength(PAGE_LIMIT);
  });

  it("keeps the pages already read, INCOMPLETE, when a later page throws", async () => {
    vi.spyOn(console, "warn").mockImplementation(() => {});
    let n = 0;
    vi.stubGlobal("fetch", async () => {
      n += 1;
      if (n > 1) throw Object.assign(new Error("aborted"), { name: "AbortError" });
      return {
        ok: true,
        status: 200,
        headers: new Headers({ Link: linkHeader({ cursor: "c1", results: true }) }),
        json: async () => fullPage("a"),
      };
    });
    const r = await glitchtipFetcher(ENV).fetch();
    expect(r).toMatchObject({ ok: true, complete: false });
    expect(r.items).toHaveLength(PAGE_LIMIT);
  });

  it("drops an issue a shifting cursor served twice", async () => {
    stubPages([
      { issues: fullPage("a"), link: linkHeader({ cursor: "c1", results: true }) },
      { issues: [issue("a0"), issue("z")] },
    ]);
    const r = await glitchtipFetcher(ENV).fetch();
    expect(r.items).toHaveLength(PAGE_LIMIT + 1);
  });
});

describe("mapIssues", () => {
  // `projectSlug` falls back slug → name → "unknown", so the project segment the board
  // keys `errors|<project>` off is NOT safe by construction — which is why
  // `errorsTarget` escapes it.
  it("falls back through slug, name, then unknown", () => {
    const [a, b, c] = mapIssues([
      { id: "1", title: "t", project: { slug: "adh", name: "ADH" } },
      { id: "2", title: "t", project: { name: "Some Team's App" } },
      { id: "3", title: "t", project: null },
    ]);
    expect([a!.project, b!.project, c!.project]).toEqual(["adh", "Some Team's App", "unknown"]);
  });

  it("parses GlitchTip's string counts and drops unparseable timestamps", () => {
    const [i] = mapIssues([
      { id: "1", title: "t", count: "42", firstSeen: "not-a-date", lastSeen: "2026-08-18T00:00:00Z" },
    ]);
    expect(i).toMatchObject({ count: 42, firstSeen: null, lastSeen: "2026-08-18T00:00:00.000Z" });
  });
});

// One test per row of the recipe's conformance-test-vectors.md (status/service/telemetry/fetchers).
describe("conformance vectors — glitchtip", () => {
  const warn = () => vi.spyOn(console, "warn").mockImplementation(() => {});

  it("status-server-fetchers-001 unconfigured makes no request", async () => {
    const calls = stubFetch([]);
    expect(await glitchtipFetcher({}).fetch()).toEqual({ ok: true, items: [] });
    expect(await glitchtipFetcher({ ...ENV, GLITCHTIP_ORG: undefined }).fetch()).toEqual({ ok: true, items: [] });
    expect(calls).toEqual([]);
  });

  it("status-server-fetchers-002 first request URL and bearer header", async () => {
    const seen: { url: string; headers: Record<string, string> }[] = [];
    vi.stubGlobal("fetch", async (url: string, init: { headers: Record<string, string> }) => {
      seen.push({ url, headers: init.headers });
      return { ok: true, status: 200, headers: new Headers(), json: async () => [] };
    });
    await glitchtipFetcher(ENV).fetch();
    expect(seen).toHaveLength(1);
    expect(seen[0]!.url).toBe("https://glitchtip.example/api/0/organizations/adh/issues/?query=is:unresolved&limit=100");
    expect(seen[0]!.headers).toEqual({ Authorization: "Bearer tok" });
  });

  it("status-server-fetchers-003 short page is complete", async () => {
    stubFetch([issue("a"), issue("b")]);
    const r = await glitchtipFetcher(ENV).fetch();
    expect(r.ok).toBe(true);
    expect(r.complete).toBe(true);
    expect(r.items.map((i) => i.issueKey)).toEqual(["a", "b"]);
  });

  it("status-server-fetchers-004 full page without a Link header is incomplete", async () => {
    stubFetch(fullPage("f"));
    const r = await glitchtipFetcher(ENV).fetch();
    expect(r.ok).toBe(true);
    expect(r.complete).toBe(false);
  });

  it("status-server-fetchers-005 non-array 200 body fails the poll", async () => {
    const w = warn();
    stubFetch({ detail: "Authentication credentials were not provided." });
    expect(await glitchtipFetcher(ENV).fetch()).toEqual({ ok: false, items: [] });
    expect(w).toHaveBeenCalledWith(expect.stringContaining("non-array body"));
  });

  it("status-server-fetchers-006 HTTP error fails the poll and logs the status", async () => {
    const w = warn();
    stubFetch([], { ok: false, status: 502 });
    expect(await glitchtipFetcher(ENV).fetch()).toEqual({ ok: false, items: [] });
    expect(w).toHaveBeenCalledWith(expect.stringContaining("HTTP 502"));
  });

  it("status-server-fetchers-007 thrown fetch fails the poll after exactly one attempt", async () => {
    const w = warn();
    let n = 0;
    vi.stubGlobal("fetch", async () => {
      n += 1;
      throw new Error("ECONNREFUSED");
    });
    expect(await glitchtipFetcher(ENV).fetch()).toEqual({ ok: false, items: [] });
    expect(n).toBe(1);
    expect(w).toHaveBeenCalledWith(expect.stringContaining("ECONNREFUSED"));
  });

  it("status-server-fetchers-008 project falls back slug, name, unknown", () => {
    const out = mapIssues([
      { id: "1", title: "t", project: { slug: "adh", name: "ADH" } },
      { id: "2", title: "t", project: { name: "Some Team's App" } },
      { id: "3", title: "t", project: null },
    ]);
    expect(out.map((i) => i.project)).toEqual(["adh", "Some Team's App", "unknown"]);
  });

  it("status-server-fetchers-009 count, timestamps and field defaults", () => {
    const [i] = mapIssues([{ id: "1", title: "t", count: "42", firstSeen: "not-a-date", lastSeen: "2026-08-18T00:00:00Z" }]);
    expect(i).toEqual({
      id: "1",
      issueKey: "1",
      project: "unknown",
      title: "t",
      culprit: null,
      level: null,
      count: 42,
      userCount: 0,
      firstSeen: null,
      lastSeen: "2026-08-18T00:00:00.000Z",
      permalink: null,
    });
  });

  it("status-server-fetchers-019 the walk is aborted after 12,000ms", async () => {
    vi.useFakeTimers();
    try {
      const w = warn();
      let signal: AbortSignal | undefined;
      vi.stubGlobal("fetch", (_url: string, init: { signal: AbortSignal }) => {
        signal = init.signal;
        return new Promise((_resolve, reject) => {
          init.signal.addEventListener("abort", () =>
            reject(Object.assign(new Error("aborted"), { name: "AbortError" })),
          );
        });
      });
      const pending = glitchtipFetcher(ENV).fetch();
      await vi.advanceTimersByTimeAsync(11_999);
      expect(signal!.aborted).toBe(false);
      await vi.advanceTimersByTimeAsync(1);
      expect(signal!.aborted).toBe(true);
      expect(await pending).toEqual({ ok: false, items: [] });
      expect(w).toHaveBeenCalledWith(expect.stringContaining("timed out after 12000ms"));
    } finally {
      vi.useRealTimers();
    }
  });

  it("status-server-fetchers-020 follows the cursor, re-reads page 1, reports complete", async () => {
    const calls = stubPages([
      { issues: fullPage("a"), link: linkHeader({ cursor: "c1", results: true }) },
      { issues: [issue("last")], link: linkHeader({ cursor: "c2", results: false }) },
      { issues: fullPage("a") },
    ]);
    const r = await glitchtipFetcher(ENV).fetch();
    expect(r).toMatchObject({ ok: true, complete: true });
    expect(r.items).toHaveLength(PAGE_LIMIT + 1);
    expect(calls).toHaveLength(3);
    expect(calls[1]).toBe(`${calls[0]}&cursor=c1`);
    expect(calls[2]).toBe(calls[0]);
  });

  it("status-server-fetchers-021 a failing later page keeps the pages read, incomplete", async () => {
    warn();
    stubPages([{ issues: fullPage("a"), link: linkHeader({ cursor: "c1", results: true }) }, { status: 502 }]);
    const r = await glitchtipFetcher(ENV).fetch();
    expect(r).toMatchObject({ ok: true, complete: false });
    expect(r.items).toHaveLength(PAGE_LIMIT);
  });

  it("status-server-fetchers-022 a repeated cursor or the page cap ends the walk incomplete", async () => {
    stubPages([{ issues: fullPage("a"), link: linkHeader({ cursor: "same", results: true }) }]);
    expect(await glitchtipFetcher(ENV).fetch()).toMatchObject({ ok: true, complete: false });
    let n = 0;
    const calls: string[] = [];
    vi.stubGlobal("fetch", async (url: string) => {
      calls.push(url);
      n += 1;
      const page = n;
      return {
        ok: true,
        status: 200,
        headers: new Headers({ Link: linkHeader({ cursor: `c${page}`, results: true }) }),
        json: async () => fullPage(`p${page}-`),
      };
    });
    expect(await glitchtipFetcher(ENV).fetch()).toMatchObject({ ok: true, complete: false });
    expect(calls).toHaveLength(MAX_PAGES);
  });

  it("status-server-fetchers-023 the next URL is rebuilt from the configured base, never the Link origin", async () => {
    const calls = stubPages([
      { issues: fullPage("a"), link: linkHeader({ cursor: "c1", results: true, origin: "https://evil.example" }) },
      { issues: [] },
    ]);
    await glitchtipFetcher(ENV).fetch();
    expect(calls).toHaveLength(2);
    expect(calls.every((u) => u.startsWith("https://glitchtip.example/"))).toBe(true);
  });

  it("status-server-fetchers-024 an explicit results=false on a full page is complete", async () => {
    const calls = stubPages([{ issues: fullPage("a"), link: linkHeader({ cursor: "c1", results: false }) }]);
    const r = await glitchtipFetcher(ENV).fetch();
    expect(r.complete).toBe(true);
    expect(calls).toHaveLength(1);
  });

  it("status-server-fetchers-028 fetchGlitchtipIssues takes the query and marks a later-page failure interrupted", async () => {
    warn();
    const calls = stubPages([{ issues: fullPage("a"), link: linkHeader({ cursor: "c1", results: true }) }, { status: 502 }]);
    const r = await fetchGlitchtipIssues(ENV, "is:resolved");
    expect(r).toMatchObject({ ok: true, complete: false, interrupted: true });
    expect(r.issues).toHaveLength(PAGE_LIMIT);
    expect(calls[0]).toContain("?query=is:resolved&limit=100");
    // A repeated cursor is incomplete but is not an interruption.
    stubPages([{ issues: fullPage("a"), link: linkHeader({ cursor: "same", results: true }) }]);
    const again = await fetchGlitchtipIssues(ENV, "is:unresolved");
    expect(again.complete).toBe(false);
    expect(again.interrupted).toBeUndefined();
  });
});

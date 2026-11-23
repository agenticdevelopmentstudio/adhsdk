// Recipe: adhsdk data, consented support access (phase 7).
// Only the transport is stubbed, so the path, method, query and body each call puts on the wire
// are asserted, along with the rules the panes read: a grant's state, the grouped log, the
// switch-off and step-up checks, and the content-table list.
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

vi.mock("../../http", async (importOriginal) => ({
  ...(await importOriginal<typeof import("../../http")>()),
  authedJson: vi.fn(),
  authedRequest: vi.fn(),
  listV1Page: vi.fn(),
}));

import { AuthHttpError } from "@adh-sdk/auth/client";
import {
  accessTable,
  grantState,
  groupAccess,
  isStepUpRequired,
  isSupportOff,
  operatorSupportApi,
  publicSupportApi,
  SUPPORT_CONTENT_TABLES,
  SUPPORT_BREAK_GLASS_HOURS_MAX,
  SUPPORT_LAPSE_DAYS,
  supportAdminApi,
  supportRequestProblem,
  supportApi,
  toSupportGrant,
  type SupportAccess,
  type SupportGrant,
  type SupportGrantWire,
  type SupportReadWire,
} from "..";
import { authedJson, authedRequest, listV1Page } from "../../http";

const mockedJson = vi.mocked(authedJson);
const mockedRequest = vi.mocked(authedRequest);
const mockedPage = vi.mocked(listV1Page);

const ECO = "0b9c4a52-6c3e-4d7e-9a1f-2f4c1d2e3a4b";
const GRANT = "5f0e1d2c-3b4a-4958-8776-655443322110";

const call = (m: typeof mockedJson | typeof mockedRequest | typeof mockedPage, i = 0) => {
  const [url, init] = m.mock.calls[i] as [string, RequestInit | undefined];
  const u = new URL(url, "https://x.test");
  return { path: u.pathname, params: Object.fromEntries(u.searchParams), init };
};

const wireGrant = (over: Partial<SupportGrantWire> = {}): SupportGrantWire => ({
  id: GRANT,
  ecosystem_id: ECO,
  target: { kind: "customer", id: "cust-1", display_name: "Sam" },
  grantee: { kind: "product_admin", display_name: "Ana", role_label: "Support" },
  reason: "Your export failed and I need to see the notes it skipped.",
  scope: "read_all",
  consent: "customer",
  status: "pending",
  requested_hours: 24,
  requested_at: "2026-11-20T10:00:00.000Z",
  decision: null,
  decided_at: null,
  expires_at: null,
  revoked_at: null,
  ...over,
});

const wireRead = (over: Partial<SupportReadWire> = {}): SupportReadWire => ({
  id: "read-1",
  grant_id: GRANT,
  grantee: { kind: "product_admin", display_name: "Ana", role_label: "Support" },
  route: "/support/grants/:id/data/:schema/:table",
  path: `/v1/support/grants/${GRANT}/data/content/notes`,
  at: "2026-11-20T12:00:00.000Z",
  ...over,
});

beforeEach(() => {
  mockedJson.mockReset();
  mockedRequest.mockReset();
  mockedPage.mockReset();
  mockedRequest.mockResolvedValue(undefined as never);
});

describe("supportApi", () => {
  it.each(["customer", "account"] as const)("lists the %s's grants and camel-cases them", async (side) => {
    mockedJson.mockResolvedValueOnce({ object: "list", data: [wireGrant()], has_more: false });
    const grants = await supportApi(side).grants();
    const c = call(mockedJson);
    expect(c.path).toBe(`/api/v1/${side}/support/grants`);
    expect(c.params.limit).toBe("100");
    expect(grants).toEqual([
      expect.objectContaining({
        id: GRANT,
        ecosystemId: ECO,
        granteeKind: "product_admin",
        granteeName: "Ana",
        granteeRole: "Support",
        consent: "customer",
        requestedFor: 24,
        decision: null,
      }),
    ]);
  });

  it.each(["approve", "deny", "revoke"] as const)("POSTs %s with no body and the id encoded", async (verb) => {
    await supportApi("account")[verb]("a/b");
    const c = call(mockedRequest);
    expect(c.path).toBe(`/api/v1/account/support/grants/a%2Fb/${verb}`);
    expect(c.init?.method).toBe("POST");
    expect(c.init?.body).toBeUndefined();
  });

  it("rethrows a 404 so the caller can tell the switch is off", async () => {
    mockedJson.mockRejectedValueOnce(new AuthHttpError(404, "Not found"));
    const err = await supportApi("customer").grants().catch((e: unknown) => e);
    expect(isSupportOff(err)).toBe(true);
  });

  it("pages the log by the legacy cursor and hands back the last id as the next one", async () => {
    mockedPage.mockResolvedValueOnce({ data: [wireRead({ id: "r1" }), wireRead({ id: "r2" })], hasMore: true });
    const page = await supportApi("customer").access({ grantId: GRANT, cursor: "r0" });
    const c = call(mockedPage);
    expect(c.path).toBe("/api/v1/customer/support/access");
    expect(c.params).toEqual({ grant_id: GRANT, cursor: "r0", limit: "50" });
    expect(page.nextCursor).toBe("r2");
    expect(page.items[0]).toEqual(
      expect.objectContaining({ id: "r1", grantId: GRANT, granteeName: "Ana", method: null }),
    );
  });

  it("leaves the cursor and grant off the first, unfiltered page and ends on the last", async () => {
    mockedPage.mockResolvedValueOnce({ data: [wireRead()], hasMore: false });
    const page = await supportApi("account").access();
    expect(call(mockedPage).params).toEqual({ limit: "50" });
    expect(page.nextCursor).toBeNull();
  });
});

describe("supportAdminApi", () => {
  it("lists with the ecosystem uuid and keeps the target", async () => {
    mockedJson.mockResolvedValueOnce({ object: "list", data: [wireGrant()], has_more: false });
    const [g] = await supportAdminApi.list(ECO);
    const c = call(mockedJson);
    expect(c.path).toBe("/api/v1/support/grants");
    expect(c.params.ecosystem).toBe(ECO);
    expect(g).toEqual(expect.objectContaining({ targetId: "cust-1", targetName: "Sam" }));
  });

  it("POSTs a request in snake case", async () => {
    mockedJson.mockResolvedValueOnce(wireGrant());
    await supportAdminApi.request(ECO, { targetId: "cust-1", reason: "A reason long enough.", hours: 48 });
    const c = call(mockedJson);
    expect(c.path).toBe("/api/v1/support/grants");
    expect(c.params.ecosystem).toBe(ECO);
    expect(c.init?.method).toBe("POST");
    expect(JSON.parse(String(c.init?.body))).toEqual({
      target_id: "cust-1",
      reason: "A reason long enough.",
      hours: 48,
    });
  });

  it("revokes with the ecosystem uuid", async () => {
    await supportAdminApi.revoke(ECO, GRANT);
    const c = call(mockedRequest);
    expect(c.path).toBe(`/api/v1/support/grants/${GRANT}/revoke`);
    expect(c.params.ecosystem).toBe(ECO);
    expect(c.init?.method).toBe("POST");
  });

  it("reads a table page with a GET and pages by starting_after", async () => {
    mockedPage.mockResolvedValueOnce({ data: [{ id: "n1" }, { id: "n2" }], hasMore: true });
    const page = await supportAdminApi.data(GRANT, "content", "notes", { cursor: "n0" });
    const c = call(mockedPage);
    expect(c.path).toBe(`/api/v1/support/grants/${GRANT}/data/content/notes`);
    expect(c.params).toEqual({ starting_after: "n0", limit: "50" });
    expect(c.init?.method ?? "GET").toBe("GET");
    expect(page).toEqual({ rows: [{ id: "n1" }, { id: "n2" }], nextCursor: "n2" });
  });

  it("reads one row with a GET", async () => {
    mockedJson.mockResolvedValueOnce({ id: "n1", title: "Hello" });
    const row = await supportAdminApi.row(GRANT, "content", "notes", "n1");
    const c = call(mockedJson);
    expect(c.path).toBe(`/api/v1/support/grants/${GRANT}/data/content/notes/n1`);
    expect(c.init?.method ?? "GET").toBe("GET");
    expect(row).toEqual({ id: "n1", title: "Hello" });
  });

  it("offers no call that writes to the viewer's paths", () => {
    expect(Object.keys(supportAdminApi).sort()).toEqual(["data", "list", "request", "revoke", "row"]);
  });
});

describe("operatorSupportApi", () => {
  it("lists with the status, consent and cursor filters", async () => {
    mockedPage.mockResolvedValueOnce({ data: [wireGrant({ id: "g1" })], hasMore: true });
    const page = await operatorSupportApi.list({ status: "live", consent: "break_glass", cursor: "g0" });
    const c = call(mockedPage);
    expect(c.path).toBe("/api/v1/system/support_grants");
    expect(c.params).toEqual({ status: "live", consent: "break_glass", cursor: "g0", limit: "50" });
    expect(page.nextCursor).toBe("g1");
  });

  it("POSTs a request naming the target's kind", async () => {
    mockedJson.mockResolvedValueOnce(wireGrant({ target: { kind: "account", id: "acc-1", display_name: null } }));
    await operatorSupportApi.request({ targetKind: "account", targetId: "acc-1", reason: "Because." });
    const c = call(mockedJson);
    expect(c.path).toBe("/api/v1/system/support_grants");
    expect(JSON.parse(String(c.init?.body))).toEqual({
      target_kind: "account",
      target_id: "acc-1",
      reason: "Because.",
    });
  });

  it("POSTs break glass with the attestation and its reference", async () => {
    mockedJson.mockResolvedValueOnce(wireGrant({ consent: "break_glass" }));
    await operatorSupportApi.breakGlass({
      targetKind: "customer",
      targetId: "cust-1",
      ecosystemId: ECO,
      reason: "Data loss in progress.",
      hours: 2,
      attestation: "I attest that this access is needed to stop an active loss of data.",
      attestationRef: "INC-42",
    });
    const c = call(mockedJson);
    expect(c.path).toBe("/api/v1/system/support_grants/break_glass");
    expect(JSON.parse(String(c.init?.body))).toEqual({
      target_kind: "customer",
      target_id: "cust-1",
      ecosystem_id: ECO,
      reason: "Data loss in progress.",
      hours: 2,
      attestation: "I attest that this access is needed to stop an active loss of data.",
      attestation_ref: "INC-42",
    });
  });

  it("revokes by id", async () => {
    await operatorSupportApi.revoke(GRANT);
    expect(call(mockedRequest).path).toBe(`/api/v1/system/support_grants/${GRANT}/revoke`);
  });

  it("reads one grant's log with the actor's method", async () => {
    mockedPage.mockResolvedValueOnce({
      data: [
        {
          id: "a1",
          grant_id: GRANT,
          actor_id: "op-1",
          method: "GET",
          path: `/v1/support/grants/${GRANT}/data/content/notes`,
          route: null,
          request_id: "req-1",
          at: "2026-11-20T12:00:00.000Z",
        },
      ],
      hasMore: false,
    });
    const page = await operatorSupportApi.access({ grantId: GRANT });
    const c = call(mockedPage);
    expect(c.path).toBe("/api/v1/system/support_access");
    expect(c.params).toEqual({ grant_id: GRANT, limit: "50" });
    expect(page.items[0]).toEqual(expect.objectContaining({ method: "GET", granteeName: null }));
    expect(page.nextCursor).toBeNull();
  });
});

describe("publicSupportApi", () => {
  const fetchMock = vi.fn();
  beforeEach(() => {
    fetchMock.mockReset();
    vi.stubGlobal("fetch", fetchMock);
  });
  afterEach(() => {
    vi.unstubAllGlobals();
  });

  const ok = (body: unknown, status = 200) =>
    new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });

  const fetched = (i = 0) => {
    const [url, init] = fetchMock.mock.calls[i] as [string, RequestInit];
    const u = new URL(url, "https://x.test");
    return { path: u.pathname, params: Object.fromEntries(u.searchParams), init };
  };

  it("reads the grant and its reads with the token and no authorization", async () => {
    fetchMock.mockResolvedValueOnce(ok({ grant: wireGrant(), reads: [wireRead()] }));
    const r = await publicSupportApi.get(GRANT, "tok");
    const f = fetched();
    expect(f.path).toBe(`/api/v1/public/support/grants/${GRANT}`);
    expect(f.params).toEqual({ token: "tok" });
    expect(new Headers(f.init.headers).get("authorization")).toBeNull();
    expect(r.grant.targetName).toBe("Sam");
    expect(r.reads).toHaveLength(1);
  });

  it.each([
    ["deny", "/deny"],
    ["revoke", "/revoke"],
  ] as const)("POSTs %s with the token in the body", async (verb, tail) => {
    fetchMock.mockResolvedValueOnce(ok(wireGrant()));
    await publicSupportApi[verb](GRANT, "tok");
    const f = fetched();
    expect(f.path).toBe(`/api/v1/public/support/grants/${GRANT}${tail}`);
    expect(f.init.method).toBe("POST");
    expect(JSON.parse(String(f.init.body))).toEqual({ token: "tok" });
  });

  it("asks for a code, then approves with it", async () => {
    fetchMock.mockResolvedValueOnce(ok({ ok: true }, 202));
    fetchMock.mockResolvedValueOnce(ok(wireGrant({ decision: "approved" })));
    expect(await publicSupportApi.sendCode(GRANT, "tok")).toEqual({ ok: true });
    await publicSupportApi.approve(GRANT, "tok", "123456");
    expect(fetched(0).path).toBe(`/api/v1/public/support/grants/${GRANT}/approve/code`);
    expect(fetched(1).path).toBe(`/api/v1/public/support/grants/${GRANT}/approve`);
    expect(JSON.parse(String(fetched(1).init.body))).toEqual({ token: "tok", code: "123456" });
  });

  it("throws the backend's refusal with its status", async () => {
    fetchMock.mockResolvedValueOnce(ok({ error: { message: "This link has expired." } }, 410));
    const err = await publicSupportApi.get(GRANT, "tok").catch((e: unknown) => e);
    expect(err).toBeInstanceOf(AuthHttpError);
    expect((err as AuthHttpError).status).toBe(410);
  });
});

describe("grantState", () => {
  const NOW = new Date("2026-11-22T12:00:00.000Z");
  // The clock rules: a grant with no status, as a hand-built one has.
  const grant = (over: Partial<SupportGrantWire>): SupportGrant => ({
    ...toSupportGrant(wireGrant(over)),
    status: undefined,
  });

  it("maps the backend's status onto the three states", () => {
    expect(toSupportGrant(wireGrant({ status: "live" })).status).toBe("live");
    for (const [status, state] of [
      ["pending", "pending"],
      ["live", "live"],
      ["denied", "ended"],
      ["lapsed", "ended"],
      ["expired", "ended"],
      ["revoked", "ended"],
    ] as const) {
      expect(grantState(toSupportGrant(wireGrant({ status })), NOW)).toBe(state);
    }
  });

  it("prefers the backend's status to a clock that disagrees", () => {
    // The client clock runs past expires_at, but the backend still reads the grant as live.
    const live = toSupportGrant(
      wireGrant({ status: "live", decision: "approved", expires_at: "2026-11-22T11:00:00.000Z" }),
    );
    expect(grantState(live, NOW)).toBe("live");
  });

  it("is pending while undecided and inside the lapse window", () => {
    expect(grantState(grant({}), NOW)).toBe("pending");
  });

  it("is ended once undecided past the lapse window", () => {
    const asked = new Date(NOW.getTime() - SUPPORT_LAPSE_DAYS * 24 * 3600 * 1000).toISOString();
    expect(grantState(grant({ requested_at: asked }), NOW)).toBe("ended");
  });

  it("is live while approved and before it expires", () => {
    expect(grantState(grant({ decision: "approved", expires_at: "2026-11-23T00:00:00.000Z" }), NOW)).toBe("live");
  });

  it("is ended once expired, denied or revoked", () => {
    expect(grantState(grant({ decision: "approved", expires_at: "2026-11-22T00:00:00.000Z" }), NOW)).toBe("ended");
    expect(grantState(grant({ decision: "denied" }), NOW)).toBe("ended");
    expect(
      grantState(
        grant({
          decision: "approved",
          expires_at: "2026-11-23T00:00:00.000Z",
          revoked_at: "2026-11-22T11:00:00.000Z",
        }),
        NOW,
      ),
    ).toBe("ended");
  });
});

describe("groupAccess", () => {
  const read = (id: string, at: string, table = "notes"): SupportAccess => ({
    id,
    grantId: GRANT,
    granteeName: "Ana",
    route: "/support/grants/:id/data/:schema/:table",
    path: `/v1/support/grants/${GRANT}/data/content/${table}`,
    method: null,
    at,
  });

  it("parses the table from the path, not the route", () => {
    expect(accessTable(read("r", "2026-11-20T12:00:00.000Z"))).toEqual({ schema: "content", table: "notes" });
    expect(accessTable({ path: "/v1/support/grants/x" })).toBeNull();
  });

  it("keeps a malformed escape as logged rather than throwing", () => {
    expect(accessTable({ path: "/v1/support/grants/x/data/content/no%E0tes" })).toEqual({
      schema: "content",
      table: "no%E0tes",
    });
  });

  it("counts reads of one table on one day as one group, newest group first", () => {
    const groups = groupAccess([
      read("r1", "2026-11-20T12:00:00"),
      read("r2", "2026-11-20T13:00:00"),
      read("r3", "2026-11-20T14:00:00"),
      read("r4", "2026-11-21T09:00:00", "tasks"),
    ]);
    expect(groups).toHaveLength(2);
    expect(groups[0]).toEqual(expect.objectContaining({ table: "tasks", count: 1 }));
    expect(groups[1]).toEqual(
      expect.objectContaining({ table: "notes", count: 3, granteeName: "Ana", latestAt: "2026-11-20T14:00:00" }),
    );
  });
});

describe("refusals", () => {
  it("reads a 404 as the switch being off, and nothing else", () => {
    expect(isSupportOff(new AuthHttpError(404, "Not found"))).toBe(true);
    expect(isSupportOff(new AuthHttpError(403, "Forbidden"))).toBe(false);
  });

  it("reads step_up_required from the code or the body", () => {
    expect(isStepUpRequired(new AuthHttpError(403, "Sign in again", "step_up_required"))).toBe(true);
    expect(
      isStepUpRequired(
        new AuthHttpError(403, "Sign in again", undefined, { error: { code: "step_up_required" } }),
      ),
    ).toBe(true);
    expect(isStepUpRequired(new AuthHttpError(403, "Forbidden"))).toBe(false);
    expect(isStepUpRequired(new AuthHttpError(401, "x", "step_up_required"))).toBe(false);
  });
});

describe("SUPPORT_CONTENT_TABLES", () => {
  it("is the backend's 89 content tables, each schema-qualified and listed once", () => {
    expect(SUPPORT_CONTENT_TABLES).toHaveLength(89);
    expect(new Set(SUPPORT_CONTENT_TABLES).size).toBe(89);
    for (const t of SUPPORT_CONTENT_TABLES) expect(t).toMatch(/^[a-z_]+\.[a-z_]+$/);
    expect(SUPPORT_CONTENT_TABLES).toContain("content.notes");
  });
});

describe("supportRequestProblem", () => {
  const reason = "Your export failed and I need to see it.";
  it("passes a reason of 10 to 500 characters and 1 to 168 hours", () => {
    expect(supportRequestProblem({ reason, hours: 24 })).toBeNull();
    expect(supportRequestProblem({ reason: "x".repeat(10), hours: 1 })).toBeNull();
    expect(supportRequestProblem({ reason: "x".repeat(500), hours: 168 })).toBeNull();
  });

  it("refuses a short or long reason, counting it trimmed", () => {
    expect(supportRequestProblem({ reason: "   too short   ", hours: 24 })).toMatch(/at least 10/);
    expect(supportRequestProblem({ reason: "x".repeat(501), hours: 24 })).toMatch(/500/);
  });

  it("refuses a length outside the range, or not whole", () => {
    expect(supportRequestProblem({ reason, hours: 0 })).toMatch(/1 to 168/);
    expect(supportRequestProblem({ reason, hours: 169 })).toMatch(/1 to 168/);
    expect(supportRequestProblem({ reason, hours: 1.5 })).toMatch(/1 to 168/);
    expect(supportRequestProblem({ reason, hours: 5 }, SUPPORT_BREAK_GLASS_HOURS_MAX)).toMatch(/1 to 4/);
  });
});

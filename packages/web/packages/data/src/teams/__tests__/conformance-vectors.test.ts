// Every test in packages/data/src lives under a `__tests__/` sibling — no exceptions.
// One `it` per row of cookbook/adh/hub/teams/conformance-test-vectors.md, titled by its vector id,
// with `fetch` stubbed so the real shared client and paging helper run.
import { describe, expect, it, vi, beforeEach } from "vitest";

import { teamsApi, toTeam, validateTeamIdentifier } from "../teams";
import { teamMembersApi, toTeamMember } from "../team-members";

const fetchMock = vi.fn();

const respondWith = (body: unknown) =>
  fetchMock.mockResolvedValue({
    ok: true,
    status: 200,
    json: async () => body,
    text: async () => JSON.stringify(body),
  });

const failWith = (status: number, message: string) =>
  fetchMock.mockResolvedValue({
    ok: false,
    status,
    statusText: message,
    json: async () => ({ error: { message } }),
    text: async () => JSON.stringify({ error: { message } }),
  });

const list = (data: unknown[]) => ({ object: "list", data, has_more: false, url: "" });

beforeEach(() => {
  fetchMock.mockReset();
  respondWith(list([]));
  vi.stubGlobal("fetch", fetchMock);
});

const urlAt = (n = 0) => String(fetchMock.mock.calls[n]![0]);
const initAt = (n = 0) => (fetchMock.mock.calls[n]![1] ?? {}) as RequestInit;
const pathAt = (n = 0) => new URL(urlAt(n), "http://x").pathname;
const params = (n = 0) => new URL(urlAt(n), "http://x").searchParams;

const teamRow = (id: string, name: string, slug = "com.acme.x") => ({
  id,
  name,
  slug,
  created: 1700000000,
  updated: 1700000100,
});

describe("teams conformance vectors", () => {
  it("hub-domain-teams-001 accepts a reverse-domain identifier", () => {
    expect(validateTeamIdentifier("com.acme.platform")).toBeNull();
  });

  it("hub-domain-teams-002 refuses an empty identifier", () => {
    expect(validateTeamIdentifier("")).toMatch(/required/i);
  });

  it("hub-domain-teams-003 accepts a single-label slug", () => {
    expect(validateTeamIdentifier("platform")).toBeNull();
  });

  it("hub-domain-teams-004 maps name and slug to displayName and identifier", () => {
    const t = toTeam({ id: "1", name: "Platform", slug: "com.acme.platform", created: 1700000000, updated: 1700000100 });
    expect(t.displayName).toBe("Platform");
    expect(t.identifier).toBe("com.acme.platform");
  });

  it("hub-domain-teams-005 sends a partial update body without the undefined slug key", async () => {
    respondWith(teamRow("1", "Renamed"));
    await teamsApi.update("1", { displayName: "Renamed", identifier: undefined });
    expect(pathAt()).toBe("/api/v1/teams/1");
    expect(initAt().method).toBe("POST");
    expect(initAt().body).toBe('{"name":"Renamed"}');
  });

  it("hub-domain-teams-006 rethrows a create conflict as the friendly message", async () => {
    failWith(409, "team already exists");
    await expect(teamsApi.create({ displayName: "X", identifier: "com.acme.x" }, "eco1")).rejects.toThrow(
      'A team with identifier "com.acme.x" already exists.',
    );
  });

  it("hub-domain-teams-007 lists the ecosystem's teams sorted by display name", async () => {
    respondWith(list([teamRow("1", "Beta"), teamRow("2", "Alpha")]));
    const teams = await teamsApi.list("eco1");
    expect(pathAt()).toBe("/api/v1/teams");
    expect(params().get("ecosystem_id")).toBe("eco1");
    expect(teams.map((t) => t.displayName)).toEqual(["Alpha", "Beta"]);
  });

  it("hub-domain-teams-008 resolves null when fetching a team throws", async () => {
    failWith(404, "not found");
    await expect(teamsApi.get("missing")).resolves.toBeNull();
  });

  it("hub-domain-teams-009 percent-encodes the id on delete", async () => {
    respondWith({ id: "t/1", deleted: true });
    await teamsApi.delete("t/1");
    expect(urlAt()).toContain("/api/v1/teams/t%2F1");
    expect(initAt().method).toBe("DELETE");
  });

  it("hub-domain-teams-010 lists no members when the response has no data key", async () => {
    respondWith({});
    await expect(teamMembersApi.list("t1")).resolves.toEqual([]);
  });

  it("hub-domain-teams-011 scopes the member list by team", async () => {
    await teamMembersApi.list("t1");
    expect(pathAt()).toBe("/api/v1/team_members");
    expect(params().get("team_id")).toBe("t1");
  });

  it("hub-domain-teams-012 maps member counts from team id to count", async () => {
    respondWith({ total_count: { counts: [{ team_id: "t1", count: 3 }] } });
    const counts = await teamMembersApi.counts();
    expect(counts.get("t1")).toBe(3);
    expect(params().getAll("include[]")).toEqual(["total_count"]);
  });

  const memberRow = {
    id: "m1",
    team_id: "t1",
    user_id: "u1",
    role: "member",
    added_at: "2026-01-01T00:00:00Z",
    member_kind: "customer",
    email: "a@b.com",
    display_name: null,
    persona_slug: null,
    persona_name: null,
  };

  it("hub-domain-teams-013 adds a member by email", async () => {
    respondWith(memberRow);
    await teamMembersApi.add("t1", "a@b.com");
    expect(pathAt()).toBe("/api/v1/team_members");
    expect(initAt().method).toBe("POST");
    expect(JSON.parse(String(initAt().body))).toEqual({ team_id: "t1", email: "a@b.com" });
  });

  it("hub-domain-teams-014 adds a persona by key", async () => {
    respondWith({ ...memberRow, member_kind: "persona", persona_slug: "sales-bot" });
    const m = await teamMembersApi.addPersona("t1", "sales-bot");
    expect(pathAt()).toBe("/api/v1/team_members");
    expect(initAt().method).toBe("POST");
    expect(JSON.parse(String(initAt().body))).toEqual({ type: "persona", team_id: "t1", persona_key: "sales-bot" });
    expect(m.memberKind).toBe("persona");
  });

  it("hub-domain-teams-015 percent-encodes the member id on remove", async () => {
    respondWith({ id: "m/1", deleted: true });
    await teamMembersApi.remove("m/1");
    expect(urlAt()).toContain("/api/v1/team_members/m%2F1");
    expect(initAt().method).toBe("DELETE");
  });

  it("hub-domain-teams-016 treats an unrecognized member kind as a customer", () => {
    const m = toTeamMember({ ...memberRow, member_kind: "elevated" as never });
    expect(m.memberKind).toBe("customer");
  });
});

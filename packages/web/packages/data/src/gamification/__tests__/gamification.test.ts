// Conformance vectors for the gamification realm-config client (cookbook adh/hub/gamification).
// Only `fetch` is stubbed: the real `authedJson` / `listAllV1`, the path builders and the
// wire <-> domain mappers all run.
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { beforeEach, describe, expect, it } from "vitest";

import { gamificationApi } from "../gamification";
import { fetchMock, initAt, installFetch, paramsAt, pathAt, bodyAt, respondOnce, respondWith, urlAt, v1List } from "../../__tests__/v1-fetch";

beforeEach(() => installFetch());

const here = dirname(fileURLToPath(import.meta.url));
const configWire = {
  ecosystem_id: "org.acme.shop",
  mode: "none",
  skin: "plain",
  surfaces: {},
  seasons: null,
  timezone: "UTC",
};

describe("gamification client conformance vectors", () => {
  it("gamification-001 wire types come from this component's own transcription", () => {
    const src = readFileSync(join(here, "..", "gamification.ts"), "utf8");
    const wire = readFileSync(join(here, "..", "wire.ts"), "utf8");
    const specifiers = [...(src + wire).matchAll(/from\s+"([^"]+)"/g)].map((m) => m[1]!);
    expect(specifiers).toContain("./wire");
    expect(specifiers.filter((s) => s.includes("adh-api-types"))).toEqual([]);
  });

  it("gamification-002 dynamic path segments are percent-encoded under the /api/v1 proxy prefix", async () => {
    respondWith(configWire);
    await gamificationApi.getRealmConfig("eco/1");
    expect(pathAt(0)).toBe("/api/v1/gamification/config");
    expect(paramsAt(0).get("ecosystem")).toBe("eco/1");

    respondWith({ id: "b#1", name: "n", description: "d", icon: "i", point_value: 1 });
    await gamificationApi.updateRealmBadge("eco 1", "b#1", {
      name: "n", description: "d", icon: "i", statKey: "s", comparator: ">=", threshold: 1,
      badgeLine: "l", tier: "none", pointValue: 1, hidden: false,
    });
    expect(urlAt(1)).toBe("/api/v1/gamification/badges/b%231");
    expect(bodyAt(1).ecosystem).toBe("eco 1");
  });

  it("gamification-003 nothing is cached: each read is its own request", async () => {
    respondOnce({ ...configWire, timezone: "UTC" });
    respondOnce({ ...configWire, timezone: "Europe/Paris" });
    const first = await gamificationApi.getRealmConfig("eco-1");
    const second = await gamificationApi.getRealmConfig("eco-1");
    expect(fetchMock).toHaveBeenCalledTimes(2);
    expect(second.timezone).not.toBe(first.timezone);
  });

  it("gamification-004 a conflict from the request propagates unmodified", async () => {
    respondOnce({ error: { message: "already exists" } }, 409);
    const err = await gamificationApi.createEventType("eco-1", { name: "dup", statKey: "k" }).catch((e) => e);
    expect(err).toBeInstanceOf(Error);
    expect(err.status).toBe(409);
    expect(String(err.message)).toContain("already exists");
  });

  it("gamification-005 reads the realm config for the ecosystem and maps it to the domain record", async () => {
    respondWith({ ...configWire });
    const cfg = await gamificationApi.getRealmConfig("org.acme.shop");
    expect(initAt(0).method ?? "GET").toBe("GET");
    expect(pathAt(0)).toBe("/api/v1/gamification/config");
    expect(paramsAt(0).get("ecosystem")).toBe("org.acme.shop");
    expect(cfg).toEqual({
      ecosystemId: "org.acme.shop", mode: "none", skin: "plain", surfaces: {}, seasons: null, timezone: "UTC",
    });
  });

  it("gamification-006 a partial update sends only the given field and always returns config", async () => {
    respondWith({ config: { ...configWire, timezone: "America/New_York" } });
    const res = await gamificationApi.updateRealmConfig("eco-1", { timezone: "America/New_York" });
    expect(initAt(0).method).toBe("POST");
    expect(pathAt(0)).toBe("/api/v1/gamification/config");
    expect(bodyAt(0)).toEqual({ timezone: "America/New_York", ecosystem: "eco-1" });
    expect(res.config).toBeDefined();
    expect(res.config.timezone).toBe("America/New_York");
    expect(res.replayed).toBeUndefined();
  });

  it.skip("gamification-007 mode is an ordered axis: this module only passes mode through; the gate predicates live in consumers, nothing here to exercise", () => {});

  it.skip("gamification-008 surfaces default on: this module passes the surfaces map through untouched; the default-on read lives in consumers", () => {});

  it("gamification-009 seasons null and a season window are sent in wire shape", async () => {
    respondWith({ config: configWire });
    await gamificationApi.updateRealmConfig("eco-1", { seasons: null });
    expect(bodyAt(0)).toHaveProperty("seasons", null);
    await gamificationApi.updateRealmConfig("eco-1", { seasons: { anchor: "2026-01-01", lengthDays: 30 } });
    expect(bodyAt(1).seasons).toEqual({ anchor: "2026-01-01", length_days: 30 });
  });

  it("gamification-010 enabling resolves the replay summary", async () => {
    respondWith({ config: { ...configWire, mode: "gamification" }, replayed: { subjects: 1, badges: 2, xp_gained: 50 } });
    const res = await gamificationApi.updateRealmConfig("eco-1", { mode: "gamification" });
    expect(res.replayed).toEqual({ subjects: 1, badges: 2, xpGained: 50 });
  });

  it("gamification-011 the effective catalog preserves each row's source tag", async () => {
    respondWith({
      badges: [
        { id: "b1", name: "A", description: "", icon: "i", point_value: 1, source: "default" },
        { id: "b2", name: "B", description: "", icon: "i", point_value: 2, source: "realm" },
      ],
      levels: [
        { name: "Novice", min_points: 0, source: "default" },
        { name: "Pro", min_points: 500, source: "realm" },
      ],
    });
    const cat = await gamificationApi.getCatalog("eco-1");
    expect(pathAt(0)).toBe("/api/v1/gamification/catalog");
    expect(cat.badges.map((b) => b.source)).toEqual(["default", "realm"]);
    expect(cat.levels.map((l) => l.source)).toEqual(["default", "realm"]);
  });

  it("gamification-012 badge create posts the ten input fields plus the ecosystem", async () => {
    respondWith({ id: "b1", name: "Streaker", description: "7-day streak", icon: "fire", point_value: 50 });
    await gamificationApi.createRealmBadge("eco-1", {
      name: "Streaker", description: "7-day streak", icon: "fire", statKey: "streak_days", comparator: ">=",
      threshold: 7, badgeLine: "streak", tier: "bronze", pointValue: 50, hidden: false,
    });
    expect(initAt(0).method).toBe("POST");
    expect(pathAt(0)).toBe("/api/v1/gamification/badges");
    expect(bodyAt(0)).toEqual({
      name: "Streaker", description: "7-day streak", icon: "fire", stat_key: "streak_days", comparator: ">=",
      threshold: 7, badge_line: "streak", tier: "bronze", point_value: 50, hidden: false, ecosystem: "eco-1",
    });
  });

  it("gamification-013 badge input omits the read-only fields even when a caller smuggles them in", async () => {
    respondWith({ id: "b1", name: "n", description: "d", icon: "i", point_value: 1 });
    const input = {
      name: "n", description: "d", icon: "i", statKey: "s", comparator: ">=" as const, threshold: 1,
      badgeLine: "l", tier: "none" as const, pointValue: 1, hidden: false,
      active: true, subjectType: "user", ecosystemId: "other",
    };
    await gamificationApi.createRealmBadge("eco-1", input);
    const body = bodyAt(0);
    expect(body).not.toHaveProperty("active");
    expect(body).not.toHaveProperty("subject_type");
    expect(body).not.toHaveProperty("ecosystem_id");
    expect(Object.keys(body)).toHaveLength(11);
  });

  it.skip("gamification-014 override-by-(badgeLine, tier) is a server-side contract; the client only posts the badge", () => {});

  it.skip("gamification-015 default-badge 404 and holdings clearing are server-side behavior, not observable with fetch mocked", () => {});

  it("gamification-016 levels replace wholesale with the rungs in snake_case", async () => {
    respondWith({ levels: [], replay_hint: "" });
    await gamificationApi.putRealmLevels("eco-1", [
      { name: "Novice", minPoints: 0 },
      { name: "Pro", minPoints: 500 },
    ]);
    expect(initAt(0).method).toBe("POST");
    expect(pathAt(0)).toBe("/api/v1/gamification/levels");
    expect(bodyAt(0)).toEqual({
      rungs: [{ name: "Novice", min_points: 0 }, { name: "Pro", min_points: 500 }],
      ecosystem: "eco-1",
    });
  });

  it("gamification-017 the ladder shape is not checked client-side", async () => {
    respondWith({ levels: [], replay_hint: "" });
    await expect(
      gamificationApi.putRealmLevels("eco-1", [{ name: "B", minPoints: 10 }, { name: "A", minPoints: 5 }]),
    ).resolves.toBeDefined();
    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(bodyAt(0).rungs).toEqual([{ name: "B", min_points: 10 }, { name: "A", min_points: 5 }]);
  });

  it("gamification-018 the replay hint is surfaced", async () => {
    respondWith({ levels: [{ name: "Novice", min_points: 0, source: "realm" }], replay_hint: "trigger a replay to backfill" });
    const res = await gamificationApi.putRealmLevels("eco-1", [{ name: "Novice", minPoints: 0 }]);
    expect(res.replayHint).toBe("trigger a replay to backfill");
    expect(res.levels).toEqual([{ name: "Novice", minPoints: 0, source: "realm" }]);
  });

  it("gamification-019 replay is scoped by the body, not the route", async () => {
    respondWith({ subjects: 1, badges: 0 });
    await gamificationApi.replayRealm("eco-1");
    expect(initAt(0).method).toBe("POST");
    expect(pathAt(0)).toBe("/api/v1/gamification/events/replay");
    expect(urlAt(0)).not.toContain("eco-1");
    expect(bodyAt(0)).toEqual({ ecosystem_id: "eco-1" });
  });

  it("gamification-020 a replay result carries subjects, badges and xpGained", async () => {
    respondWith({ subjects: 1, badges: 3, xp_gained: 120 });
    expect(await gamificationApi.replayRealm("eco-1")).toEqual({ subjects: 1, badges: 3, xpGained: 120 });
  });

  it("gamification-021 event types come back in the server's order, unsorted", async () => {
    const row = (id: string, name: string) => ({ id, ecosystem_id: "eco-1", name, stat_key: "k" });
    respondWith(v1List([row("e1", "zeta"), row("e2", "alpha"), row("e3", "mid")]));
    const list = await gamificationApi.listEventTypes("eco-1");
    expect(pathAt(0)).toBe("/api/v1/gamification/event_types");
    expect(paramsAt(0).get("ecosystem")).toBe("eco-1");
    expect(list.map((e) => e.name)).toEqual(["zeta", "alpha", "mid"]);
  });

  it("gamification-022 event type create posts the body with no client-side length check", async () => {
    respondWith({ id: "et-1", ecosystem_id: "eco-1", name: "level_up", stat_key: "levels_gained" });
    await gamificationApi.createEventType("eco-1", { name: "level_up", statKey: "levels_gained" });
    expect(initAt(0).method).toBe("POST");
    expect(pathAt(0)).toBe("/api/v1/gamification/event_types");
    expect(bodyAt(0)).toEqual({ name: "level_up", stat_key: "levels_gained", ecosystem: "eco-1" });

    respondWith({ id: "et-2", ecosystem_id: "eco-1", name: "x".repeat(200), stat_key: "" });
    await expect(gamificationApi.createEventType("eco-1", { name: "x".repeat(200), statKey: "" })).resolves.toBeDefined();
    expect(bodyAt(1).name).toHaveLength(200);
  });

  it("gamification-023 event type update posts to the item route", async () => {
    respondWith({ id: "et-1", ecosystem_id: "eco-1", name: "level_up_v2", stat_key: "levels_gained" });
    await gamificationApi.updateEventType("eco-1", "et-1", { name: "level_up_v2", statKey: "levels_gained" });
    expect(initAt(0).method).toBe("POST");
    expect(pathAt(0)).toBe("/api/v1/gamification/event_types/et-1");
    expect(bodyAt(0)).toEqual({ name: "level_up_v2", stat_key: "levels_gained", ecosystem: "eco-1" });
  });

  it("gamification-024 event type delete issues a DELETE and resolves the id", async () => {
    respondWith({ id: "et-1", deleted: true });
    expect(await gamificationApi.deleteEventType("eco-1", "et-1")).toEqual({ deleted: "et-1" });
    expect(initAt(0).method).toBe("DELETE");
    expect(pathAt(0)).toBe("/api/v1/gamification/event_types/et-1");
    expect(paramsAt(0).get("ecosystem")).toBe("eco-1");
  });
});

import { describe, it, expect, beforeEach } from "vitest";
import * as schema from "../src/libsql/schema";
import { createApp } from "../src/app";
import { testDeps } from "./helpers/storage";
import type { Db } from "../src/libsql/client";
import { sessionHeaders } from "./helpers/auth";
import { freshDb as bootDb } from "./helpers/db";
import { liveSnapshot } from "./helpers/snapshot";
import type { LiveSnapshot } from "../src/monitor/live-types";

// Conformance vectors for live-types: the `/live` wire shape, exercised through the route
// that builds it (the module itself is type-only and has nothing to call).

type App = ReturnType<typeof createApp>;

async function live(app: App, auth: { Cookie: string }): Promise<LiveSnapshot> {
  const res = await app.request("/live", { headers: auth });
  expect(res.status).toBe(200);
  return (await res.json()) as LiveSnapshot;
}

describe("live-types /live shape", () => {
  let db: Db;
  let app: App;
  let auth: { Cookie: string };
  let slug: string;

  beforeEach(async () => {
    db = await bootDb();
    auth = await sessionHeaders(db, "viewer");
    const g = (await db.insert(schema.siteGroups).values({ slug: "g", name: "G" }).returning())[0]!;
    const s = (await db.insert(schema.monitoredSites).values({ siteGroupId: g.id, slug: "s", name: "S" }).returning())[0]!;
    slug = (await db.insert(schema.monitoredEndpoints).values({ siteId: s.id, url: "https://example.com" }).returning())[0]!.id;
    app = createApp(testDeps(db));
  });

  /** A database with no endpoints and no integrations configured. */
  async function emptyDb(): Promise<{ app: App; auth: { Cookie: string } }> {
    const fresh = await bootDb();
    return { app: createApp(testDeps(fresh)), auth: await sessionHeaders(fresh, "viewer") };
  }

  it("live-types-001 providers map carries every ProviderKey, matching the default fixture", async () => {
    const e = await emptyDb();
    const body = await live(e.app, e.auth);
    const keys = Object.keys(body.providers).sort();
    expect(keys).toEqual(["cloudflare-pages", "crunchy", "railway", "vercel"]);
    expect(keys).toEqual(Object.keys(liveSnapshot().providers).sort());
  });

  it("live-types-002 a healthy latest check surfaces status, responseTimeMs and dnsOk=true", async () => {
    await db.insert(schema.healthChecks).values({ serviceSlug: slug, status: "healthy", responseTimeMs: 42, statusCode: 200 });
    const body = await live(app, auth);
    expect(body.services).toHaveLength(1);
    expect(body.services[0]).toMatchObject({ slug, status: "healthy", responseTimeMs: 42, dnsOk: true });
  });

  it("live-types-003 a latest check that failed DNS reads dnsOk=false", async () => {
    await db.insert(schema.healthChecks).values({ serviceSlug: slug, status: "down", statusCode: null, dnsOk: false });
    const body = await live(app, auth);
    expect(body.services[0]!.dnsOk).toBe(false);
  });

  it("live-types-004 downSince is the open http/dns issue's openedAt ISO string", async () => {
    await db.insert(schema.healthChecks).values({ serviceSlug: slug, status: "down", statusCode: null });
    const openedAt = new Date("2026-01-02T03:04:05.000Z");
    await db.insert(schema.issues).values({ target: slug, source: "dns", name: "S", severity: "major", state: "down", openedAt });
    const body = await live(app, auth);
    expect(body.services[0]!.downSince).toBe(openedAt.toISOString());
  });

  it("live-types-005 a healthy endpoint with no open issue has downSince null", async () => {
    const site = (await db.select().from(schema.monitoredSites))[0]!;
    const slug2 = (await db.insert(schema.monitoredEndpoints).values({ siteId: site.id, url: "https://healthy.example.com" }).returning())[0]!.id;
    await db.insert(schema.healthChecks).values({ serviceSlug: slug2, status: "healthy", statusCode: 200 });
    const body = await live(app, auth);
    expect(body.services.find((s) => s.slug === slug2)!.downSince).toBeNull();
  });

  it("live-types-006 an empty reachable database is not config-degraded", async () => {
    const e = await emptyDb();
    const body = await live(e.app, e.auth);
    expect(body.configDegraded).toBe(false);
    expect(body.configReason).toBeNull();
  });

  it("live-types-007 lastCycleAt is null before any health check is persisted", async () => {
    const body = await live(app, auth);
    expect(body.lastCycleAt).toBeNull();
  });

  it("live-types-008 lastCycleAt is a recent ISO string once a check exists", async () => {
    await db.insert(schema.healthChecks).values({ serviceSlug: slug, status: "healthy", responseTimeMs: 42, statusCode: 200 });
    const body = await live(app, auth);
    expect(typeof body.lastCycleAt).toBe("string");
    expect(Date.now() - Date.parse(body.lastCycleAt!)).toBeLessThan(60_000);
  });

  it("live-types-009 staleProd carries a persisted stale row for an owned project", async () => {
    await db.update(schema.monitoredEndpoints).set({ platform: "vercel", deployProject: "adh" });
    await db.insert(schema.deployProjectMeta).values({ platform: "vercel", projectName: "adh" });
    await db.insert(schema.vercelProdState).values({
      projectName: "adh",
      stale: true,
      detail: "live production is behind",
      sourceUrl: "https://vercel.com/team/adh",
      liveUrl: "https://adh.example.com",
    });
    const body = await live(app, auth);
    expect(body.staleProd).toHaveLength(1);
    expect(body.staleProd[0]).toMatchObject({ projectName: "adh", environment: "production", liveUrl: "https://adh.example.com" });
  });

  it("live-types-010 staleProd drops a stale row for a project no live site owns", async () => {
    await db.update(schema.monitoredEndpoints).set({ platform: "vercel", deployProject: "adh" });
    await db.insert(schema.deployProjectMeta).values({ platform: "vercel", projectName: "studio-production" });
    await db.insert(schema.vercelProdState).values({ projectName: "studio-production", stale: true, detail: "live production is behind", sourceUrl: null, liveUrl: null });
    const body = await live(app, auth);
    expect(body.staleProd.map((s) => s.projectName)).toEqual([]);
  });
});

import { describe, it, expect } from "vitest";
import type { DeploymentDTO } from "../src/monitor/types";

// The endpoint shape the deploy-view helpers are exercised against. Local to this
// test: the roster type it mirrors is HOST data, not something this package ships.
interface ServiceEndpoint {
  slug: string;
  group: string;
  name: string;
  environment: "production" | "staging" | "testing";
  url: string;
  kind: string;
  expectedStatus: number;
  platform?: "vercel" | "railway" | "cloudflare";
  deployProject?: string;
}
import {
  summarizeByPlatform,
  deploysForEndpoint,
  endpointDeploys,
  latestTerminalForEndpoint,
  failuresForEndpoint,
  platformCanon as overviewCanon,
  deployTargetKey as overviewKey,
} from "../src/monitor/overview";

// Ported from status-web's deploy-view tests when the per-platform summary and the
// endpoint→deploy correlation moved here: `/live` now publishes `platformSummary` and each
// service's `deployIds` / `latestTerminalDeployId` / `deployFailures`.

const NOW = Date.parse("2026-06-12T12:00:00.000Z");

function deploy(overrides: Partial<DeploymentDTO> & { status: DeploymentDTO["status"] }): DeploymentDTO {
  return {
    id: "test-id",
    platform: "vercel",
    projectName: "test-project",
    providerProjectId: null,
    buildPhase: null,
    deployPhase: "none",
    environment: "production",
    tier: "production",
    commitHash: "abc1234",
    commitMessage: "test commit",
    branch: "main",
    commitRepo: null,
    url: "https://test.vercel.app",
    errorText: null,
    liveHost: null,
    // Confirmed as of NOW so nothing demotes unless a test says so.
    createdAt: new Date(NOW).toISOString(),
    phaseConfirmedAt: new Date(NOW).toISOString(),
    ...overrides,
  };
}

describe("summarizeByPlatform", () => {
  it("returns empty array for empty input", () => {
    expect(summarizeByPlatform([], NOW)).toEqual([]);
  });

  it("does NOT count a STALE in-flight deploy as building — demoted to total only (matches the lists)", () => {
    const deploys = [
      deploy({ platform: "vercel", status: "building" }), // confirmed as of NOW → counts
      // Same status, but its phase went unconfirmed long ago → demoted, must NOT count as building.
      deploy({ platform: "vercel", status: "building", phaseConfirmedAt: new Date(NOW - 60 * 60_000).toISOString() }),
    ];
    const result = summarizeByPlatform(deploys, NOW);
    expect(result[0]!.building).toBe(1); // only the fresh one
    expect(result[0]!.total).toBe(2); // both still counted in total
  });

  it("buckets success→ready, building→building, queued→building, failed→failed, canceled→total only", () => {
    const deploys = [
      deploy({ platform: "vercel", status: "success" }),
      deploy({ platform: "vercel", status: "building" }),
      deploy({ platform: "vercel", status: "queued" }),
      deploy({ platform: "vercel", status: "failed" }),
      deploy({ platform: "vercel", status: "canceled" }),
    ];
    const result = summarizeByPlatform(deploys, NOW);
    expect(result).toHaveLength(1);
    expect(result[0]).toEqual({
      platform: "vercel",
      ready: 1,
      building: 2,
      // Each building deploy's deadline, so a display can drop it once that passes.
      buildingUnconfirmedAt: [new Date(NOW + 10 * 60_000).toISOString(), new Date(NOW + 10 * 60_000).toISOString()],
      failed: 1,
      total: 5,
    });
  });

  it("groups correctly across multiple platforms", () => {
    const deploys = [
      deploy({ platform: "vercel", status: "success" }),
      deploy({ platform: "vercel", status: "success" }),
      deploy({ platform: "cloudflare-pages", status: "success" }),
      deploy({ platform: "railway", status: "failed" }),
    ];
    const result = summarizeByPlatform(deploys, NOW);
    expect(result).toHaveLength(3);
    const vercel = result.find((r) => r.platform === "vercel")!;
    expect(vercel.ready).toBe(2);
    const cf = result.find((r) => r.platform === "cloudflare-pages")!;
    expect(cf.ready).toBe(1);
    expect(cf.failed).toBe(0);
    const railway = result.find((r) => r.platform === "railway")!;
    expect(railway.failed).toBe(1);
  });

  it("returns platforms in stable order: vercel, cloudflare-pages, railway", () => {
    const deploys = [
      deploy({ platform: "railway", status: "success" }),
      deploy({ platform: "vercel", status: "success" }),
      deploy({ platform: "cloudflare-pages", status: "success" }),
    ];
    const result = summarizeByPlatform(deploys, NOW);
    expect(result.map((r) => r.platform)).toEqual(["vercel", "cloudflare-pages", "railway"]);
  });

  it("handles unknown platform mixed with known ones", () => {
    const deploys = [
      deploy({ platform: "vercel", status: "success" }),
      deploy({ platform: "custom-host", status: "success" }),
    ];
    const result = summarizeByPlatform(deploys, NOW);
    // vercel first, then custom-host last
    expect(result[0]?.platform).toBe("vercel");
    expect(result[1]?.platform).toBe("custom-host");
  });

  it("total includes canceled", () => {
    const deploys = [
      deploy({ platform: "vercel", status: "canceled" }),
      deploy({ platform: "vercel", status: "canceled" }),
    ];
    const result = summarizeByPlatform(deploys, NOW);
    expect(result[0]?.total).toBe(2);
    expect(result[0]?.ready).toBe(0);
    expect(result[0]?.building).toBe(0);
    expect(result[0]?.failed).toBe(0);
  });
});


// ---------------------------------------------------------------------------
// Endpoint-aware helpers — explicit (platform, project) correlation
// ---------------------------------------------------------------------------

function endpoint(overrides: Partial<ServiceEndpoint> & Pick<ServiceEndpoint, "slug" | "environment">): ServiceEndpoint {
  return {
    group: "Test Group",
    name: "Test",
    url: "https://example.com",
    kind: "frontend",
    expectedStatus: 200,
    ...overrides,
  };
}

describe("latestTerminalForEndpoint", () => {
  const ep = endpoint({ slug: "hub-production", environment: "production", platform: "vercel", deployProject: "hub-production" });

  it("skips canceled/building and returns the latest success/failed", () => {
    const deploys = [
      deploy({ platform: "vercel", projectName: "hub-production", status: "success", createdAt: "2026-06-04T10:00:00.000Z" }),
      deploy({ platform: "vercel", projectName: "hub-production", status: "failed", createdAt: "2026-06-04T11:00:00.000Z" }),
      deploy({ platform: "vercel", projectName: "hub-production", status: "canceled", createdAt: "2026-06-04T12:00:00.000Z" }),
      deploy({ platform: "vercel", projectName: "hub-production", status: "building", createdAt: "2026-06-04T12:30:00.000Z" }),
    ];
    expect(latestTerminalForEndpoint(deploys, ep)?.status).toBe("failed");
  });

  it("returns null when there is no terminal deploy", () => {
    const deploys = [
      deploy({ platform: "vercel", projectName: "hub-production", status: "canceled", createdAt: "2026-06-04T12:00:00.000Z" }),
      deploy({ platform: "vercel", projectName: "hub-production", status: "building", createdAt: "2026-06-04T12:30:00.000Z" }),
    ];
    expect(latestTerminalForEndpoint(deploys, ep)).toBeNull();
  });
});

describe("deploysForEndpoint (explicit platform+project correlation)", () => {
  it("returns empty when the endpoint has no platform/project wired", () => {
    const ep = endpoint({ slug: "x-production", environment: "production" });
    const deploys = [deploy({ platform: "vercel", projectName: "anything", status: "success" })];
    expect(deploysForEndpoint(deploys, ep)).toHaveLength(0);
  });

  it("Vercel: matches by project (env-specific project); other projects ignored", () => {
    const ep = endpoint({ slug: "hub-staging", environment: "staging", platform: "vercel", deployProject: "hub-staging" });
    const deploys = [
      deploy({ platform: "vercel", projectName: "hub-production", status: "success", createdAt: "2024-01-01T00:00:00Z" }),
      deploy({ platform: "vercel", projectName: "hub-staging", status: "failed", createdAt: "2024-01-02T00:00:00Z" }),
      deploy({ platform: "vercel", projectName: "hub-testing", status: "success", createdAt: "2024-01-03T00:00:00Z" }),
    ];
    const result = deploysForEndpoint(deploys, ep);
    expect(result).toHaveLength(1);
    expect(result[0]?.projectName).toBe("hub-staging");
  });

  it("Railway: one project serves all envs, so the environment must also match", () => {
    const ep = endpoint({ slug: "backend-staging", environment: "staging", platform: "railway", deployProject: "adh-backend" });
    const deploys = [
      deploy({ platform: "railway", projectName: "adh-backend", environment: "production", status: "success", createdAt: "2024-01-01T00:00:00Z" }),
      deploy({ platform: "railway", projectName: "adh-backend", environment: "staging", status: "failed", createdAt: "2024-01-02T00:00:00Z" }),
      deploy({ platform: "railway", projectName: "adh-backend", environment: "testing", status: "success", createdAt: "2024-01-03T00:00:00Z" }),
    ];
    const result = deploysForEndpoint(deploys, ep);
    expect(result).toHaveLength(1);
    expect(result[0]?.environment).toBe("staging");
  });

  it("Cloudflare: config 'cloudflare' matches the deploy platform 'cloudflare-pages'", () => {
    const ep = endpoint({ slug: "temporal-production", environment: "production", platform: "cloudflare", deployProject: "temporal-web" });
    const deploys = [
      deploy({ platform: "cloudflare-pages", projectName: "temporal-web", status: "success", createdAt: "2024-01-01T00:00:00Z" }),
      deploy({ platform: "cloudflare-pages", projectName: "temporal-other", status: "success", createdAt: "2024-01-02T00:00:00Z" }),
    ];
    const result = deploysForEndpoint(deploys, ep);
    expect(result).toHaveLength(1);
    expect(result[0]?.projectName).toBe("temporal-web");
  });

  it("returns results sorted newest-first", () => {
    const ep = endpoint({ slug: "hub-production", environment: "production", platform: "vercel", deployProject: "hub-production" });
    const deploys = [
      deploy({ platform: "vercel", projectName: "hub-production", status: "success", createdAt: "2024-01-03T00:00:00Z" }),
      deploy({ platform: "vercel", projectName: "hub-production", status: "failed", createdAt: "2024-01-01T00:00:00Z" }),
      deploy({ platform: "vercel", projectName: "hub-production", status: "building", createdAt: "2024-01-02T00:00:00Z" }),
    ];
    const result = deploysForEndpoint(deploys, ep);
    expect(result[0]?.createdAt).toBe("2024-01-03T00:00:00Z");
    expect(result[2]?.createdAt).toBe("2024-01-01T00:00:00Z");
  });
});

describe("failuresForEndpoint", () => {
  it("returns 0 when nothing matches", () => {
    const ep = endpoint({ slug: "x-production", environment: "production", platform: "vercel", deployProject: "nope" });
    expect(failuresForEndpoint([], ep)).toBe(0);
  });

  it("counts only failed matching deploys", () => {
    const ep = endpoint({ slug: "hub-production", environment: "production", platform: "vercel", deployProject: "hub-production" });
    const deploys = [
      deploy({ platform: "vercel", projectName: "hub-production", status: "failed", createdAt: "2024-01-01T00:00:00Z" }),
      deploy({ platform: "vercel", projectName: "hub-production", status: "success", createdAt: "2024-01-02T00:00:00Z" }),
      deploy({ platform: "vercel", projectName: "hub-production", status: "failed", createdAt: "2024-01-03T00:00:00Z" }),
      deploy({ platform: "vercel", projectName: "hub-production", status: "building", createdAt: "2024-01-04T00:00:00Z" }),
    ];
    expect(failuresForEndpoint(deploys, ep)).toBe(2);
  });

  it("does not count building or canceled as failures", () => {
    const ep = endpoint({ slug: "hub-production", environment: "production", platform: "vercel", deployProject: "hub-production" });
    const deploys = [
      deploy({ platform: "vercel", projectName: "hub-production", status: "building", createdAt: "2024-01-01T00:00:00Z" }),
      deploy({ platform: "vercel", projectName: "hub-production", status: "canceled", createdAt: "2024-01-02T00:00:00Z" }),
    ];
    expect(failuresForEndpoint(deploys, ep)).toBe(0);
  });
});

describe("endpointDeploys (what /live publishes per service)", () => {
  it("lists the endpoint's deploy ids newest first, its latest settled outcome, and its failures", () => {
    const ep = endpoint({ slug: "hub-production", environment: "production", platform: "vercel", deployProject: "hub-production" });
    const deploys = [
      deploy({ id: "old", platform: "vercel", projectName: "hub-production", status: "failed", createdAt: "2024-01-01T00:00:00Z" }),
      deploy({ id: "mid", platform: "vercel", projectName: "hub-production", status: "success", createdAt: "2024-01-02T00:00:00Z" }),
      deploy({ id: "new", platform: "vercel", projectName: "hub-production", status: "building", createdAt: "2024-01-03T00:00:00Z" }),
      deploy({ id: "other", platform: "vercel", projectName: "elsewhere", status: "failed", createdAt: "2024-01-04T00:00:00Z" }),
    ];
    expect(endpointDeploys(deploys, ep)).toEqual({ deployIds: ["new", "mid", "old"], latestTerminalDeployId: "mid", deployFailures: 1 });
  });

  it("is empty for an endpoint wired to no deploy target", () => {
    const ep = endpoint({ slug: "x", environment: "production" });
    expect(endpointDeploys([deploy({ status: "failed" })], ep)).toEqual({ deployIds: [], latestTerminalDeployId: null, deployFailures: 0 });
  });
});

// ---------------------------------------------------------------------------
// Conformance vectors for status-server-monitor-overview
// ---------------------------------------------------------------------------

describe("overview conformance vectors", () => {
  const hub = (over: Partial<DeploymentDTO> & { status: DeploymentDTO["status"] }): DeploymentDTO =>
    deploy({ platform: "vercel", projectName: "hub", ...over });
  const vercelHub = endpoint({ slug: "hub", environment: "production", platform: "vercel", deployProject: "hub" });

  it("status-server-monitor-overview-001 summarizes by platform in fixed order, unknown platforms last", () => {
    const result = summarizeByPlatform(
      [
        deploy({ platform: "crunchy", status: "success" }),
        deploy({ platform: "netlify", status: "success" }),
        deploy({ platform: "vercel", status: "failed" }),
        deploy({ platform: "vercel", status: "building" }),
        deploy({ platform: "cloudflare-pages", status: "queued" }),
      ],
      NOW,
    );
    expect(result.map((r) => r.platform)).toEqual(["vercel", "cloudflare-pages", "crunchy", "netlify"]);
    expect(result[0]).toEqual({
      platform: "vercel",
      ready: 0,
      building: 1,
      buildingUnconfirmedAt: [new Date(NOW + 10 * 60_000).toISOString()],
      failed: 1,
      total: 2,
    });
  });

  it("status-server-monitor-overview-002 counts canceled and unknown rows in total only", () => {
    const result = summarizeByPlatform([deploy({ platform: "vercel", status: "canceled" }), deploy({ platform: "vercel", status: "unknown" })], NOW);
    expect(result).toEqual([{ platform: "vercel", ready: 0, building: 0, buildingUnconfirmedAt: [], failed: 0, total: 2 }]);
  });

  it("status-server-monitor-overview-003 groups by the raw platform string, with no canonicalization", () => {
    const result = summarizeByPlatform([deploy({ platform: "cloudflare-pages", status: "success" }), deploy({ platform: "cloudflare", status: "success" })], NOW);
    expect(result).toHaveLength(2);
    expect(result.find((r) => r.platform === "cloudflare-pages")!.total).toBe(1);
    expect(result.find((r) => r.platform === "cloudflare")!.total).toBe(1);
  });

  it("status-server-monitor-overview-004 an endpoint with no deploy target correlates to nothing", () => {
    expect(deploysForEndpoint([hub({ status: "success" }), hub({ status: "failed" })], {})).toEqual([]);
  });

  it("status-server-monitor-overview-005 returns only the endpoint's project, newest first", () => {
    const deploys = [
      hub({ id: "jan", status: "success", createdAt: "2026-01-01T00:00:00.000Z" }),
      hub({ id: "mar", status: "success", createdAt: "2026-03-01T00:00:00.000Z" }),
      hub({ id: "feb", status: "success", createdAt: "2026-02-01T00:00:00.000Z" }),
      deploy({ id: "other", platform: "vercel", projectName: "other", status: "success" }),
    ];
    expect(deploysForEndpoint(deploys, vercelHub).map((d) => d.id)).toEqual(["mar", "feb", "jan"]);
  });

  it("status-server-monitor-overview-006 Railway also matches on environment", () => {
    const ep = endpoint({ slug: "backend", environment: "production", platform: "railway", deployProject: "backend" });
    const deploys = [
      deploy({ id: "prod", platform: "railway", projectName: "backend", environment: "production", status: "success" }),
      deploy({ id: "stg", platform: "railway", projectName: "backend", environment: "staging", status: "success" }),
    ];
    expect(deploysForEndpoint(deploys, ep).map((d) => d.id)).toEqual(["prod"]);
  });

  it("status-server-monitor-overview-007 latest terminal skips newer building and canceled rows", () => {
    const deploys = [
      hub({ id: "ok", status: "success", createdAt: "2026-01-01T00:00:00.000Z" }),
      hub({ id: "bad", status: "failed", createdAt: "2026-01-02T00:00:00.000Z" }),
      hub({ id: "cx", status: "canceled", createdAt: "2026-01-03T00:00:00.000Z" }),
      hub({ id: "bld", status: "building", createdAt: "2026-01-04T00:00:00.000Z" }),
    ];
    expect(latestTerminalForEndpoint(deploys, vercelHub)?.id).toBe("bad");
  });

  it("status-server-monitor-overview-008 latest terminal also skips an unknown row", () => {
    const deploys = [
      hub({ id: "ok", status: "success", createdAt: "2026-01-01T00:00:00.000Z" }),
      hub({ id: "unk", status: "unknown", createdAt: "2026-01-02T00:00:00.000Z" }),
    ];
    expect(latestTerminalForEndpoint(deploys, vercelHub)?.id).toBe("ok");
  });

  it("status-server-monitor-overview-009 latest terminal is null when every row is in flight", () => {
    expect(latestTerminalForEndpoint([hub({ status: "building" }), hub({ status: "queued" })], vercelHub)).toBeNull();
  });

  it("status-server-monitor-overview-010 counts only failed rows", () => {
    const deploys = [hub({ status: "failed" }), hub({ status: "failed" }), hub({ status: "success" }), hub({ status: "canceled" })];
    expect(failuresForEndpoint(deploys, vercelHub)).toBe(2);
  });

  it("status-server-monitor-overview-011 re-exports the canon helpers unchanged", () => {
    expect(overviewCanon("cloudflare-pages")).toBe("cloudflare");
    expect(overviewKey("vercel", "hub", null)).toBe("vercel|hub|");
  });

  it("status-server-monitor-overview-012 summarizeByPlatform is pure across an interleaved deploysForEndpoint call", () => {
    const deploys = [hub({ status: "success" }), hub({ status: "failed" }), deploy({ platform: "railway", status: "building" })];
    const first = summarizeByPlatform(deploys, NOW);
    deploysForEndpoint(deploys, endpoint({ slug: "x", environment: "production", platform: "railway", deployProject: "test-project" }));
    expect(summarizeByPlatform(deploys, NOW)).toEqual(first);
  });
});

import type { DeploymentDTO } from "./types";
import { platformCanon, deployTargetKey, PLATFORM_ORDER } from "@adh-sdk/deploy-platform/canon";
import { deployUnconfirmed, deployUnconfirmedAt } from "./live-view";

export interface PlatformSummary {
  platform: string;
  ready: number;
  building: number;
  /** When each deploy counted in `building` stops being believed (`deployUnconfirmedAt`):
   *  a display still showing this snapshot drops it from `building` once its time passes. */
  buildingUnconfirmedAt: string[];
  failed: number;
  total: number;
}

/**
 * Summarize deploys by platform — the per-platform pills `/live` publishes as
 * `platformSummary`. Buckets: success→ready; building|queued→building; failed→failed;
 * canceled AND an unconfirmed in-flight deploy→total only.
 *
 * `nowMs`/`probeIntervalMs` drive the same demotion `effectiveDeployStatus` applies to each
 * row: an in-flight deploy nothing has re-confirmed is no longer a live "building", so it
 * drops out of the building count rather than letting the KPI pill assert progress the
 * rest of the board has stopped asserting. (Moved here from status-web's deploy-view.)
 */
export function summarizeByPlatform(deploys: DeploymentDTO[], nowMs: number, probeIntervalMs?: number | null): PlatformSummary[] {
  const map = new Map<string, PlatformSummary>();

  for (const d of deploys) {
    let entry = map.get(d.platform);
    if (!entry) {
      entry = { platform: d.platform, ready: 0, building: 0, buildingUnconfirmedAt: [], failed: 0, total: 0 };
      map.set(d.platform, entry);
    }
    entry.total++;
    if (deployUnconfirmed(d, nowMs, probeIntervalMs)) continue; // stale in-flight → total only
    if (d.status === "success") entry.ready++;
    else if (d.status === "building" || d.status === "queued") {
      entry.building++;
      const until = deployUnconfirmedAt(d, nowMs, probeIntervalMs);
      if (until) entry.buildingUnconfirmedAt.push(until);
    }
    else if (d.status === "failed") entry.failed++;
    // canceled: counted in total only
  }

  // Sort: known platforms in stable order, then any others in insertion order
  const known = PLATFORM_ORDER.filter((p) => map.has(p)).map((p) => map.get(p)!);
  const unknown = [...map.values()].filter((s) => !PLATFORM_ORDER.includes(s.platform));
  return [...known, ...unknown];
}

// ---------------------------------------------------------------------------
// Endpoint-aware helpers — correlate a monitored endpoint to its deploys by the
// EXPLICIT (platform, project) wired on the endpoint in config. No host guessing.
// ---------------------------------------------------------------------------

/** The deploy-target fields an endpoint is correlated by (from its config). */
export interface EndpointLike {
  platform?: string | null;
  deployProject?: string | null;
  environment?: string | null;
}

// platformCanon + deployTargetKey now live in @adh-sdk/deploy-platform/canon.
// Imported above for use in this module; re-exported so existing `./overview`
// importers keep their path.
export { platformCanon, deployTargetKey, PLATFORM_ORDER };

/**
 * All deploys wired to this endpoint — matched by the endpoint's EXPLICIT
 * (platform, project), newest-first. Railway serves every env from ONE project, so
 * there we also match the environment; Vercel/Cloudflare projects are env-specific,
 * so the project alone identifies them. An endpoint with no platform/project (a
 * health-only check) correlates to nothing.
 */
export function deploysForEndpoint(deploys: DeploymentDTO[], ep: EndpointLike): DeploymentDTO[] {
  const key = deployTargetKey(ep.platform, ep.deployProject, ep.environment);
  if (!key) return [];
  return deploys
    .filter((d) => deployTargetKey(d.platform, d.projectName, d.environment) === key)
    .sort((a, b) => +new Date(b.createdAt) - +new Date(a.createdAt));
}

/**
 * The most recent *terminal* deploy for an endpoint — a definitive `success` or
 * `failed`, skipping `canceled`/`building`/`queued`. So the deploy status shown
 * reflects the last real outcome, not a canceled/in-flight build on top.
 */
export function latestTerminalForEndpoint(deploys: DeploymentDTO[], ep: EndpointLike): DeploymentDTO | null {
  return deploysForEndpoint(deploys, ep).find((d) => d.status === "success" || d.status === "failed") ?? null;
}

/** Returns the count of failed deploys for a specific endpoint. */
export function failuresForEndpoint(deploys: DeploymentDTO[], ep: EndpointLike): number {
  return deploysForEndpoint(deploys, ep).filter((d) => d.status === "failed").length;
}

/** One endpoint's view of the deploy feed, as `/live` publishes it on each service: the ids
 *  of its deploys (newest first, into `deployments`), its latest settled outcome, and how
 *  many failed. The dashboard's matrix and detail pane read these instead of correlating
 *  endpoints to deploys themselves. */
export interface EndpointDeploys {
  deployIds: string[];
  latestTerminalDeployId: string | null;
  deployFailures: number;
}

export function endpointDeploys(deploys: DeploymentDTO[], ep: EndpointLike): EndpointDeploys {
  const mine = deploysForEndpoint(deploys, ep);
  return {
    deployIds: mine.map((d) => d.id),
    latestTerminalDeployId: mine.find((d) => d.status === "success" || d.status === "failed")?.id ?? null,
    deployFailures: mine.filter((d) => d.status === "failed").length,
  };
}

import type { ServiceStatusDTO, DeploymentDTO } from "./types";
import type { DeployStatus } from "./deploy-status";
import type { LiveFreshness, StaleMonitorsView } from "./live-view";
import type { EndpointDeploys, PlatformSummary } from "./overview";

// The view types the snapshot carries, re-exported so `@adh-sdk/status-server/types`
// names the whole /live contract (status-web's parity test reads them from there).
export type { LiveFreshness, SnapshotFreshnessState, StaleMonitor, StaleMonitorsView } from "./live-view";
export type { EndpointDeploys, PlatformSummary } from "./overview";

// The /api/live contract — one self-contained snapshot of everything the client
// displays, pulled live from providers + HTTP probes. Type-only module (shared by
// the route and the client store); no DB imports.

export interface LiveServiceDTO extends ServiceStatusDTO, EndpointDeploys {
  /** Whether the hostname resolved in DNS. false → a `dns`-source problem, not `http`. */
  dnsOk: boolean;
  /** ISO time the endpoint's current http/dns issue opened — SERVER-truth "down since",
   *  durable across browsers (unlike the client store's per-tab onset). null = not down.
   *  Drives the "retire stale monitor" surface: a host down this long is a likely ghost. */
  downSince: string | null;
}

/** A deployment as `/live` serves it: the raw provider row plus the status a view should
 *  SHOW — its own, or "unknown" once an in-flight phase has gone unconfirmed past the
 *  cadence-scaled window (`effectiveDeployStatus`). Judged against `generatedAt`. */
export interface LiveDeploymentDTO extends DeploymentDTO {
  effectiveStatus: DeployStatus;
  /** ISO time after which a display still showing this snapshot must read an in-flight
   *  `effectiveStatus` as "unknown" (`deployUnconfirmedAt`). Null when it never lapses. */
  unconfirmedAt: string | null;
}

/** A Vercel project whose LIVE production deploy is errored/behind (already filtered to stale). */
export interface StaleProdDTO {
  projectName: string;
  environment: string;
  detail: string | null;
  sourceUrl: string | null;
  liveUrl: string | null;
}

export type ProviderKey = "vercel" | "cloudflare-pages" | "railway" | "crunchy";

export interface ProviderHealth {
  /** Whether we actually poll this platform (active integration WITH a token). */
  configured: boolean;
  /** Whether the latest poll reached the provider API. */
  ok: boolean;
}

export interface LiveSnapshot {
  generatedAt: string; // ISO, server clock — the client's event-time reference
  /** ISO time of the NEWEST PERSISTED PROBE — the data-freshness clock for what's on
   *  screen, server-stamped, null before the first probe. Distinct from the scheduler's
   *  cycle-COMPLETION clock at `/health` (the loop-health signal): a downstream cycle
   *  stage can hang after the probes were written, which `/health` catches while the
   *  on-screen data is still current. The client warns when this lags `generatedAt` by
   *  more than a few probe intervals, so a wedged / never-redeployed poller can't
   *  masquerade as live data (`generatedAt` is READ-time and always looks fresh). */
  lastCycleAt: string | null;
  /** The backend's probe interval (ms) — so the client's staleness window scales with
   *  it (mirroring the scheduler's `staleAfterMs`) instead of hardcoding a threshold. */
  probeIntervalMs: number;
  /** The git commit THIS monitor process is running (Railway's RAILWAY_GIT_COMMIT_SHA;
   *  null outside Railway). The board displays it so "is my status-site deploy actually
   *  serving?" is answerable from the board itself — a failed/stuck self-deploy leaves
   *  an old sha on screen, which no amount of in-board monitoring can otherwise show. */
  monitorVersion: string | null;
  services: LiveServiceDTO[];
  deployments: LiveDeploymentDTO[];
  staleProd: StaleProdDTO[];
  providers: Record<ProviderKey, ProviderHealth>;
  /** True when the config read fell back to the static list (DB unreachable). */
  configDegraded: boolean;
  configReason: string | null;
  /** Whether `lastCycleAt` lags `generatedAt` past the cadence-scaled window — the
   *  wedged-poller verdict the dashboard's stale banner shows. */
  freshness: LiveFreshness;
  /** No endpoint is monitored at all — the dashboard says it is watching nothing rather
   *  than painting an empty board as clear. */
  blind: boolean;
  /** Per-platform deploy pills (ready / building / failed / total), in `PLATFORM_ORDER`. */
  platformSummary: PlatformSummary[];
  /** Endpoints down long enough to be retire candidates, longest-down first. */
  staleMonitors: StaleMonitorsView;
}

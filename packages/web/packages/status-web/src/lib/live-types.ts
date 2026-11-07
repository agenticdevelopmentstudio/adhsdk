import type { ServiceStatusDTO, DeploymentDTO, DeployStatus } from "../types";

// The /api/live contract — one self-contained snapshot of everything the client
// displays. A HAND MIRROR of status-server's monitor/live-types.ts (this package has
// the server only as a devDependency); read-types-parity.test.ts holds the two together.
//
// Every verdict here — freshness, blindness, the per-platform pills, which monitors are
// retire candidates, an endpoint's deploys and an unconfirmed deploy's status — is the
// SERVER's. The client renders these fields; it owns no copy of the rules behind them.

/** The deploy correlation `/live` publishes per endpoint (status-server overview.ts). */
export interface EndpointDeploys {
  /** Ids of this snapshot's `deployments` that belong to the endpoint's deploy target, newest first. */
  deployIds: string[];
  /** The newest definitive (success or failed) deploy of the target, or null. */
  latestTerminalDeployId: string | null;
  /** How many of the target's deploys in this snapshot failed. */
  deployFailures: number;
}

export interface LiveServiceDTO extends ServiceStatusDTO, EndpointDeploys {
  /** Whether the hostname resolved in DNS. false → a `dns`-source problem, not `http`. */
  dnsOk: boolean;
  /** ISO time the endpoint's current http/dns issue opened — SERVER-truth "down since",
   *  durable across browsers. null = not down. */
  downSince: string | null;
}

/** A deployment as `/live` serves it: the raw row plus the status a view should SHOW —
 *  its own, or "unknown" once an in-flight phase has gone unconfirmed too long. */
export interface LiveDeploymentDTO extends DeploymentDTO {
  effectiveStatus: DeployStatus;
  /** When a display still showing this snapshot must read an in-flight `effectiveStatus`
   *  as "unknown"; null when it never lapses. The server sets it; the client compares. */
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

export type SnapshotFreshnessState = "fresh" | "stale" | "very-stale";

/** The server's verdict on how far the data clock (`lastCycleAt`) lags `generatedAt`. */
export interface LiveFreshness {
  state: SnapshotFreshnessState;
  /** The data clock the verdict was judged on, for an "as of" label. */
  asOf: string | null;
}

/** One per-platform deploy pill. */
export interface PlatformSummary {
  platform: string;
  ready: number;
  building: number;
  /** When each deploy counted in `building` stops being believed; drop it once passed. */
  buildingUnconfirmedAt: string[];
  failed: number;
  total: number;
}

/** An endpoint down long enough to be a retire candidate. */
export interface StaleMonitor {
  slug: string;
  name: string;
  url: string;
  environment: string | null;
  /** What the probe last saw: its error, else the status code, else "down". */
  detail: string;
  dnsOk: boolean;
  downSince: string;
  ageMs: number;
}

export interface StaleMonitorsView {
  thresholdDays: number;
  monitors: StaleMonitor[];
}

export interface LiveSnapshot {
  generatedAt: string; // ISO, server clock — the client's event-time reference
  /** ISO time of the NEWEST PERSISTED PROBE, null before the first probe. */
  lastCycleAt: string | null;
  /** The backend's probe interval (ms). */
  probeIntervalMs: number;
  /** Git commit the MONITOR ITSELF is running (null locally). */
  monitorVersion: string | null;
  services: LiveServiceDTO[];
  deployments: LiveDeploymentDTO[];
  staleProd: StaleProdDTO[];
  providers: Record<ProviderKey, ProviderHealth>;
  /** True when the config read fell back to the static list (DB unreachable). */
  configDegraded: boolean;
  configReason: string | null;
  /** Whether the snapshot is frozen — drives the "monitoring paused" banner and the sign. */
  freshness: LiveFreshness;
  /** No endpoint is monitored at all — never read as healthy. */
  blind: boolean;
  /** Per-platform deploy pills, in canonical platform order. */
  platformSummary: PlatformSummary[];
  /** Endpoints down long enough to be retire candidates, longest-down first. */
  staleMonitors: StaleMonitorsView;
}

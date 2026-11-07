import type { DeployStatus } from "./deploy-status";
import type { LiveServiceDTO } from "./live-types";
import type { DeploymentDTO } from "./types";

// ---------------------------------------------------------------------------
// The judgements `/live` publishes beside its raw facts, so the dashboard reads a verdict
// instead of re-deriving one from the facts with its own copy of the rule. Each of these
// used to live in status-web (`snapshot-staleness.ts`, `row-model.ts`'s
// `deployDtoUnconfirmed`, `stale-monitors.ts`) and ran against the BROWSER's clock; they
// run here against the snapshot's own `generatedAt`, which the SSE stream re-stamps every
// cycle, so the verdict is never more than one cycle old — and when the stream stops, the
// freshness verdict below is exactly what goes stale and says so.
// ---------------------------------------------------------------------------

/** How old the newest probe may be before the snapshot is "stale": 5× the probe cadence,
 *  floored at five minutes so a fast cadence does not alarm on one slow cycle. */
export const SNAPSHOT_STALE_FLOOR_MS = 5 * 60_000;

export function snapshotStaleMs(probeIntervalMs?: number | null): number {
  return Math.max((probeIntervalMs ?? 0) * 5, SNAPSHOT_STALE_FLOOR_MS);
}

export type SnapshotFreshnessState = "fresh" | "stale" | "very-stale";

/**
 * How far the DATA clock (`lastCycleAt`, the newest persisted probe) lags the READ clock
 * (`generatedAt`). A wedged poller keeps serving a fresh `generatedAt` over frozen probes,
 * and this is the verdict that notices.
 *
 * "fresh" when either clock is missing: no probe ever recorded is a brand-new monitor, not
 * a wedged one (the `blind`/no-data paths speak for that case). An unparseable clock also
 * reads fresh — there is no age to judge, and a NaN must never raise a banner. A negative
 * lag (probe newer than the read, clock jitter) is fresh too.
 */
export function snapshotFreshness(
  lastCycleAt: string | null | undefined,
  generatedAt: string | null | undefined,
  probeIntervalMs?: number | null,
): SnapshotFreshnessState {
  if (!lastCycleAt || !generatedAt) return "fresh";
  const ageMs = Date.parse(generatedAt) - Date.parse(lastCycleAt);
  const staleMs = snapshotStaleMs(probeIntervalMs);
  if (!(ageMs > staleMs)) return "fresh";
  return ageMs > staleMs * 3 ? "very-stale" : "stale";
}

/** The freshness verdict as `/live` publishes it. */
export interface LiveFreshness {
  state: SnapshotFreshnessState;
  /** The data clock the verdict was judged on — `lastCycleAt`, echoed so a view can say "as of". */
  asOf: string | null;
}

export function liveFreshness(lastCycleAt: string | null, generatedAt: string, probeIntervalMs: number): LiveFreshness {
  return { state: snapshotFreshness(lastCycleAt, generatedAt, probeIntervalMs), asOf: lastCycleAt };
}

/** The floor on how long an in-flight deploy phase may go unconfirmed before it is not believed. */
export const UNCONFIRMED_AFTER_MS = 10 * 60_000;

/** 5× the probe cadence, floored at {@link UNCONFIRMED_AFTER_MS}: a slower poller must not
 *  demote a phase it confirms on its normal schedule. */
export function unconfirmedWindowMs(probeIntervalMs?: number | null): number {
  return Math.max(UNCONFIRMED_AFTER_MS, (probeIntervalMs ?? 0) * 5);
}

const IN_FLIGHT: readonly DeployStatus[] = ["building", "queued"];

/**
 * Whether an in-flight deploy's phase has outlived its confirmation. Fails CLOSED: an
 * in-flight deploy whose clock is unparseable is not believed, rather than asserting live
 * progress on a date nothing can read. A settled deploy is never unconfirmed.
 */
export function deployUnconfirmed(
  d: Pick<DeploymentDTO, "status" | "phaseConfirmedAt" | "createdAt">,
  nowMs: number,
  probeIntervalMs?: number | null,
): boolean {
  if (!IN_FLIGHT.includes(d.status)) return false;
  const confirmed = Date.parse(d.phaseConfirmedAt || d.createdAt);
  if (!Number.isFinite(confirmed)) return true;
  return nowMs - confirmed > unconfirmedWindowMs(probeIntervalMs);
}

/**
 * When an in-flight deploy's phase stops being believed: its confirmation plus the window.
 * Null for a settled deploy, and for one already unconfirmed (its status says so already).
 *
 * The snapshot is judged when it is built, and a client can go on showing it long after —
 * the monitor stalls, or the stream stalls while it still looks connected. This deadline
 * lets the display stop asserting "building" on its own clock without knowing the window.
 */
export function deployUnconfirmedAt(
  d: Pick<DeploymentDTO, "status" | "phaseConfirmedAt" | "createdAt">,
  nowMs: number,
  probeIntervalMs?: number | null,
): string | null {
  if (!IN_FLIGHT.includes(d.status) || deployUnconfirmed(d, nowMs, probeIntervalMs)) return null;
  const confirmed = Date.parse(d.phaseConfirmedAt || d.createdAt);
  return new Date(confirmed + unconfirmedWindowMs(probeIntervalMs)).toISOString();
}

/** The status a view should show for a deploy: its own, or "unknown" once an in-flight
 *  phase is no longer confirmed — the same demotion the activity feed applies. */
export function effectiveDeployStatus(
  d: Pick<DeploymentDTO, "status" | "phaseConfirmedAt" | "createdAt">,
  nowMs: number,
  probeIntervalMs?: number | null,
): DeployStatus {
  return deployUnconfirmed(d, nowMs, probeIntervalMs) ? "unknown" : d.status;
}

/** How long an endpoint must have been continuously down to be called a stale monitor. */
export const STALE_MONITOR_MS = 7 * 24 * 60 * 60 * 1000;

/** A monitor that has been down for at least {@link STALE_MONITOR_MS} — most likely a site
 *  that no longer exists, so a candidate to retire rather than an outage to chase. */
export interface StaleMonitor {
  slug: string;
  name: string;
  url: string;
  environment: string | null;
  /** What the probe last saw: its error, else the status code, else "down". */
  detail: string;
  dnsOk: boolean;
  /** ISO onset of the current down run (server truth, from the open problem). */
  downSince: string;
  ageMs: number;
}

/** The stale-monitor candidates, longest-down first. A malformed onset is skipped, never
 *  surfaced as a NaN age. DNS decides nothing: a host that still resolves can be gone. */
export function selectStaleMonitors(
  services: readonly LiveServiceDTO[],
  nowMs: number,
  thresholdMs: number = STALE_MONITOR_MS,
): StaleMonitor[] {
  const out: StaleMonitor[] = [];
  for (const s of services) {
    if (s.status !== "down" || !s.downSince) continue;
    const ageMs = nowMs - Date.parse(s.downSince);
    if (!Number.isFinite(ageMs) || ageMs < thresholdMs) continue;
    out.push({
      slug: s.slug,
      name: s.name,
      url: s.url,
      environment: s.environment || null,
      detail: s.error ?? (s.statusCode != null ? `HTTP ${s.statusCode}` : "down"),
      dnsOk: s.dnsOk,
      downSince: s.downSince,
      ageMs,
    });
  }
  out.sort((a, b) => b.ageMs - a.ageMs);
  return out;
}

/** The stale-monitor section of `/live`: the candidates and the threshold they were judged
 *  against, in whole days, so the banner can say it without owning the number. */
export interface StaleMonitorsView {
  thresholdDays: number;
  monitors: StaleMonitor[];
}

export function staleMonitorsView(services: readonly LiveServiceDTO[], nowMs: number): StaleMonitorsView {
  return {
    thresholdDays: Math.round(STALE_MONITOR_MS / (24 * 60 * 60 * 1000)),
    monitors: selectStaleMonitors(services, nowMs),
  };
}

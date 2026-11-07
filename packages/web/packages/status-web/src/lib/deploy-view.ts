// What is left of the client's deploy view after its rules moved to the server: the
// per-platform summary and the endpoint→deploy join are `/live` fields now
// (`platformSummary`, and `deployIds` / `latestTerminalDeployId` / `deployFailures` per
// service), and the unconfirmed-deploy demotion is each deploy's `effectiveStatus`.
//
// Kept as a module because the configure screens and the dashboard host import the
// platform vocabulary from here. Every name is RE-EXPORTED from the one shared engine —
// never restated — so the server and this client can't key or order a platform
// differently: `platformCanon` / `deployTargetKey` canonicalize a deploy target, and
// `PLATFORM_ORDER` is the section order the Auto Configure review lays out.
export { deployTargetKey, platformCanon, PLATFORM_ORDER } from "@adh-sdk/deploy-platform/canon";
export type { PlatformSummary } from "./live-types";

import type { DeployStatus } from "../types";
import type { LiveDeploymentDTO, PlatformSummary } from "./live-types";

/** Whether a server deadline has passed. Unparseable fails CLOSED: not believed. */
function lapsed(at: string, nowMs: number): boolean {
  const t = Date.parse(at);
  return !Number.isFinite(t) || nowMs > t;
}

/**
 * A deploy's status as of `nowMs`. The server judged `effectiveStatus` when it built the
 * snapshot; a snapshot the page keeps showing (the monitor stalled, or the stream stalled
 * while it still looks connected) must not assert "building" forever, so once the server's
 * own `unconfirmedAt` deadline passes it reads "unknown". The window is the server's; the
 * client only compares its clock to the time it was given. An older backend sends no
 * deadline, and its verdict is shown as given.
 */
export function shownDeployStatus(
  d: Pick<LiveDeploymentDTO, "effectiveStatus" | "unconfirmedAt">,
  nowMs: number,
): DeployStatus {
  return d.unconfirmedAt != null && lapsed(d.unconfirmedAt, nowMs) ? "unknown" : d.effectiveStatus;
}

/** A platform pill as of `nowMs`: a building deploy whose deadline has passed drops out of
 *  `building` (it stays in `total`), exactly as the server's own summary would drop it. */
export function shownPlatformSummary(p: PlatformSummary, nowMs: number): PlatformSummary {
  const gone = (p.buildingUnconfirmedAt ?? []).filter((at) => lapsed(at, nowMs)).length;
  return gone === 0 ? p : { ...p, building: Math.max(0, p.building - gone) };
}

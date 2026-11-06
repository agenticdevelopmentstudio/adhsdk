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

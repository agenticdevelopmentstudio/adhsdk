export * from "./types";
export { boardTargetKey, parseBoardTarget } from "./target-key";
export { deriveBoard } from "./derive";
export { BUILD_VERB, deriveActivity, indicatorFor, ISSUE_VERB, pageActivity } from "./derive-activity";
export { createActivityPageReader, readActivityPage, readBoardFacts } from "./facts";
// The ownership rule, for the surfaces OUTSIDE the fold that must agree with it about
// which deploy targets exist — the webhook door, the Deployments tab, the live-host stamp.
export {
  entryIdentity, matchRosterEntry, ownedDeployTarget, ownsDeployProject,
  rosterDeployProjects, rosterTargets,
} from "./ownership";
export type { DeployIdentity } from "./ownership";
export { reconcileBoardLedger } from "./reconcile";
export * from "./view";
// The platform-health target spelling and its inverse — so no reader outside the fold has
// to know that the string starts with "platform-health|".
export { ERROR_JUDGED_LEVELS, ERROR_RECENT_MS, errorsTarget, parseErrorsTarget, parsePlatformHealthTarget, platformHealthTarget } from "./derive-problems";

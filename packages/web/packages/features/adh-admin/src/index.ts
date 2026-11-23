// @adh-sdk/adh-admin — the admin console's panes and rail. The admin site
// (admin.agenticdeveloperhub) is their one host: the hub's /admin workspace is gone and its path
// redirects there.

// The topic list. Also published on its own as `./topics`, which is what a caller that needs only
// the names should import — this barrel carries every pane.
export { ADMIN_TOPICS } from "./adminTopics";
export type { AdminTopic, AdminTopicId } from "./adminTopics";
export { ADMIN_PANES } from "./adminPanes";

// The query scope every pane reads through — the toolkit's client with the admin freshness pinned.
// Also published on its own as `./query`, for a host layout that wraps panes it does not import.
export { AdminQueryProvider, ADMIN_STALE_TIME } from "./AdminQueryProvider";

// Every pane, standalone — each of the admin site's app/(admin)/<topic>/page.tsx mounts imports
// its own pane directly rather than going through ADMIN_PANES, since a page.tsx's default export
// must be that one component, named, not a map lookup.
export { AiNodesPane } from "./panes/AiNodesPane";
export { AuditPane } from "./panes/AuditPane";
export { AuthenticationPane } from "./panes/AuthenticationPane";
export { BreakGlassPane } from "./panes/BreakGlassPane";
export { BreakdownPane } from "./panes/BreakdownPane";
export { CostsPane } from "./panes/CostsPane";
export { FeatureFlagsPane, FlagDialog } from "./panes/FeatureFlagsPane";
export { FeedbackPane, FeedbackDialog } from "./panes/FeedbackPane";
export { InvitationsPane } from "./panes/InvitationsPane";
export { LlmProvidersPane } from "./panes/LlmProvidersPane";
export { MessagingPane } from "./panes/MessagingPane";
export { OperatorAccessPane } from "./panes/OperatorAccessPane";
export { OperatorsPane } from "./panes/OperatorsPane";
export { ProcessingConfigsPane } from "./panes/ProcessingConfigsPane";
export { ReservedIdentifiersPane } from "./panes/ReservedIdentifiersPane";
export { SecurityPane } from "./panes/SecurityPane";
export { ServerBagsPane, BagDialog } from "./panes/ServerBagsPane";
export { SupportAccessLogPane } from "./panes/SupportAccessLogPane";
export { SupportGrantsAdminPane } from "./panes/SupportGrantsAdminPane";
export { SyncPane } from "./panes/SyncPane";
export { UsageOverviewPane } from "./panes/UsageOverviewPane";
export { UsagePane, TierDialog } from "./panes/UsagePane";
export { UsersPane } from "./panes/UsersPane";

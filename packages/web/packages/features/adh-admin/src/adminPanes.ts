import type { ComponentType, ReactNode } from "react";

import { AiNodesPane } from "./panes/AiNodesPane";
import { AuditPane } from "./panes/AuditPane";
import { AuthenticationPane } from "./panes/AuthenticationPane";
import { BreakGlassPane } from "./panes/BreakGlassPane";
import { BreakdownPane } from "./panes/BreakdownPane";
import { CostsPane } from "./panes/CostsPane";
import { FeatureFlagsPane } from "./panes/FeatureFlagsPane";
import { FeedbackPane } from "./panes/FeedbackPane";
import { InvitationsPane } from "./panes/InvitationsPane";
import { LlmProvidersPane } from "./panes/LlmProvidersPane";
import { MessagingPane } from "./panes/MessagingPane";
import { OperatorAccessPane } from "./panes/OperatorAccessPane";
import { OperatorsPane } from "./panes/OperatorsPane";
import { ProcessingConfigsPane } from "./panes/ProcessingConfigsPane";
import { ReservedIdentifiersPane } from "./panes/ReservedIdentifiersPane";
import { SecurityPane } from "./panes/SecurityPane";
import { ServerBagsPane } from "./panes/ServerBagsPane";
import { SupportAccessLogPane } from "./panes/SupportAccessLogPane";
import { SupportGrantsAdminPane } from "./panes/SupportGrantsAdminPane";
import { SyncPane } from "./panes/SyncPane";
import { UsageOverviewPane } from "./panes/UsageOverviewPane";
import { UsagePane } from "./panes/UsagePane";
import { UsersPane } from "./panes/UsersPane";

import type { AdminTopicId } from "./adminTopics";

// Apart from adminTopics.ts so the topic list stays cheap to import: the admin site's shell (and
// any rail or route that only needs the names, icons and the id guard) reads `./topics`, and a
// module that ALSO held this map would pull all the panes — react-query, the editors, the
// dialogs — into every chunk that wanted a label.

/** Every topic's detail pane, keyed by {@link AdminTopicId}. The Record type is the point: a
 *  topic added to the rail without a pane is a compile error here, and the admin site's
 *  admin-pages test checks the same list against its app/(admin)/<id>/page.tsx files, so a rail
 *  entry cannot lead to a 404. */
export const ADMIN_PANES: Record<AdminTopicId, ComponentType<{ help?: ReactNode }>> = {
  users: UsersPane,
  invitations: InvitationsPane,
  "feature-flags": FeatureFlagsPane,
  "server-bags": ServerBagsPane,
  sync: SyncPane,
  audit: AuditPane,
  messaging: MessagingPane,
  feedback: FeedbackPane,
  authentication: AuthenticationPane,
  "llm-providers": LlmProvidersPane,
  usage: UsagePane,
  costs: CostsPane,
  "usage-overview": UsageOverviewPane,
  breakdown: BreakdownPane,
  "reserved-identifiers": ReservedIdentifiersPane,
  "ai-nodes": AiNodesPane,
  "processing-configs": ProcessingConfigsPane,
  "operator-access": OperatorAccessPane,
  operators: OperatorsPane,
  security: SecurityPane,
  "support-grants": SupportGrantsAdminPane,
  "break-glass": BreakGlassPane,
  "support-access": SupportAccessLogPane,
};

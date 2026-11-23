// @adh-sdk/support-access — consented support access (phase 7).
//
// The person's own view: who asked to see their content, approve, deny and revoke, and the read
// log. The same pane serves a customer (`side="customer"`) and a hub user (`side="account"`); the
// hub mounts it as the "Support access" settings tab. The data and its rules live in
// @adh-sdk/data/support.
//
// The asking side: SupportGrantsPane is a product admin's (ask, list, open, revoke) with the
// read-only SupportViewer; AdminGrantCard draws one grant for a product admin or an operator, and
// the operator site's panes in @adh-sdk/adh-admin reuse it.
export { SupportAccessPane } from "./SupportAccessPane";
export { GrantCard, endedLabel, grantTime, hoursPhrase, type GrantAction } from "./GrantCard";
export { AccessLogList, dayPhrase, describeAccess } from "./AccessLogList";
export { AdminGrantCard } from "./AdminGrantCard";
export { SupportGrantsPane, type SupportGrantsPaneProps } from "./SupportGrantsPane";
export { SupportViewer } from "./SupportViewer";

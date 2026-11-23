// @adh-sdk/support-access — consented support access (phase 7).
//
// The person's own view: who asked to see their content, approve, deny and revoke, and the read
// log. The same pane serves a customer (`side="customer"`) and a hub user (`side="account"`); the
// hub mounts it as the "Support access" settings tab. The data and its rules live in
// @adh-sdk/data/support.
export { SupportAccessPane } from "./SupportAccessPane";
export { GrantCard, hoursPhrase, type GrantAction } from "./GrantCard";
export { AccessLogList, dayPhrase, describeAccess } from "./AccessLogList";

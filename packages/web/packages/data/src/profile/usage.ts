// Metered usage: the current period's counters per principal, as the Usage sections in
// User Settings and an org's Settings render them.
//
// One endpoint, two views: with no `workspace` it returns the CALLER's principals (their
// user row, their API tokens, their personas); with `?workspace=<slug>` it returns that
// workspace's (an org's member roster + org-owned personas, admin-gated server-side). The
// subject list is derived on the backend and never sent by the client, so there is no
// "whose usage" parameter here beyond the workspace itself.

import { listAllV1, withV1Query } from "../http";
import type { UsageRow, UsageRowWire } from "./wire";

export type {
  UsageRow,
  UsageRowKind,
  UsageScope,
  UsageLimits,
  UsageRowWire,
  UsageLimitsWire,
} from "./wire";

// ── Query keys ─────────────────────────────────────────────────────────────────

const USAGE_SUMMARY_KEY = ["usage", "summary"] as const;

/** Cache key for a usage summary, namespaced by OWNER — same contract as the profile
 *  module's list keys: the two branches differ at the SAME segment, so neither is a prefix
 *  of the other and invalidating the personal view can't refetch every workspace's. */
export function usageSummaryKey(workspaceSlug?: string): readonly string[] {
  return workspaceSlug
    ? [...USAGE_SUMMARY_KEY, "org", workspaceSlug]
    : [...USAGE_SUMMARY_KEY, "self"];
}

// ── Reads ──────────────────────────────────────────────────────────────────────

const toUsageRow = (w: UsageRowWire): UsageRow => ({
  kind: w.kind,
  scope: w.scope,
  principalId: w.principal_id,
  label: w.label,
  periodStart: w.period_start,
  periodDays: w.period_days,
  tier: w.tier,
  limits: {
    quotaRequests: w.limits.quota_requests,
    quotaBytes: w.limits.quota_bytes,
    quotaTokens: w.limits.quota_tokens,
    quotaCostMicros: w.limits.quota_cost_micros,
    enforced: w.limits.enforced,
  },
  requests: w.requests,
  bytes: w.bytes,
  tokens: w.tokens,
  costMicros: w.cost_micros,
});

export async function getUsageSummary(opts?: { workspace?: string }): Promise<UsageRow[]> {
  const rows = await listAllV1<UsageRowWire>(
    withV1Query("/api/v1/usage/summary", { workspace: opts?.workspace }),
  );
  return rows.map(toUsageRow);
}

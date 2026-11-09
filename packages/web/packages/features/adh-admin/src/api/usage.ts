"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import type { RequestBody, SuccessBody } from "@adh-sdk/adh-api-types";
import { authedJson, listAllV1, unixToIso } from "./http";
import { useCreateFlag, useUpdateFlag } from "./admin";

// ── Usage metering: the enforcement switch + the tiers it arms ────────────
//
// The platform meters every authenticated request and every LLM turn, but a cap
// only REFUSES anything when two switches agree: the tier's own `quota_enforced`
// column, and one global kill switch above all of them. This module reads both
// and writes both — the read through the admin-gated `GET /api/v1/usage/enforcement`,
// which also reports the process-level pricing knobs no row can carry (snake_case, as `/v1` sends it).

/** The `system.feature_flags` key holding the global switch. */
// Mirrors ENFORCEMENT_FLAG_KEY in the backend's src/lib/usage/enforcement.ts, which
// isn't importable from the frontend (same reason HUB_ECOSYSTEM_ID is duplicated in
// ./admin.ts). The backend's migration 0158 seeds the row; this constant is only
// needed for the one case where it is absent and the console has to create it.
export const ENFORCEMENT_FLAG_KEY = "usage_enforcement";

/** What the console shows next to the switch, when it has to create the row itself. */
const ENFORCEMENT_FLAG_DESCRIPTION =
  "Master kill switch above every tier's quota_enforced flag: off means usage is recorded but never refused.";

/** The effective switch, the input that decided it, and the pricing knobs. */
export type UsageEnforcement = SuccessBody<"/v1/usage/enforcement", "get">;

export function useUsageEnforcement() {
  return useQuery({
    queryKey: ["admin", "usage", "enforcement"],
    queryFn: () => authedJson<UsageEnforcement>("/api/v1/usage/enforcement"),
  });
}

/**
 * Flip the global switch. There is no `PUT /usage/enforcement`: the switch IS a
 * `system.feature_flags` row, so the write reuses the flag store's own admin CRUD
 * (the hooks the Feature Flags page uses) rather than adding a second write path for
 * one authorization decision. `flagId: null` means the row doesn't exist yet — the
 * only case that needs a POST, and the reason the key is named here at all.
 *
 * Both queries are invalidated: the flag hooks refresh `["admin","flags"]`
 * themselves, and this adds the enforcement read, which is what the page renders.
 */
export function useSetEnforcement() {
  const qc = useQueryClient();
  const createFlag = useCreateFlag();
  const updateFlag = useUpdateFlag();
  return useMutation({
    mutationFn: async ({ flagId, enabled }: { flagId: number | null; enabled: boolean }) => {
      if (flagId === null) {
        await createFlag.mutateAsync({
          key: ENFORCEMENT_FLAG_KEY,
          enabled,
          description: ENFORCEMENT_FLAG_DESCRIPTION,
        });
        return;
      }
      await updateFlag.mutateAsync({ id: flagId, changes: { enabled } });
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ["admin", "usage", "enforcement"] }),
  });
}

// ── Rate-limit tiers ──────────────────────────────────────────────────────
//
// `/api/v1/usage/rate_limit_tiers` (any signed-in caller reads, admins write). One row per tier;
// principals without an explicit `principal_tiers` assignment fall to the `is_default` row.
//
// The tier editor works in camelCase, so the exported row and patch keep that shape and the two
// explicit mappers below (`toTier`, `toTierWire`) are the only places that know the wire names.

type TierWire = SuccessBody<"/v1/usage/rate_limit_tiers", "get">["data"][number];
type TierWireBody = RequestBody<"/v1/usage/rate_limit_tiers/{id}", "post">;

/** A `usage.rate_limit_tiers` row. */
export interface RateLimitTier {
  id: string;
  slug: string;
  name: string;
  rateCapacity: number;
  rateRefillTokens: number;
  rateRefillSeconds: number;
  quotaRequests: number | null;
  quotaBytes: number | null;
  quotaTokens: number | null;
  quotaCostMicros: number | null;
  quotaPeriodDays: number;
  quotaEnforced: boolean;
  isDefault: boolean;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}
/** The partial update body (every column optional). */
export interface UpdateTierBody {
  slug?: string;
  name?: string;
  rateCapacity?: number;
  rateRefillTokens?: number;
  rateRefillSeconds?: number;
  quotaRequests?: number | null;
  quotaBytes?: number | null;
  quotaTokens?: number | null;
  quotaCostMicros?: number | null;
  quotaPeriodDays?: number;
  quotaEnforced?: boolean;
  isDefault?: boolean;
  isActive?: boolean;
}

function toTier(w: TierWire): RateLimitTier {
  return {
    id: w.id,
    slug: w.slug,
    name: w.name,
    rateCapacity: w.rate_capacity,
    rateRefillTokens: w.rate_refill_tokens,
    rateRefillSeconds: w.rate_refill_seconds,
    quotaRequests: w.quota_requests,
    quotaBytes: w.quota_bytes,
    quotaTokens: w.quota_tokens,
    quotaCostMicros: w.quota_cost_micros,
    quotaPeriodDays: w.quota_period_days,
    quotaEnforced: w.quota_enforced,
    isDefault: w.is_default,
    isActive: w.is_active,
    createdAt: unixToIso(w.created),
    updatedAt: unixToIso(w.updated),
  };
}

/** Only the fields the caller set — an absent field must never reach the wire as undefined/null. */
function toTierWire(b: UpdateTierBody): TierWireBody {
  const out: TierWireBody = {};
  if (b.slug !== undefined) out.slug = b.slug;
  if (b.name !== undefined) out.name = b.name;
  if (b.rateCapacity !== undefined) out.rate_capacity = b.rateCapacity;
  if (b.rateRefillTokens !== undefined) out.rate_refill_tokens = b.rateRefillTokens;
  if (b.rateRefillSeconds !== undefined) out.rate_refill_seconds = b.rateRefillSeconds;
  if (b.quotaRequests !== undefined) out.quota_requests = b.quotaRequests;
  if (b.quotaBytes !== undefined) out.quota_bytes = b.quotaBytes;
  if (b.quotaTokens !== undefined) out.quota_tokens = b.quotaTokens;
  if (b.quotaCostMicros !== undefined) out.quota_cost_micros = b.quotaCostMicros;
  if (b.quotaPeriodDays !== undefined) out.quota_period_days = b.quotaPeriodDays;
  if (b.quotaEnforced !== undefined) out.quota_enforced = b.quotaEnforced;
  if (b.isDefault !== undefined) out.is_default = b.isDefault;
  if (b.isActive !== undefined) out.is_active = b.isActive;
  return out;
}

export function useRateLimitTiers() {
  return useQuery({
    queryKey: ["admin", "usage", "tiers"],
    queryFn: async (): Promise<RateLimitTier[]> =>
      (await listAllV1<TierWire>("/api/v1/usage/rate_limit_tiers")).map(toTier),
  });
}

export function useUpdateRateLimitTier() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({
      id,
      changes,
    }: {
      id: string;
      changes: UpdateTierBody;
    }): Promise<RateLimitTier> =>
      toTier(
        await authedJson<TierWire>(`/api/v1/usage/rate_limit_tiers/${encodeURIComponent(id)}`, {
          method: "POST",
          body: JSON.stringify(toTierWire(changes)),
        }),
      ),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["admin", "usage", "tiers"] }),
  });
}

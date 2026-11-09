// Profile card API: social links, addresses, and privacy grants.
// Backs the Settings > Profile editor surface (social links, addresses, contact
// privacy, avatar privacy) and the owner's live UserCard preview.

import { authedJson, authedRequest, listAllV1, unixToIso, withV1Query } from "../http";
import type {
  Address,
  AddressWire,
  AddressWrite,
  PrivacyGrant,
  PrivacyGrantWire,
  PrivacyLevel,
  PrivacyTargetTable,
  SocialLink,
  SocialLinkWire,
  SocialLinkWrite,
} from "./wire";

export type {
  Address,
  AddressWire,
  AddressWrite,
  AddressWriteWire,
  PrivacyGrant,
  PrivacyGrantWire,
  PrivacyLevel,
  PrivacyTargetTable,
  SocialLink,
  SocialLinkWire,
  SocialLinkWrite,
  SocialLinkWriteWire,
} from "./wire";

/** Maps privacy level to audienceMask integer for POST /v1/account (`privacy`). */
const AUDIENCE_MASK: Record<PrivacyLevel, number> = {
  "only-me": 0,
  public: 1,
  hub: 2,
};

// ── Query keys ─────────────────────────────────────────────────────────────────

// Namespace ROOTS, not query keys — every list lives under an owner segment below, so these
// are deliberately not exported: using a bare root as a query key would alias one owner's list
// onto another's. Go through socialLinksKey / addressesKey.
const SOCIAL_LINKS_KEY = ["profile", "social-links"] as const;
const ADDRESSES_KEY = ["profile", "addresses"] as const;
export const PRIVACY_KEY = ["account", "privacy"] as const;

/** Cache key for a social-links list, namespaced by OWNER: `self` for the caller's own list,
 *  `org/<slug>` for a workspace's. The two branches differ at the SAME segment, so neither is a
 *  prefix of the other — react-query invalidation is prefix-based, so a shorter personal key
 *  would also invalidate (and refetch) every org list. Defined once: the panel that READS and
 *  the section that INVALIDATES must not derive this shape independently, or a change to one
 *  silently desyncs the other. */
export function socialLinksKey(workspaceSlug?: string): readonly string[] {
  return workspaceSlug ? [...SOCIAL_LINKS_KEY, "org", workspaceSlug] : [...SOCIAL_LINKS_KEY, "self"];
}

/** Cache key for an addresses list. Same contract as {@link socialLinksKey}. */
export function addressesKey(workspaceSlug?: string): readonly string[] {
  return workspaceSlug ? [...ADDRESSES_KEY, "org", workspaceSlug] : [...ADDRESSES_KEY, "self"];
}

const SOCIAL_LINKS = "/api/v1/content/social_links";
const ADDRESSES = "/api/v1/content/addresses";
const ACCOUNT = "/api/v1/account";

/** Query for the owner-scoped content routes: `?workspace=<slug>` for an org's rows, nothing for
 *  the caller's own. */
const scope = (opts?: { workspace?: string }) => ({ workspace: opts?.workspace });

/** The ids and sync stamps every owner-scoped row carries, from wire to app shape. */
function ownerScoped(w: SocialLinkWire | AddressWire) {
  return {
    id: w.id,
    authorKind: w.author_kind,
    authorId: w.author_id,
    deletedAt: w.deleted_at,
    ecosystemId: w.ecosystem_id,
    ownerKind: w.owner_kind,
    ownerId: w.owner_id,
    createdAt: unixToIso(w.created),
    updatedAt: unixToIso(w.updated),
    syncVersion: w.sync_version,
    syncStampedAt: w.sync_stamped_at,
    syncTxid: w.sync_txid,
  };
}

const toSocialLink = (w: SocialLinkWire): SocialLink => ({
  ...ownerScoped(w),
  platform: w.platform,
  url: w.url,
  handle: w.handle,
  sortOrder: w.sort_order,
});

const toAddress = (w: AddressWire): Address => ({
  ...ownerScoped(w),
  label: w.label,
  line1: w.line1,
  line2: w.line2,
  city: w.city,
  region: w.region,
  postalCode: w.postal_code,
  country: w.country,
});

const socialLinkBody = (b: SocialLinkWrite) => ({
  platform: b.platform,
  url: b.url,
  handle: b.handle,
  ...(b.sortOrder !== undefined ? { sort_order: b.sortOrder } : {}),
});

const addressBody = (b: AddressWrite) => ({
  label: b.label,
  line1: b.line1,
  line2: b.line2,
  city: b.city,
  region: b.region,
  postal_code: b.postalCode,
  country: b.country,
});

const toPrivacyGrant = (w: PrivacyGrantWire): PrivacyGrant => ({
  targetTable: w.target_table,
  targetId: w.target_id,
  audienceMask: w.audience_mask,
});

// ── Social links ───────────────────────────────────────────────────────────────

export async function listSocialLinks(opts?: { workspace?: string }): Promise<SocialLink[]> {
  const rows = await listAllV1<SocialLinkWire>(withV1Query(SOCIAL_LINKS, scope(opts)));
  return rows.map(toSocialLink);
}

export async function createSocialLink(
  body: SocialLinkWrite,
  opts?: { workspace?: string },
): Promise<SocialLink> {
  const row = await authedJson<SocialLinkWire>(withV1Query(SOCIAL_LINKS, scope(opts)), {
    method: "POST",
    body: JSON.stringify(socialLinkBody(body)),
  });
  return toSocialLink(row);
}

export async function updateSocialLink(
  id: string,
  body: SocialLinkWrite,
  opts?: { workspace?: string },
): Promise<SocialLink> {
  const row = await authedJson<SocialLinkWire>(
    withV1Query(`${SOCIAL_LINKS}/${encodeURIComponent(id)}`, scope(opts)),
    { method: "POST", body: JSON.stringify(socialLinkBody(body)) },
  );
  return toSocialLink(row);
}

export async function deleteSocialLink(id: string, opts?: { workspace?: string }): Promise<void> {
  await authedRequest(withV1Query(`${SOCIAL_LINKS}/${encodeURIComponent(id)}`, scope(opts)), {
    method: "DELETE",
  });
}

// ── Addresses ──────────────────────────────────────────────────────────────────

export async function listAddresses(opts?: { workspace?: string }): Promise<Address[]> {
  const rows = await listAllV1<AddressWire>(withV1Query(ADDRESSES, scope(opts)));
  return rows.map(toAddress);
}

export async function createAddress(
  body: AddressWrite,
  opts?: { workspace?: string },
): Promise<Address> {
  const row = await authedJson<AddressWire>(withV1Query(ADDRESSES, scope(opts)), {
    method: "POST",
    body: JSON.stringify(addressBody(body)),
  });
  return toAddress(row);
}

export async function updateAddress(
  id: string,
  body: AddressWrite,
  opts?: { workspace?: string },
): Promise<Address> {
  const row = await authedJson<AddressWire>(
    withV1Query(`${ADDRESSES}/${encodeURIComponent(id)}`, scope(opts)),
    { method: "POST", body: JSON.stringify(addressBody(body)) },
  );
  return toAddress(row);
}

export async function deleteAddress(id: string, opts?: { workspace?: string }): Promise<void> {
  await authedRequest(withV1Query(`${ADDRESSES}/${encodeURIComponent(id)}`, scope(opts)), {
    method: "DELETE",
  });
}

// ── Privacy ────────────────────────────────────────────────────────────────────

export async function getPrivacyGrants(): Promise<PrivacyGrant[]> {
  const res = await authedJson<{ privacy?: { items: PrivacyGrantWire[] } }>(
    withV1Query(ACCOUNT, { "include[]": "privacy" }),
  );
  return (res.privacy?.items ?? []).map(toPrivacyGrant);
}

export async function setPrivacyGrant(
  targetTable: PrivacyTargetTable,
  targetId: string,
  level: PrivacyLevel,
): Promise<PrivacyGrant> {
  const res = await authedJson<{ privacy?: PrivacyGrantWire }>(ACCOUNT, {
    method: "POST",
    body: JSON.stringify({
      privacy: {
        target_table: targetTable,
        target_id: targetId,
        audience_mask: AUDIENCE_MASK[level],
      },
    }),
  });
  // The echo is the written grant; fall back to the request if a backend omits it.
  return res.privacy
    ? toPrivacyGrant(res.privacy)
    : { targetTable, targetId, audienceMask: AUDIENCE_MASK[level] };
}

/**
 * Derive the PrivacyLevel for a (targetTable, targetId) pair from the loaded
 * grants. Returns 'only-me' when no matching grant exists (the default).
 *
 * Bit semantics: bit 0 = PUBLIC (mask & 1), bit 1 = HUB (mask & 2).
 * When both are set (mask = 3), PUBLIC wins as the broader audience.
 */
export function resolvePrivacyLevel(
  grants: PrivacyGrant[],
  targetTable: PrivacyTargetTable,
  targetId: string,
): PrivacyLevel {
  const grant = grants.find((g) => g.targetTable === targetTable && g.targetId === targetId);
  if (!grant) return "only-me";
  if (grant.audienceMask & 1) return "public";
  if (grant.audienceMask & 2) return "hub";
  return "only-me";
}

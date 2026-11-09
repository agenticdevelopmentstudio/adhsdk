"use client";

// Owner-decoupled STORAGE-access token principals (the `adh_…` secrets), each with its own
// isolated bucket. Distinct from the PERSONAL API tokens the user-settings panel mints
// (`tmp_…`, @adh-sdk/authentication's TokensPanel) — same noun, different principal.
//
// Hand-written wire types in ./wire, for the reason feature-flags.ts states.

import { authedJson, authedRequest, listAllV1, unixToIso, withV1Query } from "../http";
import type {
  MintTokenPrincipalBody,
  TokenPrincipal,
  TokenPrincipalCreated,
  TokenPrincipalCreatedRow,
  TokenPrincipalRow,
} from "./wire";

export type { MintTokenPrincipalBody, TokenPrincipal, TokenPrincipalCreated } from "./wire";

const BASE = "/api/v1/api_keys";

/** Owner/bucket scoping shared by every op: `workspace` (a verified slug) pins the op
 *  to the WORKSPACE'S owning principal — the caller's own customer or an org they
 *  belong to — so an org workspace lists/mints/revokes the ORG'S tokens. `ecosystemId`
 *  (rdid or uuid; list only) narrows to tokens whose bucket lives in that ecosystem
 *  (the per-product Tokens topic's scope). */
export interface TokenScope {
  ecosystemId?: string;
  workspace?: string;
}

function scoped(path: string, scope?: TokenScope): string {
  return withV1Query(path, { ecosystem_id: scope?.ecosystemId, workspace: scope?.workspace });
}

const toPrincipal = (r: TokenPrincipalRow): TokenPrincipal => ({
  id: r.id,
  slug: r.slug,
  description: r.description,
  prefix: r.prefix,
  rdid: r.rdid ?? null,
  bucketRdid: r.bucket_rdid ?? null,
  expiresAt: r.expires_at ?? null,
  lastUsedAt: r.last_used_at ?? null,
  createdAt: unixToIso(r.created),
});

const toCreated = (r: TokenPrincipalCreatedRow): TokenPrincipalCreated => ({
  id: r.id,
  rdid: r.rdid,
  slug: r.slug,
  description: r.description,
  prefix: r.prefix,
  bucketRdid: r.bucket_rdid,
  token: r.token,
});

export const tokenPrincipalsApi = {
  async list(scope?: TokenScope): Promise<TokenPrincipal[]> {
    const rows = await listAllV1<TokenPrincipalRow>(scoped(BASE, scope));
    return rows.map(toPrincipal);
  },
  async mint(body: MintTokenPrincipalBody, scope?: TokenScope): Promise<TokenPrincipalCreated> {
    const row = await authedJson<TokenPrincipalCreatedRow>(scoped(BASE, scope), {
      method: "POST",
      body: JSON.stringify({
        name: body.name,
        ...(body.description !== undefined ? { description: body.description } : {}),
        ...(body.expiresAt !== undefined ? { expires_at: body.expiresAt } : {}),
        ...(body.ecosystemId !== undefined ? { ecosystem_id: body.ecosystemId } : {}),
      }),
    });
    return toCreated(row);
  },
  revoke(id: string, scope?: TokenScope): Promise<void> {
    return authedRequest(scoped(`${BASE}/${encodeURIComponent(id)}`, scope), {
      method: "DELETE",
    });
  },
};

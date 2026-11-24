import { authedJson, authedRequest, listAllV1, unixToIso } from "../http";
import type { ApiTokenCreatedRow, ApiTokenCreatedWire, ApiTokenRow, ApiTokenWire, MintTokenBody } from "./wire";

export type ApiToken = ApiTokenRow;
export type ApiTokenCreated = ApiTokenCreatedRow;
export type { MintTokenBody };

const BASE = "/api/v1/api_keys";

const toToken = (w: ApiTokenWire): ApiToken => ({
  id: w.id,
  name: w.name,
  prefix: w.prefix,
  createdAt: unixToIso(w.created),
  expiresAt: w.expires_at ?? null,
  lastUsedAt: w.last_used_at ?? null,
  ...(w.scope !== undefined ? { scope: w.scope } : {}),
});

export const tokensApi = {
  async list(): Promise<ApiToken[]> {
    const rows = await listAllV1<ApiTokenWire>(BASE);
    return rows.map(toToken);
  },
  async scopes(): Promise<string[]> {
    const r = await authedJson<{ prefixes: string[] }>(`${BASE}/scopes`);
    return r.prefixes;
  },
  async mint(body: MintTokenBody): Promise<ApiTokenCreated> {
    const w = await authedJson<ApiTokenCreatedWire>(BASE, {
      method: "POST",
      body: JSON.stringify({
        name: body.name,
        ...(body.expiresAt !== undefined ? { expires_at: body.expiresAt } : {}),
        ...(body.scope !== undefined ? { scope: body.scope } : {}),
      }),
    });
    return { ...toToken(w), token: w.token };
  },
  revoke(id: string): Promise<void> {
    return authedRequest(`${BASE}/${encodeURIComponent(id)}`, { method: "DELETE" });
  },
};

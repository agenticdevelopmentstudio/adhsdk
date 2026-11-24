// Persona ability + permission-grant API client — `/v1/personas/{id}/tools`
// (Abilities: grant/revoke/autonomy), `/v1/personas/{id}/actors` (Permissions: may-act context
// grants), and `/v1/processing/persona_approvals` (Permissions: the human-in-the-loop decision
// queue). Wire shapes are the package-local /v1 mirrors in ./wire, mapped to the camelCase
// domain rows by ./mappers, so a backend contract change breaks the type-check here rather than
// at runtime.
import { authedJson, authedRequest, listAllV1, withV1Query } from "../http";
import { enc } from "../client-helpers";
import { approvalFromWire, toolFromWire, toolGrantFromWire } from "./mappers";
import type {
  ApprovalListRow,
  MayActGrantBody,
  MayActRow,
  SetAutonomyBody,
  ToolCatalogListRow,
  ToolGrantRow,
  V1Actors,
  V1PersonaApproval,
  V1PersonaTool,
  V1PersonaToolGrant,
} from "./wire";

const V1 = "/api/v1";

export type ApprovalList = ApprovalListRow;
export type Approval = ApprovalList["approvals"][number];
export type ApprovalStatus = "pending" | "approved" | "rejected";

export type ToolCatalogList = ToolCatalogListRow;
export type ToolCatalogItem = ToolCatalogList["tools"][number];
export type ToolGrant = ToolGrantRow;

export const personaApprovalsApi = {
  // `personaId` narrows the decidable queue server-side to one persona (#14) — the backend
  // intersects it with the caller's decidable set, so the response already contains only that
  // persona's pending rows; callers no longer need to filter the response themselves.
  async list(status: ApprovalStatus = "pending", personaId?: string): Promise<Approval[]> {
    const rows = await listAllV1<V1PersonaApproval>(
      withV1Query(`${V1}/processing/persona_approvals`, { status, persona_id: personaId }),
    );
    return rows.map(approvalFromWire);
  },
  async approve(id: string): Promise<Approval> {
    const row = await authedJson<V1PersonaApproval>(
      `${V1}/processing/persona_approvals/${enc(id)}/approve`,
      { method: "POST" },
    );
    return approvalFromWire(row);
  },
  async reject(id: string): Promise<Approval> {
    const row = await authedJson<V1PersonaApproval>(
      `${V1}/processing/persona_approvals/${enc(id)}/reject`,
      { method: "POST" },
    );
    return approvalFromWire(row);
  },
};

export type MayActList = MayActRow;
export type MayActKind = MayActList["kinds"][number];

/** The two may-act contexts a persona can be granted leave to act under (#10/#12). */
export type MayActGrantableKind = "user" | "team";

export const personaMayActApi = {
  async list(personaId: string): Promise<MayActKind[]> {
    const body = await authedJson<V1Actors>(`${V1}/personas/${enc(personaId)}/actors`);
    return body.kinds;
  },
  // `kind`-parameterized grant/revoke (#12) — collapses the former grantUser/grantTeam and
  // revokeUser/revokeTeam pairs, which differed only in the literal kind/URL segment.
  async grant(personaId: string, kind: MayActGrantableKind): Promise<MayActKind[]> {
    const input: MayActGrantBody = { kind };
    const body = await authedJson<V1Actors>(`${V1}/personas/${enc(personaId)}/actors`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(input),
    });
    return body.kinds;
  },
  async revoke(personaId: string, kind: MayActGrantableKind): Promise<void> {
    await authedRequest(`${V1}/personas/${enc(personaId)}/actors/${enc(kind)}`, {
      method: "DELETE",
    });
  },
};

export const personaToolsApi = {
  async list(personaId: string): Promise<ToolCatalogItem[]> {
    const rows = await listAllV1<V1PersonaTool>(`${V1}/personas/${enc(personaId)}/tools`);
    return rows.map(toolFromWire);
  },
  async grant(personaId: string, toolName: string): Promise<ToolCatalogItem> {
    const row = await authedJson<V1PersonaTool>(`${V1}/personas/${enc(personaId)}/tools`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ tool_name: toolName }),
    });
    return toolFromWire(row);
  },
  async revoke(personaId: string, toolName: string): Promise<void> {
    await authedRequest(`${V1}/personas/${enc(personaId)}/tools/${enc(toolName)}`, {
      method: "DELETE",
    });
  },
  async setAutonomy(personaId: string, toolName: string, autonomous: boolean): Promise<ToolGrant> {
    const input: SetAutonomyBody = { autonomous };
    const row = await authedJson<V1PersonaToolGrant>(
      `${V1}/personas/${enc(personaId)}/tools/${enc(toolName)}`,
      { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(input) },
    );
    return toolGrantFromWire(row);
  },
};

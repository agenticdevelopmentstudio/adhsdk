// Per-user persona tool-consent API client (Layer-2). A user who a persona may act FOR
// (the persona holds the `may_act 'user'` grant) controls, per owner-granted tool, whether
// that persona may invoke it on their behalf. Backed by `/v1/personas?actable_by=me` and
// `/v1/personas/{id}/user_tools`; typed via package-local /v1 wire types (see ./wire) so a
// contract change stops these calls from type-checking.
import { authedJson, listAllV1, withV1Query } from "../http";
import { enc } from "../client-helpers";
import { userToolFromWire } from "./mappers";
import type {
  SetAllowedBody,
  UserActableListRow,
  UserToolListRow,
  V1Persona,
  V1UserTool,
  V1UserToolsSet,
} from "./wire";

const V1 = "/api/v1";

/** The personas the caller may configure per-tool consent for — those with `may_act 'user'`. */
export type UserActableList = UserActableListRow;
/** One configurable persona (`{ id, slug, name }`). */
export type UserActablePersona = UserActableList["personas"][number];

export type UserToolList = UserToolListRow;
export type UserTool = UserToolList["tools"][number];

export const personaUserToolsApi = {
  async listActable(): Promise<UserActablePersona[]> {
    const rows = await listAllV1<V1Persona>(withV1Query(`${V1}/personas`, { actable_by: "me" }));
    return rows.map(({ id, slug, name }) => ({ id, slug, name }));
  },
  async listTools(personaId: string): Promise<UserTool[]> {
    const rows = await listAllV1<V1UserTool>(`${V1}/personas/${enc(personaId)}/user_tools`);
    return rows.map(userToolFromWire);
  },
  async setAllowed(personaId: string, allowed: string[]): Promise<UserTool[]> {
    const input: SetAllowedBody = { allowed };
    const body = await authedJson<V1UserToolsSet>(
      `${V1}/personas/${enc(personaId)}/user_tools`,
      { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(input) },
    );
    return body.tools.map(userToolFromWire);
  },
};

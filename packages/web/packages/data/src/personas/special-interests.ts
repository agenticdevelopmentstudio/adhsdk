// `/v1/special_interests` — a persona's one or two deep interests.
//
// Routes: /api/v1/special_interests (list/create), /api/v1/special_interests/{id}
//         (post/delete).
//
// The list MUST be filtered by persona: the resource scopes to the caller's own rows, so an
// unfiltered call returns every interest the caller owns across ALL their personas.
import { authedJson, authedRequest, listAllV1, withV1Query } from "../http";
import { enc } from "../client-helpers";
import { specialInterestFromWire } from "./mappers";
import type { SpecialInterestRow, V1SpecialInterest } from "./wire";

const BASE = "/api/v1/special_interests";

/** Create body. `personaId` takes the persona's rdid (`persona.<owner>.<name>`) or its uuid —
 *  the backend resolves either. `slug` is a single rdid segment: [a-z0-9-], no dots. */
export interface SpecialInterestBody {
  personaId: string;
  slug: string;
  general: string;
  topical?: string | null;
  specific?: string | null;
  stances?: string | null;
  position?: number;
}

/** Update body: everything except the two fields the server owns. `personaId` is immutable
 *  (moving an interest would orphan its provisioned bucket) and `bucketId` is server-assigned. */
export type SpecialInterestPatch = Partial<Omit<SpecialInterestBody, "personaId">>;

export const specialInterestsApi = {
  list: (personaId: string) =>
    listAllV1<V1SpecialInterest>(withV1Query(BASE, { persona_id: personaId })).then((rows) =>
      rows.map(specialInterestFromWire),
    ),
  create: (body: SpecialInterestBody) =>
    authedJson<V1SpecialInterest>(BASE, {
      method: "POST",
      body: JSON.stringify({
        persona_id: body.personaId,
        slug: body.slug,
        general: body.general,
        topical: body.topical,
        specific: body.specific,
        stances: body.stances,
        position: body.position,
      }),
    }).then(specialInterestFromWire),
  update: (id: string, patch: SpecialInterestPatch) => {
    // Build the body from the editable fields only: a real personaId change is a 400 and
    // bucketId is server-assigned, so even a caller that passes them through (they are not in
    // the type) cannot send them. Failing here silently is better than a confusing 400 the
    // user cannot act on.
    return authedJson<V1SpecialInterest>(`${BASE}/${enc(id)}`, {
      method: "POST",
      body: JSON.stringify({
        slug: patch.slug,
        general: patch.general,
        topical: patch.topical,
        specific: patch.specific,
        stances: patch.stances,
        position: patch.position,
      }),
    }).then(specialInterestFromWire);
  },
  delete: (id: string) => authedRequest(`${BASE}/${enc(id)}`, { method: "DELETE" }),
};

export type { SpecialInterestRow } from "./wire";

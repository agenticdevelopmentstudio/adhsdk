// Ecosystem users client — the end-customers who authenticate to an ecosystem.
// Wired to the /v1 customers routes (/api/v1/customers). A customer is the platform's
// end-customer identity / login store, scoped to an ecosystem by `ecosystem_id`.
//
// Field map (UI <-> /v1 row):
//   email       <->  email          displayName <->  display_name
//   externalId  <->  external_id    slug        <->  slug (a short handle)
//   avatarUrl   <->  avatar_url     ecosystemId <->  ecosystem_id
//   createdAt   <->  created (unix seconds)   updatedAt <-> updated
//
// `token_version` (session-invalidation counter) and the soft-delete columns are
// internal auth bookkeeping and intentionally not surfaced on the form.

import type { RequestBody, SuccessBody } from "@adh-sdk/adh-api-types";
import { authedJson, listAllV1, unixToIso, withV1Query } from "@adh-sdk/auth/client";
import { compact, enc, sortByText } from "@adh-sdk/data";

export interface EcosystemUser {
  id: string;
  ecosystemId: string;
  email: string;
  displayName: string;
  externalId: string;
  slug: string;
  avatarUrl: string;
  createdAt: string;
  updatedAt: string;
}

export interface EcosystemUserInput {
  email: string;
  displayName: string;
  externalId: string;
  slug: string;
  avatarUrl: string;
}

const BASE = "/api/v1/customers";

/** The backend `customer.customers` row, sourced from the OpenAPI spec. */
type CustomerRow = SuccessBody<"/v1/customers", "get">["data"][number];

export function toUser(r: CustomerRow): EcosystemUser {
  return {
    id: r.id,
    ecosystemId: r.ecosystem_id,
    email: r.email ?? "",
    displayName: r.display_name ?? "",
    externalId: r.external_id ?? "",
    slug: r.slug ?? "",
    avatarUrl: r.avatar_url ?? "",
    createdAt: unixToIso(r.created),
    updatedAt: unixToIso(r.updated),
  };
}

export const ecosystemUsersApi = {
  async list(ecosystemId?: string): Promise<EcosystemUser[]> {
    // The SERVER narrows to the ecosystem, never the browser. This used to fetch every customer and
    // keep the rows whose `ecosystemId` equalled the pane's — but the hub names an ecosystem by its
    // RDID (`ecosystem.ads.agenticdeveloperhub`) while a customer row carries the stored UUID, so the
    // comparison matched nothing and every ecosystem's Users pane read "No users yet." (Mike,
    // 2026-10-06). It also filtered only the newest 500 rows of the WHOLE table (the backend's list
    // cap), so even matching ids would have dropped older users. The backend's `?ecosystemId=`
    // filter resolves an rdid to the stored uuid itself (crud/factory.ts, `ecosystemAddrProp`), and
    // the cap then applies to this ecosystem's rows alone. `listAllV1` walks the cursor pages.
    const url = ecosystemId ? withV1Query(BASE, { ecosystem_id: ecosystemId }) : BASE;
    const rows = await listAllV1<CustomerRow>(url);
    return sortByText(rows.map(toUser), (u) => u.displayName || u.email);
  },

  async get(id: string): Promise<EcosystemUser | null> {
    try {
      return toUser(await authedJson<CustomerRow>(`${BASE}/${enc(id)}`));
    } catch {
      // Backend 404s with a thrown error; the UI contract is null-for-missing.
      return null;
    }
  },

  async create(input: EcosystemUserInput, ecosystemId: string): Promise<EcosystemUser> {
    // Fail fast rather than silently mis-scoping: an absent ecosystemId would let
    // the backend assign the new customer to the caller's own ecosystem.
    if (!ecosystemId) {
      throw new Error("Cannot create a user without a selected ecosystem.");
    }
    const body: RequestBody<"/v1/customers", "post"> = {
      ecosystem_id: ecosystemId,
      email: input.email || undefined,
      display_name: input.displayName || undefined,
      external_id: input.externalId || undefined,
      // Required: the backend refuses a create with no handle (it has no default to fall
      // back on), so it is sent as given — `userValidate` has already refused an empty one.
      slug: input.slug,
      avatar_url: input.avatarUrl || undefined,
    };
    const row = await authedJson<CustomerRow>(BASE, {
      method: "POST",
      body: JSON.stringify(compact(body)),
    });
    return toUser(row);
  },

  async update(id: string, input: Partial<EcosystemUserInput>): Promise<EcosystemUser> {
    const fields: Partial<RequestBody<"/v1/customers/{id}", "post">> = {
      // "" goes out as NULL for the two columns under a unique index. `toUser` reads NULL back as
      // "", so an SSO user created from an externalId alone (NULL email) comes back with email "",
      // and a save that echoed it wrote '' — a VALUE to Postgres, where NULL is not one: the
      // non-partial (ecosystem_id, email) and (ecosystem_id, external_id) indexes admit any
      // number of NULLs but a single '', so the SECOND such user saved in an ecosystem got a 409.
      // `compact` keeps an explicit null (a clear) and drops only undefined (a field not sent).
      // Only these two: `slug` and `avatarUrl` are NOT NULL (the wire type refuses null for
      // both), and `displayName` is under no unique index.
      email: input.email === "" ? null : input.email,
      display_name: input.displayName,
      external_id: input.externalId === "" ? null : input.externalId,
      slug: input.slug,
      avatar_url: input.avatarUrl,
    };
    const row = await authedJson<CustomerRow>(`${BASE}/${enc(id)}`, {
      method: "POST",
      body: JSON.stringify(compact(fields)),
    });
    return toUser(row);
  },

  async delete(id: string): Promise<void> {
    await authedJson<unknown>(`${BASE}/${enc(id)}`, { method: "DELETE" });
  },
};

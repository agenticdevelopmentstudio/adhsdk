"use client";

// An ecosystem's SIGN-UP LIST (phase 5): emails that may sign in, each with the product role it
// receives the first time that address is proven in a session. While the ecosystem limits sign-in
// to a list of emails, this list IS that list: the backend mirrors every add and remove onto
// `login_allowed_emails`, so the Sign-up list pane replaces the old allow-list field.
//
// Wired to the backend's /v1/ecosystems/{id}/signup_list_entries: list (GET), add or change by
// email (POST, keyed on the address, so adding an address already listed changes its role), and
// remove (DELETE .../{entry_id}). A role already granted stays granted when its entry is removed.
//
// Hand-written wire types, as every client in this package (see ecosystems/wire.ts).

import { authedJson, authedRequest, listAllV1, unixToIso } from "../http";
import { enc, sortByText } from "../client-helpers";

export interface SignupListEntry {
  id: string;
  /** Trimmed and lower-cased by the backend. */
  email: string;
  /** The product role granted at the first proven session; null grants none. */
  roleId: string | null;
  /** The set granted at the first proven session; null grants none. */
  setId: string | null;
  createdAt: string;
  /** When the entry was applied; null while it waits. */
  grantedAt: string | null;
  grantedCustomerId: string | null;
}

/** Add or change one entry. The email is the key. */
export interface SignupListEntryInput {
  email: string;
  roleId?: string | null;
  setId?: string | null;
}

/** `/v1/ecosystems/{id}/signup_list_entries` row. */
interface SignupEntryWire {
  id: string;
  email: string;
  role_id: string | null;
  set_id: string | null;
  created: number;
  granted_at: string | null;
  granted_customer_id: string | null;
}

const toEntry = (r: SignupEntryWire): SignupListEntry => ({
  id: r.id,
  email: r.email,
  roleId: r.role_id,
  setId: r.set_id,
  createdAt: unixToIso(r.created),
  grantedAt: r.granted_at,
  grantedCustomerId: r.granted_customer_id,
});

const base = (ecoId: string): string => `/api/v1/ecosystems/${enc(ecoId)}/signup_list_entries`;

export const signupListApi = {
  /** Every entry, by email. */
  async list(ecoId: string): Promise<SignupListEntry[]> {
    const rows = await listAllV1<SignupEntryWire>(base(ecoId));
    return sortByText(rows.map(toEntry), (e) => e.email);
  },

  /** Add an email, or change the role or set of one already listed. */
  async put(ecoId: string, input: SignupListEntryInput): Promise<SignupListEntry> {
    const row = await authedJson<SignupEntryWire>(base(ecoId), {
      method: "POST",
      body: JSON.stringify({
        email: input.email,
        role_id: input.roleId ?? null,
        set_id: input.setId ?? null,
      }),
    });
    return toEntry(row);
  },

  /** Remove one entry. A role it already granted stays granted. */
  async remove(ecoId: string, entryId: string): Promise<void> {
    await authedRequest(`${base(ecoId)}/${enc(entryId)}`, { method: "DELETE" });
  },
};

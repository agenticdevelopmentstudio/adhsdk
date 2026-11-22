"use client";

// A product's ADMIN SITE (phase 6), for the product's managers at the hub: the host the
// product's own admins sign in at, and whether admin sites are switched on at all. The hub reads
// `enabled` and `site` together to decide which panes a product shows.
//
// Route: /api/v1/admin_site?ecosystem=<uuid>   read (GET), set up or move (POST; PUT inside),
//                                              take down (DELETE)
//
// A set-up is 409 when the product already has its own `admin-site` application or another
// product's site uses the host; the backend's message says which, and the pane shows it.

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { authedJson, authedRequest, unixToIso, withV1Query } from "../http";

export interface AdminSiteWire {
  id: string;
  host: string;
  application_id: string;
  client_id: string;
  created: number;
  updated: number;
}

export interface AdminSiteStateWire {
  site: AdminSiteWire | null;
  enabled: boolean;
}

export interface AdminSite {
  id: string;
  /** The lower-case host the site answers on. */
  host: string;
  /** The product's staff `admin-site` application. */
  applicationId: string;
  /** That application's login registration. */
  clientId: string;
  createdAt: string | null;
  updatedAt: string | null;
}

export interface AdminSiteState {
  site: AdminSite | null;
  /** Whether the `product_admin_site` switch is on. */
  enabled: boolean;
}

export const ADMIN_SITE_PATH = "/api/v1/admin_site";

export const toAdminSite = (w: AdminSiteWire): AdminSite => ({
  id: w.id,
  host: w.host,
  applicationId: w.application_id,
  clientId: w.client_id,
  createdAt: unixToIso(w.created),
  updatedAt: unixToIso(w.updated),
});

export const toAdminSiteState = (w: AdminSiteStateWire): AdminSiteState => ({
  site: w.site ? toAdminSite(w.site) : null,
  enabled: Boolean(w.enabled),
});

const url = (ecosystemId: string) => withV1Query(ADMIN_SITE_PATH, { ecosystem: ecosystemId });

export const adminSiteApi = {
  async get(ecosystemId: string): Promise<AdminSiteState> {
    return toAdminSiteState(await authedJson<AdminSiteStateWire>(url(ecosystemId)));
  },

  /** Set the site up at `host`, or move it there. */
  async put(ecosystemId: string, host: string): Promise<AdminSiteState> {
    return toAdminSiteState(
      await authedJson<AdminSiteStateWire>(url(ecosystemId), {
        method: "POST",
        body: JSON.stringify({ host }),
      }),
    );
  },

  async remove(ecosystemId: string): Promise<void> {
    await authedRequest(url(ecosystemId), { method: "DELETE" });
  },
};

// ── Hooks ─────────────────────────────────────────────────────────────────────

export const ADMIN_SITE_KEY = (ecosystemId: string) => ["product-admin", ecosystemId, "admin-site"] as const;

/** The product's admin site and the switch. Disabled until there is an id to ask about. */
export function useAdminSite(ecosystemId: string | null | undefined) {
  return useQuery({
    queryKey: ADMIN_SITE_KEY(ecosystemId ?? ""),
    queryFn: () => adminSiteApi.get(ecosystemId as string),
    enabled: Boolean(ecosystemId),
  });
}

/** Set up or move the site; writes the answer straight into the cache. */
export function usePutAdminSite(ecosystemId: string | null | undefined) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (host: string) => adminSiteApi.put(ecosystemId as string, host),
    onSuccess: (state) => {
      qc.setQueryData(ADMIN_SITE_KEY(ecosystemId ?? ""), state);
    },
  });
}

export function useRemoveAdminSite(ecosystemId: string | null | undefined) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: () => adminSiteApi.remove(ecosystemId as string),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ADMIN_SITE_KEY(ecosystemId ?? "") });
    },
  });
}

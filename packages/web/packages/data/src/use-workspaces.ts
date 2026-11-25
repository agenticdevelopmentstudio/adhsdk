"use client";

import { useEffect } from "react";
import { useQuery, type UseQueryResult } from "@tanstack/react-query";
import { getToolkitQueryClient } from "./query";
import {
  WORKSPACES_QUERY_KEY,
  onWorkspacesChanged,
  workspacesApi,
  type WorkspaceRow,
} from "./workspaces";

/**
 * Every workspace the caller can switch to, teams included ({@link workspacesApi.listAll}), cached
 * on the toolkit's query client under {@link WORKSPACES_QUERY_KEY}. Moved from the hub's own
 * `useWorkspaces`; a caller that wants fewer rows (a satellite: no teams) filters what this returns,
 * so there is one cache entry for the endpoint and one thing for a change to invalidate.
 *
 * SUBSCRIBED to {@link onWorkspacesChanged} by the act of reading. `notifyWorkspacesChanged`
 * already invalidates this client's entry directly, but only the copy of this module that sent it:
 * a host that bundles a second physical `@adh-sdk/data` has a second toolkit client, and the window
 * event is the one announcement every copy hears. Invalidating twice is harmless.
 *
 * `enabled` gates the authed request — pass the signed-in state, so it never fires on a public or
 * signed-out page. No retry: the menu shows the failure, and a second try only delays it.
 */
export function useWorkspaces(opts?: { enabled?: boolean }): UseQueryResult<WorkspaceRow[]> {
  const client = getToolkitQueryClient();
  useEffect(
    () =>
      onWorkspacesChanged(() => {
        void client.invalidateQueries({ queryKey: WORKSPACES_QUERY_KEY });
      }),
    [client],
  );
  return useQuery<WorkspaceRow[]>(
    {
      queryKey: WORKSPACES_QUERY_KEY,
      queryFn: () => workspacesApi.listAll(),
      enabled: opts?.enabled ?? true,
      retry: false,
    },
    client,
  );
}

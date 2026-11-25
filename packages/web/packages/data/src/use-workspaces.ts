"use client";

import { useEffect } from "react";
import { useQuery, type QueryClient, type UseQueryResult } from "@tanstack/react-query";
import { getToolkitQueryClient } from "./query";
import {
  WORKSPACE_ROWS_QUERY_KEY,
  onWorkspacesChangedElsewhere,
  workspacesApi,
  type WorkspaceRow,
} from "./workspaces";

/** One change-event subscription per query client, however many `useWorkspaces` readers are
 *  mounted on it: the header menu, the rail and a gate can all read at once, and a subscription
 *  each would sweep the one shared entry once per reader. Counted, so the last reader to unmount
 *  removes it. */
const subscriptions = new WeakMap<QueryClient, { readers: number; unsubscribe: () => void }>();

function subscribeRows(client: QueryClient): () => void {
  let held = subscriptions.get(client);
  if (!held) {
    held = {
      readers: 0,
      unsubscribe: onWorkspacesChangedElsewhere(() => {
        void client.invalidateQueries({ queryKey: WORKSPACE_ROWS_QUERY_KEY });
      }),
    };
    subscriptions.set(client, held);
  }
  held.readers += 1;
  const entry = held;
  return () => {
    entry.readers -= 1;
    if (entry.readers > 0) return;
    entry.unsubscribe();
    if (subscriptions.get(client) === entry) subscriptions.delete(client);
  };
}

/**
 * Every workspace the caller can switch to, teams included ({@link workspacesApi.listAll}), cached
 * on the toolkit's query client under {@link WORKSPACE_ROWS_QUERY_KEY}. Moved from the hub's own
 * `useWorkspaces`; a caller that wants fewer rows (a satellite: no teams) filters what this returns,
 * so every switcher shares one entry of all rows. (`workspacesApi.list()`'s owner subset is a
 * different shape and keeps its own key, {@link WORKSPACES_QUERY_KEY}.)
 *
 * SUBSCRIBED to the change event by the act of reading. `notifyWorkspacesChanged` already
 * invalidates this client's entry directly, but only the copy of this module that sent it: a host
 * that bundles a second physical `@adh-sdk/data` has a second toolkit client, and the window event
 * is the one announcement every copy hears. A second invalidation is NOT harmless: react-query's
 * `invalidateQueries` cancels the refetch in flight and starts another, so each extra sweep is an
 * extra request. So one change is one sweep per client: the subscription skips the events this copy
 * sent itself (its direct sweep already covered them), and it is held once per client, not once per
 * mounted reader.
 *
 * `enabled` gates the authed request — pass the signed-in state, so it never fires on a public or
 * signed-out page. No retry: the menu shows the failure, and a second try only delays it.
 */
export function useWorkspaces(opts?: { enabled?: boolean }): UseQueryResult<WorkspaceRow[]> {
  const client = getToolkitQueryClient();
  useEffect(() => subscribeRows(client), [client]);
  return useQuery<WorkspaceRow[]>(
    {
      queryKey: WORKSPACE_ROWS_QUERY_KEY,
      queryFn: () => workspacesApi.listAll(),
      enabled: opts?.enabled ?? true,
      retry: false,
    },
    client,
  );
}

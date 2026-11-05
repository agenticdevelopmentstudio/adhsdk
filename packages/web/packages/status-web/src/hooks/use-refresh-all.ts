"use client";
import { useCallback, useEffect } from "react";
import { useQueryClient, type Query } from "@tanstack/react-query";

/**
 * Queries that poll on their own `refetchInterval`, so the shared refresh leaves them alone:
 * refetching them here as well would double their load. `live` would double the provider
 * fan-out to two polls per minute per client (use-live-snapshot); the two dashboards each poll
 * at their own pace, faster while the backend is still filling them (use-dashboards).
 */
const SELF_POLLING = new Set(["live", "analytics-dashboard", "errors-dashboard"]);

/** Whether the shared refresh should refetch this query. */
export function refreshedTogether(query: Query): boolean {
  // Disabled queries are skipped: an observer with `enabled: false` (e.g. the board's
  // config-status while Settings isn't the topic) opted OUT of fetching — refetching it here
  // would undo that gate every 60s.
  return !SELF_POLLING.has(String(query.queryKey[0])) && !query.isDisabled();
}

/**
 * Refresh the supporting queries (uptime, integrations, response history, …)
 * together on one shared interval, so the dashboard never shows a mix of
 * fresh + stale datasets.
 *
 * Only ACTIVE queries, the ones something on screen is watching. An inactive one is cached for a
 * later visit, and refetching it would spend a backend call nobody reads and reset its gcTime,
 * so it would never be collected: every range a visitor ever opened would keep polling.
 */
export function useRefreshAll(intervalMs = 60_000): { refreshAll: () => void } {
  const queryClient = useQueryClient();
  const refreshAll = useCallback(() => {
    void queryClient.refetchQueries({ type: "active", predicate: refreshedTogether });
  }, [queryClient]);

  useEffect(() => {
    const id = setInterval(refreshAll, intervalMs);
    return () => clearInterval(id);
  }, [refreshAll, intervalMs]);

  return { refreshAll };
}

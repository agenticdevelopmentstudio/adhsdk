"use client";

import { useCallback, useState } from "react";
import { useResourceItemQuery, useResourceItemWriter } from "./use-resource-item";
import {
  readCachedWorkspace,
  workspacePrefsApi,
  writeCachedWorkspace,
  type WorkspacePrefs,
} from "./workspace-prefs";

/**
 * The preference row's identity in the shared item cache. A collection of exactly one member — the
 * signed-in caller's own row — so the id is a constant: `useTenantId` inside the item hook already
 * separates one signed-in caller from the next. Exported so every reader and writer of the row
 * (`/home`'s `useWorkspaceRoute`, the header's workspace menu) shares ONE entry; two keys would let
 * a pick in the header leave `/home` resolving the old preference from its cache.
 */
export const WORKSPACE_PREFS_CACHE_KEY = "workspace-prefs";
export const WORKSPACE_PREFS_ID = "me";

/** Module scope: the item hook holds `load` in a dependency array. */
export const loadWorkspacePrefs = (): Promise<WorkspacePrefs> => workspacePrefsApi.get();

export interface WorkspacePreference {
  /** The chosen slug: the server's row once read, the browser cache before that, null for a caller
   *  who has never chosen (or while signed out). Not validated against the caller's workspaces —
   *  the caller holds the list and decides what a slug that is not in it means. */
  slug: string | null;
  /** The server's answer is in — a row, `{}`, or a failure. */
  settled: boolean;
  /** Record `slug` as the family's workspace preference: the browser cache, the shared item cache
   *  and the server row, in that order, so this hook (and `/home`) show it at once. A failed PUT
   *  leaves the choice standing locally; it is retried by the next pick, not by this call. */
  choose: (slug: string) => void;
}

/**
 * The caller's cross-site workspace preference, read and written through the one shared cache entry
 * (see {@link WORKSPACE_PREFS_CACHE_KEY}). For a surface that RECORDS a choice without navigating —
 * a satellite's header workspace menu. `/home`'s route logic keeps its own, richer state machine
 * over the same entry.
 *
 * `enabled: false` (signed out) reads nothing and reports `slug: null`.
 */
export function useWorkspacePreference(opts?: { enabled?: boolean }): WorkspacePreference {
  const enabled = opts?.enabled ?? true;
  // The first paint does not wait on a round trip: the browser cache seeds it.
  const [cached, setCached] = useState<string | null>(() => readCachedWorkspace());
  const { item, error } = useResourceItemQuery<WorkspacePrefs>(
    WORKSPACE_PREFS_CACHE_KEY,
    enabled ? WORKSPACE_PREFS_ID : null,
    loadWorkspacePrefs,
  );
  const writePrefs = useResourceItemWriter<WorkspacePrefs>(WORKSPACE_PREFS_CACHE_KEY);
  const choose = useCallback(
    (slug: string) => {
      writeCachedWorkspace(slug);
      setCached(slug);
      writePrefs(WORKSPACE_PREFS_ID, { slug });
      workspacePrefsApi.put({ slug }).catch(() => {
        // Silent, deliberately: the caches already carry the choice.
      });
    },
    [writePrefs],
  );
  if (!enabled) return { slug: null, settled: false, choose };
  return {
    slug: item?.slug ?? (item === null ? cached : null),
    settled: item !== null || error !== null,
    choose,
  };
}

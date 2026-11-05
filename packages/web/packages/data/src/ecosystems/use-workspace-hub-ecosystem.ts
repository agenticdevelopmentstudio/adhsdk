"use client";

import { useQuery } from "@tanstack/react-query";
import { ecosystemsApi } from "./ecosystems";
import { useWorkspaceDefaultEcosystemId } from "./use-workspace-default-ecosystem";
import { useToolkitQueryClient } from "../query";
import { useTenantId } from "../tenant";

/**
 * The ecosystem a workspace's HUB DATA (Notes, Research, Documents, Integrations, Planning,
 * Storage) lives in: the workspace's live `personal` / `organization` child, else — for a user
 * or backend the move has not reached — the workspace's default (infrastructure) ecosystem, which
 * held that data before. The fallback is what keeps hub reads working through a rollout.
 *
 * `undefined` while either answer is still in flight (a caller must not act on it yet), `null` when
 * the workspace has neither. A failed child lookup falls back rather than failing: the default
 * ecosystem is the pre-move answer and still correct for anyone not yet moved.
 */
export function useWorkspaceHubEcosystemId(
  workspaceSlug: string | undefined,
): string | null | undefined {
  const tenantId = useTenantId();
  const client = useToolkitQueryClient();
  const hub = useQuery(
    {
      queryKey: ["workspace-hub-ecosystem", tenantId, workspaceSlug ?? null],
      queryFn: () =>
        workspaceSlug != null ? ecosystemsApi.hubDataEcosystemId(workspaceSlug) : null,
      retry: false,
    },
    client,
  );
  const fallback = useWorkspaceDefaultEcosystemId(workspaceSlug);
  if (hub.isPending) return undefined;
  if (hub.data) return hub.data;
  if (fallback.isPending) return undefined;
  return fallback.ecosystemId ?? null;
}

/**
 * {@link useWorkspaceDefaultEcosystemId}'s answer with `ecosystemId` swapped for the hub-data
 * ecosystem: the one scope shape a pane that binds to "where this owner's hub data lives" reads
 * (Storage, Integrations). The management flag and the error flags stay the workspace's, because
 * the hub-data child is the same principal's and has no permission rows of its own to read.
 *
 * `isPending` covers BOTH answers: the id is not final until the child lookup and the fallback
 * have each settled, so a caller that shows a "no ecosystem" notice must wait on this one.
 */
export function useWorkspaceHubScope(
  workspaceSlug: string | undefined,
): ReturnType<typeof useWorkspaceDefaultEcosystemId> {
  const hubId = useWorkspaceHubEcosystemId(workspaceSlug);
  const workspace = useWorkspaceDefaultEcosystemId(workspaceSlug);
  return {
    ...workspace,
    ecosystemId: hubId ?? undefined,
    isPending: hubId === undefined,
  };
}

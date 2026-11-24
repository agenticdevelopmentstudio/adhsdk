"use client";

import type { RequestBody, SuccessBody, components } from "@adh-sdk/adh-api-types";
import {
  useInfiniteQuery,
  useMutation,
  useQuery,
  useQueryClient,
} from "@tanstack/react-query";
import { authedJson, authedRequest, listAllV1 } from "./http";

// ── AI processing: config sets, nodes, logs, retention ──────────────────────
//
// Admin-gated reads and writes over `/v1/processing/*`. Plain functions at the `authedJson`
// boundary plus a key factory; the panes wrap them in react-query. Types are spec-derived so a
// backend change fails this file's tsc. No LLM key appears anywhere here: a node receives the
// provider key with each claimed job. The one secret this file handles is a worker token's raw value,
// which the backend returns once, on create, and never again.

export type ConfigSet = components["schemas"]["AiProcessingConfigSet"];
export type ConfigSetInput = RequestBody<"/v1/processing/config_sets", "post">;
export type ConfigSetParams = components["schemas"]["AiProcessingConfigSetParams"];
export type ProcessingNode = components["schemas"]["AiProcessingNode"];
export type NodeLog = components["schemas"]["AiProcessingNodeLog"];
export type NodeLogPage = components["schemas"]["AiProcessingNodeLogPage"];
export type LogLevel = NodeLog["level"];
export type ProcessingSettings = components["schemas"]["AiProcessingSettings"];
export type ConfigSetList = ConfigSet[];
export type NodeList = ProcessingNode[];
export type WorkerToken = components["schemas"]["AiProcessingWorkerToken"];
export type WorkerTokenInput = components["schemas"]["AiProcessingWorkerTokenInput"];
export type WorkerTokenList = WorkerToken[];
/** The create response: the listed token plus its raw value, shown this once. */
export type CreatedWorkerToken = SuccessBody<"/v1/processing/worker_tokens", "post", 201>;

export interface NodeLogQuery {
  level?: LogLevel;
  before?: number;
  limit?: number;
}

/** Every processing-admin read keys under this prefix (pinned fresh in AdminQueryProvider). */
export const PROCESSING_ADMIN_KEY = ["processing-admin"] as const;

export const processingKeys = {
  configSets: () => [...PROCESSING_ADMIN_KEY, "config-sets"] as const,
  nodes: () => [...PROCESSING_ADMIN_KEY, "nodes"] as const,
  node: (id: string) => [...PROCESSING_ADMIN_KEY, "node", id] as const,
  logs: (id: string, query: Omit<NodeLogQuery, "before"> = {}) =>
    [...PROCESSING_ADMIN_KEY, "logs", id, query] as const,
  settings: () => [...PROCESSING_ADMIN_KEY, "settings"] as const,
  workerTokens: () => [...PROCESSING_ADMIN_KEY, "worker-tokens"] as const,
};

const BASE = "/api/v1/processing";
const send = (method: string, body?: unknown): RequestInit => ({
  method,
  ...(body === undefined ? {} : { body: JSON.stringify(body) }),
});

export const listConfigSets = () => listAllV1<ConfigSet>(`${BASE}/config_sets`);
export const createConfigSet = (input: ConfigSetInput) =>
  authedJson<ConfigSet>(`${BASE}/config_sets`, send("POST", input));
export const updateConfigSet = (id: string, input: ConfigSetInput) =>
  authedJson<ConfigSet>(`${BASE}/config_sets/${encodeURIComponent(id)}`, send("POST", input));
export const deleteConfigSet = (id: string) =>
  authedRequest(`${BASE}/config_sets/${encodeURIComponent(id)}`, send("DELETE"));
export const setDefaultConfigSet = (id: string) =>
  authedJson<ConfigSet>(`${BASE}/config_sets/${encodeURIComponent(id)}/make_default`, send("POST"));
export const clearDefaultConfigSet = () =>
  authedRequest(`${BASE}/config_sets/default`, send("DELETE"));

export const listNodes = () => listAllV1<ProcessingNode>(`${BASE}/nodes`);
export const getNode = (id: string) =>
  authedJson<ProcessingNode>(`${BASE}/nodes/${encodeURIComponent(id)}`);
export const deleteNode = (id: string) =>
  authedRequest(`${BASE}/nodes/${encodeURIComponent(id)}`, send("DELETE"));

export function listNodeLogs(nodeId: string, query: NodeLogQuery = {}) {
  const params = new URLSearchParams();
  if (query.level) params.set("level", query.level);
  if (query.before !== undefined) params.set("before", String(query.before));
  if (query.limit !== undefined) params.set("limit", String(query.limit));
  const qs = params.toString();
  return authedJson<NodeLogPage>(
    `${BASE}/nodes/${encodeURIComponent(nodeId)}/logs${qs ? `?${qs}` : ""}`,
  );
}

export const getProcessingSettings = () => authedJson<ProcessingSettings>(`${BASE}/settings`);
export const putProcessingSettings = (settings: ProcessingSettings) =>
  authedJson<ProcessingSettings>(`${BASE}/settings`, send("POST", settings));

export const listWorkerTokens = () => listAllV1<WorkerToken>(`${BASE}/worker_tokens`);
export const createWorkerToken = (input: WorkerTokenInput) =>
  authedJson<CreatedWorkerToken>(`${BASE}/worker_tokens`, send("POST", input));
export const revokeWorkerToken = (id: string) =>
  authedRequest(`${BASE}/worker_tokens/${encodeURIComponent(id)}`, send("DELETE"));

// ── react-query hooks ───────────────────────────────────────────────────────

export const useConfigSets = () =>
  useQuery({
    queryKey: processingKeys.configSets(),
    queryFn: listConfigSets,
  });

/** Create (no `id`) or update (with `id`) one config set. */
export function useSaveConfigSet() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, input }: { id?: string; input: ConfigSetInput }) =>
      id ? updateConfigSet(id, input) : createConfigSet(input),
    onSuccess: () => qc.invalidateQueries({ queryKey: processingKeys.configSets() }),
  });
}

export function useDeleteConfigSet() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: deleteConfigSet,
    onSuccess: () => qc.invalidateQueries({ queryKey: processingKeys.configSets() }),
  });
}

export function useSetDefaultConfigSet() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: setDefaultConfigSet,
    onSuccess: () => qc.invalidateQueries({ queryKey: processingKeys.configSets() }),
  });
}

export function useClearDefaultConfigSet() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: clearDefaultConfigSet,
    onSuccess: () => qc.invalidateQueries({ queryKey: processingKeys.configSets() }),
  });
}

/** Nodes re-register every 60 s, so a 30 s poll keeps Online/Offline honest without a refresh. */
export const useNodes = () =>
  useQuery({
    queryKey: processingKeys.nodes(),
    queryFn: listNodes,
    refetchInterval: 30_000,
  });

export const NODE_LOG_PAGE_SIZE = 50;

/** One node's logs, newest first; each further page is the older entries after `nextBefore`. */
export const useNodeLogs = (nodeId: string, level?: LogLevel) =>
  useInfiniteQuery({
    queryKey: processingKeys.logs(nodeId, { level }),
    queryFn: ({ pageParam }) =>
      listNodeLogs(nodeId, { level, before: pageParam, limit: NODE_LOG_PAGE_SIZE }),
    initialPageParam: undefined as number | undefined,
    getNextPageParam: (page) => page.next_before ?? undefined,
  });

export function useDeleteNode() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: deleteNode,
    onSuccess: () => qc.invalidateQueries({ queryKey: processingKeys.nodes() }),
  });
}

export const useProcessingSettings = () =>
  useQuery({ queryKey: processingKeys.settings(), queryFn: getProcessingSettings });

export function usePutProcessingSettings() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: putProcessingSettings,
    onSuccess: () => qc.invalidateQueries({ queryKey: processingKeys.settings() }),
  });
}

export const useWorkerTokens = () =>
  useQuery({
    queryKey: processingKeys.workerTokens(),
    queryFn: listWorkerTokens,
  });

export function useCreateWorkerToken() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: createWorkerToken,
    onSuccess: () => qc.invalidateQueries({ queryKey: processingKeys.workerTokens() }),
  });
}

export function useRevokeWorkerToken() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: revokeWorkerToken,
    onSuccess: () => qc.invalidateQueries({ queryKey: processingKeys.workerTokens() }),
  });
}

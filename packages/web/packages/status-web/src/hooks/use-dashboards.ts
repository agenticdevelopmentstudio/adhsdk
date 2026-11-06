"use client";
import { keepPreviousData, useQuery, type UseQueryResult } from "@tanstack/react-query";
import { errorMessage, useStatusApi } from "../api/client";
import type {
  AnalyticsDashboardResponse,
  AnalyticsRange,
  ErrorsDashboardResponse,
} from "../telemetry/dashboard-types";

// Both dashboards answer at once with what the backend has and refresh behind the response, so a
// client watches them fill in: quick polls while `refreshing`, then at the board's usual pace.

const FILLING_POLL_MS = 5_000;
const SETTLED_POLL_MS = 60_000;

export function dashboardPollMs(data: { refreshing: boolean } | undefined): number {
  return data?.refreshing ? FILLING_POLL_MS : SETTLED_POLL_MS;
}

/**
 * The poll interval for a dashboard query. A failed read keeps the last body, and if that body
 * was taken mid-refresh it still says `refreshing`: judged by the body alone, a backend that has
 * started failing would be polled every 5s for as long as it fails. Nothing is filling in while
 * the read fails, so it goes back to the usual pace.
 */
function refetchMs(query: { state: { status: string; data?: { refreshing: boolean } } }): number {
  return query.state.status === "error" ? SETTLED_POLL_MS : dashboardPollMs(query.state.data);
}

type Api = ReturnType<typeof useStatusApi>;

async function getDashboard<T>(api: Api, path: string): Promise<T> {
  const response = await api.fetch(path);
  if (!response.ok) throw new Error((await errorMessage(response)) ?? `status ${response.status}`);
  return (await response.json()) as T;
}

export function useAnalyticsDashboard(
  range: AnalyticsRange,
  options?: { enabled?: boolean },
): UseQueryResult<AnalyticsDashboardResponse> {
  const api = useStatusApi();
  return useQuery<AnalyticsDashboardResponse>({
    queryKey: ["analytics-dashboard", range],
    enabled: options?.enabled ?? true,
    queryFn: () => getDashboard(api, `/analytics/dashboard?range=${range}`),
    // Keep the last chart up while another range loads, instead of flashing skeletons.
    placeholderData: keepPreviousData,
    refetchInterval: refetchMs,
    refetchOnWindowFocus: true,
  });
}

export function useErrorsDashboard(options?: { enabled?: boolean }): UseQueryResult<ErrorsDashboardResponse> {
  const api = useStatusApi();
  return useQuery<ErrorsDashboardResponse>({
    queryKey: ["errors-dashboard"],
    enabled: options?.enabled ?? true,
    queryFn: () => getDashboard(api, "/errors/dashboard"),
    refetchInterval: refetchMs,
    refetchOnWindowFocus: true,
  });
}

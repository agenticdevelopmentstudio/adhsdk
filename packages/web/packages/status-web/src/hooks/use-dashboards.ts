"use client";
import { keepPreviousData, useQuery, type UseQueryResult } from "@tanstack/react-query";
import { useStatusApi } from "../api/client";
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

type Api = ReturnType<typeof useStatusApi>;

async function getDashboard<T>(api: Api, path: string): Promise<T> {
  const response = await api.fetch(path);
  if (!response.ok) {
    const detail = await response
      .json()
      .then((body: { error?: string }) => body.error)
      .catch(() => null);
    throw new Error(detail || `status ${response.status}`);
  }
  return (await response.json()) as T;
}

export function useAnalyticsDashboard(range: AnalyticsRange): UseQueryResult<AnalyticsDashboardResponse> {
  const api = useStatusApi();
  return useQuery<AnalyticsDashboardResponse>({
    queryKey: ["analytics-dashboard", range],
    queryFn: () => getDashboard(api, `/analytics/dashboard?range=${range}`),
    // Keep the last chart up while another range loads, instead of flashing skeletons.
    placeholderData: keepPreviousData,
    refetchInterval: (query) => dashboardPollMs(query.state.data),
    refetchOnWindowFocus: true,
  });
}

export function useErrorsDashboard(): UseQueryResult<ErrorsDashboardResponse> {
  const api = useStatusApi();
  return useQuery<ErrorsDashboardResponse>({
    queryKey: ["errors-dashboard"],
    queryFn: () => getDashboard(api, "/errors/dashboard"),
    refetchInterval: (query) => dashboardPollMs(query.state.data),
    refetchOnWindowFocus: true,
  });
}

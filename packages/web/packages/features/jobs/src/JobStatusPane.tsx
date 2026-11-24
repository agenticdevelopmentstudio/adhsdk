"use client";

import { type ReactElement } from "react";
import { useInfiniteQuery } from "@tanstack/react-query";

import { jobStatusApi, jobsKeys, type JobRunStatusRow } from "@adh-sdk/data/jobs";
import { Button } from "@adh-sdk/ui/components/button";

import { JobsReadError, Loading, StatusBadge, formatTime } from "./job-ui";

export interface JobStatusPaneProps {
  /** The product's ecosystem. */
  ecosystemId: string;
}

/** How much of a run's error the table shows. */
const ERROR_PREVIEW = 80;

const preview = (s: string | null): string =>
  !s ? "" : s.length > ERROR_PREVIEW ? `${s.slice(0, ERROR_PREVIEW)}…` : s;

/**
 * The product admin's view of its customers' runs: status only. Each row is the job, its template,
 * its owner, the status, the error code and the first part of the error, and the times, newest
 * first, with Load more. It never reads a run's inputs, steps, outputs or logs.
 */
export function JobStatusPane({ ecosystemId }: JobStatusPaneProps): ReactElement {
  // Every loaded page in one query, so a refetch starts again from the newest run.
  const page = useInfiniteQuery({
    queryKey: jobsKeys.status(ecosystemId),
    queryFn: ({ pageParam }) => jobStatusApi.list(ecosystemId, { before: pageParam }),
    initialPageParam: undefined as string | undefined,
    getNextPageParam: (last) => last.nextBefore ?? undefined,
  });

  const rows: JobRunStatusRow[] = page.data?.pages.flatMap((p) => p.runs) ?? [];

  if (page.error && !page.data) {
    return <JobsReadError error={page.error} step="list-status" what="the run status" />;
  }
  if (page.isPending) return <Loading />;

  return (
    <div className="flex flex-col gap-3">
      <h2 className="text-sm font-medium text-apt-text">Job runs</h2>
      {rows.length === 0 ? (
        <p className="text-sm text-apt-text-muted">No customer runs yet.</p>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="text-xs text-apt-text-muted">
              <tr>
                <th className="px-2 py-1 font-normal">Job</th>
                <th className="px-2 py-1 font-normal">Template</th>
                <th className="px-2 py-1 font-normal">Owner</th>
                <th className="px-2 py-1 font-normal">Status</th>
                <th className="px-2 py-1 font-normal">Error</th>
                <th className="px-2 py-1 font-normal">Started</th>
                <th className="px-2 py-1 font-normal">Finished</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-apt-border">
              {rows.map((r) => (
                <tr key={r.runId}>
                  <td className="px-2 py-1 text-apt-text">{r.jobName}</td>
                  <td className="px-2 py-1 font-mono text-xs text-apt-text-muted">{r.templateKey ?? "Custom"}</td>
                  <td className="px-2 py-1 font-mono text-xs text-apt-text-muted">{r.ownerId}</td>
                  <td className="px-2 py-1">
                    <StatusBadge status={r.status} />
                  </td>
                  <td className="px-2 py-1 text-xs text-apt-text-muted">
                    {r.errorCode ? <span className="font-mono">{r.errorCode}</span> : null}
                    {r.error ? <span className="block">{preview(r.error)}</span> : null}
                  </td>
                  <td className="px-2 py-1 text-xs text-apt-text-muted">{formatTime(r.startedAt ?? r.createdAt)}</td>
                  <td className="px-2 py-1 text-xs text-apt-text-muted">{formatTime(r.finishedAt)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
      {/* A Load more that failed is reported under the rows already shown, never in their place. */}
      {page.error ? <JobsReadError error={page.error} step="list-status" what="more runs" /> : null}
      {page.hasNextPage ? (
        <div>
          <Button
            type="button"
            size="sm"
            variant="ghost"
            disabled={page.isFetching}
            onClick={() => void page.fetchNextPage()}
          >
            Load more
          </Button>
        </div>
      ) : null}
    </div>
  );
}

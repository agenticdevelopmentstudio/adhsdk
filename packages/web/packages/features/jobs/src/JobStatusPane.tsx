"use client";

import { useState, type ReactElement } from "react";
import { useQuery } from "@tanstack/react-query";

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
  const [before, setBefore] = useState<string | undefined>(undefined);
  const [older, setOlder] = useState<JobRunStatusRow[]>([]);
  const query = { before };
  const page = useQuery({
    queryKey: jobsKeys.status(ecosystemId, query),
    queryFn: () => jobStatusApi.list(ecosystemId, query),
  });

  const rows = before ? [...older, ...(page.data?.runs ?? [])] : (page.data?.runs ?? []);

  if (page.error) return <JobsReadError error={page.error} step="list-status" what="the run status" />;
  if (page.isPending && rows.length === 0) return <Loading />;

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
      {page.data?.nextBefore ? (
        <div>
          <Button
            type="button"
            size="sm"
            variant="ghost"
            disabled={page.isFetching}
            onClick={() => {
              setOlder(rows);
              setBefore(page.data?.nextBefore ?? undefined);
            }}
          >
            Load more
          </Button>
        </div>
      ) : null}
    </div>
  );
}

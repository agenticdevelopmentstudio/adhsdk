"use client";

import { useMemo } from "react";
import { Button } from "@adh-sdk/ui/components/button";
import { ErrorText } from "@adh-sdk/ui/components/error-text";
import { errorMessage } from "@adh-sdk/ui/lib/errors";
import {
  EditableList,
  useEditableList,
  type EditableListColumn,
} from "../components/editable-list";
import { formatRelativeTime } from "../llm-providers/sync-format";
import { deadJobTime, useDeadJobs, useRetryDeadJob, type DeadJob } from "../api/processing";

/**
 * The queue's dead rows across every ecosystem, newest death first, each with Retry. A row shows
 * its type, ecosystem, attempts, last error and when it died, never its payload (a step's payload
 * can hold a customer's prompt). A retry that succeeds takes the row out of the list; one that
 * fails is shown beside the list and the row stays.
 */
export function DeadJobs() {
  const dead = useDeadJobs();
  const retry = useRetryDeadJob();
  const { mutate, reset } = retry;
  const retryingId = retry.isPending ? retry.variables : undefined;

  const columns = useMemo<EditableListColumn<DeadJob>[]>(
    () => [
      {
        key: "jobType",
        header: "Type",
        width: "12rem",
        value: (j) => j.jobType,
        render: (j) => (
          <span className="block truncate font-mono text-xs font-medium text-apt-text" title={j.id}>
            {j.jobType}
          </span>
        ),
      },
      {
        key: "ecosystemId",
        header: "Ecosystem",
        width: "10rem",
        value: (j) => j.ecosystemId,
        render: (j) => (
          <span className="block truncate font-mono text-xs text-apt-text-muted" title={j.ecosystemId}>
            {j.ecosystemId}
          </span>
        ),
      },
      {
        key: "attempts",
        header: "Attempts",
        width: "6rem",
        align: "end",
        searchable: false,
        value: (j) => j.attempts,
        render: (j) => <span className="tabular-nums">{j.attempts}</span>,
      },
      {
        key: "lastError",
        header: "Last error",
        width: "minmax(0,1fr)",
        value: (j) => j.lastError ?? "",
        render: (j) =>
          j.lastError ? (
            <span className="block truncate text-apt-text" title={j.lastError}>
              {j.lastError}
            </span>
          ) : (
            <span className="text-apt-text-muted">—</span>
          ),
      },
      {
        key: "failedAt",
        header: "Died",
        width: "9rem",
        searchable: false,
        value: (j) => deadJobTime(j),
        render: (j) => <span title={j.failedAt}>{formatRelativeTime(j.failedAt)}</span>,
      },
      {
        key: "retry",
        header: <span className="sr-only">Retry</span>,
        width: "7rem",
        resizable: false,
        render: (j) => (
          <Button
            type="button"
            size="sm"
            variant="secondary"
            aria-label={`Retry ${j.jobType} ${j.id}`}
            disabled={retryingId === j.id}
            onClick={() => {
              reset();
              mutate(j.id);
            }}
          >
            {retryingId === j.id ? "Retrying…" : "Retry"}
          </Button>
        ),
      },
    ],
    // `retry` is a fresh object each render; the columns need only its pending id and its two
    // stable functions.
    [retryingId, mutate, reset],
  );

  const list = useEditableList<DeadJob>({
    rows: dead.data ?? [],
    getRowId: (j) => j.id,
    columns,
    initialSort: { key: "failedAt", dir: "desc" },
  });

  return (
    <section aria-label="Dead jobs" className="mb-6 flex flex-col gap-2">
      <h2 className="text-sm font-medium text-apt-text">Dead jobs</h2>
      <p className="max-w-2xl text-sm text-apt-text-muted">
        Queue rows that used up their attempts, from every product, newest first. Retry puts a row
        back on the queue with its attempts reset.
      </p>
      {retry.error && (
        <ErrorText error={`Couldn't retry that job: ${errorMessage(retry.error)}`} />
      )}
      <EditableList<DeadJob>
        list={list}
        ariaLabel="Dead jobs"
        loading={dead.isLoading}
        error={dead.error}
        errorTitle="Couldn't load dead jobs"
        columnWidthsKey="admin-ai-dead-jobs"
        describeRow={(j) => `${j.jobType} ${j.id}`}
        searchPlaceholder="Type, ecosystem or error"
        emptyLabel="No dead jobs."
        emptyFilteredLabel="No dead jobs match this search."
      />
    </section>
  );
}

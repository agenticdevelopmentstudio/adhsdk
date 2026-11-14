"use client";

import { useMemo, type ReactNode } from "react";
import { RotateCcw, Wifi, WifiOff } from "lucide-react";
import {
  schemaOf,
  type SyncTableEnrollment,
  type SyncTablesFamily,
} from "@adh-sdk/data/ecosystem-config";
import { useBatchRun } from "@adh-sdk/data/query";
import { DetailsPane, useReportBusy } from "@adh-sdk/resource";
import { Badge } from "@adh-sdk/ui/components/badge";
import { Button } from "@adh-sdk/ui/components/button";
import {
  EditableList,
  ProgressModal,
  useEditableList,
  type EditableListColumn,
  type EditableListFacet,
} from "@adh-sdk/ui/blocks";
import { useClearSyncOverride, useSetSyncOverride, useSyncTables } from "./sync-tables-hooks";

const NO_ROWS: SyncTableEnrollment[] = [];

/**
 * Which catalog tables one ecosystem syncs to offline clients, as one list: the schema is a
 * facet, and Sync / Don't sync / Reset to default act on the selection. Each decision overrides
 * the resource's code default; "Reset to default" drops the override.
 *
 * The editor is the list and its progress modal, with no chrome. It is shared by the admin
 * console, which wraps it with an ecosystem picker and calls the `"admin"` route family, and the
 * hub's {@link SyncTablesPane}, which calls the `"ecosystem"` family the ecosystem's managers may
 * use. Every write answers the full catalog, so the list always shows the server's state rather
 * than a hand-patched row.
 *
 * Mount it under a `key` of the ecosystem id: resource ids are the same catalog everywhere, so a
 * selection would otherwise SURVIVE a switch of ecosystem, and a bar button pressed afterwards
 * would write to an ecosystem whose state the user never looked at.
 */
export function SyncTablesEditor({
  ecosystemId,
  family = "ecosystem",
}: {
  ecosystemId: string;
  family?: SyncTablesFamily;
}) {
  const { data, isLoading, isFetching, error } = useSyncTables(family, ecosystemId);
  const setOverride = useSetSyncOverride(family, ecosystemId);
  const clearOverride = useClearSyncOverride(family, ecosystemId);
  const rows = data ?? NO_ROWS;
  useReportBusy(isFetching);

  const run = useBatchRun({ successMessage: "saved" });

  const columns = useMemo<EditableListColumn<SyncTableEnrollment>[]>(
    () => [
      {
        key: "resource",
        header: "Table",
        width: "minmax(0,1fr)",
        value: (row) => row.resource,
        render: (row) => (
          <span className="flex items-center gap-2">
            <span className="truncate font-mono text-sm text-apt-text">{row.resource}</span>
            {row.overridden && (
              <Badge variant="accent" title={`Default: ${syncedLabel(row.defaultEnabled)}`}>
                overridden
              </Badge>
            )}
          </span>
        ),
      },
      { key: "schema", header: "Schema", width: "11rem", value: schemaOf },
      { key: "scope", header: "Scope", width: "9rem", value: (row) => row.scope },
      { key: "pushMode", header: "Push", width: "7rem", value: (row) => row.pushMode },
      {
        key: "enabled",
        header: "Synced",
        width: "8rem",
        // Sorted and searched by the WORD, so the facet's ticks and a typed "not synced" find the
        // same rows the badge shows. A boolean would sort as "false" and "true".
        value: (row) => syncedLabel(row.enabled),
        render: (row) => (
          <Badge variant={row.enabled ? "success" : "neutral"}>{syncedLabel(row.enabled)}</Badge>
        ),
      },
      {
        key: "defaultEnabled",
        header: "Default",
        width: "8rem",
        value: (row) => syncedLabel(row.defaultEnabled),
        render: (row) => (
          <span className="text-xs text-apt-text-dim">{syncedLabel(row.defaultEnabled)}</span>
        ),
      },
    ],
    [],
  );

  const facets = useMemo<EditableListFacet<SyncTableEnrollment>[]>(
    () => [
      { id: "schema", label: "Schema", valuesOf: (row) => [schemaOf(row)] },
      { id: "synced", label: "Synced", valuesOf: (row) => [syncedLabel(row.enabled)] },
      {
        id: "overridden",
        label: "Override",
        valuesOf: (row) => [row.overridden ? "overridden" : "default"],
      },
    ],
    [],
  );

  const list = useEditableList<SyncTableEnrollment>({
    rows,
    getRowId: (row) => row.resource,
    columns,
    facets,
    initialSort: { key: "resource", dir: "asc" },
  });

  const selected = list.selectedRows;

  /**
   * Enrol (or un-enrol) the selection, skipping every row already in that state.
   *
   * A no-op write stores a real override row: a resource that merely INHERITS "synced" would come
   * back marked `overridden`, pinning it against a later change to the code default. That is a
   * silent, lasting difference, which is why the skip is not just about the count.
   */
  const setSynced = (enabled: boolean) => {
    const changing = selected.filter((row) => row.enabled !== enabled);
    void run.run(
      changing.map((row) => ({ id: row.resource, label: row.resource })),
      (item) => setOverride.mutateAsync({ resource: item.id, enabled }),
    );
  };

  const resetToDefault = () => {
    const overridden = selected.filter((row) => row.overridden);
    void run.run(
      overridden.map((row) => ({ id: row.resource, label: row.resource })),
      (item) => clearOverride.mutateAsync(item.id),
    );
  };

  const wouldSet = (enabled: boolean) => selected.some((row) => row.enabled !== enabled);
  const anyOverridden = selected.some((row) => row.overridden);

  return (
    <>
      <EditableList<SyncTableEnrollment>
        list={list}
        ariaLabel="Sync tables"
        loading={isLoading}
        // Distinct from the list's own empty state — a failed load must NOT read as
        // "No catalog tables."
        error={error}
        errorTitle="Couldn't load sync tables"
        columnWidthsKey={`${family}-sync-tables`}
        // The resource IS the row id, so the table's own guess skips it and lands on `scope` —
        // where every row says "owner" or "ecosystem" and no two checkboxes can be told apart.
        describeRow={(row) => row.resource}
        searchPlaceholder="Table or schema"
        emptyLabel="No catalog tables."
        emptyFilteredLabel="No tables match these filters."
        actions={
          <>
            <Button
              size="sm"
              variant="ghost"
              disabled={!wouldSet(true)}
              onClick={() => setSynced(true)}
            >
              <Wifi data-icon="inline-start" />
              Sync
            </Button>
            <Button
              size="sm"
              variant="ghost"
              disabled={!wouldSet(false)}
              onClick={() => setSynced(false)}
            >
              <WifiOff data-icon="inline-start" />
              Don&apos;t sync
            </Button>
            {/* Only overridden rows have anything to clear; a selection of pure defaults leaves
                this dead rather than firing DELETEs that would each no-op. */}
            <Button size="sm" variant="ghost" disabled={!anyOverridden} onClick={resetToDefault}>
              <RotateCcw data-icon="inline-start" />
              Reset to default
            </Button>
          </>
        }
      />

      <ProgressModal
        open={run.state.running || run.state.finished}
        title="Saving sync enrollment"
        description="Each table is saved on its own; a failure leaves the earlier saves in place."
        total={run.state.total}
        done={run.state.done}
        currentLabel={run.state.currentLabel}
        error={run.state.error}
        results={run.state.results}
        finished={run.state.finished}
        onContinue={run.continueRun}
        onStop={run.stop}
        onClose={() => {
          run.reset();
          list.clearSelection();
        }}
      />
    </>
  );
}

/**
 * The hub's SYNC pane: an ecosystem's managers (its owner, or an admin of the organization that
 * holds it) choose which tables their apps sync, through the `"ecosystem"` route family.
 */
export function SyncTablesPane({
  ecosystemId,
  help,
}: {
  ecosystemId?: string;
  /** Unused: the breadcrumb names the pane (kept for the ScopedPane prop shape). */
  title?: ReactNode;
  help?: ReactNode;
}) {
  return (
    <DetailsPane
      help={help}
      api={{
        path: "/ecosystem/sync-tables/{id}",
        pathValues: { id: ecosystemId },
        title: "Sync tables API",
      }}
      bodyClassName="px-6 py-6"
    >
      <p className="mb-6 max-w-2xl text-sm text-apt-text-muted">
        Choose which tables your apps sync for offline use. Syncing a table overrides its default
        for this ecosystem; &ldquo;Reset to default&rdquo; removes the override. Syncing a table
        never shows anyone rows they could not already read.
      </p>
      {ecosystemId && <SyncTablesEditor key={ecosystemId} ecosystemId={ecosystemId} />}
    </DetailsPane>
  );
}

/** "synced" / "not synced" — the words the badge, the facet and the search box all share. */
function syncedLabel(enabled: boolean): string {
  return enabled ? "synced" : "not synced";
}

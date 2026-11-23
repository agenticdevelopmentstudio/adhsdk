"use client";

import { useState } from "react";
import { useQuery } from "@tanstack/react-query";

import {
  SUPPORT_CONTENT_TABLES,
  supportAdminApi,
  useSupportData,
} from "@adh-sdk/data/support";
import { Button } from "@adh-sdk/ui/components/button";
import { ErrorText } from "@adh-sdk/ui/components/error-text";
import { Label } from "@adh-sdk/ui/components/label";
import { Select } from "@adh-sdk/ui/components/select";

/** The longest a cell shows before it is cut; the row view shows the whole value. */
const CELL_MAX = 80;

/** A value as plain text: strings as they are, everything else as JSON. */
function asText(v: unknown): string {
  if (v === null || v === undefined) return "";
  if (typeof v === "string") return v;
  try {
    return JSON.stringify(v);
  } catch {
    return String(v);
  }
}

const cut = (s: string) => (s.length > CELL_MAX ? `${s.slice(0, CELL_MAX - 1)}…` : s);

/** A row's single-row key: its `id` when it has one. A table keyed otherwise (`sync.push_ops`,
 *  keyed by owner and op) has no single-row read, so its rows show in the table only. */
function rowKey(row: Record<string, unknown>): string | null {
  const id = row.id;
  return typeof id === "string" || typeof id === "number" ? String(id) : null;
}

/** Why a read failed, in words: a 404 is a table the grant cannot read, a 403 an ended grant. */
function readError(err: unknown): string {
  const status = (err as { status?: unknown } | null)?.status;
  if (status === 404) return "This table cannot be read under a support grant.";
  if (status === 403) return "This grant is no longer live.";
  return err instanceof Error && err.message ? err.message : "Something went wrong.";
}

function columnsOf(rows: readonly Record<string, unknown>[]): string[] {
  const seen = new Set<string>();
  for (const r of rows) for (const k of Object.keys(r)) seen.add(k);
  return [...seen];
}

/** One row, read through the grant and shown as text. */
function RowView({
  grantId,
  schema,
  table,
  rowId,
  onClose,
}: {
  grantId: string;
  schema: string;
  table: string;
  rowId: string;
  onClose: () => void;
}) {
  const row = useQuery({
    queryKey: ["support", "admin", "row", grantId, schema, table, rowId],
    queryFn: () => supportAdminApi.row(grantId, schema, table, rowId),
    retry: false,
  });
  return (
    <section aria-label={`Row ${rowId}`} className="flex flex-col gap-2 rounded-md border border-apt-border p-3">
      <div className="flex items-center justify-between gap-2">
        <span className="font-mono text-xs text-apt-text-muted">{rowId}</span>
        <Button size="sm" variant="ghost" onClick={onClose}>
          Close row
        </Button>
      </div>
      {row.isLoading && <p className="text-sm text-apt-text-muted">Loading…</p>}
      {row.error && <ErrorText error={readError(row.error)} />}
      {row.data && (
        <pre className="max-h-96 overflow-auto whitespace-pre-wrap break-all font-mono text-xs text-apt-text">
          {JSON.stringify(row.data, null, 2)}
        </pre>
      )}
    </section>
  );
}

/**
 * The read-only viewer a product admin opens on a live grant: pick one of the customer's content
 * tables, page through its rows newest first, and open one row. It reads and never writes: there
 * is no field to change and no save, and the backend answers any write on these paths 405. The
 * rows stay in memory only. A table the backend refuses (404) or a grant that has ended (403)
 * shows the reason in place.
 */
export function SupportViewer({ grantId }: { grantId: string }) {
  const [qualified, setQualified] = useState("");
  // The cursors of the pages before this one, so Previous can step back.
  const [cursors, setCursors] = useState<string[]>([]);
  const [openRow, setOpenRow] = useState<string | null>(null);

  const [schema, table] = qualified ? (qualified.split(".") as [string, string]) : [null, null];
  const cursor = cursors.length > 0 ? cursors[cursors.length - 1] : undefined;
  const page = useSupportData(grantId, schema, table, cursor);
  const rows = page.data?.rows ?? [];
  const columns = columnsOf(rows);

  const pick = (next: string) => {
    setQualified(next);
    setCursors([]);
    setOpenRow(null);
  };

  return (
    <section aria-label="Customer content" className="flex flex-col gap-3">
      <div className="flex flex-col gap-1">
        <Label htmlFor={`support-table-${grantId}`}>Table</Label>
        <Select id={`support-table-${grantId}`} value={qualified} onChange={(e) => pick(e.target.value)}>
          <option value="">Choose a table</option>
          {SUPPORT_CONTENT_TABLES.map((t) => (
            <option key={t} value={t}>
              {t}
            </option>
          ))}
        </Select>
      </div>

      {page.isLoading && <p className="text-sm text-apt-text-muted">Loading…</p>}
      {page.error && <ErrorText error={readError(page.error)} />}

      {schema && table && page.data && rows.length === 0 && (
        <p className="text-sm text-apt-text-muted">No rows.</p>
      )}

      {rows.length > 0 && (
        <div className="overflow-x-auto">
          <table className="w-full border-collapse text-left text-xs">
            <thead>
              <tr>
                <th className="px-2 py-1" aria-label="Open" />
                {columns.map((c) => (
                  <th key={c} className="px-2 py-1 font-mono text-apt-text-muted">
                    {c}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {rows.map((r, i) => {
                const key = rowKey(r);
                return (
                  <tr key={key ?? i} className="border-t border-apt-border">
                    <td className="px-2 py-1">
                      {key !== null && (
                        <Button size="xs" variant="ghost" aria-label={`Open row ${key}`} onClick={() => setOpenRow(key)}>
                          Open
                        </Button>
                      )}
                    </td>
                    {columns.map((c) => (
                      <td key={c} className="px-2 py-1 font-mono text-apt-text">
                        {cut(asText(r[c]))}
                      </td>
                    ))}
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}

      {page.data?.hasMore && !page.data.nextCursor && (
        <p className="text-sm text-apt-text-muted" role="note">
          This table has more rows than the viewer can page through, because its rows have no id.
        </p>
      )}

      {(cursors.length > 0 || page.data?.nextCursor) && (
        <div className="flex items-center gap-2">
          <Button
            size="sm"
            variant="ghost"
            disabled={cursors.length === 0}
            onClick={() => setCursors((c) => c.slice(0, -1))}
          >
            Previous
          </Button>
          <Button
            size="sm"
            variant="ghost"
            disabled={!page.data?.nextCursor}
            onClick={() => {
              const next = page.data?.nextCursor;
              if (next) setCursors((c) => [...c, next]);
            }}
          >
            Next
          </Button>
        </div>
      )}

      {schema && table && openRow && (
        <RowView grantId={grantId} schema={schema} table={table} rowId={openRow} onClose={() => setOpenRow(null)} />
      )}
    </section>
  );
}

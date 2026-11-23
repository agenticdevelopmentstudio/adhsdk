"use client";

import { useState, type FormEvent, type ReactElement, type ReactNode } from "react";

import { FeatureTitle } from "@adh-sdk/resource";
import { isSupportOff, useOperatorSupportAccess } from "@adh-sdk/data/support";
import { Button } from "@adh-sdk/ui/components/button";
import { ErrorText } from "@adh-sdk/ui/components/error-text";
import { Input } from "@adh-sdk/ui/components/input";
import { Label } from "@adh-sdk/ui/components/label";

import { formatDateTime } from "../lib/timestamps";
import { isUuidText, supportRefusalText } from "./supportTarget";

/**
 * The support read log, for an operator (phase 7): every read made under one grant, newest first,
 * with its time, method and path. The backend reads it one grant at a time, so the pane asks for
 * the grant id first. While the backend's `consented_access` switch is off it answers 404 and the
 * pane says so.
 */
export function SupportAccessLogPane({ help }: { help?: ReactNode } = {}): ReactElement {
  const [draft, setDraft] = useState("");
  const [draftError, setDraftError] = useState<string | null>(null);
  const [grantId, setGrantId] = useState<string | undefined>(undefined);
  const [cursors, setCursors] = useState<string[]>([]);
  const cursor = cursors.length > 0 ? cursors[cursors.length - 1] : undefined;
  const log = useOperatorSupportAccess({ grantId, cursor });
  const rows = log.data?.items ?? [];

  const apply = (e: FormEvent) => {
    e.preventDefault();
    if (!isUuidText(draft)) {
      setDraftError("The grant id must be a uuid.");
      return;
    }
    setDraftError(null);
    setCursors([]);
    setGrantId(draft.trim().toLowerCase());
  };

  return (
    <div className="flex min-h-0 min-w-0 flex-1 flex-col">
      <FeatureTitle title="Support Access Log" help={help} />
      <div className="flex min-h-0 min-w-0 flex-1 flex-col gap-4 overflow-y-auto px-6 pb-8 pt-2">
        <form aria-label="Filter by grant" noValidate onSubmit={apply} className="flex flex-wrap items-end gap-3">
          <div className="flex min-w-80 flex-col gap-1">
            <Label htmlFor="support-access-grant">Grant id</Label>
            <Input
              id="support-access-grant"
              value={draft}
              placeholder="uuid"
              onChange={(e) => setDraft(e.target.value)}
            />
          </div>
          <Button type="submit">Show reads</Button>
        </form>
        <ErrorText error={draftError} />

        {!grantId && <p className="text-sm text-apt-text-muted">Enter a grant id to see the reads made under it.</p>}
        {log.error && isSupportOff(log.error) && (
          <p className="text-sm text-apt-text-muted">Support access is not turned on, or there is no such grant.</p>
        )}
        {log.error && !isSupportOff(log.error) && <ErrorText error={supportRefusalText(log.error)} />}
        {log.isLoading && <p className="text-sm text-apt-text-muted">Loading…</p>}
        {grantId && log.data && rows.length === 0 && (
          <p className="text-sm text-apt-text-muted">No reads under this grant.</p>
        )}

        {rows.length > 0 && (
          <table aria-label="Reads" className="w-full border-collapse text-left text-sm">
            <thead>
              <tr className="text-xs text-apt-text-muted">
                <th className="px-2 py-1">When</th>
                <th className="px-2 py-1">Method</th>
                <th className="px-2 py-1">Path</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((r) => (
                <tr key={r.id} className="border-t border-apt-border">
                  <td className="whitespace-nowrap px-2 py-1">{formatDateTime(r.at)}</td>
                  <td className="px-2 py-1 font-mono">{r.method ?? ""}</td>
                  <td className="break-all px-2 py-1 font-mono">{r.path}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}

        {(cursors.length > 0 || log.data?.nextCursor) && (
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
              disabled={!log.data?.nextCursor}
              onClick={() => {
                const next = log.data?.nextCursor;
                if (next) setCursors((c) => [...c, next]);
              }}
            >
              Next
            </Button>
          </div>
        )}
      </div>
    </div>
  );
}

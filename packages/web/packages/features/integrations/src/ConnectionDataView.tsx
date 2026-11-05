"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { integrationsApi, type ConnectionDataResource } from "@adh-sdk/data/integrations";
import { errMsg } from "@adh-sdk/data";
import { Button } from "@adh-sdk/ui/components/button";
import { ErrorText } from "@adh-sdk/ui/components/error-text";

/** The columns shown per resource, in order. Read-only: the data route has no writes. */
export const CONNECTION_DATA_COLUMNS: Record<ConnectionDataResource, string[]> = {
  "social-posts": ["body", "url", "likeCount", "replyCount", "repostCount", "externalCreatedAt"],
  "social-notifications": ["notificationType", "title", "authorHandle", "isRead", "externalCreatedAt"],
  "media-items": ["title", "mediaType", "mimeType", "takenAt", "externalUrl"],
  "media-albums": ["title", "itemCount", "externalUrl"],
  "email-labels": ["name", "type", "messagesTotal", "messagesUnread"],
};

const MAX_CELL_CHARS = 80;

export function dataCellText(value: unknown): string {
  if (value == null) return "—";
  const text = typeof value === "string" ? value : JSON.stringify(value);
  return text.length > MAX_CELL_CHARS ? `${text.slice(0, MAX_CELL_CHARS)}…` : text;
}

/** One connection's synced rows for one resource, paged by the route's `nextCursor`. */
export function ConnectionDataView({
  connectionId,
  resource,
}: {
  connectionId: string;
  resource: ConnectionDataResource;
}) {
  const [rows, setRows] = useState<Array<Record<string, unknown>>>([]);
  const [nextCursor, setNextCursor] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  // Guards a response that lands after the connection/resource changed or the view unmounted.
  const generation = useRef(0);

  const loadPage = useCallback(
    async (cursor: string | null, replace: boolean) => {
      const mine = ++generation.current;
      setLoading(true);
      setError(null);
      try {
        const page = await integrationsApi.getConnectionData(connectionId, resource, { cursor });
        if (mine !== generation.current) return;
        setRows((prev) => (replace ? page.rows : [...prev, ...page.rows]));
        setNextCursor(page.nextCursor);
      } catch (err) {
        if (mine !== generation.current) return;
        setError(errMsg(err, "Couldn't load synced data."));
      } finally {
        if (mine === generation.current) setLoading(false);
      }
    },
    [connectionId, resource],
  );

  useEffect(() => {
    void loadPage(null, true);
    return () => {
      generation.current++;
    };
  }, [loadPage]);

  const columns = CONNECTION_DATA_COLUMNS[resource];
  return (
    <div className="flex min-w-0 flex-col gap-3">
      <span className="font-mono text-[0.7rem] text-apt-text-dim">
        {loading && rows.length === 0
          ? "Loading…"
          : `${rows.length} row${rows.length === 1 ? "" : "s"}${nextCursor ? "+" : ""}`}
      </span>
      <ErrorText error={error} />
      {rows.length > 0 && (
        <div className="min-w-0 overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead>
              <tr className="text-apt-text-muted">
                {columns.map((c) => (
                  <th key={c} className="px-2 py-1 font-medium">
                    {c}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {rows.map((row, i) => (
                <tr key={String(row.id ?? i)} className="border-t border-apt-border">
                  {columns.map((c) => (
                    <td key={c} className="px-2 py-1 align-top text-apt-text">
                      {dataCellText(row[c])}
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
      {nextCursor && (
        <div>
          <Button
            variant="ghost"
            size="sm"
            disabled={loading}
            onClick={() => void loadPage(nextCursor, false)}
          >
            {loading ? "Loading…" : "Load more"}
          </Button>
        </div>
      )}
    </div>
  );
}

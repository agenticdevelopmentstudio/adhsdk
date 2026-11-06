import { createHash } from "node:crypto";
import type { RuntimeErrorsStore } from "../storage/ports";
import type { RuntimeErrorGroup, RuntimeErrorsReport, RuntimeLogEntry } from "./types";

// The rules for Vercel runtime errors, kept apart from the fetcher (network) and the store (SQL)
// so each is testable alone: which log lines count, how they group, how a re-read is told apart
// from new lines, and how the report is ordered. The store and the route both call these, so
// there is one copy of each rule.

/** How long a group lives after it was last seen. */
export const RUNTIME_ERROR_RETENTION_MS = 7 * 24 * 60 * 60_000;
/** The window `GET /errors/runtime` reports. */
export const RUNTIME_ERROR_WINDOW_MS = 24 * 60 * 60_000;
/** At most this many groups in a report; `total` still counts them all. */
export const RUNTIME_ERROR_REPORT_CAP = 200;
const MESSAGE_MAX = 200;

/** Vercel's log levels, worst first. The store's SQL ranks levels from this same list. */
export const RUNTIME_LEVELS = ["fatal", "error", "warning", "info", "debug", "trace"] as const;
const LEVEL_RANK: Record<string, number> = Object.fromEntries(
  RUNTIME_LEVELS.map((level, i) => [level, RUNTIME_LEVELS.length - 1 - i]),
);

/** Higher is worse. An unknown level sorts below every known one. */
export function levelRank(level: string | null | undefined): number {
  return LEVEL_RANK[level ?? ""] ?? -1;
}

/** The worse of two levels. */
export function worseLevel(a: string, b: string): string {
  return levelRank(b) > levelRank(a) ? b : a;
}

/** One raw line of the runtime-logs stream, as Vercel sends it. */
export interface RawRuntimeLog {
  level?: unknown;
  message?: unknown;
  requestMethod?: unknown;
  requestPath?: unknown;
  responseStatusCode?: unknown;
  rowId?: unknown;
  source?: unknown;
  timestampInMs?: unknown;
  domain?: unknown;
}

const str = (v: unknown): string | null => (typeof v === "string" && v !== "" ? v : null);
const num = (v: unknown): number | null => (typeof v === "number" && Number.isFinite(v) ? v : null);

/**
 * The line as an entry, or null if it is not an error worth keeping: an `error`/`fatal` line, or
 * any line that answered 5xx. A line without a `rowId` or timestamp is dropped too, since it could
 * never be counted exactly once.
 */
export function toRuntimeEntry(
  raw: RawRuntimeLog,
  at: { project: string; deploymentId: string; domain: string | null },
): RuntimeLogEntry | null {
  const level = str(raw.level) ?? "info";
  const status = num(raw.responseStatusCode);
  if (level !== "error" && level !== "fatal" && !(status !== null && status >= 500)) return null;
  const rowId = str(raw.rowId);
  const timestampMs = num(raw.timestampInMs);
  if (rowId === null || timestampMs === null) return null;
  const path = str(raw.requestPath);
  return {
    project: at.project,
    deploymentId: at.deploymentId,
    domain: str(raw.domain) ?? at.domain,
    rowId,
    timestampMs,
    level,
    source: str(raw.source) ?? "unknown",
    method: str(raw.requestMethod),
    path: path === null ? null : path.split(/[?#]/)[0] || "/",
    status: status !== null && status > 0 ? status : null,
    message: typeof raw.message === "string" ? raw.message : "",
  };
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const HEX = /^[0-9a-f]{12,}$/i;

function isIdSegment(seg: string): boolean {
  if (/^\d+$/.test(seg) || UUID.test(seg)) return true;
  if (HEX.test(seg) && /\d/.test(seg)) return true;
  // A long token mixing letters and digits (a base64/nanoid id or a content hash).
  return seg.length >= 20 && /^[A-Za-z0-9_-]+$/.test(seg) && /\d/.test(seg) && /[A-Za-z]/.test(seg);
}

/** `/posts/123/edit` and `/posts/456/edit` are one route: id-like segments read `:id`. */
export function normalizePath(path: string | null): string | null {
  if (path === null) return null;
  return path
    .split("/")
    .map((seg) => (seg !== "" && isIdSegment(seg) ? ":id" : seg))
    .join("/");
}

/** The first line of a message, at most 200 characters. */
export function messageHead(message: string): string {
  return (message.split(/\r?\n/)[0] ?? "").trim().slice(0, MESSAGE_MAX);
}

/** The grouping fields of an entry, and their stable hash. */
export function groupIdentity(e: RuntimeLogEntry): {
  key: string;
  path: string | null;
  message: string;
} {
  const path = normalizePath(e.path);
  const message = messageHead(e.message);
  const key = createHash("sha256")
    .update(JSON.stringify([e.project, e.source, e.method, path, e.status, message]))
    .digest("hex")
    .slice(0, 32);
  return { key, path, message };
}

/**
 * Where reading a deployment's stream got to: the newest timestamp counted, and the rowIds
 * counted AT that timestamp (several lines can share a millisecond).
 */
export interface RuntimeCursor {
  lastTimestampMs: number;
  lastRowIds: string[];
}

/**
 * The entries a re-read has not counted yet. Anything older than the cursor was counted, and so
 * was anything at its timestamp whose rowId it holds. Duplicate rowIds within the batch count
 * once.
 */
export function unseenEntries(entries: RuntimeLogEntry[], cursor: RuntimeCursor | undefined): RuntimeLogEntry[] {
  const seenAtEdge = new Set(cursor?.lastRowIds ?? []);
  const inBatch = new Set<string>();
  return entries.filter((e) => {
    if (cursor && e.timestampMs < cursor.lastTimestampMs) return false;
    if (cursor && e.timestampMs === cursor.lastTimestampMs && seenAtEdge.has(e.rowId)) return false;
    if (inBatch.has(e.rowId)) return false;
    inBatch.add(e.rowId);
    return true;
  });
}

/** The cursor after counting `entries` on top of `prev`. */
export function advanceCursor(prev: RuntimeCursor | undefined, entries: RuntimeLogEntry[]): RuntimeCursor | undefined {
  let ts = prev?.lastTimestampMs ?? -Infinity;
  let ids = new Set(prev?.lastRowIds ?? []);
  for (const e of entries) {
    if (e.timestampMs > ts) {
      ts = e.timestampMs;
      ids = new Set([e.rowId]);
    } else if (e.timestampMs === ts) ids.add(e.rowId);
  }
  return ts === -Infinity ? prev : { lastTimestampMs: ts, lastRowIds: [...ids] };
}

/** What one batch adds to each group: the store merges this into what it holds. */
export type RuntimeGroupDelta = Omit<RuntimeErrorGroup, "firstSeen" | "lastSeen"> & {
  firstSeenMs: number;
  lastSeenMs: number;
};

/** Fold entries into per-group deltas. The newest line supplies deployment, domain and sample. */
export function groupRuntimeEntries(entries: RuntimeLogEntry[]): RuntimeGroupDelta[] {
  const groups = new Map<string, RuntimeGroupDelta>();
  for (const e of entries) {
    const { key, path, message } = groupIdentity(e);
    const g = groups.get(key);
    if (!g) {
      groups.set(key, {
        key,
        project: e.project,
        deploymentId: e.deploymentId,
        domain: e.domain,
        source: e.source,
        method: e.method,
        path,
        status: e.status,
        level: e.level,
        message,
        count: 1,
        firstSeenMs: e.timestampMs,
        lastSeenMs: e.timestampMs,
        sampleRowId: e.rowId,
      });
      continue;
    }
    g.count++;
    g.level = worseLevel(g.level, e.level);
    g.firstSeenMs = Math.min(g.firstSeenMs, e.timestampMs);
    if (e.timestampMs >= g.lastSeenMs) {
      g.lastSeenMs = e.timestampMs;
      g.deploymentId = e.deploymentId;
      g.domain = e.domain ?? g.domain;
      g.sampleRowId = e.rowId;
    }
  }
  return [...groups.values()];
}

/** Report order: worst level first, then most frequent, then most recent. */
export function compareRuntimeGroups(a: RuntimeErrorGroup, b: RuntimeErrorGroup): number {
  return (
    levelRank(b.level) - levelRank(a.level) ||
    b.count - a.count ||
    b.lastSeen.localeCompare(a.lastSeen) ||
    a.key.localeCompare(b.key)
  );
}

/** The 24h report over stored groups (any order, any age). */
export function runtimeErrorsReport(groups: RuntimeErrorGroup[], nowMs: number): RuntimeErrorsReport {
  const since = nowMs - RUNTIME_ERROR_WINDOW_MS;
  const inWindow = groups.filter((g) => Date.parse(g.lastSeen) >= since).sort(compareRuntimeGroups);
  return {
    generatedAt: new Date(nowMs).toISOString(),
    window: "24h",
    total: inWindow.length,
    groups: inWindow.slice(0, RUNTIME_ERROR_REPORT_CAP),
  };
}

/** The 24h report, read from the store: what `GET /errors/runtime` and the dashboard serve. */
export async function loadRuntimeErrorsReport(
  store: Pick<RuntimeErrorsStore, "load">,
  nowMs: number = Date.now(),
): Promise<RuntimeErrorsReport> {
  return runtimeErrorsReport(await store.load({ sinceMs: nowMs - RUNTIME_ERROR_WINDOW_MS }), nowMs);
}

/**
 * Read a newline-delimited JSON stream, handing each parsed line to `onLine`, until the stream
 * ends or `signal` aborts. A line split across chunks is joined; a line that is not JSON is
 * skipped. Abort is the normal end for a stream that stays open, so it resolves (with
 * `aborted: true`) rather than throwing; any other read failure throws.
 */
export async function readJsonLines(
  body: ReadableStream<Uint8Array>,
  signal: AbortSignal,
  onLine: (value: unknown) => void,
): Promise<{ aborted: boolean }> {
  const reader = body.getReader();
  const decoder = new TextDecoder();
  let buffer = "";
  const emit = (line: string): void => {
    const trimmed = line.trim();
    if (!trimmed) return;
    try {
      onLine(JSON.parse(trimmed));
    } catch {
      // Not JSON (a keep-alive, a truncated tail): skip it.
    }
  };
  // The underlying stream may not watch the signal itself, so cancel the reader on abort: that
  // settles a pending `read()` either way.
  const onAbort = (): void => {
    reader.cancel().catch(() => {});
  };
  if (signal.aborted) onAbort();
  else signal.addEventListener("abort", onAbort, { once: true });
  try {
    for (;;) {
      let chunk: Awaited<ReturnType<typeof reader.read>>;
      try {
        chunk = await reader.read();
      } catch (err) {
        if (signal.aborted) return { aborted: true };
        throw err;
      }
      if (chunk.done) break;
      buffer += decoder.decode(chunk.value, { stream: true });
      let nl: number;
      while ((nl = buffer.indexOf("\n")) >= 0) {
        emit(buffer.slice(0, nl));
        buffer = buffer.slice(nl + 1);
      }
      if (signal.aborted) return { aborted: true };
    }
    // On abort the reader reports `done` with the tail possibly cut mid-line: drop that tail.
    if (signal.aborted) return { aborted: true };
    emit(buffer + decoder.decode());
    return { aborted: false };
  } finally {
    signal.removeEventListener("abort", onAbort);
    reader.releaseLock();
  }
}

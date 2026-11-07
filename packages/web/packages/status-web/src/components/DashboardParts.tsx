"use client";
import { useRef, useState, type ReactElement, type ReactNode } from "react";
import { StatCard } from "@adh-sdk/ui/blocks/stat-card";
import { DataTable, type DataTableProps } from "@adh-sdk/ui/components/data-table";
import { Skeleton } from "@adh-sdk/ui/components/skeleton";
import { useNow } from "../hooks/use-now";
import { timeAgo } from "../lib/time-ago";
import type { DashboardSection } from "../telemetry/dashboard-types";

// The pieces the Analytics and Errors topics share. The panel is the shared StatCard, with a
// section's four states inside it so both topics say them the same way: a failed provider must
// never look like a quiet one.

/** Which provider a panel came from, for a panel with no single tool to link to. */
function SourceTag({ children }: { children: ReactNode }): ReactElement {
  return (
    <span className="whitespace-nowrap font-mono text-[10px] uppercase tracking-[0.06em] text-apt-text-dim">
      {children}
    </span>
  );
}

/**
 * A status server older than this page answers the dashboards without `views`, the server-side
 * rankings and ratings the panels draw. Drawing those panels from nothing would read as an
 * all-clear ("no site reported an error") while the sections beside them hold real numbers, so
 * they say this instead.
 */
export const VIEWS_MISSING =
  "This status server is older than this page and does not send the views this is drawn from. Update status-server to see it.";

/** True when the server answered without `views`; false before any answer. */
export function viewsMissing(body: { views?: unknown } | undefined): boolean {
  return body !== undefined && (body.views === undefined || body.views === null);
}

export interface DashboardPanelProps<T> {
  title: string;
  source: string;
  /** Turns the source into the "{tool} ↗" link every StatCard carries. */
  sourceHref?: string;
  section: DashboardSection<T>;
  configured: boolean;
  /** The topic is still fetching, so an empty section is loading rather than absent. */
  refreshing: boolean;
  /** Said in place of the content when it cannot be drawn at all (see {@link VIEWS_MISSING}). */
  unavailable?: string;
  note?: ReactNode;
  actions?: ReactNode;
  skeletonHeight?: number;
  children: (data: T) => ReactNode;
}

export function DashboardPanel<T>({
  title,
  source,
  sourceHref,
  section,
  configured,
  refreshing,
  unavailable,
  note,
  actions,
  skeletonHeight = 120,
  children,
}: DashboardPanelProps<T>): ReactElement {
  const now = useNow();
  return (
    <StatCard
      title={title}
      className="min-w-0"
      link={sourceHref ? { href: sourceHref, label: source } : undefined}
      actions={
        actions || !sourceHref ? (
          <>
            {actions}
            {!sourceHref && <SourceTag>{source}</SourceTag>}
          </>
        ) : undefined
      }
      footnote={configured && section.data !== null && !unavailable ? note : undefined}
    >
      {section.data !== null && section.error !== null && (
        <p className="m-0 font-mono text-[11px] text-apt-gold">
          Last good data{section.updatedAt ? ` from ${timeAgo(section.updatedAt, now)} ago` : ""}. The latest refresh
          failed: {section.error}
        </p>
      )}
      {!configured ? (
        <Notice>{source} is not configured on this backend.</Notice>
      ) : unavailable && section.data !== null ? (
        <p role="alert" className="m-0 font-mono text-xs text-apt-gold">
          {unavailable}
        </p>
      ) : section.data !== null ? (
        children(section.data)
      ) : section.error !== null ? (
        <p role="alert" className="m-0 font-mono text-xs text-apt-red">
          Could not load from {source}: {section.error}
        </p>
      ) : refreshing ? (
        <Skeleton aria-label={`Loading ${title}`} style={{ height: skeletonHeight }} />
      ) : (
        <Notice>No data yet.</Notice>
      )}
    </StatCard>
  );
}

function Notice({ children }: { children: ReactNode }): ReactElement {
  return <p className="m-0 font-mono text-xs text-apt-text-dim">{children}</p>;
}

/** "3.2%", or a dash when nothing was attempted: a rate of nothing is not a 0% failure rate. */
export function formatRate(part: number, whole: number): string {
  return whole > 0 ? `${((part / whole) * 100).toFixed(1)}%` : "—";
}

/** "3h ago", or a dash when it is not known. */
export function formatAge(iso: string | null, now: number): string {
  if (!iso) return "—";
  const text = timeAgo(iso, now);
  return text === "just now" ? text : `${text} ago`;
}

/** The earliest of these times, null when none is known. */
function oldest(times: readonly (string | null)[]): string | null {
  let found: string | null = null;
  for (const t of times) {
    if (t !== null && (found === null || Date.parse(t) < Date.parse(found))) found = t;
  }
  return found;
}

/**
 * A panel fed by several providers, keyed by provider name: it has data if any answered.
 *
 * The error and the time travel together. Each failure names its provider, and `updatedAt` is when
 * the FAILED providers last read well, so "Last good data from 3h ago. The latest refresh failed"
 * describes one provider's data, not one provider's failure beside the other's fresh read. With
 * nothing failing, it is the oldest read on the panel, since that is how old part of it is.
 */
export function eitherSection(sources: Readonly<Record<string, DashboardSection<unknown>>>): DashboardSection<true> {
  const all = Object.entries(sources);
  const failed = all.filter(([, s]) => s.error !== null);
  return {
    data: all.some(([, s]) => s.data !== null) ? true : null,
    error:
      failed.length === 0
        ? null
        : failed.map(([name, s]) => (all.length > 1 ? `${name}: ${s.error}` : s.error)).join("; "),
    updatedAt: oldest((failed.length > 0 ? failed : all).map(([, s]) => s.updatedAt)),
  };
}

/** Table text that wraps rather than being cut off by the cell. */
export function WrappedCell({ children }: { children: ReactNode }): ReactElement {
  return <span className="whitespace-normal [overflow-wrap:anywhere]">{children}</span>;
}

/**
 * A DataTable whose rows each open a page: a click, a double-click or Enter opens one.
 *
 * The arrow keys only move the highlight. DataTable reports a click and an arrow key the same
 * way (a new selection), so opening on every selection change sent a keyboard user to the first
 * row they arrowed onto. The click is told apart here instead: the wrapper's capture phase marks
 * it before the row's own handler reports the selection it causes.
 */
export function OpenOnClickTable<T>({
  onOpen,
  ...table
}: Omit<DataTableProps<T>, "selectedIds" | "onSelectionChange" | "onRowActivate"> & {
  onOpen: (id: string) => void;
}): ReactElement {
  const [selected, setSelected] = useState<Set<string>>(() => new Set());
  const clicking = useRef(false);
  return (
    <div
      onClickCapture={() => {
        clicking.current = true;
      }}
      onClick={() => {
        clicking.current = false;
      }}
    >
      <DataTable
        {...table}
        selectedIds={selected}
        onSelectionChange={(ids) => {
          setSelected(ids);
          const [next] = ids;
          if (clicking.current && ids.size === 1 && next !== undefined) onOpen(next);
        }}
        onRowActivate={onOpen}
      />
    </div>
  );
}

/** A failure rate, in red when the server judged it high (`failureRateHigh`): the worst rate on a page is what an operator scans for. */
export function SiteFailureRate({ failures, requests, high }: { failures: number; requests: number; high: boolean }): ReactElement {
  return <span className={high ? "font-semibold text-apt-red" : undefined}>{formatRate(failures, requests)}</span>;
}

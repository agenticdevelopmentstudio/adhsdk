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

export interface DashboardPanelProps<T> {
  title: string;
  source: string;
  /** Turns the source into the "{tool} ↗" link every StatCard carries. */
  sourceHref?: string;
  section: DashboardSection<T>;
  configured: boolean;
  /** The topic is still fetching, so an empty section is loading rather than absent. */
  refreshing: boolean;
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
      footnote={configured && section.data !== null ? note : undefined}
    >
      {section.data !== null && section.error !== null && (
        <p className="m-0 font-mono text-[11px] text-apt-gold">
          Last good data{section.updatedAt ? ` from ${timeAgo(section.updatedAt, now)} ago` : ""}. The latest refresh
          failed: {section.error}
        </p>
      )}
      {!configured ? (
        <Notice>{source} is not configured on this backend.</Notice>
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

/** A panel fed by two providers: it has data if either answered, and shows the first failure. */
export function eitherSection(a: DashboardSection<unknown>, b: DashboardSection<unknown>): DashboardSection<true> {
  return {
    data: a.data !== null || b.data !== null ? true : null,
    error: a.error ?? b.error,
    updatedAt: a.updatedAt ?? b.updatedAt,
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

/** The worst failure rate on a page is what an operator scans for. */
export function SiteFailureRate({ failures, requests }: { failures: number; requests: number }): ReactElement {
  const rate = requests > 0 ? failures / requests : 0;
  return (
    <span className={rate >= 0.05 ? "font-semibold text-apt-red" : undefined}>{formatRate(failures, requests)}</span>
  );
}

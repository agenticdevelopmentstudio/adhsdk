"use client";
import type { ReactElement, ReactNode } from "react";
import { InfoPanel } from "@agenticdevelopertoolkit/ui/blocks/info-panel";
import { Skeleton } from "@agenticdevelopertoolkit/ui/components/skeleton";
import { useNow } from "../hooks/use-now";
import { timeAgo } from "../lib/time-ago";
import type { DashboardSection } from "../telemetry/dashboard-types";

// The pieces the Analytics and Errors topics share. A section's four states live here so both say
// them the same way: a failed provider must never look like a quiet one.

/** Which provider a figure came from. The two count differently, so it is always on screen. */
export function SourceTag({ children }: { children: ReactNode }): ReactElement {
  return (
    <span className="whitespace-nowrap font-mono text-[10px] uppercase tracking-[0.06em] text-apt-text-dim">
      {children}
    </span>
  );
}

export interface DashboardPanelProps<T> {
  title: string;
  source: string;
  section: DashboardSection<T>;
  configured: boolean;
  /** The topic is still fetching, so an empty section is loading rather than absent. */
  refreshing: boolean;
  /** Said instead of a loading state when this section does not apply to the current filters. */
  notApplicable?: string | null;
  note?: ReactNode;
  actions?: ReactNode;
  skeletonHeight?: number;
  children: (data: T) => ReactNode;
}

export function DashboardPanel<T>({
  title,
  source,
  section,
  configured,
  refreshing,
  notApplicable = null,
  note,
  actions,
  skeletonHeight = 120,
  children,
}: DashboardPanelProps<T>): ReactElement {
  const now = useNow();
  return (
    <InfoPanel
      title={title}
      className="min-w-0"
      actions={
        <>
          {actions}
          <SourceTag>{source}</SourceTag>
        </>
      }
    >
      {section.data !== null && section.error !== null && (
        <p className="m-0 mb-3 font-mono text-[11px] text-apt-gold">
          Last good data{section.updatedAt ? ` from ${timeAgo(section.updatedAt, now)} ago` : ""}. The latest refresh
          failed: {section.error}
        </p>
      )}
      {!configured ? (
        <Notice>{source} is not configured on this backend.</Notice>
      ) : notApplicable !== null ? (
        <Notice>{notApplicable}</Notice>
      ) : section.data !== null ? (
        <>
          {children(section.data)}
          {note && <p className="m-0 mt-3 font-mono text-[10px] leading-relaxed text-apt-text-dim">{note}</p>}
        </>
      ) : section.error !== null ? (
        <p role="alert" className="m-0 font-mono text-xs text-apt-red">
          Could not load from {source}: {section.error}
        </p>
      ) : refreshing ? (
        <Skeleton aria-label={`Loading ${title}`} style={{ height: skeletonHeight }} />
      ) : (
        <Notice>No data yet.</Notice>
      )}
    </InfoPanel>
  );
}

function Notice({ children }: { children: ReactNode }): ReactElement {
  return <p className="m-0 font-mono text-xs text-apt-text-dim">{children}</p>;
}

export interface FigureTileProps {
  label: string;
  /** Null while unknown, which prints a dash rather than a zero. */
  value: string | null;
  source?: string;
  hint?: string;
  /** A color is not enough on its own, so the caller's value or label must also say why. */
  alert?: boolean;
}

/** A headline number. The figure is the point, so it is the largest thing in the tile. */
export function FigureTile({ label, value, source, hint, alert = false }: FigureTileProps): ReactElement {
  return (
    <div className="min-w-0 rounded-[10px] border border-apt-border bg-apt-surface px-3.5 py-3">
      <div className="flex items-baseline justify-between gap-2">
        <span className="truncate text-xs text-apt-text-muted">{label}</span>
        {source && <SourceTag>{source}</SourceTag>}
      </div>
      <div className={`mt-1 font-mono text-2xl font-bold leading-none ${alert ? "text-apt-red" : "text-apt-text"}`}>
        {value ?? "—"}
      </div>
      {hint && <div className="mt-1.5 truncate font-mono text-[10px] text-apt-text-dim">{hint}</div>}
    </div>
  );
}

/** "3.2%", or a dash when nothing was attempted: a rate of nothing is not a 0% failure rate. */
export function formatRate(part: number, whole: number): string {
  return whole > 0 ? `${((part / whole) * 100).toFixed(1)}%` : "—";
}

/** The worst failure rate on a page is what an operator scans for. */
export function SiteFailureRate({ failures, requests }: { failures: number; requests: number }): ReactElement {
  const rate = requests > 0 ? failures / requests : 0;
  return (
    <span className={rate >= 0.05 ? "font-semibold text-apt-red" : undefined}>{formatRate(failures, requests)}</span>
  );
}

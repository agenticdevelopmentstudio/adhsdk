"use client";
import type { ReactElement } from "react";
import Link from "next/link";
import { Bug, TrendingUp } from "lucide-react";
import { StatCard } from "@agenticdevelopertoolkit/ui/blocks/stat-card";
import { StatList, StatListRow } from "@agenticdevelopertoolkit/ui/blocks/stat-list";
import { ExternalLink } from "@agenticdevelopertoolkit/ui/components/external-link";
import { type StatusDotTone } from "@agenticdevelopertoolkit/ui/components/status-dot";
import { useNow } from "../hooks/use-now";
import { useTelemetry } from "../hooks/use-telemetry";
import { isActiveError } from "../lib/error-activity";
import { useStatusHost } from "./StatusHost";
import type { AnalyticsMetricDTO } from "../telemetry/types";

// Errors (GlitchTip) and Traffic (PostHog) cards for the Overview rail, stacked
// under the Stats card. Always rendered, including a healthy/empty state, so the
// dashboard is never silent about production. Each deep-links into the full tool.
// The card itself is the shared StatCard (InfoPanel + StatRows + ExternalLink);
// this file owns only the telemetry wiring and the Errors top-issue list.

// Deep-dive targets come from the HOST (StatusHostProvider) — this package knows no
// hostname. Without one, a card renders its data and simply carries no deep link.

// Compact number formatter — handles k/M/B with correct rounding (e.g. 999_999 → "1M",
// 1_240 → "1.2K"), unlike a hand-rolled /1000 that breaks above 'k'.
const COMPACT = new Intl.NumberFormat("en", { notation: "compact", maximumFractionDigits: 1 });

function levelTone(level: string | null): StatusDotTone {
  switch (level) {
    case "fatal":
    case "error":
      return "error";
    case "warning":
      return "accent";
    default:
      return "blue";
  }
}

/** The per-issue deep link: the issue's own permalink, else the host's GlitchTip,
 *  else nothing — never a dead `#`. */
function IssueLink({ href, title }: { href: string | undefined; title: string }): ReactElement | null {
  if (!href) return null;
  return <ExternalLink href={href} aria-label={`Open issue "${title}" in GlitchTip`} />;
}

/**
 * Errors card: what GlitchTip says is happening now, and how much old backlog sits behind it.
 *
 * Only ACTIVE issues turn this card red: the backend's `active`, which is the very test that raises
 * a Problem (error or fatal, seen in the last 24h, from an allowed project, with the recency test
 * suspended while GlitchTip can't be read). GlitchTip's unresolved set is a backlog nobody clears, so
 * coloring by its size left this card permanently red on a healthy fleet, with nothing in Problems
 * to explain it and nothing an operator could do to clear it. The backlog is still counted, in a
 * neutral tone, and the Errors topic lists it.
 */
export function ErrorsCard(): ReactElement {
  const { errors, errorsFrozen } = useTelemetry();
  const now = useNow();
  const { glitchtipUrl } = useStatusHost();
  // The backend marks each error with the board's own verdict (allowlist and frozen feed
  // included). `isActiveError` covers only a cached snapshot from before it did.
  const active = errors.filter((e) => e.active ?? isActiveError(e.level, e.lastSeen, now));
  const totalEvents = errors.reduce((s, e) => s + (e.count || 0), 0);
  // Sort by event count desc so the shown "top 5" actually matches the prominent
  // {count}× label — the feed arrives in GlitchTip's last-seen order, not by volume.
  const top = [...active].sort((a, b) => b.count - a.count).slice(0, 5);

  return (
    <StatCard
      title="Errors"
      icon={<Bug size={15} className={active.length > 0 ? "text-apt-red" : "text-apt-text-muted"} />}
      link={glitchtipUrl ? { href: glitchtipUrl, label: "GlitchTip" } : undefined}
      stats={
        errors.length > 0
          ? [
              { label: "active · 24h", value: String(active.length), tone: active.length > 0 ? "error" : undefined },
              { label: "backlog", value: String(errors.length - active.length) },
              { label: "events · all unresolved", value: COMPACT.format(totalEvents) },
            ]
          : undefined
      }
    >
      {errorsFrozen && (
        <p className="mb-2 font-mono text-[11px] text-apt-text-muted">
          GlitchTip can&apos;t be read right now; this is its last answer.
        </p>
      )}
      {active.length === 0 ? (
        // An unreadable feed can't vouch for the last 24h, so it makes no all-clear.
        errorsFrozen ? null : (
          <div className="font-mono text-[13px] font-semibold text-apt-green">✓ No errors in the last 24h</div>
        )
      ) : (
        // Each deep-links to its GlitchTip page (the shared status-list block).
        <StatList divided>
          {top.map((e) => (
            <StatListRow
              key={e.id}
              tone={levelTone(e.level)}
              label={e.title}
              labelTitle={e.title}
              trailing={
                <>
                  <span className="font-bold text-apt-red">{e.count}×</span>
                  <IssueLink href={e.permalink ?? glitchtipUrl} title={e.title} />
                </>
              }
            />
          ))}
        </StatList>
      )}
      <Link href="/errors" className="mt-2 block font-mono text-[11px] text-apt-text-muted hover:text-apt-text">
        All errors →
      </Link>
    </StatCard>
  );
}

function kpi(metrics: AnalyticsMetricDTO[], metric: string, window: string): number | null {
  const m = metrics.find((x) => x.metric === metric && x.window === window && x.scope === "all");
  return m ? m.value : null;
}
function fmt(n: number | null): string {
  return n === null ? "—" : COMPACT.format(n);
}

/** Traffic card — anonymous, cookieless headline KPIs from PostHog. */
export function TrafficCard(): ReactElement {
  const { analytics } = useTelemetry();
  const figures = [
    { label: "pageviews · 24h", value: kpi(analytics, "pageviews", "24h") },
    { label: "visitors · 24h", value: kpi(analytics, "visitors", "24h") },
    { label: "pageviews · 7d", value: kpi(analytics, "pageviews", "7d") },
    { label: "visitors · 7d", value: kpi(analytics, "visitors", "7d") },
  ];
  const { posthogUrl } = useStatusHost();

  return (
    <StatCard
      title="Traffic"
      icon={<TrendingUp size={15} className="text-apt-blue" />}
      link={posthogUrl ? { href: posthogUrl, label: "PostHog" } : undefined}
      stats={figures.map((f) => ({ label: f.label, value: fmt(f.value) }))}
    />
  );
}

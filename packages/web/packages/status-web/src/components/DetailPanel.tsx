"use client";
import type { ReactElement } from "react";
import type { ServiceStatusDTO, UptimeService } from "../types";
import type { LiveDeploymentDTO, LiveServiceDTO } from "../lib/live-types";
import { COLORS, PALETTE } from "../lib/colors";
import { useHistory } from "../hooks/use-history";
import { ResponseChart } from "./ResponseChart";
import { ChecksStrip } from "./ChecksStrip";
import { DeployList } from "./DeployList";
import { paneStyle } from "./panel-styles";
import { sectionLabelClass } from "@adh-sdk/ui/components/section-label";

export interface DetailPanelProps {
  /** Slug of the selected endpoint (single env). */
  selectedSlug: string;
  /** The one ServiceStatusDTO for this endpoint. */
  svc: ServiceStatusDTO | undefined;
  uptime?: UptimeService;
  /** The same endpoint as the live snapshot serves it — carries the server's join of the
   *  endpoint to its deploys (`deployIds`). Undefined when the snapshot lacks the slug. */
  live: LiveServiceDTO | undefined;
  /** The live snapshot's deployments, which `live.deployIds` index into. */
  deploys: LiveDeploymentDTO[];
}

export function DetailPanel({
  selectedSlug,
  svc,
  uptime,
  live,
  deploys,
}: DetailPanelProps): ReactElement {
  const history = useHistory(selectedSlug);

  // Deploy list for this endpoint — the server's join, newest first.
  const byId = new Map(deploys.map((d) => [d.id, d]));
  const endpointDeploys = (live?.deployIds ?? []).flatMap((id) => byId.get(id) ?? []);

  // Response chart data from history
  const checks = history.data?.checks ?? [];
  const respPoints = checks.map((c) => c.responseTimeMs);
  const stripStatuses = checks.map((c): "healthy" | "degraded" | "down" =>
    c.status === "healthy" ? "healthy" : c.status === "degraded" ? "degraded" : "down",
  );

  // Chart color from current status
  const isDown = svc?.status === "down" || svc?.status === "unknown";
  const isDeg = svc?.status === "degraded";
  const chartColor = isDown ? PALETTE.red : isDeg ? PALETTE.amber : PALETTE.blue;

  const uptimePct = uptime?.uptimePercent;
  const uptimeLabel = uptimePct != null ? `${uptimePct.toFixed(2)}%` : "—";
  // The server's verdict on the figure (`uptimeTone`); the client only picks the colour.
  // No figure keeps the green it always had — the label already reads "—".
  const uptimeColor =
    uptime?.uptimeTone === "bad" ? PALETTE.red : uptime?.uptimeTone === "warn" ? PALETTE.amber : PALETTE.green;

  return (
    // The pane's identity (host, env badge, open link) lives on the split's
    // header bar (Dashboard passes it) — this is just the body.
    <div style={{ flex: 1, minHeight: 0, overflow: "hidden", display: "flex", flexDirection: "column" }}>
      {/* Body: 3-pane grid */}
      <div style={{
        flex: "1 1 auto", overflow: "hidden", display: "grid",
        gridTemplateColumns: "1.4fr 1fr 1.1fr", gap: 0,
      }}>
        {/* Pane 1: Response time chart + uptime */}
        <div style={paneStyle}>
          <h4 className={sectionLabelClass}>Response time · 24h</h4>
          {history.isLoading ? (
            <div style={{ color: PALETTE.dim, fontFamily: "var(--mono,ui-monospace,monospace)", fontSize: 11 }}>loading…</div>
          ) : (
            <ResponseChart points={respPoints} color={chartColor} />
          )}
          <div style={{ display: "flex", gap: 16, alignItems: "baseline" }}>
            <span style={{ fontFamily: "var(--mono,ui-monospace,monospace)", fontSize: 20, color: uptimeColor }}>{uptimeLabel}</span>
            <span style={{ fontFamily: "var(--mono,ui-monospace,monospace)", fontSize: 10, color: PALETTE.dim }}>uptime 90d</span>
          </div>
        </div>

        {/* Pane 2: Recent checks + incidents */}
        <div style={{ ...paneStyle, borderRight: `1px solid ${COLORS.border}` }}>
          <h4 className={sectionLabelClass}>Recent checks · last {stripStatuses.length || 40}</h4>
          {stripStatuses.length > 0 && <ChecksStrip statuses={stripStatuses} />}
        </div>

        {/* Pane 3: Deploys for this env endpoint */}
        <div style={{ ...paneStyle, borderRight: "none" }}>
          <h4 className={sectionLabelClass}>Deploys for this endpoint</h4>
          <div style={{ flex: 1, overflow: "hidden" }}>
            <DeployList deploys={endpointDeploys} />
          </div>
        </div>
      </div>
    </div>
  );
}

import type { HealthStatus } from "./lib/health";
import type { OverallStatus } from "./lib/overall";
import type { DeployStatus, BuildPhase, DeployPhase } from "./lib/deploy-status";

export type { HealthStatus, OverallStatus, DeployStatus };

export interface ServiceStatusDTO {
  slug: string;
  group: string;
  name: string;
  url: string;
  environment: string;
  platform: string | null;      // explicit deploy target (correlation key)
  deployProject: string | null;
  status: HealthStatus | "unknown";
  responseTimeMs: number | null;
  statusCode: number | null;
  error: string | null;
  lastCheckedAt: string | null;
  /** The server's verdict that the last response was slow (`isSlowResponse`). */
  slow: boolean;
}

/** Endpoint tallies `GET /status` publishes. `down` includes an unprobed ("unknown")
 *  endpoint: an endpoint with no probe is never counted as up. */
export interface EndpointCounts {
  up: number;
  degraded: number;
  down: number;
  total: number;
}

export interface StatusResponse {
  overall: OverallStatus;
  services: ServiceStatusDTO[];
  checkedAt: string;
  counts: EndpointCounts;
}

/** How an uptime figure reads — good ≥ 99%, warn ≥ 95%, bad below, unknown with no figure.
 *  The thresholds are the server's (`monitor/uptime.ts`); the client maps a tone to a colour. */
export type UptimeTone = "good" | "warn" | "bad" | "unknown";

export interface UptimeDay {
  day: string;
  status: HealthStatus;
  uptimePercent: number | null;
}
export interface UptimeService {
  slug: string;
  name: string;
  uptimePercent: number | null;
  /** How `uptimePercent` reads, judged by the server (`uptimeTone`). */
  uptimeTone: UptimeTone;
  totalChecks: number;
  daily: UptimeDay[];
}
export interface UptimeResponse {
  services: UptimeService[];
  days: number;
  /** Portfolio-wide uptime, judged by the server; null when no service has data. */
  overallUptimePercent: number | null;
  /** How `overallUptimePercent` reads, judged by the server. */
  overallUptimeTone: UptimeTone;
}

export interface DeploymentDTO {
  id: string;
  platform: string;
  projectName: string;
  /** The provider's immutable project id, when the row has one. */
  providerProjectId: string | null;
  status: DeployStatus;          // derived (combinedStatus) — for the Details/KPI views
  buildPhase: BuildPhase | null; // for the activity transcript
  deployPhase: DeployPhase;
  environment: string | null;
  /** The LOGICAL TIER this build belongs to, derived server-side by `deployEnv` (branch
   *  first, then the project name); null when the row is not a deployment of any tier — a
   *  Vercel preview. Render THIS, never `environment`: that one is the provider's promotion
   *  target and reads "production" for every Vercel project, testing fleet included. The
   *  client deliberately owns no copy of the derivation (see board-types.ts). */
  tier: string | null;
  commitHash: string | null;
  commitMessage: string | null;
  branch: string | null;
  commitRepo: string | null; // "owner/name" — to build a GitHub commit link
  url: string | null;
  // Provider failure reason for a FAILED deploy (Vercel errorMessage / Railway
  // build-log tail); null otherwise. Rendered verbatim in the details pane.
  errorText: string | null;
  liveHost: string | null; // resolved live custom domain host (correlation key + live url)
  createdAt: string;
  /** ISO time the PHASES were last confirmed against provider truth. The server judges
   *  an in-flight phase against it (`/live`'s `effectiveStatus`); the client never does. */
  phaseConfirmedAt: string;
}

export interface HistoryCheck {
  status: HealthStatus | "unknown";
  responseTimeMs: number | null;
  statusCode: number | null;
  error: string | null;
  checkedAt: string;
}

export interface HistoryResponse {
  service: string;
  hours: number;
  checks: HistoryCheck[];
}

export type CheckState = "ok" | "warn" | "error";

export interface IntegrationCheck {
  id: string;
  label: string;
  configured: boolean;
  ok: boolean;
  state: CheckState;
  detail: string;
  /** Expected env vars this check found UNSET (named exactly, e.g. CLOUDFLARE_ACCOUNT_ID).
   *  Drives the "missing env" error bar. Omitted/empty when nothing is missing. */
  missingEnv?: string[];
  /** The probe got NO HTTP response at all (timeout/abort/connection failure) —
   *  debounced backend-side before it may surface as an error. */
  unreachable?: boolean;
  /** Confirmed-unreachable together with other providers in the same run — the backend
   *  judged it monitor-side connectivity; the banner shows only the Connectivity chip. */
  correlated?: boolean;
}

/** The self-check bar's verdict, judged by the server; null on the wire when all is well. */
export interface SelfCheckView {
  /** Expected env vars found unset, deduped, in check order. */
  missingEnv: string[];
  /** A missing-env check is error-severity — the env chip goes red rather than amber. */
  missingEnvError: boolean;
  /** Reachability/freshness issues to chip out. */
  issues: IntegrationCheck[];
  /** Any errored check → the bar renders in its red state. */
  hasError: boolean;
  /** How many things the bar lists — the KPI pill's count. */
  issueCount: number;
}

export interface IntegrationsResponse {
  generatedAt: string;
  overall: CheckState;
  checks: IntegrationCheck[];
  selfCheck: SelfCheckView | null;
}

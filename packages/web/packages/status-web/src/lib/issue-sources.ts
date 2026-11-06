/**
 * Where a row/problem came from — DNS resolution, the HTTP probe, the error tracker, or a deploy
 * provider.
 *
 * `glitchtip` is the odd one out and deliberately so: the other sources answer "is the thing
 * reachable", it answers "is the thing THROWING". A site can be up on every probe and still
 * have an error Problem open, which is the whole point of carrying it here rather than
 * folding it into `http`.
 *
 * MIRROR of `src/monitor/issue-sources.ts` — same union, same labels, same
 * order. This side indexes `SOURCE_LABEL[row.source]`, so a source the server can emit and
 * the client has never heard of renders `undefined` in the filter and the badge.
 */
export type IssueSource =
  | "dns"
  | "http"
  | "glitchtip"
  | "vercel"
  | "vercel-runtime"
  | "cloudflare-pages"
  | "railway"
  | "crunchy";

/** Display labels for the source filter + badges. */
export const SOURCE_LABEL: Record<IssueSource, string> = {
  dns: "DNS",
  http: "HTTP",
  glitchtip: "GlitchTip",
  vercel: "Vercel",
  "vercel-runtime": "Vercel runtime logs",
  "cloudflare-pages": "Cloudflare",
  railway: "Railway",
  crunchy: "Crunchy Bridge",
};

/** Canonical order for the source filter UI. */
export const ISSUE_SOURCES: IssueSource[] = [
  "dns",
  "http",
  "glitchtip",
  "vercel",
  "vercel-runtime",
  "cloudflare-pages",
  "railway",
  "crunchy",
];

/** Narrows a raw platform/source string to a known `IssueSource`, so a caller can
 *  filter/index by it without an unchecked `as IssueSource` cast. */
export function isIssueSource(s: string): s is IssueSource {
  return (ISSUE_SOURCES as readonly string[]).includes(s);
}

// NOTE: how long a build may sit BUILDING before it counts as stuck is the SERVER's
// threshold alone (`STUCK_DEPLOY_MS` / `deployIsStuck`, src/monitor/issue-sources.ts); the
// board publishes the resulting Problem and the client renders it.

// NOTE: the platform-unreachable debounce lives SERVER-side (applyPlatformIssues +
// the platform_health_state table) and is folded into the board as a
// `platform-health|<source>` Problem (src/board/derive-problems.ts) — the client
// renders that verdict directly, so there is no client-side streak/threshold here.

import { describe, it, expect } from "vitest";
import type { Problem, ActivityRow } from "./board-types";
import * as rowModel from "./row-model";
import {
  problemToRow,
  activityToRow,
  rowToStatusRowProps,
  rowSearchText,
  rowToText,
  rowsToText,
  commitUrlOf,
  type Row,
} from "./row-model";

// One `it` per conformance vector in cookbook/status/dashboard/logic/row-model/conformance-test-vectors.md.

function problem(o: Partial<Problem>): Problem {
  return {
    target: "adh-app-production",
    source: "http",
    name: "App",
    environment: "production",
    severity: "major",
    state: "down",
    since: "2026-06-04T18:00:00.000Z",
    statusCode: 503,
    detail: "HTTP 503",
    sourceUrl: "https://x",
    liveUrl: "https://x",
    commitHash: null,
    commitMessage: null,
    commitRepo: null,
    branch: null,
    errorText: null,
    ...o,
  };
}

function activity(o: Partial<ActivityRow>): ActivityRow {
  return {
    id: "a1",
    kind: "deploy",
    step: "build",
    source: null,
    tone: "good",
    verb: "built",
    target: "vercel|adh123|",
    name: "adh",
    environment: "production",
    detail: null,
    sourceUrl: null,
    liveUrl: null,
    commitHash: null,
    commitMessage: null,
    commitRepo: null,
    branch: null,
    errorText: null,
    at: "2026-06-04T18:00:00.000Z",
    ...o,
  };
}

function row(o: Partial<Row>): Row {
  return {
    key: "k",
    source: "vercel",
    platform: "vercel",
    name: "adh",
    environment: "production",
    statusWord: "deployed",
    tone: "good",
    sha: null,
    commitUrl: null,
    message: null,
    detail: null,
    at: "2026-06-04T18:00:00.000Z",
    sourceUrl: null,
    liveUrl: null,
    ...o,
  };
}

const AT = "2026-06-04T18:00:00.000Z";
const AT_MS = Date.parse(AT);
const NOW_1M = Date.parse("2026-06-04T18:01:00.000Z");

describe("row-model conformance vectors", () => {
  it("row-model-001 problem builder: source, word, tone, urls, at", () => {
    const r = problemToRow(
      problem({
        source: "vercel",
        state: "failed",
        severity: "major",
        sourceUrl: "https://vercel.com/team/adh",
        liveUrl: "https://app.example.com",
        since: AT,
      }),
    );
    expect(r.source).toBe("vercel");
    expect(r.platform).toBe("vercel");
    expect(r.statusWord).toBe("deploy failed");
    expect(r.tone).toBe("bad");
    expect(r.sourceUrl).toBe("https://vercel.com/team/adh");
    expect(r.liveUrl).toBe("https://app.example.com");
    expect(r.at).toBe(AT);
  });

  it("row-model-002 problem builder: linked commit gives sha, url, subject", () => {
    const r = problemToRow(
      problem({
        commitHash: "abc1234def",
        commitRepo: "example-org/example-app",
        commitMessage: "fix the thing\nbody text",
      }),
    );
    expect(r.sha).toBe("abc1234");
    expect(r.commitUrl).toBe("https://github.com/example-org/example-app/commit/abc1234def");
    expect(r.message).toBe("fix the thing");
  });

  it("row-model-003 problem builder: no repo gives null url and null sha", () => {
    const r = problemToRow(
      problem({ commitHash: "abc1234def", commitRepo: null, commitMessage: "fix the thing\nbody" }),
    );
    expect(r.commitUrl).toBeNull();
    expect(r.sha).toBeNull();
    expect(r.message).toBe("fix the thing");
  });

  it("row-model-004 problem builder: stuck state label", () => {
    expect(problemToRow(problem({ state: "stuck" })).statusWord).toBe("deploy stuck");
  });

  it("row-model-005 problem builder: unknown state passes through", () => {
    expect(problemToRow(problem({ state: "mystery" as Problem["state"] })).statusWord).toBe("mystery");
  });

  it("row-model-006 problem builder: minor severity is progress", () => {
    expect(problemToRow(problem({ severity: "minor", state: "degraded" })).tone).toBe("progress");
  });

  it("row-model-007 problem builder: subject in message, full text in commitBody", () => {
    const msg = "fix the thing\n\nbody line 1\nbody line 2";
    const r = problemToRow(problem({ commitMessage: msg, commitRepo: "o/r", commitHash: "deadbeef" }));
    expect(r.message).toBe("fix the thing");
    expect(r.commitBody).toBe(msg);
  });

  it("row-model-008 problem builder: branch and errorText pass through", () => {
    const r = problemToRow(problem({ branch: "prepared", errorText: "next build exited 1" }));
    expect(r.branch).toBe("prepared");
    expect(r.errorText).toBe("next build exited 1");
  });

  it("row-model-009 problem builder: key, downSince, no probe diagnostics", () => {
    const r = problemToRow(problem({ target: "adh-app-production", since: AT }));
    expect(r.key).toBe("problem:adh-app-production");
    expect(r.downSince).toBe(AT);
    expect(r.responseTimeMs).toBeUndefined();
    expect(r.lastCheckedAt).toBeUndefined();
  });

  it("row-model-010 activity builder: platform, source, verb, tone", () => {
    const r = activityToRow(activity({ kind: "deploy", source: "vercel", verb: "deployed", tone: "good" }));
    expect(r.platform).toBe("vercel");
    expect(r.source).toBe("vercel");
    expect(r.statusWord).toBe("deployed");
    expect(r.tone).toBe("good");
  });

  it("row-model-011 activity builder: probe kind uses its own source", () => {
    const r = activityToRow(activity({ kind: "probe", source: "http", target: "adh-app-production" }));
    expect(r.platform).toBe("http");
    expect(r.source).toBe("http");
  });

  it("row-model-012 activity builder: source wins over target segment", () => {
    const r = activityToRow(
      activity({ kind: "deploy", source: "cloudflare-pages", target: "cloudflare|proj123|" }),
    );
    expect(r.platform).toBe("cloudflare-pages");
    expect(r.source).toBe("cloudflare-pages");
    expect(r.platform).not.toBe("cloudflare");
  });

  it("row-model-013 activity builder: null source falls back to kind", () => {
    const r = activityToRow(activity({ kind: "deploy", source: null }));
    expect(r.platform).toBeNull();
    expect(r.source).toBe("deploy");
  });

  it("row-model-014 activity builder: key, passthrough, no diagnostics", () => {
    const r = activityToRow(activity({ id: "a1", branch: "staging", errorText: "next build exited 1" }));
    expect(r.key).toBe("a1");
    expect(r.branch).toBe("staging");
    expect(r.errorText).toBe("next build exited 1");
    expect(r.downSince).toBeUndefined();
    expect(r.statusCode).toBeUndefined();
  });

  it("row-model-015 adapter: good, bad, progress colors and bold", () => {
    const good = rowToStatusRowProps(row({ tone: "good" }), NOW_1M);
    const bad = rowToStatusRowProps(row({ tone: "bad" }), NOW_1M);
    const progress = rowToStatusRowProps(row({ tone: "progress" }), NOW_1M);
    expect([good.statusColor, good.statusBold]).toEqual(["var(--color-apt-green)", false]);
    expect([bad.statusColor, bad.statusBold]).toEqual(["var(--color-apt-red)", true]);
    expect([progress.statusColor, progress.statusBold]).toEqual(["var(--color-apt-gold)", false]);
  });

  it("row-model-016 adapter: neutral and stale colors, not bold", () => {
    const neutral = rowToStatusRowProps(row({ tone: "neutral" }), NOW_1M);
    const stale = rowToStatusRowProps(row({ tone: "stale" }), NOW_1M);
    expect([neutral.statusColor, neutral.statusBold]).toEqual(["var(--color-apt-gold)", false]);
    expect([stale.statusColor, stale.statusBold]).toEqual(["var(--color-apt-text-muted)", false]);
  });

  it("row-model-017 adapter: an hour-old activity row keeps its word and tone", () => {
    const r = activityToRow(activity({ verb: "building", tone: "progress", at: AT }));
    const props = rowToStatusRowProps(r, AT_MS + 3600_000);
    expect(props.statusWord).toBe("building");
    expect(props.statusColor).toBe("var(--color-apt-gold)");
  });

  it("row-model-018 adapter: a 30-day-old problem keeps its word and red color", () => {
    const r = problemToRow(problem({ state: "failed", since: AT }));
    const props = rowToStatusRowProps(r, AT_MS + 30 * 86_400_000);
    expect(props.statusWord).toBe("deploy failed");
    expect(props.statusColor).toBe("var(--color-apt-red)");
  });

  it("row-model-019 adapter: time label, absent platform, urls pass through", () => {
    const props = rowToStatusRowProps(
      row({ at: AT, platform: null, liveUrl: "https://live", sourceUrl: "https://src" }),
      NOW_1M,
    );
    expect(props.timeLabel).toBe("1m");
    expect(props.platform).toBeUndefined();
    expect(props.liveUrl).toBe("https://live");
    expect(props.sourceUrl).toBe("https://src");
  });

  it("row-model-020 search text: name, env, word, subject and body", () => {
    const r = problemToRow(
      problem({ name: "adh", environment: "production", state: "failed", commitMessage: "broke login\nbody" }),
    );
    const text = rowSearchText(r);
    for (const part of ["adh", "production", "deploy failed", "broke login", "body"]) {
      expect(text).toContain(part);
    }
  });

  it("row-model-021 search text and adapter both carry the rendered word", () => {
    const r = row({ statusWord: "unknown", tone: "stale" });
    expect(rowSearchText(r)).toContain("unknown");
    expect(rowToStatusRowProps(r, NOW_1M).statusWord).toBe("unknown");
  });

  it("row-model-022 search text: exact shape, sha excluded", () => {
    const r = row({ name: "a", environment: null, statusWord: "s", detail: null, sha: "abc1234" });
    expect(rowSearchText(r)).toBe("a  s  ");
  });

  it("row-model-023 commit url function", () => {
    expect(commitUrlOf("o/r", "deadbeef")).toBe("https://github.com/o/r/commit/deadbeef");
    expect(commitUrlOf(null, "deadbeef")).toBeNull();
    expect(commitUrlOf("o/r", null)).toBeNull();
  });

  it("row-model-024 row text: columns, commit precedence, url", () => {
    const r = row({
      at: AT,
      environment: "production",
      source: "cloudflare-pages",
      name: "adh",
      statusWord: "deployed",
      sha: "abc1234",
      message: "fix",
      detail: "x",
      liveUrl: null,
      sourceUrl: "https://src",
    });
    expect(rowToText(r, NOW_1M)).toBe(
      ["1m", "PROD", "Cloudflare", "adh", "deployed", "abc1234 fix", "https://src"].join("\t"),
    );
  });

  it("row-model-025 row text: unknown source verbatim, detail fallback, empty columns", () => {
    const r = row({
      source: "deploy",
      environment: null,
      sha: null,
      message: null,
      detail: "HTTP 503",
      liveUrl: null,
      sourceUrl: null,
    });
    const text = rowToText(r, NOW_1M);
    const cols = text.split("\t");
    expect(cols).toHaveLength(7);
    expect(cols[1]).toBe("");
    expect(cols[2]).toBe("deploy");
    expect(cols[5]).toBe("HTTP 503");
    expect(cols[6]).toBe("");
  });

  it("row-model-026 rows text: empty list and two rows", () => {
    expect(rowsToText([], NOW_1M)).toBe("");
    const r1 = row({ name: "one" });
    const r2 = row({ name: "two" });
    expect(rowsToText([r1, r2], NOW_1M)).toBe(`${rowToText(r1, NOW_1M)}\n${rowToText(r2, NOW_1M)}`);
  });

  it("row-model-027 activity builder: an unconfirmed phase (unknown, stale) passes through verbatim", () => {
    const r = activityToRow(activity({ verb: "unknown", tone: "stale" }));
    expect(r.statusWord).toBe("unknown");
    expect(r.tone).toBe("stale");
  });

  it("row-model-028 adapter: an unconfirmed phase stays unknown and muted however old", () => {
    const r = row({ statusWord: "unknown", tone: "stale", at: AT });
    const props = rowToStatusRowProps(r, AT_MS + 30 * 86_400_000);
    expect(props.statusWord).toBe("unknown");
    expect(props.statusColor).toBe("var(--color-apt-text-muted)");
    expect(props.statusBold).toBe(false);
  });

  it("row-model-033 row text: a tab inside a field adds a column (no escaping)", () => {
    const r = row({ detail: "a\tb", sha: null, message: null });
    const cols = rowToText(r, NOW_1M).split("\t");
    expect(cols).toHaveLength(8);
    expect(cols[5]).toBe("a");
    expect(cols[6]).toBe("b");
  });

  it("row-model-034 exported functions are pure and synchronous", () => {
    const p = problem({ commitHash: "abc1234def", commitRepo: "o/r", commitMessage: "m\nb" });
    const a = activity({ source: "vercel" });
    const r = row({ detail: "d" });
    const frozen = JSON.stringify({ p, a, r });
    const calls: Array<() => unknown> = [
      () => problemToRow(p),
      () => activityToRow(a),
      () => rowToStatusRowProps(r, NOW_1M),
      () => rowSearchText(r),
      () => rowToText(r, NOW_1M),
      () => rowsToText([r], NOW_1M),
      () => commitUrlOf("o/r", "h"),
    ];
    for (const call of calls) {
      const first = call();
      const second = call();
      expect(second).toEqual(first);
      expect(first).not.toBeInstanceOf(Promise);
    }
    expect(JSON.stringify({ p, a, r })).toBe(frozen);
    expect(Object.keys(rowModel)).not.toContain("deployUnconfirmed");
    expect(Object.keys(rowModel)).not.toContain("deployDtoUnconfirmed");
  });
});

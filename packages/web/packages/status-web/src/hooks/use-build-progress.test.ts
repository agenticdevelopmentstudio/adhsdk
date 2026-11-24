// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from "vitest";
import { renderHook, act, cleanup } from "@testing-library/react";
import { useBuildProgress } from "./use-build-progress";
import type { ActivityRow } from "../lib/board-types";
// @ts-expect-error vite raw import; read as text to check the directive
import source from "./use-build-progress.ts?raw";

// Fix Round 4 item 5.7. The cohort predicate used to AND in a private 10-minute clock
// (`nowMs - Date.parse(a.at) < UNCONFIRMED_AFTER_MS`) that re-judged a verdict the
// server had already made — while the RENDERED row went on saying "building". So past
// ten minutes the bar dropped a build and read complete while the row beside it still
// said "building". The rule is now: in-flight ⇔ the board's own `buildInFlight` verdict on
// the row (src/board/view.ts `isBuildInFlight`: a deploy/build row toned "progress") — the
// fixture below stamps it exactly as the server does.

const T0 = Date.parse("2026-06-04T19:30:00.000Z");

function buildRow(name: string, tone: ActivityRow["tone"], atMs: number): ActivityRow {
  return {
    id: `deploy:vc_${name}:build`,
    kind: "deploy",
    step: "build",
    source: "vercel",
    target: `vercel|${name}|production`,
    name,
    environment: "production",
    verb: tone === "progress" ? "building" : "built",
    tone,
    detail: null,
    sourceUrl: null,
    liveUrl: null,
    commitHash: null,
    commitMessage: null,
    commitRepo: null,
    branch: null,
    errorText: null,
    at: new Date(atMs).toISOString(),
    buildInFlight: tone === "progress",
  };
}

afterEach(() => {
  cleanup();
  vi.useRealTimers();
});

describe("useBuildProgress", () => {
  it("counts a build as in-flight while the board tones it progress", () => {
    const { result } = renderHook(({ a }: { a: ActivityRow[] }) => useBuildProgress(a), {
      initialProps: { a: [buildRow("app", "progress", T0)] },
    });
    expect(result.current.visible).toBe(true);
    expect(result.current.total).toBe(1);
    expect(result.current.completed).toBe(0);
    expect(result.current.pct).toBe(0);
  });

  it("completes a build when the board settles its row", () => {
    const { result, rerender } = renderHook(({ a }: { a: ActivityRow[] }) => useBuildProgress(a), {
      initialProps: { a: [buildRow("app", "progress", T0)] },
    });
    rerender({ a: [buildRow("app", "good", T0)] });
    expect(result.current.total).toBe(1);
    expect(result.current.completed).toBe(1);
    expect(result.current.pct).toBe(100);
    expect(result.current.complete).toBe(true);
  });

  it("completes a build when the SERVER expires it to `stale` — the server's demotion, not a client clock", () => {
    const { result, rerender } = renderHook(({ a }: { a: ActivityRow[] }) => useBuildProgress(a), {
      initialProps: { a: [buildRow("app", "progress", T0)] },
    });
    // reconcile-stuck-deploys expires an unconfirmed in-flight phase; the tone stops
    // being "progress", so the row leaves the cohort at exactly that instant.
    rerender({ a: [buildRow("app", "stale", T0)] });
    expect(result.current.completed).toBe(1);
    expect(result.current.complete).toBe(true);
  });

  it("keeps an OLD in-flight build in the cohort — the client no longer runs a 10-minute demotion clock", () => {
    // The row's `at` is a full hour in the past and the board is STILL toning it
    // progress. Under the removed clock this read 1/1, 100%, complete — a green bar
    // over a row that still said "building". It must read 0/1 now.
    const anHourOld = T0 - 60 * 60_000;
    const { result } = renderHook(() => useBuildProgress([buildRow("wedged", "progress", anHourOld)]));
    expect(result.current.visible).toBe(true);
    expect(result.current.total).toBe(1);
    expect(result.current.completed).toBe(0);
    expect(result.current.pct).toBe(0);
    expect(result.current.complete).toBe(false);
  });

  it("tracks a mixed cohort and hides two seconds after the last build settles", () => {
    vi.useFakeTimers();
    const { result, rerender } = renderHook(({ a }: { a: ActivityRow[] }) => useBuildProgress(a), {
      initialProps: { a: [buildRow("one", "progress", T0), buildRow("two", "progress", T0 + 1)] },
    });
    expect(result.current.total).toBe(2);

    rerender({ a: [buildRow("one", "good", T0), buildRow("two", "progress", T0 + 1)] });
    expect(result.current.pct).toBe(50);
    expect(result.current.visible).toBe(true);

    rerender({ a: [buildRow("one", "good", T0), buildRow("two", "good", T0 + 1)] });
    expect(result.current.pct).toBe(100);
    expect(result.current.visible).toBe(true); // holds full…

    act(() => void vi.advanceTimersByTime(2100));
    expect(result.current.visible).toBe(false); // …then the cohort resets and it hides
  });

  it("ignores rows the server does not mark as builds in flight", () => {
    // The DEPLOY step of a deployment has its own progress semantics and is not part of
    // the build cohort; a probe row isn't a deployment at all. Both are toned "progress",
    // and the server marks neither `buildInFlight` (`isBuildInFlight`, tested in
    // status-server's board-view.test.ts) — the hook must follow the flag, not the tone. The probe row wears the
    // shape `deriveActivity` actually emits for one — an ISSUE event, `kind: "probe"` with
    // a null step and an `issue:<target>:<step>:<atMs>:<issueId>` id — because a fixture
    // that invents a third id grammar would keep passing a cohort predicate that had
    // started keying off the id.
    const deployStep: ActivityRow = { ...buildRow("app", "progress", T0), id: "deploy:vc_app:deploy", step: "deploy", buildInFlight: false };
    const probe: ActivityRow = { ...buildRow("app", "progress", T0), id: `issue:ep-app:opened:${T0}:41`, kind: "probe", step: null, buildInFlight: false };
    const { result } = renderHook(() => useBuildProgress([deployStep, probe]));
    expect(result.current.visible).toBe(false);
    expect(result.current.total).toBe(0);
  });
});

// One `it` per conformance vector in cookbook/status/dashboard/state/build-progress/conformance-test-vectors.md.
describe("useBuildProgress conformance vectors", () => {
  type Props = { a: ActivityRow[] };
  const mount = (a: ActivityRow[]) =>
    renderHook(({ a: rows }: Props) => useBuildProgress(rows), { initialProps: { a } });

  it("build-progress-001 one in-flight build is visible at 0%", () => {
    const { result } = mount([buildRow("app", "progress", T0)]);
    expect(result.current).toMatchObject({ visible: true, total: 1, completed: 0, pct: 0 });
  });

  it("build-progress-002 a settled build is complete at 100%", () => {
    const { result, rerender } = mount([buildRow("app", "progress", T0)]);
    rerender({ a: [buildRow("app", "good", T0)] });
    expect(result.current).toMatchObject({ total: 1, completed: 1, pct: 100, complete: true });
  });

  it("build-progress-003 a server-expired (stale) build counts as completed", () => {
    const { result, rerender } = mount([buildRow("app", "progress", T0)]);
    rerender({ a: [buildRow("app", "stale", T0)] });
    expect(result.current).toMatchObject({ completed: 1, complete: true });
  });

  it("build-progress-004 an hour-old in-flight build is never demoted by the client", () => {
    const { result } = mount([buildRow("wedged", "progress", T0 - 60 * 60_000)]);
    expect(result.current).toMatchObject({ visible: true, total: 1, completed: 0, pct: 0, complete: false });
  });

  it("build-progress-005 two-build cohort: 50%, 100% held, then hidden after 2100 ms", () => {
    vi.useFakeTimers();
    const { result, rerender } = mount([buildRow("one", "progress", T0), buildRow("two", "progress", T0)]);
    expect(result.current.total).toBe(2);
    rerender({ a: [buildRow("one", "good", T0), buildRow("two", "progress", T0)] });
    expect(result.current).toMatchObject({ pct: 50, visible: true });
    rerender({ a: [buildRow("one", "good", T0), buildRow("two", "good", T0)] });
    expect(result.current).toMatchObject({ pct: 100, visible: true });
    act(() => void vi.advanceTimersByTime(2100));
    expect(result.current.visible).toBe(false);
  });

  it("build-progress-006 deploy-step and non-deploy rows are excluded", () => {
    const deployStep: ActivityRow = { ...buildRow("app", "progress", T0), id: "deploy:vc_app:deploy", step: "deploy", buildInFlight: false };
    const probe: ActivityRow = { ...buildRow("app", "progress", T0), id: `issue:ep-app:opened:${T0}:41`, kind: "probe", step: null, buildInFlight: false };
    const { result } = mount([deployStep, probe]);
    expect(result.current).toMatchObject({ visible: false, total: 0 });
  });

  it("build-progress-007 a build that drops out of the feed counts as completed", () => {
    const { result, rerender } = mount([buildRow("app", "progress", T0)]);
    rerender({ a: [] });
    expect(result.current).toMatchObject({ total: 1, completed: 1, complete: true });
  });

  it("build-progress-008 a new build during the hold cancels the reset", () => {
    vi.useFakeTimers();
    const { result, rerender } = mount([buildRow("a", "progress", T0)]);
    rerender({ a: [buildRow("a", "good", T0)] });
    act(() => void vi.advanceTimersByTime(1000));
    rerender({ a: [buildRow("a", "good", T0), buildRow("b", "progress", T0)] });
    act(() => void vi.advanceTimersByTime(2000));
    expect(result.current).toMatchObject({ total: 2, completed: 1, pct: 50, visible: true });
  });

  it("build-progress-009 percentage rounds to an integer (1/3 is 33, 2/3 is 67)", () => {
    const rows = (tones: ActivityRow["tone"][]) => tones.map((t, i) => buildRow(`b${i}`, t, T0));
    const { result, rerender } = mount(rows(["progress", "progress", "progress"]));
    rerender({ a: rows(["good", "progress", "progress"]) });
    expect(result.current).toMatchObject({ total: 3, completed: 1, pct: 33 });
    rerender({ a: rows(["good", "good", "progress"]) });
    expect(result.current).toMatchObject({ completed: 2, pct: 67 });
  });

  it("build-progress-010 two rows with the same id are one build", () => {
    const { result } = mount([buildRow("app", "progress", T0), buildRow("app", "progress", T0)]);
    expect(result.current.total).toBe(1);
  });

  it("build-progress-011 an empty feed on first evaluation is idle", () => {
    const { result } = mount([]);
    expect(result.current).toEqual({ visible: false, total: 0, completed: 0, pct: 0, complete: false });
  });

  it("build-progress-012 unmounting during the hold leaves no pending timer", () => {
    vi.useFakeTimers();
    const { result, rerender, unmount } = mount([buildRow("app", "progress", T0)]);
    rerender({ a: [buildRow("app", "good", T0)] });
    expect(result.current.complete).toBe(true);
    expect(vi.getTimerCount()).toBe(1);
    unmount();
    expect(vi.getTimerCount()).toBe(0);
    expect(() => vi.advanceTimersByTime(2000)).not.toThrow();
  });

  it("build-progress-013 the module is marked client-only", () => {
    expect((source as string).trimStart().startsWith('"use client"')).toBe(true);
  });
});

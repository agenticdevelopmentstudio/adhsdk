import { describe, it, expect } from "vitest";
// The SERVER's board types, imported by relative path (there is no shared build between the
// backend and its embedded web app — see deploy-status-parity.test.ts for the precedent).
import type * as server from "@adh-sdk/status-server/board";
import type * as web from "./board-types";
import type { IssueSource } from "./issue-sources";
import { INDICATOR_STATE } from "./overview";

// DRIFT GUARD. web/src/lib/board-types.ts is a HAND MIRROR of src/board/types.ts (there is no
// shared package between the backend and its embedded web app). If the two drift — a renamed
// field, a widened nullability, a union member added on one side only — the board silently
// mis-renders with no compile error to catch it, because `pnpm test` transpiles without
// typechecking. So the type half below is what makes the drift visible: it is real code that
// only compiles when both sides still agree. TWO typechecks compile it: this package's own
// `pnpm typecheck`, and the dashboard host's `web` typecheck, whose tsconfig names this file
// (and deploy-status-parity.test.ts) under `files` so the vendored copy is checked against
// the vendored status-server — the pair that actually ships together.

/** Mutual assignability. Drift a field name, a nullability, or a union member on either
 *  side and this stops resolving to `true`. */
type Exact<A, B> = [A] extends [B] ? ([B] extends [A] ? true : never) : never;

const _board: Exact<server.Board, web.Board> = true;
const _problem: Exact<server.Problem, web.Problem> = true;
const _activityRow: Exact<server.ActivityRow, web.ActivityRow> = true;
const _activityTone: Exact<server.ActivityTone, web.ActivityTone> = true;
const _activityKind: Exact<server.ActivityKind, web.ActivityKind> = true;
const _indicator: Exact<server.Indicator, web.Indicator> = true;
// The pagination protocol itself: `useActivityHistory` reads `/api/activity`'s response as
// `web.ActivityPage` and mints its query string from `web.ActivityCursor`, so a field the
// server renamed on one side only would page silently wrong rather than fail to compile.
const _activityCursor: Exact<server.ActivityCursor, web.ActivityCursor> = true;
const _activityPage: Exact<server.ActivityPage, web.ActivityPage> = true;
// The verdicts the board publishes beside its problems — freshness, the stats strip's
// counts and the scoped headline. The client renders them; it no longer derives them.
const _freshness: Exact<server.BoardFreshness, web.BoardFreshness> = true;
const _deployCounts: Exact<server.DeployCounts, web.DeployCounts> = true;
const _scope: Exact<server.BoardScope, web.BoardScope> = true;
const _issueSource: Exact<server.Problem["source"], IssueSource> = true;
void [
  _board, _problem, _activityRow, _activityTone, _activityKind, _indicator,
  _activityCursor, _activityPage, _freshness, _deployCounts, _scope, _issueSource,
];

describe("board-types parity (web mirrors server)", () => {
  it("INDICATOR_STATE covers every member of the server's Indicator union, with no extras", () => {
    // A Record<BoardIndicator, …> is exhaustive by construction at compile time — but only
    // this key check catches a member removed from both the union and the map together.
    expect(Object.keys(INDICATOR_STATE).sort()).toEqual(["degraded", "operational", "outage"]);
  });
});

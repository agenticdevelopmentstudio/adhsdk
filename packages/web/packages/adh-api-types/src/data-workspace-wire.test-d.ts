// The drift gate for `@adh-sdk/data`'s workspace row — the same arrangement, for the same reason,
// as ./data-profile-wire.test-d.ts (read its header first). `data` types `WorkspaceRow` by hand
// because the generated spec lives here, in the adh vocabulary tier above that portable package,
// and `tools/check_boundaries.py` refuses the import that would let it derive the row. A hand
// transcription with nothing measuring it is the failure that file describes: a backend rename
// regenerates ./schema.ts, every consumer still compiles, and the header's workspace menu, the
// hub's rail and its workspace gate read `undefined`. So the measuring happens here, pointing the
// sanctioned way.
//
// The row is measured as `data` READS it: `workspacesApi.listAll()` maps the wire through
// `fromV1`, so the generated row goes through `FromV1` (the type of that mapping) before it is
// compared. A snake_case column added to the row is then measured under the name the client sees.
//
// Like the profile gate, this reads `data`'s BUILT `dist/*.d.ts` (fail-closed: an unbuilt `data`
// fails to resolve) and the spec straight from ./schema.ts. Run by `tsc --noEmit`, not vitest.
import type { SuccessBody } from "./index";
import type { FromV1, WorkspaceRow, WorkspaceType } from "@adh-sdk/data";

// ── assertion utilities (same set as ./index.test-d.ts) ──────────────────────────────────
type Expect<T extends true> = T;
type Equal<A, B> =
  (<T>() => T extends A ? 1 : 2) extends <T>() => T extends B ? 1 : 2 ? true : false;
type Extends<A, B> = A extends B ? true : false;
type IsNever<T> = [T] extends [never] ? true : false;
type IsAny<T> = 0 extends 1 & T ? true : false;

// ── what the backend actually declares, as `fromV1` hands it to `data` ───────────────────
type WireWorkspace = SuccessBody<"/v1/workspaces", "get">["data"][number];
type ReadWorkspace = FromV1<WireWorkspace>;

// Exported so every assertion is referenced and none can be dead-stripped.
export type Checks = [
  // ── FAIL TO CHECK ───────────────────────────────────────────────────────────────────
  // A mistyped path resolves to `never`, which satisfies every check below; `any` likewise.
  Expect<Equal<IsNever<WireWorkspace>, false>>,
  Expect<Equal<IsAny<WireWorkspace>, false>>,
  Expect<Equal<IsNever<ReadWorkspace>, false>>,

  // ── READ SIDE ───────────────────────────────────────────────────────────────────────
  // Every row the backend sends satisfies the transcription: a renamed, removed or retyped
  // column stops it being assignable. One way only, as in the profile gate: a column the
  // client does not read cannot come out `undefined` anywhere.
  Expect<Extends<ReadWorkspace, WorkspaceRow>>,

  // `type` is pinned EXACTLY, both ways. A type the backend adds already fails the read side
  // (every switcher must decide how to show it: its route, its de-duplication by slug, its
  // composite id). The reverse direction catches the backend dropping one, which the read side
  // cannot see, and which leaves the client switching on a type that never arrives.
  Expect<Equal<ReadWorkspace["type"], WorkspaceType>>,
  Expect<Equal<WorkspaceRow["type"], WorkspaceType>>,

  // The keys the client names are all keys of the row as read: no field the backend dropped.
  Expect<Equal<Exclude<keyof WorkspaceRow, keyof ReadWorkspace>, never>>,
];

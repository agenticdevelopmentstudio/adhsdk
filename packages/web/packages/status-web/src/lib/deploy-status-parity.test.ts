import { describe, it, expect } from "vitest";
import type * as web from "./deploy-status";
// The SERVER's vocabulary module. Type-only: the rules over these unions (phase mappings,
// combinedStatus, in-flight, the unconfirmed demotion) live on the server alone now, so
// what is left to hold together is the vocabulary the client renders.
import type * as server from "@adh-sdk/status-server/deploy-status";

// DRIFT GUARD. web/src/lib/deploy-status.ts mirrors the server's deploy unions by hand.
// A union member added on one side only would mislabel deploys with no compile error, so
// the assertions below only compile while both sides agree. The dashboard host's `web`
// typecheck names this file under `files`, which checks the vendored pair as well.

/** Mutual assignability: a union member on one side only stops this resolving to `true`. */
type Exact<A, B> = [A] extends [B] ? ([B] extends [A] ? true : never) : never;

const vocabularyAgrees: [
  Exact<server.DeployStatus, web.DeployStatus>,
  Exact<server.BuildPhase, web.BuildPhase>,
  Exact<server.DeployPhase, web.DeployPhase>,
] = [true, true, true];

describe("deploy-status vocabulary parity (web mirrors server)", () => {
  it("compiles only while the unions agree", () => {
    expect(vocabularyAgrees).toEqual([true, true, true]);
  });
});

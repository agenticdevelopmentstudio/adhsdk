import { describe, it, expect } from "vitest";
import { QUEUED_VERB } from "./overview";
import { BUILD_VERB } from "@agentic-toolkit/status-server/board";

// DRIFT GUARD. Queued and building rows both arrive with tone "progress"; the client tells
// them apart by the server's verb alone (`isActiveBuild`). If the server renamed the queued
// verb, every queued row would read as running and the filtered view would stop sorting.
describe("activity verb parity (web mirrors server)", () => {
  it("names a queued build with the server's own verb", () => {
    expect(QUEUED_VERB).toBe(BUILD_VERB.queued);
  });

  it("gives no other build phase the queued verb", () => {
    const others = Object.entries(BUILD_VERB).filter(([phase]) => phase !== "queued");
    for (const [, verb] of others) expect(verb).not.toBe(QUEUED_VERB);
  });
});

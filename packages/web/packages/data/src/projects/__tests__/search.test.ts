// URL/method/short-circuit contract for the cross-board search client.
//
// Same arrangement as the other /v1 client tests: only `fetch` is stubbed, so the pager, the
// query building and the mapper run for real. Three things are worth pinning, and each is a decision
// this module makes rather than a call it forwards:
//
//   1. a blank `q` never leaves the process. The server 400s on one, and an empty search box is
//      the ordinary state of a search box — a request would turn typing into an error;
//   2. the optional params are OMITTED when unset rather than sent empty, because `?workspace=`
//      is fail-closed on the server: an empty slug and no slug must not mean the same thing by
//      accident on the wire;
//   3. the page comes back in the SERVER's order. Nothing here re-sorts by rank — a client
//      holding one page cannot rank a result set it only partly has, and the keyed-hit-first
//      rule lives in SQL where the key is known.
import { describe, expect, it, beforeEach } from "vitest";

import { projectSearchApi, toWorkItemSearchHit, EMPTY_WORK_ITEM_SEARCH } from "../search";
import type { WorkItemSearchHitRow } from "../wire";
import { fetchMock, installFetch, paramsAt, pathAt, respondWith, v1List } from "../../__tests__/v1-fetch";

beforeEach(() => installFetch());

// A hit as /v1 sends it: snake_case, a unix-second `updated`.
const wireHit = (extra: Record<string, unknown> = {}) => ({
  object: "work_item_search_hit",
  id: "w1",
  project_id: "p1",
  project_name: "Alpha",
  item_key: "ALP-1",
  title: "Tungsten filament rollout",
  status_id: "s1",
  updated: 1767225600,
  snippet: "the plan for the alpha board",
  rank: 0.6,
  ...extra,
});

const hitRow = (extra: Partial<WorkItemSearchHitRow> = {}): WorkItemSearchHitRow => ({
  id: "w1",
  projectId: "p1",
  projectName: "Alpha",
  itemKey: "ALP-1",
  title: "Tungsten filament rollout",
  statusId: "s1",
  updatedAt: "u",
  snippet: "the plan for the alpha board",
  rank: 0.6,
  ...extra,
});


describe("projectSearchApi.workItems", () => {
  it("sends no workspace when none is asked for, and the legacy default page of 20", async () => {
    respondWith(v1List([wireHit()]));
    await projectSearchApi.workItems("tungsten");
    expect(pathAt(0)).toBe("/api/v1/work_items/search");
    expect(paramsAt(0).get("q")).toBe("tungsten");
    expect(paramsAt(0).has("workspace")).toBe(false);
    expect(paramsAt(0).get("limit")).toBe("20");
  });

  it("carries a workspace and a limit when given", async () => {
    await projectSearchApi.workItems("tungsten", { workspace: "acme", limit: 5 });
    expect(paramsAt(0).get("q")).toBe("tungsten");
    expect(paramsAt(0).get("workspace")).toBe("acme");
    expect(paramsAt(0).get("limit")).toBe("5");
  });

  it("encodes a phrase rather than pasting it into the URL", async () => {
    await projectSearchApi.workItems("two words & a symbol");
    expect(paramsAt(0).get("q")).toBe("two words & a symbol");
    expect(String(fetchMock.mock.calls[0]![0])).not.toContain(" & ");
  });

  it("never sends a blank query — an empty box is a state, not a 400", async () => {
    expect(await projectSearchApi.workItems("")).toBe(EMPTY_WORK_ITEM_SEARCH);
    expect(await projectSearchApi.workItems("   ")).toBe(EMPTY_WORK_ITEM_SEARCH);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("trims what it does send, so a trailing space is not a different search", async () => {
    await projectSearchApi.workItems("  tungsten  ");
    expect(paramsAt(0).get("q")).toBe("tungsten");
  });

  it("keeps the server's order and reports the limit it ACTUALLY applied (clamped to the page max)", async () => {
    // /v1 caps a page at 100 rather than refusing, so the reported limit can differ from what was
    // asked. A client that displayed its own request would lie about how much it is showing.
    const weaker = wireHit({ id: "w2", item_key: "ALP-2", title: "Order more tungsten", rank: 0.1 });
    respondWith(v1List([weaker, wireHit()], true));
    const result = await projectSearchApi.workItems("tungsten", { limit: 500 });
    expect(result.results.map((r) => r.id)).toEqual(["w2", "w1"]);
    expect(paramsAt(0).get("limit")).toBe("100");
    expect(result.limit).toBe(100);
    expect(result.hasMore).toBe(true);
    expect(result.results[0]!.itemKey).toBe("ALP-2");
  });
});

describe("toWorkItemSearchHit", () => {
  it("carries the board's NAME through, which is the field a card row does not have", async () => {
    const hit = toWorkItemSearchHit(hitRow({ projectName: "Beta" }));
    expect(hit.projectName).toBe("Beta");
    expect(hit.itemKey).toBe("ALP-1");
  });

  it("defaults a missing snippet/rank rather than emitting undefined", () => {
    // A title-only hit's headline can come back empty; a renderer should get "" and show the
    // title alone, not `undefined` printed into the DOM.
    const bare = { ...hitRow(), snippet: undefined, rank: undefined } as unknown as
      WorkItemSearchHitRow;
    const hit = toWorkItemSearchHit(bare);
    expect(hit.snippet).toBe("");
    expect(hit.rank).toBe(0);
  });
});

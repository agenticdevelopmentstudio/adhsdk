import { beforeEach, describe, expect, it } from "vitest";

import { taxonomyApi } from "../taxonomy";
import { fetchMock, initAt, installFetch, pathAt, respondOnce, v1List } from "../../__tests__/v1-fetch";

// The real `authedJson` / `listAllV1` run; only the network is faked.

beforeEach(() => installFetch());

const edge = (id: string, parent: string, child: string, deleted_at: string | null = null) => ({
  id,
  parent_id: parent,
  child_id: child,
  sort_order: 0,
  deleted_at,
});

describe("taxonomyApi.removeCategoryParent", () => {
  it("HDM-017 resolves with zero DELETE calls when no edge with that parent exists for the child", async () => {
    respondOnce(
      v1List([
        edge("e1", "p-other", "child"), // a different parent of the same child
        edge("e2", "p-wanted", "someone-else"), // the wanted parent, but another child
        edge("e3", "p-wanted", "child", "2026-01-01T00:00:00Z"), // a tombstoned link
      ]),
    );
    await expect(taxonomyApi.removeCategoryParent("child", "p-wanted")).resolves.toBeUndefined();
    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(pathAt(0)).toBe("/api/v1/content/category_edges");
    expect(initAt(0).method ?? "GET").toBe("GET");
  });

  it("HDM-017 deletes exactly the live matching edge when one exists", async () => {
    respondOnce(v1List([edge("e1", "p-other", "child"), edge("e2", "p-wanted", "child")]));
    fetchMock.mockResolvedValueOnce({ ok: true, status: 204, json: async () => ({}), text: async () => "" });
    await taxonomyApi.removeCategoryParent("child", "p-wanted");
    expect(fetchMock).toHaveBeenCalledTimes(2);
    expect(pathAt(1)).toBe("/api/v1/content/category_edges/e2");
    expect(initAt(1).method).toBe("DELETE");
  });
});

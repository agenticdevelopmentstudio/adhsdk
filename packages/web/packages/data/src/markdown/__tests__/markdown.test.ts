import { describe, it, expect, vi } from "vitest";

vi.mock("../../http", async (orig) => ({
  ...(await orig<Record<string, unknown>>()),
  authedJson: vi.fn(),
  authedRequest: vi.fn(),
}));

import { withTags, categoryNodes, tagNodes } from "../markdown";
import type { MarkdownCategoryTreeBody, MarkdownTagSetBody } from "../wire";
import { installFetch, paramsAt, pathAt, urlAt, fetchMock } from "../../__tests__/v1-fetch";

// Regression: the ResearchPane crashed ("tags is not iterable" / reading `length`
// of undefined) when a document arrived without a `tags` array — which happens
// when the backend deploy is OLDER than this frontend (before the category/tags
// migration). The API boundary must guarantee `tags` is always an array.
describe("withTags", () => {
  it("HDM-001 defaults a missing tags field to []", () => {
    const doc = { id: "d1", title: "Doc" } as unknown as { id: string; title: string; tags: string[] };
    expect(withTags(doc).tags).toEqual([]);
  });

  it("HDM-002 defaults a null tags field to []", () => {
    const doc = { id: "d1", tags: null } as unknown as { id: string; tags: string[] };
    expect(withTags(doc).tags).toEqual([]);
  });

  it("HDM-003 passes a real array through unchanged (same reference, no needless copy)", () => {
    const doc = { id: "d1", tags: ["a", "b"] };
    expect(withTags(doc)).toBe(doc);
  });

  it("preserves the other fields when defaulting", () => {
    const doc = { id: "d1", title: "Doc" } as unknown as { id: string; title: string; tags: string[] };
    expect(withTags(doc)).toMatchObject({ id: "d1", title: "Doc", tags: [] });
  });
});

// The same skew one migration later, and the same rule: the boundary owes the notebook
// rail an array. What is worth pinning is that the fallback is the FLAT LIST and not an
// empty one — `items` carries every category such a backend has, and a category is used
// by NAME everywhere downstream (`?category=<name>` filtering, `slugFor(name, id)`), so
// returning [] would blank a rail whose contents arrived in the very same response.
describe("categoryNodes", () => {
  const old = (items: string[]) => ({ items }) as unknown as MarkdownCategoryTreeBody;

  it("HDM-004 passes real nodes through unchanged (same reference, no needless copy)", () => {
    const res = { items: ["Meetings"], nodes: [{ id: "c1", name: "Meetings", parentIds: [], sortOrder: 0 }] };
    expect(categoryNodes(res)).toBe(res.nodes);
  });

  it("HDM-005 prefers nodes even when they are EMPTY — a workspace with no categories is not skew", () => {
    // `items` and `nodes` describe one set: a current backend that sends `nodes: []` sent
    // `items: []` too. Falling back on emptiness rather than absence would be untestable
    // here and identical in effect — but it would rebuild names on a backend that has
    // already answered, which is the wrong reading of a legitimately empty workspace.
    expect(categoryNodes({ items: [], nodes: [] })).toEqual([]);
  });

  it("HDM-006 rebuilds an older backend's flat names as roots, in the order it sent them", () => {
    expect(categoryNodes(old(["Admin", "Meetings", "Reading"]))).toEqual([
      { id: "Admin", name: "Admin", parentIds: [], sortOrder: 0 },
      { id: "Meetings", name: "Meetings", parentIds: [], sortOrder: 1 },
      { id: "Reading", name: "Reading", parentIds: [], sortOrder: 2 },
    ]);
  });

  it("names each rebuilt row by its own name — the only identity such a backend has", () => {
    // A name is unique per owner, so it is a usable key for the rail's fold; and it never
    // travels back, because a flat list has no children and the only write taking an id is
    // `createCategory({ parentIds })` on a level the rail cannot publish.
    const [meetings] = categoryNodes(old(["Meetings"]));
    expect(meetings?.id).toBe("Meetings");
    expect(meetings?.name).toBe("Meetings");
  });

  it("HDM-007 yields [] when NEITHER field is an array, rather than throwing", () => {
    expect(categoryNodes({} as unknown as MarkdownCategoryTreeBody)).toEqual([]);
  });
});

// The tag twin of the above. It differs in one way worth pinning: a rebuilt id is the LABEL,
// and the taxonomy door (`/content/keywords/{id}`) takes only row ids — so against such a
// backend a rename or delete fails loudly. What must stay true is that it cannot fail QUIETLY
// by addressing some other row, which holds because real ids are uuids.
describe("tagNodes", () => {
  const old = (items: string[]) => ({ items }) as unknown as MarkdownTagSetBody;

  it("passes real nodes through unchanged (same reference, no needless copy)", () => {
    const res = { items: ["draft"], nodes: [{ id: "k1", label: "draft" }] };
    expect(tagNodes(res)).toBe(res.nodes);
  });

  it("prefers nodes even when they are EMPTY — a workspace with no tags is not skew", () => {
    expect(tagNodes({ items: [], nodes: [] })).toEqual([]);
  });

  it("HDM-008 rebuilds an older backend's flat labels, in the order it sent them", () => {
    expect(tagNodes(old(["alpha", "beta"]))).toEqual([
      { id: "alpha", label: "alpha" },
      { id: "beta", label: "beta" },
    ]);
  });

  it("yields [] when NEITHER field is an array, rather than throwing", () => {
    expect(tagNodes({} as unknown as MarkdownTagSetBody)).toEqual([]);
  });
});

// `routeAvailable` — the editor's "is this slug free?" question, answered by the endpoint
// Task 2 added. The transport is mocked because what is worth pinning here is the URL: the
// route travels as a PATH SEGMENT, so it must be encoded, and the workspace must ride along
// (an org member editing an org document asks about the ORG's slug space, not their own).
describe("markdownApi.routeAvailable", () => {
  it("HDM-009 asks the author-scoped endpoint with both segments encoded", async () => {
    const { authedJson } = await import("../../http");
    const spy = vi.mocked(authedJson);
    spy.mockResolvedValueOnce({ available: true, reason: "ok" });
    const { markdownApi } = await import("../markdown");

    await markdownApi.routeAvailable("doc 1", "a/b", { workspace: "acme" });

    // /v1 spells it as a filter on the collection: route and excluding are query values, so
    // both are still encoded, and the workspace still rides along.
    expect(spy).toHaveBeenCalledWith("/api/v1/papers?route=a%2Fb&excluding=doc+1&workspace=acme");
  });

  it("HDM-010 returns the backend's verdict unchanged — the reason drives the message", async () => {
    const { authedJson } = await import("../../http");
    vi.mocked(authedJson).mockResolvedValueOnce({ available: false, reason: "reserved" });
    const { markdownApi } = await import("../markdown");

    expect(await markdownApi.routeAvailable("d1", "home")).toEqual({
      available: false,
      reason: "reserved",
    });
  });
});

// Conflict mapping: a 409 from the backend becomes a sentence the form shows inline, and the
// original error is discarded; any other error passes through untouched.
describe("markdownApi conflict mapping", () => {
  const conflict = () => Object.assign(new Error("duplicate"), { status: 409 });

  it("HDM-011 publish maps a 409 to the friendly route-in-use error, discarding the original", async () => {
    const { authedJson } = await import("../../http");
    vi.mocked(authedJson).mockRejectedValueOnce(conflict());
    const { markdownApi } = await import("../markdown");
    const err = await markdownApi.publish("d1", "my-paper").catch((e: Error) => e);
    expect(err).toBeInstanceOf(Error);
    expect((err as Error).message).toBe("The route “my-paper” is already used by one of your papers.");
    expect((err as { status?: number }).status).toBeUndefined();
  });

  it("HDM-011 publish rethrows a non-conflict error unchanged", async () => {
    const { authedJson } = await import("../../http");
    const boom = Object.assign(new Error("down"), { status: 500 });
    vi.mocked(authedJson).mockRejectedValueOnce(boom);
    const { markdownApi } = await import("../markdown");
    await expect(markdownApi.publish("d1", "r")).rejects.toBe(boom);
  });

  it("HDM-012 createCategory maps a 409 to the friendly already-exists error", async () => {
    const { authedJson } = await import("../../http");
    vi.mocked(authedJson).mockRejectedValueOnce(conflict());
    const { markdownApi } = await import("../markdown");
    await expect(markdownApi.createCategory({ name: "Meetings" })).rejects.toThrow(
      "A category named “Meetings” already exists somewhere else.",
    );
  });
});

// The list query: the corpus flags are presence-only, so a `false` is the unfiltered list and
// must not travel as `noted=false`.
describe("markdownApi.list query", () => {
  it("HDM-018 omits `noted` and `doc` entirely when they are false", async () => {
    installFetch();
    const { markdownApi } = await import("../markdown");
    await markdownApi.list({}, { noted: false, doc: false });
    expect(pathAt(0)).toBe("/api/v1/papers");
    expect(paramsAt(0).has("noted")).toBe(false);
    expect(paramsAt(0).has("doc")).toBe(false);
    expect(urlAt(0)).not.toContain("noted");
    expect(urlAt(0)).not.toContain("doc=");

    // Control: true is sent.
    fetchMock.mockClear();
    await markdownApi.list({}, { noted: true, doc: true });
    expect(paramsAt(0).get("noted")).toBe("true");
    expect(paramsAt(0).get("doc")).toBe("true");
  });
});

// Conformance tests for docsApi — one test per vector in
// cookbook/adh/hub/content/docs-client/conformance-test-vectors.md. The real /v1 pager,
// authedJson/authedRequest and the markdown mappers run; only `fetch` is stubbed.
import { describe, expect, it, vi, beforeEach, afterEach } from "vitest";

import { docsApi, taxonomyApi, type CreateDocBody } from "../docs";
import {
  fetchMock,
  installFetch,
  respondOnce,
  respondWith,
  v1List,
  urlAt,
  pathAt,
  paramsAt,
  initAt,
  bodyAt,
} from "../../__tests__/v1-fetch";

beforeEach(() => installFetch());
afterEach(() => vi.unstubAllGlobals());

const paper = (over: Record<string, unknown> = {}) => ({
  id: "d1",
  title: "T",
  content: "x",
  category: null,
  tags: [],
  visibility: "private",
  ...over,
});

describe("docsApi conformance", () => {
  it("HDD-001: list is scoped to the doc marker and the workspace", async () => {
    await docsApi.list({}, { workspace: "acme" });
    expect(pathAt()).toBe("/api/v1/papers");
    const p = paramsAt();
    expect(p.get("doc")).toBe("true");
    expect(p.get("workspace")).toBe("acme");
    expect(p.get("limit")).toBe("100");
    expect(p.has("noted")).toBe(false);
  });

  it("HDD-002: create sends the doc marker in the POST body", async () => {
    respondOnce(paper());
    await docsApi.create({ content: "# Hello" });
    expect(initAt().method).toBe("POST");
    expect(initAt().body).toBe(JSON.stringify({ content: "# Hello", doc: true }));
  });

  it("HDD-003: create keeps a caller's note field and still sets doc", async () => {
    respondOnce(paper());
    await docsApi.create({ content: "x", note: true } as CreateDocBody);
    expect(bodyAt()).toEqual({ content: "x", note: true, doc: true });
  });

  it("HDD-004: get by id carries no doc marker and returns the full row", async () => {
    respondOnce(paper({ id: "note-only-id", title: "Jotted", content: "body" }));
    const doc = await docsApi.get("note-only-id");
    expect(pathAt()).toBe("/api/v1/papers/note-only-id");
    expect(paramsAt().has("doc")).toBe(false);
    expect(paramsAt().has("noted")).toBe(false);
    expect(initAt().body).toBeUndefined();
    expect(doc).toMatchObject({ id: "note-only-id", title: "Jotted", content: "body" });
  });

  it("HDD-005: a create response without tags resolves with tags []", async () => {
    respondOnce({ id: "d1", title: "T", content: "x", category: null, visibility: "private" });
    const doc = await docsApi.create({ content: "x" });
    expect(doc.tags).toEqual([]);
  });

  it("HDD-006: a flat categories response degrades to root nodes in sent order", async () => {
    respondOnce({ items: ["Admin", "Meetings"] });
    expect(await docsApi.categories()).toEqual([
      { id: "Admin", name: "Admin", parentIds: [], sortOrder: 0 },
      { id: "Meetings", name: "Meetings", parentIds: [], sortOrder: 1 },
    ]);
    expect(pathAt()).toBe("/api/v1/paper_categories");
  });

  it("HDD-007: a flat tags response degrades to id=label nodes", async () => {
    respondOnce({ items: ["draft", "final"] });
    expect(await docsApi.tagSet()).toEqual([
      { id: "draft", label: "draft" },
      { id: "final", label: "final" },
    ]);
    expect(pathAt()).toBe("/api/v1/paper_tags");
  });

  it("HDD-008: a 409 on createCategory rejects with the friendly message", async () => {
    respondOnce({ error: "conflict" }, 409);
    await expect(docsApi.createCategory({ name: "Meetings" })).rejects.toThrow(
      "A category named “Meetings” already exists somewhere else.",
    );
    expect(pathAt()).toBe("/api/v1/paper_categories");
    expect(initAt().method).toBe("POST");
  });

  it("HDD-009: remove resolves void on 204 without parsing a body", async () => {
    const json = vi.fn();
    fetchMock.mockResolvedValueOnce({ ok: true, status: 204, json, text: async () => "" });
    await expect(docsApi.remove("d1")).resolves.toBeUndefined();
    expect(initAt().method).toBe("DELETE");
    expect(pathAt()).toBe("/api/v1/papers/d1");
    expect(json).not.toHaveBeenCalled();
  });

  it("HDD-010: taxonomy ops are not workspace scoped", async () => {
    respondOnce({ id: "c1", name: "Renamed", sort_order: 0 });
    await taxonomyApi.renameCategory("c1", "Renamed");
    expect(pathAt()).toBe("/api/v1/content/categories/c1");
    expect(new URL(urlAt(), "http://x").search).toBe("");
    expect(bodyAt()).toEqual({ name: "Renamed" });
  });

  it("HDD-011: list pages through the whole collection, not just the first 200", async () => {
    const rows = (from: number, n: number) =>
      Array.from({ length: n }, (_, i) => ({ id: `d${from + i}`, title: `T${from + i}`, tags: [], visibility: "private" }));
    respondOnce(v1List(rows(0, 100), true));
    respondOnce(v1List(rows(100, 100), true));
    respondOnce(v1List(rows(200, 50), false));
    const out = await docsApi.list();
    expect(out).toHaveLength(250);
    expect(fetchMock).toHaveBeenCalledTimes(3);
    expect(paramsAt(1).get("starting_after")).toBe("d99");
    expect(paramsAt(2).get("starting_after")).toBe("d199");
  });

  it("HDD-012: get propagates the backend's 404 unmodified", async () => {
    respondWith({ error: "not found" }, 404);
    const err = await docsApi.get("missing").catch((e: unknown) => e);
    expect(err).toBeInstanceOf(Error);
    expect((err as { status?: number }).status).toBe(404);
  });
});

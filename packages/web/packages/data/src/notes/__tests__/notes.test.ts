// Conformance tests for notesApi — one test per vector in
// cookbook/adh/hub/content/notes-client/conformance-test-vectors.md. The real /v1 pager,
// authedJson/authedRequest and the markdown mappers run; only `fetch` is stubbed.
import { describe, expect, it, vi, beforeEach, afterEach } from "vitest";

import { notesApi, taxonomyApi, type CreateNoteBody } from "../notes";
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

describe("notesApi conformance", () => {
  it("HDN-001: list is scoped to the noted marker and the workspace", async () => {
    await notesApi.list({}, { workspace: "acme" });
    expect(pathAt()).toBe("/api/v1/papers");
    const p = paramsAt();
    expect(p.get("noted")).toBe("true");
    expect(p.get("workspace")).toBe("acme");
    expect(p.get("limit")).toBe("100");
    expect(p.has("doc")).toBe(false);
  });

  it("HDN-002: create sends the note marker in the POST body", async () => {
    respondOnce(paper());
    await notesApi.create({ content: "# Hello" });
    expect(initAt().method).toBe("POST");
    expect(initAt().body).toBe(JSON.stringify({ content: "# Hello", note: true }));
  });

  it("HDN-003: create keeps a caller's doc field and still sets note", async () => {
    respondOnce(paper());
    await notesApi.create({ content: "x", doc: true } as CreateNoteBody);
    expect(bodyAt()).toEqual({ content: "x", doc: true, note: true });
  });

  it("HDN-004: get by id carries no note marker and returns the full row", async () => {
    respondOnce(paper({ id: "doc-only-id", title: "Written", content: "body" }));
    const note = await notesApi.get("doc-only-id");
    expect(pathAt()).toBe("/api/v1/papers/doc-only-id");
    expect(paramsAt().has("noted")).toBe(false);
    expect(paramsAt().has("doc")).toBe(false);
    expect(initAt().body).toBeUndefined();
    expect(note).toMatchObject({ id: "doc-only-id", title: "Written", content: "body" });
  });

  it("HDN-005: a create response without tags resolves with tags []", async () => {
    respondOnce({ id: "d1", title: "T", content: "x", category: null, visibility: "private" });
    const note = await notesApi.create({ content: "x" });
    expect(note.tags).toEqual([]);
  });

  it("HDN-006: a flat categories response degrades to root nodes in sent order", async () => {
    respondOnce({ items: ["Admin", "Meetings"] });
    expect(await notesApi.categories()).toEqual([
      { id: "Admin", name: "Admin", parentIds: [], sortOrder: 0 },
      { id: "Meetings", name: "Meetings", parentIds: [], sortOrder: 1 },
    ]);
    expect(pathAt()).toBe("/api/v1/paper_categories");
  });

  it("HDN-007: tags resolves to the flat labels and ignores nodes", async () => {
    respondOnce({
      items: ["draft", "final"],
      nodes: [
        { id: "k1", label: "draft" },
        { id: "k2", label: "final" },
      ],
    });
    expect(await notesApi.tags()).toEqual(["draft", "final"]);
    expect(pathAt()).toBe("/api/v1/paper_tags");
  });

  it("HDN-008: a flat tags response degrades tagSet to id=label nodes", async () => {
    respondOnce({ items: ["draft", "final"] });
    expect(await notesApi.tagSet()).toEqual([
      { id: "draft", label: "draft" },
      { id: "final", label: "final" },
    ]);
    expect(pathAt()).toBe("/api/v1/paper_tags");
  });

  it("HDN-009: a 409 on createCategory rejects with the friendly message", async () => {
    respondOnce({ error: "conflict" }, 409);
    await expect(notesApi.createCategory({ name: "Meetings" })).rejects.toThrow(
      "A category named “Meetings” already exists somewhere else.",
    );
    expect(pathAt()).toBe("/api/v1/paper_categories");
    expect(initAt().method).toBe("POST");
  });

  it("HDN-010: remove resolves void on 204 without parsing a body", async () => {
    const json = vi.fn();
    fetchMock.mockResolvedValueOnce({ ok: true, status: 204, json, text: async () => "" });
    await expect(notesApi.remove("d1")).resolves.toBeUndefined();
    expect(initAt().method).toBe("DELETE");
    expect(pathAt()).toBe("/api/v1/papers/d1");
    expect(json).not.toHaveBeenCalled();
  });

  it("HDN-011: taxonomy ops are not workspace scoped", async () => {
    respondOnce({ id: "c1", name: "Renamed", sort_order: 0 });
    await taxonomyApi.renameCategory("c1", "Renamed");
    expect(pathAt()).toBe("/api/v1/content/categories/c1");
    expect(new URL(urlAt(), "http://x").search).toBe("");
    expect(bodyAt()).toEqual({ name: "Renamed" });
  });

  it("HDN-012: list pages through the whole collection, not just the first 200", async () => {
    const rows = (from: number, n: number) =>
      Array.from({ length: n }, (_, i) => ({ id: `n${from + i}`, title: `T${from + i}`, tags: [], visibility: "private" }));
    respondOnce(v1List(rows(0, 100), true));
    respondOnce(v1List(rows(100, 100), true));
    respondOnce(v1List(rows(200, 50), false));
    const out = await notesApi.list();
    expect(out).toHaveLength(250);
    expect(fetchMock).toHaveBeenCalledTimes(3);
    expect(paramsAt(1).get("starting_after")).toBe("n99");
    expect(paramsAt(2).get("starting_after")).toBe("n199");
  });

  it("HDN-013: get propagates the backend's 404 unmodified", async () => {
    respondWith({ error: "not found" }, 404);
    const err = await notesApi.get("missing").catch((e: unknown) => e);
    expect(err).toBeInstanceOf(Error);
    expect((err as { status?: number }).status).toBe(404);
  });

  it("HDN-014: categories returns the nodes rows, not bare names", async () => {
    respondOnce({
      items: ["Meetings"],
      nodes: [{ id: "c1", name: "Meetings", parent_ids: [], sort_order: 0 }],
    });
    const out = await notesApi.categories();
    expect(out).toEqual([{ id: "c1", name: "Meetings", parentIds: [], sortOrder: 0 }]);
    expect(typeof out[0]).toBe("object");
  });
});

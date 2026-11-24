// Conformance tests for the v1-case recipe (cookbook/data/services/v1-case): the /v1 wire
// boundary. The pure mappers run for real; the three request-layer functions are wrapped in
// spies that default to the real implementation (so paging runs against the stubbed `fetch`)
// and are overridden per test where a vector needs to hand back a canned result or error.
import { beforeEach, describe, expect, expectTypeOf, it, vi } from "vitest";
import { fetchMock, installFetch, respondOnce, urlAt } from "./v1-fetch";

vi.mock("../http", async (importOriginal) => {
  const actual = await importOriginal<typeof import("../http")>();
  return {
    ...actual,
    authedJson: vi.fn(actual.authedJson),
    listAllV1: vi.fn(actual.listAllV1),
    listV1Page: vi.fn(actual.listV1Page),
  };
});

import * as http from "../http";
import { fromV1, toV1Body, v1Json, v1List, v1Page, v1Write, type FromV1 } from "../v1-case";

const real = await vi.importActual<typeof import("../http")>("../http");

beforeEach(() => {
  installFetch();
  vi.mocked(http.authedJson).mockReset().mockImplementation(real.authedJson);
  vi.mocked(http.listAllV1).mockReset().mockImplementation(real.listAllV1);
  vi.mocked(http.listV1Page).mockReset().mockImplementation(real.listV1Page);
});

describe("v1-case mappers", () => {
  it("v1-case-001 camelizes keys and turns created/updated into ISO createdAt/updatedAt", () => {
    expect(fromV1({ id: "p1", project_id: "x", created: 1700000000, updated: 1700000060 })).toEqual({
      id: "p1",
      projectId: "x",
      createdAt: "2023-11-14T22:13:20.000Z",
      updatedAt: "2023-11-14T22:14:20.000Z",
    });
  });

  it("v1-case-002 camelizing is idempotent", () => {
    expect(fromV1({ project_id: "a" })).toEqual({ projectId: "a" });
    expect(fromV1({ projectId: "a" })).toEqual({ projectId: "a" });
  });

  it("v1-case-003 drops the object type tag", () => {
    expect(fromV1({ object: "project", id: "p1" })).toEqual({ id: "p1" });
  });

  it("v1-case-004 drops the object tag at every depth", () => {
    expect(fromV1({ data: [{ object: "item", item_key: "K-1" }] })).toEqual({ data: [{ itemKey: "K-1" }] });
  });

  it("v1-case-005 keeps the keys inside counts", () => {
    expect(fromV1({ counts: { in_progress: 3 } })).toEqual({ counts: { in_progress: 3 } });
  });

  it("v1-case-006 keeps every nested key of config, detail, body and value", () => {
    expect(fromV1({ config: { sort_by: "x" }, detail: { a_b: 1 }, body: { c_d: 2 }, value: { e_f: 3 } })).toEqual({
      config: { sort_by: "x" },
      detail: { a_b: 1 },
      body: { c_d: 2 },
      value: { e_f: 3 },
    });
  });

  it("v1-case-007 keeps the keys inside config on write", () => {
    expect(toV1Body({ config: { sortBy: "x" } })).toEqual({ config: { sortBy: "x" } });
  });

  it("v1-case-008 snake-cases keys on write", () => {
    expect(toV1Body({ projectId: "p", createdAt: "x" })).toEqual({ project_id: "p", created_at: "x" });
  });

  it("v1-case-009 keeps null and drops undefined on write", () => {
    const out = toV1Body({ dueDate: null, note: undefined }) as Record<string, unknown>;
    expect(out).toEqual({ due_date: null });
    expect("note" in out).toBe(false);
  });

  it("v1-case-010 keeps an object key on write", () => {
    expect(toV1Body({ object: "x" })).toEqual({ object: "x" });
  });

  it("v1-case-011 passes a non-number created through unchanged", () => {
    expect(fromV1({ created: null })).toEqual({ created: null });
  });

  it("v1-case-012 maps a non-finite created to a null createdAt", () => {
    expect(fromV1({ created: NaN })).toEqual({ createdAt: null });
  });

  it("v1-case-013 passes scalars through", () => {
    expect(fromV1(null)).toBeNull();
    expect(fromV1("s")).toBe("s");
    expect(toV1Body(undefined)).toBeUndefined();
  });

  it("v1-case-014 recurses into arrays", () => {
    expect(fromV1([{ a_b: 1 }, { c_d: 2 }])).toEqual([{ aB: 1 }, { cD: 2 }]);
  });

  it("v1-case-015 does not mutate its input and returns a distinct object", () => {
    const x = { projectId: "p", nested: { innerKey: 1 } };
    const copy = structuredClone(x);
    const out = toV1Body(x) as typeof x;
    expect(x).toEqual(copy);
    expect(out).not.toBe(x);
    expect(out.nested).not.toBe(x.nested);
  });

  it("v1-case-016 lets the later of two colliding keys win", () => {
    expect(fromV1({ project_id: "a", projectId: "b" })).toEqual({ projectId: "b" });
  });

  it("v1-case-024 casts without checking the shape", () => {
    expect(fromV1<{ a: number }>({ b: "x" })).toEqual({ b: "x" });
  });
});

describe("v1-case wrappers", () => {
  it("v1-case-017 v1Write returns method and a snake-cased JSON body with no headers", () => {
    const init = v1Write("POST", { projectId: "p" });
    expect(init).toEqual({ method: "POST", body: '{"project_id":"p"}' });
    expect("headers" in init).toBe(false);
  });

  it("v1-case-018 v1Write with an undefined body has an undefined body", () => {
    const init = v1Write("POST", undefined);
    expect(init).toEqual({ method: "POST", body: undefined });
  });

  it("v1-case-019 v1Json maps the resolved object", async () => {
    vi.mocked(http.authedJson).mockResolvedValueOnce({ project_id: "x", created: 0 });
    await expect(v1Json("/v1/projects/x")).resolves.toEqual({
      projectId: "x",
      createdAt: "1970-01-01T00:00:00.000Z",
    });
  });

  it("v1-case-020 v1Json rejects with the very error authedJson threw", async () => {
    const err = Object.assign(new Error("not found"), { status: 404 });
    vi.mocked(http.authedJson).mockRejectedValueOnce(err);
    await expect(v1Json("/v1/projects/x")).rejects.toBe(err);
  });

  it("v1-case-021 v1List pages on the wire row id and returns every row camelCased", async () => {
    respondOnce({ object: "list", data: [{ id: "r1", row_a: 1 }, { id: "r2", row_a: 2 }], has_more: true, url: "" });
    respondOnce({ object: "list", data: [{ id: "r3", row_a: 3 }], has_more: false, url: "" });
    const rows = await v1List("/v1/things");
    expect(fetchMock).toHaveBeenCalledTimes(2);
    expect(new URL(urlAt(1), "http://x").searchParams.get("starting_after")).toBe("r2");
    expect(rows).toEqual([
      { id: "r1", rowA: 1 },
      { id: "r2", rowA: 2 },
      { id: "r3", rowA: 3 },
    ]);
  });

  it("v1-case-022 v1Page returns one mapped page and requests the url verbatim", async () => {
    vi.mocked(http.listV1Page).mockResolvedValueOnce({ data: [{ a_b: 1 }], hasMore: true });
    await expect(v1Page("/v1/things?x=1")).resolves.toEqual({ data: [{ aB: 1 }], hasMore: true });
    expect(vi.mocked(http.listV1Page).mock.calls[0]![0]).toBe("/v1/things?x=1");
  });

  it("v1-case-023 v1List rejects with listAllV1's error when a has_more page's last row has no id", async () => {
    respondOnce({ object: "list", data: [{ name: "no id" }], has_more: true, url: "" });
    await expect(v1List("/v1/things")).rejects.toBeInstanceOf(Error);
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });
});

describe("FromV1 (the type of fromV1's result)", () => {
  it("camelizes keys, drops `object`, stamps created/updated, and leaves opaque maps alone", () => {
    type Wire = {
      object?: string;
      id: string;
      list_id: string;
      from_name: string | null;
      created: number;
      updated: number;
      config: { snake_key: number };
      rows: { contact_id: string }[];
    };
    expectTypeOf<FromV1<Wire>>().toEqualTypeOf<{
      id: string;
      listId: string;
      fromName: string | null;
      createdAt: string;
      updatedAt: string;
      config: { snake_key: number };
      rows: { contactId: string }[];
    }>();
  });

  it("renames `created` to `createdAt` only when it is a unix-seconds number", () => {
    expectTypeOf<FromV1<{ created: string }>>().toEqualTypeOf<{ created: string }>();
  });
});

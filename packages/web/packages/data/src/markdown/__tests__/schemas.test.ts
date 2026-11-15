import { beforeEach, describe, expect, it, vi } from "vitest";

vi.mock("../../http", async (orig) => ({
  ...(await orig<Record<string, unknown>>()),
  authedJson: vi.fn(),
  authedRequest: vi.fn(),
}));

import { authedJson, authedRequest } from "../../http";
import { schemasApi } from "../schemas";
import { fetchMock, installFetch, paramsAt, pathAt, respondWith, v1List } from "../../__tests__/v1-fetch";

// "buckets need unique slugs and rdids" (Mike, 2026-09-24): a bucket's slug is its rdid leaf, so
// the client sends it, and a slug edit MOVES the bucket's id — everything after the PUT has to
// address the bucket by the id the PUT returned.

const json = vi.mocked(authedJson);
const ROW = {
  id: "storage.acme.crm",
  object: "bucket",
  ecosystem_id: "eco-uuid",
  name: "Customer CRM",
  slug: "crm",
  kind: "custom",
  description: "",
  created: 1767225600,
  updated: 1767225600,
};

beforeEach(() => {
  json.mockReset();
  installFetch();
});

describe("schemasApi — bucket slugs", () => {
  it("create sends the slug and maps it back", async () => {
    json.mockResolvedValueOnce(ROW);
    const made = await schemasApi.create(
      { name: " Customer CRM ", slug: " crm ", description: "", tables: [] },
      "ecosystem.acme",
    );
    expect(JSON.parse(json.mock.calls[0]![1]!.body as string)).toMatchObject({
      name: "Customer CRM",
      slug: "crm",
    });
    expect(made).toMatchObject({ id: "storage.acme.crm", slug: "crm" });
  });

  it("a slug edit re-reads the tables under the NEW id", async () => {
    json.mockResolvedValueOnce({ ...ROW, id: "storage.acme.customers", slug: "customers" });
    respondWith(v1List([]));
    const saved = await schemasApi.update("storage.acme.crm", { slug: "customers" });
    expect(json.mock.calls[0]![0]).toBe("/api/v1/buckets/storage.acme.crm");
    expect(JSON.parse(json.mock.calls[0]![1]!.body as string)).toEqual({ slug: "customers" });
    // The tables are re-read off the bucket_types collection (no bucket filter on /v1; the
    // client narrows to the NEW id).
    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(pathAt(0)).toBe("/api/v1/bucket_types");
    expect(paramsAt(0).get("bucket_id")).toBeNull();
    expect(saved.id).toBe("storage.acme.customers");
  });

  it("a taken slug and a taken name are told apart", async () => {
    json.mockRejectedValueOnce(new Error("resource already exists (uq_bucket_buckets_owner_parent_slug)"));
    await expect(
      schemasApi.create({ name: "New", slug: "crm", description: "", tables: [] }, "ecosystem.acme"),
    ).rejects.toThrow('A bucket with the slug "crm" already exists.');

    // A taken ADDRESS is spelled differently by the two verbs: create answers `id already exists`,
    // while an update's rename cascade trips `rdid.identifiers`' primary key. Both are the slug —
    // even though the pane's update sends the unchanged name alongside it.
    json.mockRejectedValueOnce(new Error("id already exists"));
    await expect(
      schemasApi.create({ name: "New", slug: "crm", description: "", tables: [] }, "ecosystem.acme"),
    ).rejects.toThrow('A bucket with the slug "crm" already exists.');

    json.mockRejectedValueOnce(new Error("resource already exists (identifiers_pkey)"));
    await expect(
      schemasApi.update("storage.acme.x", { name: "Customer CRM", slug: "crm" }),
    ).rejects.toThrow('A bucket with the slug "crm" already exists.');

    json.mockRejectedValueOnce(new Error("resource already exists (uq_bucket_buckets_owner_parent_name)"));
    await expect(
      schemasApi.create({ name: "Customer CRM", slug: "other", description: "", tables: [] }, "ecosystem.acme"),
    ).rejects.toThrow('A bucket named "Customer CRM" already exists.');
  });
});

describe("schemasApi — conformance vectors", () => {
  const request = vi.mocked(authedRequest);
  beforeEach(() => request.mockReset());

  it("HDM-013 create rejects a duplicate table name (case-insensitive) before any request", async () => {
    await expect(
      schemasApi.create(
        {
          name: "CRM",
          slug: "crm",
          description: "",
          tables: [
            { id: "t1", name: "Contacts", type: "content.contacts" },
            { id: "t2", name: "contacts", type: "content.contacts" },
          ],
        },
        "ecosystem.acme",
      ),
    ).rejects.toThrow('Duplicate table name "contacts" in this bucket.');
    expect(json).not.toHaveBeenCalled();
    expect(fetchMock).not.toHaveBeenCalled();
    expect(request).not.toHaveBeenCalled();
  });

  it("HDM-014 a failed second table rolls back the first table and the bucket, then rethrows the original error", async () => {
    const failure = new Error("table insert failed");
    json
      .mockResolvedValueOnce(ROW)
      .mockResolvedValueOnce({ id: "bt1", bucket_id: ROW.id, sql_table_name: "content.a", name: "a" })
      .mockRejectedValueOnce(failure);
    request.mockResolvedValue(undefined);
    await expect(
      schemasApi.create(
        {
          name: "Customer CRM",
          slug: "crm",
          description: "",
          tables: [
            { id: "x1", name: "a", type: "content.a" },
            { id: "x2", name: "b", type: "content.b" },
          ],
        },
        "ecosystem.acme",
      ),
    ).rejects.toBe(failure);
    expect(request).toHaveBeenCalledTimes(2);
    const calls = request.mock.calls.map(([url, init]) => [url, init?.method]);
    expect(calls).toContainEqual(["/api/v1/bucket_types/bt1", "DELETE"]);
    expect(calls).toContainEqual(["/api/v1/buckets/storage.acme.crm", "DELETE"]);
  });

  it("HDM-015 get resolves null for a 404, a 500 and a network failure alike", async () => {
    for (const err of [
      Object.assign(new Error("not found"), { status: 404 }),
      Object.assign(new Error("boom"), { status: 500 }),
      new TypeError("Failed to fetch"),
    ]) {
      json.mockReset();
      json.mockRejectedValueOnce(err);
      await expect(schemasApi.get("storage.acme.crm")).resolves.toBeNull();
    }
  });

  it("HDM-016 list keeps only the ecosystem's buckets, sorted alphabetically by name", async () => {
    const row = (id: string, name: string, eco: string) => ({ ...ROW, id, name, slug: id, ecosystem_id: eco });
    fetchMock.mockImplementation(async (url: unknown) => {
      const body = String(url).includes("/api/v1/buckets")
        ? v1List([row("b1", "Zeta", "eco-a"), row("b2", "Other", "eco-b"), row("b3", "alpha", "eco-a"), row("b4", "Mid", "eco-a")])
        : v1List([]);
      return { ok: true, status: 200, json: async () => body, text: async () => JSON.stringify(body) };
    });
    const out = await schemasApi.list("eco-a");
    expect(out.map((d) => d.name)).toEqual(["alpha", "Mid", "Zeta"]);
    expect(out.every((d) => d.ecosystemId === "eco-a")).toBe(true);
  });
});

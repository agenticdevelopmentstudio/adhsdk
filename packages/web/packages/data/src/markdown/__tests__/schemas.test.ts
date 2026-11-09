import { beforeEach, describe, expect, it, vi } from "vitest";

vi.mock("../../http", async (orig) => ({
  ...(await orig<Record<string, unknown>>()),
  authedJson: vi.fn(),
  authedRequest: vi.fn(),
}));

import { authedJson } from "../../http";
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

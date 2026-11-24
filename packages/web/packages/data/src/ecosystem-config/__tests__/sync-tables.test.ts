// Recipe: adhsdk ecosystem-config, sync-tables topic (vectors ecosystem-config-024..028).
// The http boundary is mocked so each test asserts the exact request a family sends and the
// camelCase rows it hands back.
import { describe, expect, it, vi, beforeEach } from "vitest";

const { authedJson, listAllV1 } = vi.hoisted(() => ({ authedJson: vi.fn(), listAllV1: vi.fn() }));
vi.mock("../../http", () => ({ authedJson, listAllV1 }));

import { enrollmentCursor, schemaOf, syncTablesApi } from "../sync-tables";

interface Wire {
  id: string;
  resource: string;
  scope: string;
  push_mode: string;
  default_enabled: boolean;
  enabled: boolean;
  overridden: boolean;
}

const wire = (o: Partial<Wire> & { resource: string }): Wire => ({
  id: o.resource,
  scope: "owner",
  push_mode: "generic",
  default_enabled: true,
  enabled: true,
  overridden: false,
  ...o,
});

beforeEach(() => {
  authedJson.mockReset();
  listAllV1.mockReset();
});

describe("schemaOf (ecosystem-config-028)", () => {
  it("ecosystem-config-028: reads the schema off the prefix before the first dot", () => {
    expect(schemaOf({ resource: "content.feed" })).toBe("content");
    expect(schemaOf({ resource: "persona_memory.links" })).toBe("persona_memory");
    expect(schemaOf({ resource: "content.feed.items" })).toBe("content");
  });
});

describe("reading the catalog (ecosystem-config-026)", () => {
  it("ecosystem-config-026: drains the list and maps snake_case to camelCase", async () => {
    listAllV1.mockResolvedValueOnce([
      wire({ resource: "content.feed", push_mode: "route", default_enabled: false }),
    ]);
    await expect(syncTablesApi("ecosystem").get("eco-1")).resolves.toEqual([
      {
        resource: "content.feed",
        scope: "owner",
        pushMode: "route",
        defaultEnabled: false,
        enabled: true,
        overridden: false,
      },
    ]);
    expect(listAllV1).toHaveBeenCalledWith("/api/v1/ecosystems/eco-1/sync_tables", {}, {
      cursorOf: enrollmentCursor,
    });
  });

  it("ecosystem-config-038: pages by the row's id, which is its resource", () => {
    expect(enrollmentCursor(wire({ resource: "content.feed" }))).toBe("content.feed");
    expect(enrollmentCursor({ resource: "content.feed" })).toBeUndefined();
  });

  it("the admin family reads the admin path", async () => {
    listAllV1.mockResolvedValueOnce([]);
    await syncTablesApi("admin").get("eco-1");
    expect(listAllV1).toHaveBeenCalledWith("/api/v1/sync/tables/eco-1", {}, { cursorOf: enrollmentCursor });
  });

  it("encodes the ecosystem id", async () => {
    listAllV1.mockResolvedValueOnce([]);
    await syncTablesApi("ecosystem").get("a/b");
    expect(listAllV1).toHaveBeenCalledWith("/api/v1/ecosystems/a%2Fb/sync_tables", {}, { cursorOf: enrollmentCursor });
  });
});

describe("setting an override (ecosystem-config-024, -025)", () => {
  it("ecosystem-config-024: the ecosystem family POSTs to /ecosystems/{id}/sync_tables/{resource}", async () => {
    authedJson.mockResolvedValueOnce({
      tables: [wire({ resource: "content.notes", enabled: true, overridden: true })],
    });
    const tables = await syncTablesApi("ecosystem").setOverride("eco-1", "content.notes", true);
    expect(authedJson).toHaveBeenCalledWith("/api/v1/ecosystems/eco-1/sync_tables/content.notes", {
      method: "POST",
      body: JSON.stringify({ enabled: true }),
    });
    expect(tables[0]).toMatchObject({ enabled: true, overridden: true, defaultEnabled: true });
  });

  it("ecosystem-config-025: the admin family POSTs to /sync/tables/{id}/resources/{resource}", async () => {
    authedJson.mockResolvedValueOnce({ tables: [] });
    await syncTablesApi("admin").setOverride("eco-1", "content.notes", false);
    expect(authedJson).toHaveBeenCalledWith("/api/v1/sync/tables/eco-1/resources/content.notes", {
      method: "POST",
      body: JSON.stringify({ enabled: false }),
    });
  });
});

describe("the refreshed catalog a write returns (ecosystem-config-033)", () => {
  it("ecosystem-config-033: setOverride returns the whole catalog mapped from `tables`, not one row", async () => {
    authedJson.mockResolvedValueOnce({
      tables: [
        wire({ resource: "content.notes", enabled: true, overridden: true }),
        wire({ resource: "content.feed", enabled: false, overridden: true, default_enabled: true }),
        wire({ resource: "mail.threads" }),
      ],
    });
    const tables = await syncTablesApi("ecosystem").setOverride("eco-1", "content.notes", true);
    expect(tables.map((t) => t.resource)).toEqual(["content.notes", "content.feed", "mail.threads"]);
    expect(tables[1]).toMatchObject({ pushMode: "generic", defaultEnabled: true, enabled: false });
  });
});

describe("clearing an override (ecosystem-config-027)", () => {
  it("ecosystem-config-027: DELETEs, then re-reads the catalog because /v1 answers a tombstone", async () => {
    authedJson.mockResolvedValueOnce({ id: "content.notes", object: "resource", deleted: true });
    listAllV1.mockResolvedValueOnce([wire({ resource: "content.notes" })]);
    const tables = await syncTablesApi("ecosystem").clearOverride("eco-1", "content.notes");
    expect(authedJson).toHaveBeenCalledWith("/api/v1/ecosystems/eco-1/sync_tables/content.notes", {
      method: "DELETE",
    });
    expect(listAllV1).toHaveBeenCalledWith("/api/v1/ecosystems/eco-1/sync_tables", {}, { cursorOf: enrollmentCursor });
    expect(tables).toHaveLength(1);
    expect(tables[0]!.overridden).toBe(false);
  });
});

describe("errors propagate", () => {
  it("a failed load rejects", async () => {
    listAllV1.mockRejectedValueOnce(new Error("HTTP 403 Forbidden"));
    await expect(syncTablesApi("ecosystem").get("eco-1")).rejects.toThrow("HTTP 403 Forbidden");
  });

  it("a failed write rejects", async () => {
    authedJson.mockRejectedValueOnce(new Error("HTTP 500"));
    await expect(
      syncTablesApi("admin").setOverride("eco-1", "content.feed", false),
    ).rejects.toThrow("HTTP 500");
  });
});

import { describe, expect, it, vi, beforeEach } from "vitest";

const authedJson = vi.fn();
const listAllV1 = vi.fn();
vi.mock("@adh-sdk/auth/client", () => ({
  authedJson: (...args: unknown[]) => authedJson(...args),
  authedRequest: vi.fn(),
  listAllV1: (...args: unknown[]) => listAllV1(...args),
  unixToIso: (s: number) => new Date(s * 1000).toISOString(),
}));

import { listContacts } from "./account";

beforeEach(() => authedJson.mockReset());

describe("account api", () => {
  it("reads contacts from /v1/account/contacts and maps them", async () => {
    listAllV1.mockResolvedValue([
      { id: "c1", type: "email", value: "a@b.com", verified: true, is_primary: true, created: 1700000000 },
    ]);
    const rows = await listContacts();
    expect(listAllV1).toHaveBeenCalledWith("/api/v1/account/contacts");
    expect(rows).toEqual([
      { id: "c1", type: "email", value: "a@b.com", verified: true, isPrimary: true, createdAt: "2023-11-14T22:13:20.000Z" },
    ]);
  });
});

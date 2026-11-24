// The users page reads its Roles column from the /v1 capabilities list, which answers a paged
// envelope, not a bare array; reading the envelope as the array crashed the page in toUserRows.
import { beforeEach, describe, expect, it, vi } from "vitest";

const listAllV1 = vi.fn();
vi.mock("../http", async (importOriginal) => ({
  ...(await importOriginal<typeof import("../http")>()),
  listAllV1,
}));

const { fetchCapabilityGrants, toUserRows } = await import("../admin");

describe("fetchCapabilityGrants", () => {
  beforeEach(() => {
    listAllV1.mockReset();
  });

  it("reads every page of the list and hands toUserRows the rows", async () => {
    listAllV1.mockResolvedValue([{ user_id: "u1", capability: "admin" }]);
    const caps = await fetchCapabilityGrants();
    expect(listAllV1).toHaveBeenCalledWith("/api/v1/auth/capabilities");
    const rows = toUserRows([{ id: "u1", created: 0 } as never], caps);
    expect(rows[0]?.capabilities).toEqual(["admin"]);
  });

  it("fails rather than truncating a list it cannot page", async () => {
    listAllV1.mockRejectedValue(new Error("has_more is set but the last row carries no id"));
    await expect(fetchCapabilityGrants()).rejects.toThrow(/no id/);
  });
});

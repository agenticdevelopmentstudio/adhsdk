// Recipe: adhsdk ecosystem-config, the web storage-token client (vector ecosystem-config-023).
import { describe, expect, it, vi, beforeEach } from "vitest";

vi.mock("../../http", async (importOriginal) => ({
  ...(await importOriginal<typeof import("../../http")>()),
  authedJson: vi.fn(),
  authedRequest: vi.fn(),
  listAllV1: vi.fn(),
}));

import { tokenPrincipalsApi } from "../storage-tokens";
import { authedJson } from "../../http";

const mockedJson = vi.mocked(authedJson);

beforeEach(() => {
  mockedJson.mockReset();
});

describe("tokenPrincipalsApi.mint", () => {
  it("ecosystem-config-023: carries the ecosystem id only in the scope query, not in the body", async () => {
    mockedJson.mockResolvedValueOnce({
      id: "tok-1",
      rdid: "token.nightly",
      slug: "nightly",
      description: "",
      prefix: "adh_",
      bucket_rdid: "bucket.nightly",
      token: "adh_secret",
    });
    const created = await tokenPrincipalsApi.mint({ name: "nightly" }, { ecosystemId: "eco-1" });
    const [url, init] = mockedJson.mock.calls[0] as [string, RequestInit];
    expect(url).toBe("/api/v1/api_keys?ecosystem_id=eco-1");
    expect(JSON.parse(String(init.body))).toEqual({ name: "nightly" });
    expect(JSON.parse(String(init.body))).not.toHaveProperty("ecosystem_id");
    expect(created.token).toBe("adh_secret");
  });
});

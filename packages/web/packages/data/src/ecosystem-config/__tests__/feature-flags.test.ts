// Recipe: adhsdk ecosystem-config, the web feature-flags client (vector ecosystem-config-021).
// Only the transport is stubbed, so the URL and body the client puts on the wire are asserted.
import { describe, expect, it, vi, beforeEach } from "vitest";

vi.mock("../../http", async (importOriginal) => ({
  ...(await importOriginal<typeof import("../../http")>()),
  authedJson: vi.fn(),
  authedRequest: vi.fn(),
  listAllV1: vi.fn(),
}));

import { ecosystemFeatureFlagsApi } from "../feature-flags";
import { authedJson } from "../../http";

const mockedJson = vi.mocked(authedJson);

beforeEach(() => {
  mockedJson.mockReset();
});

describe("ecosystemFeatureFlagsApi.update", () => {
  it("ecosystem-config-021: addresses the flag by its key in the path and sends only the ecosystem and the change", async () => {
    mockedJson.mockResolvedValueOnce({
      key: "dark_mode",
      enabled: false,
      description: "",
      created: 1767225600,
      updated: 1767225600,
    });
    const flag = await ecosystemFeatureFlagsApi.update("eco-1", "dark_mode", { enabled: false });
    expect(mockedJson).toHaveBeenCalledTimes(1);
    const [url, init] = mockedJson.mock.calls[0] as [string, RequestInit];
    expect(url).toBe("/api/v1/feature_flags/dark_mode");
    expect(init.method).toBe("POST");
    // The key is immutable and lives in the path; the body never carries it.
    expect(JSON.parse(String(init.body))).toEqual({ ecosystem: "eco-1", enabled: false });
    expect(flag).toMatchObject({ key: "dark_mode", enabled: false });
  });
});

import { beforeEach, describe, expect, it, vi } from "vitest";

const authedJson = vi.fn();
const authedRequest = vi.fn();
vi.mock("@adh-sdk/auth/client", () => ({
  authedJson: (...a: unknown[]) => authedJson(...a),
  authedRequest: (...a: unknown[]) => authedRequest(...a),
}));

import { setEcosystemFlag } from "../api/feature-flags";

beforeEach(() => {
  authedJson.mockReset();
  authedRequest.mockReset();
});

describe("setEcosystemFlag", () => {
  it("updates the flag in place when its row already exists, and does not create", async () => {
    authedJson.mockResolvedValueOnce({});
    await setEcosystemFlag("eco_1", "billing", true);
    expect(authedJson).toHaveBeenCalledTimes(1);
    expect(authedJson.mock.calls[0][0]).toBe("/api/v1/feature_flags/billing");
    expect(authedJson.mock.calls[0][1]).toMatchObject({ method: "POST" });
    expect(JSON.parse(authedJson.mock.calls[0][1].body)).toEqual({ ecosystem: "eco_1", enabled: true });
  });

  // The ordinary state of a fresh ecosystem is NO row at all — which is exactly the state the
  // operator is trying to leave, so a 404 here must create rather than fail.
  it("falls back to create on the update's 404, carrying the key in the body", async () => {
    authedJson
      .mockRejectedValueOnce(Object.assign(new Error("not found"), { status: 404 }))
      .mockResolvedValueOnce({});
    await setEcosystemFlag("eco_1", "billing", true, "Sell offers through Stripe.");
    expect(authedJson).toHaveBeenCalledTimes(2);
    expect(authedJson.mock.calls[1][0]).toBe("/api/v1/feature_flags");
    expect(authedJson.mock.calls[1][1]).toMatchObject({ method: "POST" });
    expect(JSON.parse(authedJson.mock.calls[1][1].body)).toEqual({
      ecosystem: "eco_1",
      key: "billing",
      enabled: true,
      description: "Sell offers through Stripe.",
    });
  });

  it("rethrows any status other than 404 rather than creating a second row", async () => {
    authedJson.mockRejectedValueOnce(Object.assign(new Error("nope"), { status: 403 }));
    await expect(setEcosystemFlag("eco_1", "billing", true)).rejects.toThrow("nope");
    expect(authedJson).toHaveBeenCalledTimes(1);
  });
});

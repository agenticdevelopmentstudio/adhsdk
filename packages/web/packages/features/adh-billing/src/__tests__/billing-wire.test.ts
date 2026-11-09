import { beforeEach, describe, expect, it, vi } from "vitest";

const authedJson = vi.fn();
const authedRequest = vi.fn();
const listAllV1 = vi.fn();
const listV1Page = vi.fn();
vi.mock("@adh-sdk/auth/client", async () => {
  const real = await vi.importActual<typeof import("@adh-sdk/auth/client")>("@adh-sdk/auth/client");
  return {
    ...real,
    authedJson: (...a: unknown[]) => authedJson(...a),
    authedRequest: (...a: unknown[]) => authedRequest(...a),
    listAllV1: (...a: unknown[]) => listAllV1(...a),
    listV1Page: (...a: unknown[]) => listV1Page(...a),
  };
});

import {
  claimPurchase,
  getBillingContext,
  listAccounts,
  listOffers,
  redriveEvents,
  resendClaim,
  updateOffer,
  type OfferBody,
} from "../api/billing";

beforeEach(() => {
  authedJson.mockReset();
  authedRequest.mockReset();
  listAllV1.mockReset();
  listV1Page.mockReset();
});

const offer: OfferBody = {
  slug: "pro",
  name: "Pro",
  description: null,
  purpose: "access",
  stripePriceId: "price_1",
  stripeProductId: null,
  collectionMethod: "charge_automatically",
  daysUntilDue: null,
  grantsEcosystemId: null,
  lapseAction: "none",
  graceDays: 3,
  isActive: true,
};

describe("billing /v1 wire", () => {
  it("maps the snake_case context onto the camelCase app type", async () => {
    authedJson.mockResolvedValueOnce({
      ecosystem_id: "e1",
      billing_enabled: true,
      can_manage: true,
      stripe_status: "connected",
      webhook_path: "/w",
    });
    await expect(getBillingContext()).resolves.toEqual({
      ecosystemId: "e1",
      billingEnabled: true,
      canManage: true,
      stripeStatus: "connected",
      webhookPath: "/w",
    });
    expect(authedJson).toHaveBeenCalledWith("/api/v1/billing/context");
  });

  it("drains the offers list and maps rows", async () => {
    listAllV1.mockResolvedValueOnce([
      { id: "o1", ...JSON.parse(JSON.stringify({ slug: "pro", name: "Pro", description: null, purpose: "access", stripe_price_id: "price_1", stripe_product_id: null, collection_method: "charge_automatically", days_until_due: null, grants_ecosystem_id: null, lapse_action: "none", grace_days: 3, is_active: true })) },
    ]);
    const rows = await listOffers();
    expect(listAllV1).toHaveBeenCalledWith("/api/v1/billing/offers");
    expect(rows[0]).toMatchObject({ id: "o1", stripePriceId: "price_1", graceDays: 3, isActive: true });
  });

  it("updates an offer with a POST carrying a snake_case body", async () => {
    authedJson.mockResolvedValueOnce({ id: "o1", ...{ slug: "pro", name: "Pro", description: null, purpose: "access", stripe_price_id: "price_1", stripe_product_id: null, collection_method: "charge_automatically", days_until_due: null, grants_ecosystem_id: null, lapse_action: "none", grace_days: 3, is_active: true } });
    await updateOffer("o1", offer);
    const [url, init] = authedJson.mock.calls[0];
    expect(url).toBe("/api/v1/billing/offers/o1");
    expect(init.method).toBe("POST");
    expect(JSON.parse(init.body)).toMatchObject({ stripe_price_id: "price_1", grace_days: 3, is_active: true });
  });

  it("turns the unix-second `created` into an ISO createdAt", async () => {
    listAllV1.mockResolvedValueOnce([
      { id: "a1", offer_id: "o1", status: "active", created: 1_700_000_000 },
    ]);
    const [a] = await listAccounts();
    expect(a?.createdAt).toBe("2023-11-14T22:13:20.000Z");
    expect(a?.offerId).toBe("o1");
  });

  it("resends a claim on the snake_case path and camel-cases the answer", async () => {
    authedJson.mockResolvedValueOnce({ ok: true, account_id: "a1", expires_at: "2030-01-01T00:00:00Z" });
    await expect(resendClaim("a1")).resolves.toEqual({
      ok: true,
      accountId: "a1",
      expiresAt: "2030-01-01T00:00:00Z",
    });
    expect(authedJson).toHaveBeenCalledWith("/api/v1/billing/accounts/a1/resend_claim", { method: "POST" });
  });

  it("redrives with snake_case query params and maps the counts", async () => {
    authedJson.mockResolvedValueOnce({
      examined: 1, applied: 1, terminal: 0, still_pending: 2, unreadable: 0, failed: 0, next_offset: 5,
    });
    const r = await redriveEvents({ includeProcessed: true, offset: 5 });
    expect(authedJson.mock.calls[0][0]).toBe("/api/v1/billing/events/redrive?include_processed=true&offset=5");
    expect(authedJson.mock.calls[0][1]).toEqual({ method: "POST" });
    expect(r).toMatchObject({ stillPending: 2, nextOffset: 5 });
  });

  it("claims a purchase on /accounts/claim", async () => {
    authedJson.mockResolvedValueOnce({ ok: true, ecosystem_id: "e1", offer_id: "o1" });
    await expect(claimPurchase("tok")).resolves.toEqual({ ok: true, ecosystemId: "e1", offerId: "o1" });
    expect(authedJson.mock.calls[0][0]).toBe("/api/v1/billing/accounts/claim");
  });
});

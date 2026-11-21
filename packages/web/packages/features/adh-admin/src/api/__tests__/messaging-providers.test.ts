// @vitest-environment jsdom
// The platform's messaging providers at the http boundary: each hook calls its documented /v1
// path and method, every mutation refreshes the providers list, and the pane's row model offers
// a webhook-secret rotate to Postmark only.
import { beforeEach, describe, expect, it, vi } from "vitest";
import { createElement, type ReactNode } from "react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { renderHook, waitFor } from "@testing-library/react";

const { authedJson, authedRequest, listAllV1 } = vi.hoisted(() => ({
  authedJson: vi.fn(),
  authedRequest: vi.fn(),
  listAllV1: vi.fn(),
}));
vi.mock("../http", async (importOriginal) => ({
  ...(await importOriginal<typeof import("../http")>()),
  authedJson,
  authedRequest,
  listAllV1,
}));

const {
  MESSAGING_PROVIDERS_KEY,
  messagingProviderRows,
  useMessagingProviders,
  useRemoveMessagingProvider,
  useRotateMessagingWebhookSecret,
  useSetMessagingProvider,
  useTestMessagingProvider,
} = await import("../admin");

type Wire = Parameters<typeof messagingProviderRows>[0][number];

const BASE = "/api/v1/messaging/providers";

function harness() {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  const invalidate = vi.spyOn(client, "invalidateQueries");
  const wrapper = ({ children }: { children: ReactNode }) =>
    createElement(QueryClientProvider, { client }, children);
  return { client, invalidate, wrapper };
}

/** Whether `invalidateQueries` was called with the providers list key. */
function invalidatedProviders(invalidate: ReturnType<typeof harness>["invalidate"]): boolean {
  return invalidate.mock.calls.some(
    ([filters]) => JSON.stringify(filters?.queryKey) === JSON.stringify(MESSAGING_PROVIDERS_KEY),
  );
}

const config = (o: Partial<Wire> & { provider_id: string }): Wire =>
  ({
    id: `id-${o.provider_id}`,
    ecosystem_id: "00000000-0000-4000-8000-00000000a001",
    name: o.provider_id,
    rdid: null,
    config: {},
    has_secret: true,
    active: true,
    ...o,
  }) as Wire;

beforeEach(() => {
  authedJson.mockReset();
  authedRequest.mockReset();
  listAllV1.mockReset();
  authedJson.mockResolvedValue({});
  authedRequest.mockResolvedValue(undefined);
  listAllV1.mockResolvedValue([]);
});

describe("useMessagingProviders", () => {
  it("lists from GET /api/v1/messaging/providers", async () => {
    listAllV1.mockResolvedValue([config({ provider_id: "postmark" })]);
    const { wrapper } = harness();
    const { result } = renderHook(() => useMessagingProviders(), { wrapper });
    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(listAllV1).toHaveBeenCalledWith(BASE);
    expect(result.current.data?.map((c) => c.provider_id)).toEqual(["postmark"]);
  });
});

describe("the provider mutations", () => {
  it("sets a provider with a POST on its item path and refreshes the list", async () => {
    const { wrapper, invalidate } = harness();
    const { result } = renderHook(() => useSetMessagingProvider(), { wrapper });
    await result.current.mutateAsync({
      providerId: "twilio",
      fields: { accountSid: "AC1", authToken: "t", fromNumber: "+15551234567" },
    });
    expect(authedJson).toHaveBeenCalledWith(`${BASE}/twilio`, {
      method: "POST",
      body: JSON.stringify({
        fields: { accountSid: "AC1", authToken: "t", fromNumber: "+15551234567" },
      }),
    });
    await waitFor(() => expect(invalidatedProviders(invalidate)).toBe(true));
  });

  it("removes a provider with a DELETE and refreshes the list", async () => {
    const { wrapper, invalidate } = harness();
    const { result } = renderHook(() => useRemoveMessagingProvider(), { wrapper });
    await result.current.mutateAsync("postmark");
    expect(authedRequest).toHaveBeenCalledWith(`${BASE}/postmark`, { method: "DELETE" });
    await waitFor(() => expect(invalidatedProviders(invalidate)).toBe(true));
  });

  it("tests a provider with a POST to /test, sending `to` only when given", async () => {
    authedJson.mockResolvedValue({ status: "sent", provider_id: "pm-1" });
    const { wrapper, invalidate } = harness();
    const { result } = renderHook(() => useTestMessagingProvider(), { wrapper });
    const sent = await result.current.mutateAsync({ providerId: "postmark" });
    expect(sent).toEqual({ status: "sent", provider_id: "pm-1" });
    expect(authedJson).toHaveBeenLastCalledWith(`${BASE}/postmark/test`, {
      method: "POST",
      body: JSON.stringify({}),
    });
    await result.current.mutateAsync({ providerId: "twilio", to: "+15550001111" });
    expect(authedJson).toHaveBeenLastCalledWith(`${BASE}/twilio/test`, {
      method: "POST",
      body: JSON.stringify({ to: "+15550001111" }),
    });
    await waitFor(() => expect(invalidatedProviders(invalidate)).toBe(true));
  });

  it("rotates the webhook secret with a POST to /rotate_webhook_secret and refreshes the list", async () => {
    const { wrapper, invalidate } = harness();
    const { result } = renderHook(() => useRotateMessagingWebhookSecret(), { wrapper });
    await result.current.mutateAsync("postmark");
    expect(authedJson).toHaveBeenCalledWith(`${BASE}/postmark/rotate_webhook_secret`, {
      method: "POST",
    });
    await waitFor(() => expect(invalidatedProviders(invalidate)).toBe(true));
  });

  it("does not refresh the list when a write fails", async () => {
    authedRequest.mockRejectedValue(new Error("not found"));
    const { wrapper, invalidate } = harness();
    const { result } = renderHook(() => useRemoveMessagingProvider(), { wrapper });
    await expect(result.current.mutateAsync("twilio")).rejects.toThrow(/not found/);
    expect(invalidatedProviders(invalidate)).toBe(false);
  });
});

describe("messagingProviderRows", () => {
  it("has one row per provider, Postmark first, set or not", () => {
    const rows = messagingProviderRows([config({ provider_id: "postmark" })]);
    expect(rows.map((r) => r.providerId)).toEqual(["postmark", "twilio"]);
    expect(rows[0]!.config?.provider_id).toBe("postmark");
    expect(rows[1]!.config).toBeNull();
  });

  it("offers rotate-webhook-secret for Postmark and never for Twilio", () => {
    const rows = messagingProviderRows([
      config({ provider_id: "postmark" }),
      config({ provider_id: "twilio" }),
    ]);
    const byId = Object.fromEntries(rows.map((r) => [r.providerId, r]));
    expect(byId.postmark!.canRotateWebhookSecret).toBe(true);
    expect(byId.twilio!.canRotateWebhookSecret).toBe(false);
  });

  it("shows the active row when a provider has more than one", () => {
    const rows = messagingProviderRows([
      config({ provider_id: "twilio", id: "old", active: false }),
      config({ provider_id: "twilio", id: "live", active: true }),
    ]);
    expect(rows[1]!.config?.id).toBe("live");
  });

  it("ignores providers other than Postmark and Twilio", () => {
    const rows = messagingProviderRows([config({ provider_id: "sendgrid" })]);
    expect(rows.every((r) => r.config === null)).toBe(true);
  });

  it("requires a recipient for a Twilio test only", () => {
    const rows = messagingProviderRows([]);
    expect(rows.map((r) => r.testNeedsRecipient)).toEqual([false, true]);
  });
});

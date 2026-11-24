import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { cleanup, fireEvent, render, screen, waitFor, within } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";

vi.mock("@adh-sdk/auth", async (orig) => ({
  ...(await orig<Record<string, unknown>>()),
  useAuth: () => ({ user: { email: "mike@example.com" }, isAuthenticated: true }),
  // listWebauthn pages through listAllV1 inside the auth package, beyond the client mock below, so
  // it is re-expressed over the same `authedJson` stub with the wire-to-domain mapping it applies.
  listWebauthn: async () => {
    const res = (await mocks.authedJson("/api/v1/account/mfa/passkeys?limit=100")) as {
      data: { id: string; name: string; kind: string; created: number; last_used_at: string | null }[];
    };
    return {
      items: res.data.map((c) => ({
        id: c.id,
        name: c.name,
        kind: c.kind,
        createdAt: new Date(c.created * 1000).toISOString(),
        lastUsedAt: c.last_used_at,
      })),
    };
  },
}));

// SecurityWorkspace queries MFA status via useQuery, which throws "No QueryClient set" without a
// real QueryClientProvider ancestor. Stub the transport boundary the account-security calls go
// through (`authedJson` / `authedRequest`, imported straight from `@adh-sdk/auth/client`)
// and wrap in a real `QueryClientProvider`, the same seam `ArchivedPanel.test.tsx` in this
// package already established for the identical reason.
const mocks = vi.hoisted(() => ({
  authedJson: vi.fn(),
  authedRequest: vi.fn(),
}));
const { authedJson, authedRequest } = mocks;
vi.mock("@adh-sdk/auth/client", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@adh-sdk/auth/client")>()),
  authedJson: mocks.authedJson,
  authedRequest: mocks.authedRequest,
  // The paged-collection helper walks `authedJson` inside the auth package, so route it through the stub.
  listAllV1: async (url: string) => (await mocks.authedJson(url)).data,
}));

import { SecurityWorkspace } from "./SecurityWorkspace";

const STATUS = {
  sms: false,
  totp: false,
  webauthn: true,
  totpPending: false,
  recoveryRemaining: 0,
  preferredMethod: null,
};

const V1_STATUS = {
  object: "account.mfa",
  sms: STATUS.sms,
  totp: STATUS.totp,
  webauthn: STATUS.webauthn,
  totp_pending: STATUS.totpPending,
  recovery_remaining: STATUS.recoveryRemaining,
  preferred_method: STATUS.preferredMethod,
};

const CREDS = [
  { id: "c1", name: "MacBook", kind: "passkey", createdAt: "2026-01-02T00:00:00Z", lastUsedAt: null },
  { id: "c2", name: "YubiKey", kind: "security_key", createdAt: "2026-02-03T00:00:00Z", lastUsedAt: null },
];

function routeJson(creds = CREDS) {
  authedJson.mockImplementation((path: string) => {
    if (path === "/api/v1/account/mfa") return Promise.resolve(V1_STATUS);
    if (path.startsWith("/api/v1/account/mfa/passkeys")) {
      return Promise.resolve({
        object: "list",
        data: creds.map((c) => ({
          id: c.id,
          name: c.name,
          kind: c.kind,
          created: Date.parse(c.createdAt) / 1000,
          last_used_at: c.lastUsedAt,
        })),
        has_more: false,
        url: "/v1/account/mfa/passkeys",
      });
    }
    return Promise.reject(new Error(`unexpected ${path}`));
  });
}

function renderWorkspace() {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  return render(
    <QueryClientProvider client={client}>
      <SecurityWorkspace />
    </QueryClientProvider>,
  );
}

beforeEach(() => {
  authedJson.mockReset();
  authedRequest.mockReset();
  authedRequest.mockResolvedValue(new Response(null, { status: 204 }));
});
afterEach(cleanup);

describe("SecurityWorkspace", () => {
  it("draws its sections under the registry's title — no page heading or API button of its own", async () => {
    routeJson();
    renderWorkspace();
    expect(
      await screen.findByRole("heading", { name: "Two-factor authentication" }),
    ).toBeInTheDocument();
    expect(screen.getByRole("heading", { name: "Passkeys & security keys" })).toBeInTheDocument();
    // The topic title "Security" is the registry's FeatureTitle; a second one here duplicated it.
    expect(screen.queryByRole("heading", { name: /^security$/i })).toBeNull();
    expect(screen.queryByRole("button", { name: /api/i })).toBeNull();
  });

  it("lists passkeys in a table with Add and Remove on the bar, not per row", async () => {
    routeJson();
    renderWorkspace();
    expect(await screen.findByText("MacBook")).toBeInTheDocument();
    expect(screen.getByText("YubiKey")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Add passkey" })).toBeInTheDocument();
    // One Remove, on the bar, disabled until a row is ticked.
    const remove = screen.getAllByRole("button", { name: "Remove" });
    expect(remove).toHaveLength(1);
    expect(remove[0]).toBeDisabled();
  });

  it("removes every ticked credential after confirming", async () => {
    routeJson();
    renderWorkspace();
    await screen.findByText("MacBook");
    fireEvent.click(screen.getByRole("checkbox", { name: "Select MacBook" }));
    fireEvent.click(screen.getByRole("checkbox", { name: "Select YubiKey" }));
    fireEvent.click(screen.getByRole("button", { name: "Remove" }));

    const dialog = await screen.findByRole("dialog");
    expect(within(dialog).getByText(/MacBook, YubiKey/)).toBeInTheDocument();
    fireEvent.click(within(dialog).getByRole("button", { name: "Remove" }));

    await waitFor(() => expect(authedRequest).toHaveBeenCalledTimes(2));
    expect(authedRequest).toHaveBeenCalledWith("/api/v1/account/mfa/passkeys/c1", { method: "DELETE" });
    expect(authedRequest).toHaveBeenCalledWith("/api/v1/account/mfa/passkeys/c2", { method: "DELETE" });
  });

  it("opens the register dialog from the bar's Add", async () => {
    routeJson([]);
    renderWorkspace();
    expect(
      await screen.findByText(/No passkeys or security keys yet/),
    ).toBeInTheDocument();
    fireEvent.click(screen.getByRole("button", { name: "Add passkey" }));
    expect(await screen.findByLabelText("Device name")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Add security key" })).toBeInTheDocument();
  });
});

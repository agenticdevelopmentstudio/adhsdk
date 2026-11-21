// @vitest-environment jsdom
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { cleanup, fireEvent, render, screen } from "@testing-library/react";
import { AuthHttpError } from "@adh-sdk/auth/client";
import type { AdminUserSummary } from "../api/admin";

const { revokeMutateAsync, users } = vi.hoisted(() => ({
  revokeMutateAsync: vi.fn(),
  users: { current: [] as unknown[] },
}));

// The pane's data and mutations are the seam; the table, the menu and the error modal are real.
vi.mock("../api/admin", async (importOriginal) => ({
  ...(await importOriginal<typeof import("../api/admin")>()),
  useAdminUsers: () => ({ data: users.current, isLoading: false, error: null }),
  useHubEcosystemRdid: () => ({ data: null }),
  useDeleteUser: () => ({ mutate: vi.fn(), mutateAsync: vi.fn() }),
  useRevokeRole: () => ({ mutateAsync: revokeMutateAsync, isPending: false }),
}));
vi.mock("../api/memberships", async (importOriginal) => ({
  ...(await importOriginal<typeof import("../api/memberships")>()),
  useAddToEcosystem: () => ({ mutate: vi.fn(), mutateAsync: vi.fn() }),
  useRemoveFromEcosystem: () => ({ mutate: vi.fn(), mutateAsync: vi.fn() }),
}));
vi.mock("../api/http", async (importOriginal) => ({
  ...(await importOriginal<typeof import("../api/http")>()),
  authedJson: vi.fn().mockResolvedValue({}),
  authedRequest: vi.fn(),
  listAllV1: vi.fn().mockResolvedValue([]),
  listV1Page: vi.fn().mockResolvedValue({ data: [], has_more: false }),
}));
vi.mock("next/navigation", () => ({ useRouter: () => ({ push: vi.fn() }) }));
// The header's API affordance is a portal into a host this test does not mount; the title is
// stubbed to expose the endpoint it was handed, which is the part this file pins.
vi.mock("@adh-sdk/resource", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@adh-sdk/resource")>()),
  FeatureTitle: ({ title, api }: { title: string; api?: { method: string; path: string } | null }) => (
    <h1 data-api-method={api?.method} data-api-path={api?.path}>
      {title}
    </h1>
  ),
}));

import { UsersPane } from "./UsersPane";

const customer = (over: Partial<AdminUserSummary>): AdminUserSummary => ({
  id: "u-1",
  email: "plain@example.com",
  name: "Plain",
  avatarUrl: "",
  capabilities: [],
  createdAt: "2026-11-01T00:00:00.000Z",
  rdid: null,
  ecosystems: [],
  ...over,
});

beforeEach(() => {
  revokeMutateAsync.mockReset();
  users.current = [customer({})];
});
afterEach(cleanup);

function mount() {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  render(
    <QueryClientProvider client={client}>
      <UsersPane />
    </QueryClientProvider>,
  );
}

describe("UsersPane role menu", () => {
  // Design §8: granting admin to anyone but an operator account is gone; the backend answers 400.
  // So a hub customer's role is text, not a menu whose one choice does nothing.
  it("offers a hub customer no role menu", async () => {
    mount();
    expect(await screen.findByText("Plain")).toBeTruthy();
    expect(screen.queryByRole("button", { name: "Role for Plain" })).toBeNull();
    expect(revokeMutateAsync).not.toHaveBeenCalled();
  });

  // A pre-cutover admin row on a hub customer still shows, and "User" revokes it; a refusal from
  // the server reaches the operator rather than vanishing.
  it("revokes a held admin and shows the server's refusal", async () => {
    const message = "This is the last operator. Make someone else an operator first.";
    users.current = [customer({ name: "Legacy", capabilities: ["admin"] })];
    revokeMutateAsync.mockRejectedValue(
      new AuthHttpError(409, message, "last_operator", { error: { message } }),
    );
    mount();
    fireEvent.click(await screen.findByRole("button", { name: "Role for Legacy" }));
    fireEvent.click(await screen.findByRole("option", { name: "User" }));
    expect(revokeMutateAsync).toHaveBeenCalledWith({ userId: "u-1", role: "admin" });
    expect(await screen.findByText(message)).toBeTruthy();
  });
});

describe("UsersPane API link", () => {
  // Phase 3: hub accounts are platform accounts, so the pane's endpoint is /v1/accounts. The
  // product-user door, /v1/customers, belongs to the product panes.
  it("names /v1/accounts", async () => {
    mount();
    const heading = await screen.findByRole("heading", { name: "Users" });
    expect(heading.getAttribute("data-api-method")).toBe("GET");
    expect(heading.getAttribute("data-api-path")).toBe("/v1/accounts");
  });
});

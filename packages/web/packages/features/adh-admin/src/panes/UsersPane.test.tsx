// @vitest-environment jsdom
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { cleanup, fireEvent, render, screen } from "@testing-library/react";
import { AuthHttpError } from "@adh-sdk/auth/client";
import type { AdminUserSummary } from "../api/admin";

const { grantMutate, revokeMutate, users } = vi.hoisted(() => ({
  grantMutate: vi.fn(),
  revokeMutate: vi.fn(),
  users: { current: [] as unknown[] },
}));

// The pane's data and mutations are the seam; the table, the menu and the error modal are real.
vi.mock("../api/admin", async (importOriginal) => ({
  ...(await importOriginal<typeof import("../api/admin")>()),
  useAdminUsers: () => ({ data: users.current, isLoading: false, error: null }),
  useHubEcosystemRdid: () => ({ data: null }),
  useDeleteUser: () => ({ mutate: vi.fn(), mutateAsync: vi.fn() }),
  useGrantRole: () => ({ mutate: grantMutate }),
  useRevokeRole: () => ({ mutate: revokeMutate }),
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
  grantMutate.mockReset();
  revokeMutate.mockReset();
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
  it("offers a hub customer no Operator role to grant", async () => {
    mount();
    fireEvent.click(await screen.findByRole("button", { name: "Role for Plain" }));
    const options = (await screen.findAllByRole("option")).map((o) => o.textContent);
    expect(options).toEqual(["User"]);
    expect(grantMutate).not.toHaveBeenCalled();
  });

  // A pre-cutover admin row on a hub customer still shows, and "User" revokes it; a refusal from
  // the server reaches the operator rather than vanishing.
  it("revokes a held admin and shows the server's refusal", async () => {
    const message = "This is the last operator. Make someone else an operator first.";
    users.current = [customer({ name: "Legacy", capabilities: ["admin"] })];
    revokeMutate.mockImplementation((_vars, opts?: { onError?: (e: unknown) => void }) =>
      opts?.onError?.(new AuthHttpError(409, message, "last_operator", { error: { message } })),
    );
    mount();
    fireEvent.click(await screen.findByRole("button", { name: "Role for Legacy" }));
    fireEvent.click(await screen.findByRole("option", { name: "User" }));
    expect(revokeMutate).toHaveBeenCalledWith(
      { userId: "u-1", role: "admin" },
      expect.objectContaining({ onError: expect.any(Function) }),
    );
    expect(await screen.findByText(message)).toBeTruthy();
  });
});

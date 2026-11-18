// @vitest-environment jsdom
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import { AuthHttpError } from "@adh-sdk/auth/client";
import type { OperatorWire } from "../api/admin";

const { authedJson, authedRequest, listAllV1 } = vi.hoisted(() => ({
  authedJson: vi.fn(),
  authedRequest: vi.fn(),
  listAllV1: vi.fn(),
}));
// `unixToIso` is pure, so the real one is kept; only the network is replaced.
vi.mock("../api/http", async (importOriginal) => ({
  ...(await importOriginal<typeof import("../api/http")>()),
  authedJson,
  authedRequest,
  listAllV1,
}));
vi.mock("next/navigation", () => ({ useRouter: () => ({ push: vi.fn() }) }));
// The signed-in operator, whose own row must offer no revoke.
const { selfUser } = vi.hoisted(() => ({ selfUser: { current: null as { id: string } | null } }));
vi.mock("@adh-sdk/auth", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@adh-sdk/auth")>()),
  useOptionalAuth: () => (selfUser.current ? { user: selfUser.current } : null),
}));

import { OperatorsPane } from "./OperatorsPane";

const operator = (over: Partial<OperatorWire>): OperatorWire => ({
  id: "op-1",
  email: "root@example.com",
  name: "Root",
  created: 1790812800,
  holds_admin: true,
  ...over,
});

beforeEach(() => {
  authedJson.mockReset();
  authedRequest.mockReset();
  listAllV1.mockReset();
  listAllV1.mockImplementation(async (url: string) =>
    url === "/api/v1/auth/capabilities/operators"
      ? [
          operator({}),
          operator({ id: "op-2", email: "second@example.com", name: "Second", holds_admin: false }),
        ]
      : [],
  );
  authedJson.mockResolvedValue({});
  selfUser.current = null;
});
afterEach(cleanup);

function mount() {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  render(
    <QueryClientProvider client={client}>
      <OperatorsPane />
    </QueryClientProvider>,
  );
}

describe("OperatorsPane", () => {
  it("lists each operator's email", async () => {
    mount();
    expect(await screen.findByText("root@example.com")).toBeTruthy();
    expect(screen.getByText("second@example.com")).toBeTruthy();
  });

  // The /v1 gateway takes snake_case bodies; the route reads them as `{ userId, capability }`.
  it("revokes admin by posting the user and the capability to the revoke route", async () => {
    mount();
    fireEvent.click(await screen.findByRole("button", { name: "Revoke admin from root@example.com" }));
    expect(authedJson).not.toHaveBeenCalled();
    fireEvent.click(await screen.findByRole("button", { name: "Revoke admin" }));
    await waitFor(() =>
      expect(authedJson).toHaveBeenCalledWith("/api/v1/auth/capabilities/revoke", {
        method: "POST",
        body: JSON.stringify({ user_id: "op-1", capability: "admin" }),
      }),
    );
  });

  it("grants admin to an operator who does not hold it", async () => {
    mount();
    fireEvent.click(await screen.findByRole("button", { name: "Grant admin to second@example.com" }));
    expect(authedJson).not.toHaveBeenCalled();
    fireEvent.click(await screen.findByRole("button", { name: "Grant admin" }));
    await waitFor(() =>
      expect(authedJson).toHaveBeenCalledWith("/api/v1/auth/capabilities/grant", {
        method: "POST",
        body: JSON.stringify({ user_id: "op-2", capability: "admin" }),
      }),
    );
  });

  // authedJson throws an AuthHttpError carrying the body's `error.message` for a non-2xx
  // answer; this is the one the backend sends when the revoke would leave no operator.
  it("shows the server's message when the last operator cannot be revoked", async () => {
    const message = "This is the last operator. Make someone else an operator first.";
    authedJson.mockImplementation(async (url: string) => {
      if (url.endsWith("/revoke")) {
        throw new AuthHttpError(409, message, "last_operator", {
          error: { code: "last_operator", message },
        });
      }
      return {};
    });
    mount();
    fireEvent.click(await screen.findByRole("button", { name: "Revoke admin from root@example.com" }));
    fireEvent.click(await screen.findByRole("button", { name: "Revoke admin" }));
    expect(await screen.findByText(message)).toBeTruthy();
  });

  it("does nothing when the confirmation is cancelled", async () => {
    mount();
    fireEvent.click(await screen.findByRole("button", { name: "Revoke admin from root@example.com" }));
    fireEvent.click(await screen.findByRole("button", { name: "Cancel" }));
    await waitFor(() => expect(screen.queryByRole("button", { name: "Cancel" })).toBeNull());
    expect(authedJson).not.toHaveBeenCalled();
  });

  // The backend refuses only the last holder, so a self-revoke with a second operator present
  // would succeed and lock the caller out; the pane never offers it.
  it("offers no revoke on the signed-in operator's own row", async () => {
    selfUser.current = { id: "op-1" };
    mount();
    expect(await screen.findByText("root@example.com")).toBeTruthy();
    expect(screen.queryByRole("button", { name: "Revoke admin from root@example.com" })).toBeNull();
    expect(screen.getByText("You")).toBeTruthy();
  });
});

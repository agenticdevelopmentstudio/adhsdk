// @vitest-environment jsdom
import { describe, it, expect, afterEach, beforeEach, vi } from "vitest";
import { render, screen, cleanup, waitFor } from "@testing-library/react";

const { getConnectionData, listConnections } = vi.hoisted(() => ({
  getConnectionData: vi.fn(),
  listConnections: vi.fn(),
}));
vi.mock("@adh-sdk/data/integrations", () => ({
  integrationsApi: { getConnectionData, listConnections },
}));

vi.mock("@adh-sdk/crud", () => ({
  CRUD_TABLES: { "integration/integration-bookmarks": {} },
  CrudDataView: () => <div>crud-view</div>,
  useExitGuardChannel: () => ({ exitGuard: undefined, registerGuard: vi.fn() }),
}));
vi.mock("@adh-sdk/resource", () => ({
  useRailExitGuard: () => undefined,
  StackGroupDetail: () => null,
}));

import { IntegrationData, providerDataTables } from "./IntegrationData";

afterEach(cleanup);
beforeEach(() => {
  getConnectionData.mockReset();
  listConnections.mockReset();
});

const dataResources = (id: string) =>
  providerDataTables(id).map((t) => (t.source.kind === "data" ? t.source.resource : t.source.key));

describe("providerDataTables — provider to data-route resource mapping", () => {
  it("serves reddit's Inbox from the data route and keeps its Posts on CRUD", () => {
    const t = providerDataTables("reddit");
    expect(t.map((x) => x.label)).toEqual(["Inbox", "Posts"]);
    expect(dataResources("reddit")).toEqual(["social-notifications", "integration/integration-bookmarks"]);
  });

  it("maps gmail to its labels and google-photos to media items and albums", () => {
    expect(dataResources("gmail")).toEqual(["email-labels"]);
    expect(dataResources("google-photos")).toEqual(["media-items", "media-albums"]);
  });

  it.each(["bluesky", "mastodon", "x", "facebook", "instagram"])(
    "maps %s to posts and notifications",
    (id) => {
      expect(dataResources(id)).toEqual(["social-posts", "social-notifications"]);
    },
  );

  it("leaves providers without synced tables empty", () => {
    expect(providerDataTables("github")).toEqual([]);
  });
});

describe("IntegrationData — a data-route table", () => {
  it("reads the provider's connection through the data route, not CRUD", async () => {
    listConnections.mockResolvedValue([
      { id: "conn-1", provider: "gmail", displayName: "me@example.com" },
      { id: "conn-2", provider: "reddit", displayName: "other" },
    ]);
    getConnectionData.mockResolvedValue({
      rows: [{ id: "l1", name: "INBOX", type: "system", messagesTotal: 12, messagesUnread: 3 }],
      nextCursor: null,
    });
    render(<IntegrationData providerId="gmail" ecosystemId="eco-1" />);
    await waitFor(() => expect(screen.getByText("INBOX")).toBeTruthy());
    expect(listConnections).toHaveBeenCalledWith("eco-1");
    expect(getConnectionData).toHaveBeenCalledTimes(1);
    expect(getConnectionData).toHaveBeenCalledWith("conn-1", "email-labels", { cursor: null });
    expect(screen.queryByText("crud-view")).toBeNull();
  });

  it("says so when the provider has no connection", async () => {
    listConnections.mockResolvedValue([]);
    render(<IntegrationData providerId="gmail" ecosystemId="eco-1" />);
    await waitFor(() => expect(screen.getByText("No account connected.")).toBeTruthy());
    expect(getConnectionData).not.toHaveBeenCalled();
  });
});

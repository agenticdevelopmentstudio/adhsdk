// @vitest-environment jsdom
import { describe, it, expect, afterEach, beforeEach, vi } from "vitest";
import { render, screen, cleanup, waitFor, fireEvent } from "@testing-library/react";

const { getConnectionData, listConnections, guard } = vi.hoisted(() => ({
  getConnectionData: vi.fn(),
  listConnections: vi.fn(),
  // The exit guard the mounted editor reports; null = no unsaved work.
  guard: { current: null as { isDirty: () => boolean } | null },
}));
vi.mock("@adh-sdk/data/integrations", () => ({
  integrationsApi: { getConnectionData, listConnections },
}));

vi.mock("@adh-sdk/crud", () => ({
  CRUD_TABLES: { "integration/integration-bookmarks": {} },
  CrudDataView: () => <div>crud-view</div>,
  useExitGuardChannel: () => ({ exitGuard: guard.current, registerGuard: vi.fn() }),
}));
vi.mock("@adh-sdk/resource", () => ({
  useRailExitGuard: () => undefined,
}));

import { IntegrationData, providerDataTables } from "./IntegrationData";

afterEach(cleanup);
beforeEach(() => {
  getConnectionData.mockReset();
  listConnections.mockReset();
  guard.current = null;
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

// Several tables render INSIDE the saved integration's detail, so they must never publish a rail
// level: one would take over that detail's frontier and hide its configuration and connected
// accounts behind a "Select an item from Data" hint (the Bluesky/Mastodon regression).
describe("IntegrationData — several tables", () => {
  beforeEach(() => {
    listConnections.mockResolvedValue([{ id: "conn-1", provider: "bluesky", displayName: "me" }]);
    getConnectionData.mockResolvedValue({ rows: [], nextCursor: null });
  });

  it("shows the first table at once and switches tables with a local tab strip", async () => {
    render(<IntegrationData providerId="bluesky" ecosystemId="eco-1" />);
    const posts = screen.getByRole("tab", { name: "Posts" });
    const notifications = screen.getByRole("tab", { name: "Notifications" });
    expect(posts.getAttribute("aria-selected")).toBe("true");
    await waitFor(() =>
      expect(getConnectionData).toHaveBeenCalledWith("conn-1", "social-posts", { cursor: null }),
    );

    fireEvent.click(notifications);
    expect(notifications.getAttribute("aria-selected")).toBe("true");
    await waitFor(() =>
      expect(getConnectionData).toHaveBeenCalledWith("conn-1", "social-notifications", {
        cursor: null,
      }),
    );
  });

  it("holds a tab switch behind the unsaved-changes prompt while the editor is dirty", async () => {
    guard.current = { isDirty: () => true };
    render(<IntegrationData providerId="bluesky" ecosystemId="eco-1" />);
    fireEvent.click(screen.getByRole("tab", { name: "Notifications" }));
    await waitFor(() => expect(screen.getByRole("button", { name: "Discard" })).toBeTruthy());
    // `hidden`: the open alert marks the page behind it inert, so the strip leaves the a11y tree.
    expect(
      screen.getByRole("tab", { name: "Posts", hidden: true }).getAttribute("aria-selected"),
    ).toBe("true");

    // Discard runs the held switch.
    fireEvent.click(screen.getByRole("button", { name: "Discard" }));
    await waitFor(() =>
      expect(
        screen.getByRole("tab", { name: "Notifications" }).getAttribute("aria-selected"),
      ).toBe("true"),
    );
  });
});

// @vitest-environment jsdom
// Recipe: adhsdk ecosystem-config, sync-tables topic.
import { type ReactNode } from "react";
import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

vi.mock("next/navigation", () => ({ useRouter: () => ({ push: vi.fn() }) }));

// Mocked at the client boundary so the real react-query wiring and batch runner run.
const { get, setOverride, clearOverride, families } = vi.hoisted(() => ({
  get: vi.fn(),
  setOverride: vi.fn(),
  clearOverride: vi.fn(),
  families: [] as string[],
}));
vi.mock("@adh-sdk/data/ecosystem-config", () => ({
  syncTablesApi: (family: string) => {
    families.push(family);
    return { get, setOverride, clearOverride };
  },
  schemaOf: (row: { resource: string }) => row.resource.split(".")[0] ?? "",
}));

import { SyncTablesEditor } from "./SyncTablesPane";

const row = (resource: string, enabled: boolean, overridden = false) => ({
  resource,
  scope: "owner",
  pushMode: "generic",
  defaultEnabled: overridden ? !enabled : enabled,
  enabled,
  overridden,
});

const CATALOG = [row("content.feed", true), row("content.notes", false), row("mail.threads", false, true)];

afterEach(() => {
  cleanup();
  vi.clearAllMocks();
  families.length = 0;
});

beforeEach(() => {
  get.mockResolvedValue(CATALOG);
  setOverride.mockResolvedValue(CATALOG);
  clearOverride.mockResolvedValue(CATALOG);
});

function renderEditor(props: { family?: "admin" | "ecosystem" } = {}) {
  const qc = new QueryClient({
    defaultOptions: { queries: { retry: false }, mutations: { retry: false } },
  });
  const wrapper = ({ children }: { children: ReactNode }) => (
    <QueryClientProvider client={qc}>{children}</QueryClientProvider>
  );
  return render(<SyncTablesEditor ecosystemId="eco-1" {...props} />, { wrapper });
}

const tick = async (name: string) =>
  fireEvent.click(await screen.findByRole("checkbox", { name: `Select ${name}` }));

describe("SyncTablesEditor", () => {
  it("reads through the ecosystem family by default", async () => {
    renderEditor();
    expect(await screen.findByText("content.notes")).toBeTruthy();
    expect(get).toHaveBeenCalledWith("eco-1");
    expect(families.every((f) => f === "ecosystem")).toBe(true);
  });

  it("the admin family is passed through", async () => {
    renderEditor({ family: "admin" });
    await screen.findByText("content.notes");
    expect(families.every((f) => f === "admin")).toBe(true);
  });

  it("Sync writes only the selected rows not already synced", async () => {
    renderEditor();
    await tick("content.feed");
    await tick("content.notes");
    fireEvent.click(screen.getByRole("button", { name: "Sync" }));
    await waitFor(() => expect(setOverride).toHaveBeenCalledTimes(1));
    expect(setOverride).toHaveBeenCalledWith("eco-1", "content.notes", true);
  });

  it("Reset to default clears only overridden rows, and is dead without one", async () => {
    renderEditor();
    await tick("content.feed");
    const reset = screen.getByRole("button", { name: "Reset to default" }) as HTMLButtonElement;
    expect(reset.disabled).toBe(true);
    await tick("mail.threads");
    expect(reset.disabled).toBe(false);
    fireEvent.click(reset);
    await waitFor(() => expect(clearOverride).toHaveBeenCalledTimes(1));
    expect(clearOverride).toHaveBeenCalledWith("eco-1", "mail.threads");
  });

  it("a failed load shows the error, not the empty state", async () => {
    get.mockRejectedValue(new Error("HTTP 403 Forbidden"));
    renderEditor();
    expect(await screen.findByText("Couldn't load sync tables")).toBeTruthy();
    expect(screen.queryByText("No catalog tables.")).toBeNull();
  });
});

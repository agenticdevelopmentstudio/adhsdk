// @vitest-environment jsdom
// The Users pane of the product admin site: the roster, search, paging, and pause, unpause, quota
// and delete, each confirmed. Mocks only the data boundary (the hooks).
import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const hooks = vi.hoisted(() => ({
  useProductCustomers: vi.fn(),
  pause: vi.fn(),
  unpause: vi.fn(),
  setQuota: vi.fn(),
  remove: vi.fn(),
}));

vi.mock("@adh-sdk/data/product-admin", async (importOriginal) => {
  const real = await importOriginal<typeof import("@adh-sdk/data/product-admin")>();
  const mutation = (fn: unknown) => () => ({ mutateAsync: fn, isPending: false });
  return {
    DEFAULT_QUOTA_BYTES: real.DEFAULT_QUOTA_BYTES,
    isAdminSeatProtected: real.isAdminSeatProtected,
    useProductCustomers: hooks.useProductCustomers,
    usePauseCustomer: mutation(hooks.pause),
    useUnpauseCustomer: mutation(hooks.unpause),
    useSetCustomerQuota: mutation(hooks.setQuota),
    useDeleteCustomer: mutation(hooks.remove),
  };
});

import type { ProductCustomer, ProductCustomerPage } from "@adh-sdk/data/product-admin";
import { ProductUsersPane } from "../ProductUsersPane";

const GIB = 1024 ** 3;

const customer = (over: Partial<ProductCustomer> & { id: string }): ProductCustomer => ({
  email: `${over.id}@x.test`,
  displayName: null,
  avatarUrl: null,
  externalId: null,
  createdAt: null,
  lastActiveDay: null,
  roles: [],
  sets: [],
  storageBytes: 0,
  quotaBytes: GIB,
  paused: false,
  ...over,
});

const ANN = customer({ id: "ann", displayName: "Ann", roles: [{ id: "r-admin", slug: "admin", name: "Admin" }] });
const BOB = customer({ id: "bob", displayName: "Bob", paused: true });
const CY = customer({ id: "cy", displayName: "Cy" });

// Page one is Ann and Bob, with a cursor to page two (Cy); a search for "cy" answers Cy alone.
function pageFor(_eco: string, opts: { q?: string; cursor?: string }): ProductCustomerPage {
  if (opts.q === "cy") return { items: [CY], nextCursor: null };
  if (opts.cursor === "c2") return { items: [CY], nextCursor: null };
  return { items: [ANN, BOB], nextCursor: "c2" };
}

beforeEach(() => {
  vi.clearAllMocks();
  hooks.useProductCustomers.mockImplementation((eco: string, opts: { q?: string; cursor?: string }) => ({
    data: pageFor(eco, opts),
    error: null,
    isPending: false,
  }));
  hooks.pause.mockResolvedValue({ paused: true });
  hooks.unpause.mockResolvedValue(undefined);
  hooks.setQuota.mockResolvedValue({ quotaBytes: 2 * GIB });
  hooks.remove.mockResolvedValue(undefined);
});

afterEach(cleanup);

const confirm = (name: string) => fireEvent.click(screen.getByRole("button", { name }));

describe("ProductUsersPane", () => {
  it("lists the roster for the product it is given, with roles, storage and paused", () => {
    render(<ProductUsersPane ecosystemId="eco-1" />);
    expect(hooks.useProductCustomers).toHaveBeenCalledWith("eco-1", { q: "", cursor: undefined });
    expect(screen.getByText("Ann")).toBeInTheDocument();
    expect(screen.getByText("Admin")).toBeInTheDocument();
    expect(screen.getAllByText("0 B of 1.0 GB")).toHaveLength(2);
    expect(screen.getByText("Paused")).toBeInTheDocument();
  });

  it("pages forward by the cursor and back again", () => {
    render(<ProductUsersPane ecosystemId="eco-1" />);
    expect(screen.getByRole("button", { name: "Previous" })).toBeDisabled();
    fireEvent.click(screen.getByRole("button", { name: "Next" }));
    expect(hooks.useProductCustomers).toHaveBeenLastCalledWith("eco-1", { q: "", cursor: "c2" });
    expect(screen.getByText("Cy")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Next" })).toBeDisabled();
    fireEvent.click(screen.getByRole("button", { name: "Previous" }));
    expect(hooks.useProductCustomers).toHaveBeenLastCalledWith("eco-1", { q: "", cursor: undefined });
    expect(screen.getByText("Ann")).toBeInTheDocument();
  });

  it("searches from the first page", () => {
    render(<ProductUsersPane ecosystemId="eco-1" />);
    fireEvent.click(screen.getByRole("button", { name: "Next" }));
    fireEvent.change(screen.getByLabelText("Search users"), { target: { value: " cy " } });
    fireEvent.click(screen.getByRole("button", { name: "Search" }));
    expect(hooks.useProductCustomers).toHaveBeenLastCalledWith("eco-1", { q: "cy", cursor: undefined });
    expect(screen.getByText("Cy")).toBeInTheDocument();
    expect(screen.queryByText("Ann")).toBeNull();
  });

  it("pauses only after the confirmation", async () => {
    render(<ProductUsersPane ecosystemId="eco-1" />);
    fireEvent.click(screen.getByRole("button", { name: "Pause Ann" }));
    expect(hooks.pause).not.toHaveBeenCalled();
    expect(await screen.findByText("Pause Ann?")).toBeInTheDocument();
    confirm("Pause");
    await waitFor(() => expect(hooks.pause).toHaveBeenCalledWith({ customerId: "ann" }));
  });

  it("sends nothing when the confirmation is cancelled", async () => {
    render(<ProductUsersPane ecosystemId="eco-1" />);
    fireEvent.click(screen.getByRole("button", { name: "Delete Ann" }));
    await screen.findByText("Delete Ann?");
    confirm("Cancel");
    await waitFor(() => expect(screen.queryByText("Delete Ann?")).toBeNull());
    expect(hooks.remove).not.toHaveBeenCalled();
  });

  it("unpauses a paused user", async () => {
    render(<ProductUsersPane ecosystemId="eco-1" />);
    fireEvent.click(screen.getByRole("button", { name: "Unpause Bob" }));
    await screen.findByText("Unpause Bob?");
    confirm("Unpause");
    await waitFor(() => expect(hooks.unpause).toHaveBeenCalledWith("bob"));
  });

  it("sets a quota in GB, and refuses one above the default", async () => {
    render(<ProductUsersPane ecosystemId="eco-1" />);
    fireEvent.click(screen.getByRole("button", { name: "Quota for Ann" }));
    const field = await screen.findByLabelText("Quota in GB");
    expect(field).toHaveValue(1);
    fireEvent.change(field, { target: { value: "6" } });
    confirm("Save");
    expect(await screen.findByText("The quota can be at most 5 GB.")).toBeInTheDocument();
    expect(hooks.setQuota).not.toHaveBeenCalled();
    fireEvent.change(screen.getByLabelText("Quota in GB"), { target: { value: "2" } });
    confirm("Save");
    await waitFor(() => expect(hooks.setQuota).toHaveBeenCalledWith({ customerId: "ann", bytes: 2 * GIB }));
  });

  it("says admins cannot be paused or deleted here on the backend's 422", async () => {
    hooks.remove.mockRejectedValue(
      Object.assign(new Error("admin_seat_protected"), { status: 422, code: "admin_seat_protected" }),
    );
    render(<ProductUsersPane ecosystemId="eco-1" />);
    fireEvent.click(screen.getByRole("button", { name: "Delete Ann" }));
    await screen.findByText("Delete Ann?");
    confirm("Delete");
    expect(await screen.findByText("Admins cannot be paused or deleted here.")).toBeInTheDocument();
  });

  it("shows any other refusal as the backend says it", async () => {
    hooks.remove.mockRejectedValue(new Error("This person still owns data."));
    render(<ProductUsersPane ecosystemId="eco-1" />);
    fireEvent.click(screen.getByRole("button", { name: "Delete Ann" }));
    await screen.findByText("Delete Ann?");
    confirm("Delete");
    expect(await screen.findByText("This person still owns data.")).toBeInTheDocument();
  });
});

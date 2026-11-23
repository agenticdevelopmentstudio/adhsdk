// @vitest-environment jsdom
// A product admin's support grants: the request form's checks, the step-up on
// `step_up_required`, the grants in order with revoke and open on a live one, and the read-only
// viewer (tables, paging, one row, no edit control, no row read for a table with no `id`). Mocks
// only the data boundary (the hooks and the row read); the rules (grantState,
// supportRequestProblem, isStepUpRequired, isSupportOff) are the real ones.
import type { ReactNode } from "react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { cleanup, fireEvent, render, screen, waitFor, within } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const hooks = vi.hoisted(() => ({
  useAdminSupportGrants: vi.fn(),
  request: vi.fn(),
  revoke: vi.fn(),
  useSupportData: vi.fn(),
  row: vi.fn(),
  useProductCustomers: vi.fn(),
  stepUp: vi.fn(),
  auth: { current: null as null | { stepUp: (p?: string) => void } },
}));

vi.mock("@adh-sdk/data/support", async (importOriginal) => {
  const real = await importOriginal<typeof import("@adh-sdk/data/support")>();
  return {
    ...real,
    useAdminSupportGrants: hooks.useAdminSupportGrants,
    useRequestSupportGrant: () => ({ mutateAsync: hooks.request, isPending: false }),
    useRevokeAdminGrant: () => ({ mutateAsync: hooks.revoke, isPending: false }),
    useSupportData: hooks.useSupportData,
    supportAdminApi: { ...real.supportAdminApi, row: hooks.row },
  };
});

vi.mock("@adh-sdk/data/product-admin", () => ({
  useProductCustomers: hooks.useProductCustomers,
}));

vi.mock("@adh-sdk/auth", () => ({
  useOptionalProductAdminAuth: () => hooks.auth.current,
}));

import { AuthHttpError } from "@adh-sdk/auth/client";
import type { SupportAdminGrant } from "@adh-sdk/data/support";
import { SupportGrantsPane } from "../SupportGrantsPane";

const ECO = "0b9c4a52-6c3e-4d7e-9a1f-2f4c1d2e3a4b";
const HOUR = 3600 * 1000;
const ago = (ms: number) => new Date(Date.now() - ms).toISOString();
const ahead = (ms: number) => new Date(Date.now() + ms).toISOString();
const REASON = "Your export failed and I need to see the notes it skipped.";

const grant = (over: Partial<SupportAdminGrant> & { id: string }): SupportAdminGrant => ({
  ecosystemId: ECO,
  granteeKind: "product_admin",
  granteeName: "Ana",
  granteeRole: "Support",
  reason: REASON,
  consent: "customer",
  requestedFor: 24,
  requestedAt: ago(HOUR),
  decision: null,
  decidedAt: null,
  expiresAt: null,
  revokedAt: null,
  targetId: "cust-1",
  targetName: "Sam",
  ...over,
});

const PENDING = grant({ id: "g-pending", targetName: "Pat" });
const LIVE = grant({
  id: "g-live",
  targetName: "Sam",
  requestedAt: ago(3 * HOUR),
  decision: "approved",
  decidedAt: ago(2 * HOUR),
  expiresAt: ahead(20 * HOUR),
});

const grantsAre = (data: SupportAdminGrant[] | undefined, error: unknown = null) =>
  hooks.useAdminSupportGrants.mockReturnValue({ data, error, isLoading: data === undefined && !error });

const dataIs = (rows: Record<string, unknown>[], nextCursor: string | null = null, error: unknown = null) =>
  hooks.useSupportData.mockImplementation((_g: string, schema: string | null) =>
    schema
      ? { data: error ? undefined : { rows, nextCursor }, error, isLoading: false }
      : { data: undefined, error: null, isLoading: false },
  );

function renderPane(props: Partial<Parameters<typeof SupportGrantsPane>[0]> = {}) {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  const wrap = ({ children }: { children: ReactNode }) => (
    <QueryClientProvider client={qc}>{children}</QueryClientProvider>
  );
  return render(<SupportGrantsPane ecosystemId={ECO} {...props} />, { wrapper: wrap });
}

const form = () => screen.getByRole("form", { name: "Ask a customer for access" });

function fillForm({ customer = "cust-1", reason = REASON, hours = "24" } = {}) {
  fireEvent.change(screen.getByLabelText("Customer"), { target: { value: customer } });
  fireEvent.change(screen.getByLabelText("Reason"), { target: { value: reason } });
  fireEvent.change(screen.getByLabelText("Hours"), { target: { value: hours } });
}

const submit = () => fireEvent.click(within(form()).getByRole("button", { name: "Ask for access" }));

beforeEach(() => {
  hooks.request.mockReset().mockResolvedValue(grant({ id: "g-new" }));
  hooks.revoke.mockReset().mockResolvedValue(undefined);
  hooks.row.mockReset();
  hooks.stepUp.mockReset();
  hooks.auth.current = { stepUp: hooks.stepUp };
  hooks.useProductCustomers.mockReset().mockReturnValue({
    data: {
      items: [
        { id: "cust-1", email: "sam@x.test", displayName: "Sam" },
        { id: "cust-2", email: "pat@x.test", displayName: null },
      ],
      nextCursor: null,
    },
  });
  grantsAre([PENDING, LIVE]);
  dataIs([]);
});

afterEach(() => cleanup());

describe("SupportGrantsPane: the request", () => {
  it("lists the roster in the customer picker, searching by what is typed", () => {
    renderPane();
    const picker = screen.getByLabelText("Customer");
    expect(within(picker).getByRole("option", { name: "Sam (sam@x.test)" })).toBeTruthy();
    expect(within(picker).getByRole("option", { name: "pat@x.test" })).toBeTruthy();
    fireEvent.change(screen.getByLabelText("Find a customer"), { target: { value: " sam " } });
    expect(hooks.useProductCustomers).toHaveBeenLastCalledWith(ECO, { q: "sam" });
  });

  it("starts at 24 hours", () => {
    renderPane();
    expect((screen.getByLabelText("Hours") as HTMLInputElement).value).toBe("24");
  });

  it("asks for the customer, the reason and the length it was given", async () => {
    renderPane();
    fillForm({ hours: "48" });
    submit();
    await waitFor(() => expect(hooks.request).toHaveBeenCalledWith({ targetId: "cust-1", reason: REASON, hours: 48 }));
    expect(await screen.findByText(/The customer has been sent the request/)).toBeTruthy();
  });

  it("never sends to a customer the search has filtered out of the list", () => {
    renderPane();
    fillForm({ customer: "cust-2" });
    // The search narrows the roster to Sam alone; the picker no longer shows the chosen customer.
    hooks.useProductCustomers.mockReturnValue({
      data: { items: [{ id: "cust-1", email: "sam@x.test", displayName: "Sam" }], nextCursor: null },
    });
    fireEvent.change(screen.getByLabelText("Find a customer"), { target: { value: "sam" } });
    expect((screen.getByLabelText("Customer") as HTMLSelectElement).value).toBe("");
    submit();
    expect(within(form()).getByRole("alert").textContent).toMatch("Choose a customer.");
    expect(hooks.request).not.toHaveBeenCalled();
  });

  it.each([
    ["no customer", { customer: "" }, "Choose a customer."],
    ["a short reason", { reason: "too short" }, /at least 10 characters/],
    ["a long reason", { reason: "x".repeat(501) }, /500 characters or fewer/],
    ["zero hours", { hours: "0" }, /1 to 168/],
    ["more than seven days", { hours: "169" }, /1 to 168/],
    ["part of an hour", { hours: "2.5" }, /1 to 168/],
  ])("refuses %s before sending", (_name, fields, text) => {
    renderPane();
    fillForm(fields);
    submit();
    expect(within(form()).getByRole("alert").textContent).toMatch(text);
    expect(hooks.request).not.toHaveBeenCalled();
  });

  it("sends a step_up_required refusal through stepUp('/support')", async () => {
    hooks.request.mockRejectedValueOnce(new AuthHttpError(403, "Sign in again", "step_up_required"));
    renderPane();
    fillForm();
    submit();
    await waitFor(() => expect(hooks.stepUp).toHaveBeenCalledWith("/support"));
    expect(within(form()).queryByRole("alert")).toBeNull();
  });

  it("reads step_up_required from the refusal's body too, and honours returnPath and onStepUp", async () => {
    const onStepUp = vi.fn();
    hooks.request.mockRejectedValueOnce(
      new AuthHttpError(403, "Forbidden", undefined, { error: { code: "step_up_required", message: "x" } }),
    );
    renderPane({ returnPath: "/support?tab=grants", onStepUp });
    fillForm();
    submit();
    await waitFor(() => expect(onStepUp).toHaveBeenCalledWith("/support?tab=grants"));
    expect(hooks.stepUp).not.toHaveBeenCalled();
  });

  it("says to sign in again when there is no provider to step up through", async () => {
    hooks.auth.current = null;
    hooks.request.mockRejectedValueOnce(new AuthHttpError(403, "Sign in again", "step_up_required"));
    renderPane();
    fillForm();
    submit();
    expect((await within(form()).findByRole("alert")).textContent).toMatch(/second factor/);
  });

  it("shows any other refusal as the backend's message", async () => {
    hooks.request.mockRejectedValueOnce(new AuthHttpError(409, "There is already an open request for this customer."));
    renderPane();
    fillForm();
    submit();
    expect((await within(form()).findByRole("alert")).textContent).toBe(
      "There is already an open request for this customer.",
    );
    expect(hooks.stepUp).not.toHaveBeenCalled();
  });
});

describe("SupportGrantsPane: the grants", () => {
  it("lists each grant with its state, live first", () => {
    renderPane();
    const cards = screen.getAllByRole("article");
    expect(cards.map((c) => c.getAttribute("data-state"))).toEqual(["live", "pending"]);
    expect(within(cards[0]!).getByText("Live")).toBeTruthy();
    expect(within(cards[1]!).getByText("Waiting for consent")).toBeTruthy();
  });

  it("offers open and revoke on a live grant only", () => {
    renderPane();
    const [live, pending] = screen.getAllByRole("article");
    expect(within(live!).getByRole("button", { name: "Open" })).toBeTruthy();
    expect(within(live!).getByRole("button", { name: "Revoke access to Sam" })).toBeTruthy();
    expect(within(pending!).queryByRole("button")).toBeNull();
  });

  it("revokes a live grant", async () => {
    renderPane();
    fireEvent.click(screen.getByRole("button", { name: "Revoke access to Sam" }));
    await waitFor(() => expect(hooks.revoke).toHaveBeenCalledWith("g-live"));
  });

  it("says support access is off when the grants read answers 404", () => {
    grantsAre(undefined, new AuthHttpError(404, "Not found"));
    renderPane();
    expect(screen.getByText(/not turned on/)).toBeTruthy();
    expect(screen.queryByRole("form")).toBeNull();
  });

  it("says when there are no grants", () => {
    grantsAre([]);
    renderPane();
    expect(screen.getByText("No grants yet.")).toBeTruthy();
  });
});

describe("SupportViewer", () => {
  const open = () => {
    renderPane();
    fireEvent.click(screen.getByRole("button", { name: "Open" }));
    return screen.getByRole("region", { name: "Customer content" });
  };
  const pick = (viewer: HTMLElement, table: string) =>
    fireEvent.change(within(viewer).getByLabelText("Table"), { target: { value: table } });

  it("offers the content tables and reads the one picked", () => {
    dataIs([{ id: "n1", title: "Hello" }]);
    const viewer = open();
    expect(within(viewer).getByRole("option", { name: "content.notes" })).toBeTruthy();
    expect(within(viewer).getByRole("option", { name: "sync.push_ops" })).toBeTruthy();
    pick(viewer, "content.notes");
    expect(hooks.useSupportData).toHaveBeenLastCalledWith("g-live", "content", "notes", undefined);
    expect(within(viewer).getByText("Hello")).toBeTruthy();
  });

  it("pages forward by the next cursor and back again", () => {
    dataIs([{ id: "n1", title: "Hello" }], "n1");
    const viewer = open();
    pick(viewer, "content.notes");
    fireEvent.click(within(viewer).getByRole("button", { name: "Next" }));
    expect(hooks.useSupportData).toHaveBeenLastCalledWith("g-live", "content", "notes", "n1");
    fireEvent.click(within(viewer).getByRole("button", { name: "Previous" }));
    expect(hooks.useSupportData).toHaveBeenLastCalledWith("g-live", "content", "notes", undefined);
  });

  it("opens one row, read through the grant", async () => {
    dataIs([{ id: "n1", title: "Hello" }]);
    hooks.row.mockResolvedValue({ id: "n1", title: "Hello", body: "The whole note" });
    const viewer = open();
    pick(viewer, "content.notes");
    fireEvent.click(within(viewer).getByRole("button", { name: "Open row n1" }));
    const row = await screen.findByRole("region", { name: "Row n1" });
    await waitFor(() => expect(within(row).getByText(/The whole note/)).toBeTruthy());
    expect(hooks.row).toHaveBeenCalledWith("g-live", "content", "notes", "n1");
  });

  it("offers no single-row read for a table whose rows have no id", () => {
    dataIs([{ owner_kind: "customer", owner_id: "c1", op_id: "op-1" }]);
    const viewer = open();
    pick(viewer, "sync.push_ops");
    expect(within(viewer).getByText("op-1")).toBeTruthy();
    expect(within(viewer).queryByRole("button", { name: /Open row/ })).toBeNull();
  });

  it("never shows an edit control", async () => {
    dataIs([{ id: "n1", title: "Hello" }]);
    hooks.row.mockResolvedValue({ id: "n1", title: "Hello" });
    const viewer = open();
    pick(viewer, "content.notes");
    fireEvent.click(within(viewer).getByRole("button", { name: "Open row n1" }));
    await screen.findByRole("region", { name: "Row n1" });
    // The only control that takes input is the table picker; every button reads or moves.
    expect(within(viewer).queryAllByRole("textbox")).toHaveLength(0);
    expect(within(viewer).queryAllByRole("checkbox")).toHaveLength(0);
    expect(within(viewer).queryAllByRole("spinbutton")).toHaveLength(0);
    expect(within(viewer).getAllByRole("combobox")).toHaveLength(1);
    for (const b of within(viewer).getAllByRole("button")) {
      expect(b.textContent ?? "").not.toMatch(/edit|save|delete|update|change/i);
    }
    expect(viewer.querySelector("[contenteditable]")).toBeNull();
  });

  it("says a refused table cannot be read, and an ended grant is no longer live", () => {
    dataIs([], null, new AuthHttpError(404, "Not found"));
    const viewer = open();
    pick(viewer, "content.notes");
    expect(within(viewer).getByRole("alert").textContent).toMatch(/cannot be read/);
    cleanup();
    dataIs([], null, new AuthHttpError(403, "not_live"));
    const again = open();
    pick(again, "content.notes");
    expect(within(again).getByRole("alert").textContent).toMatch(/no longer live/);
  });
});

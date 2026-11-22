// @vitest-environment jsdom
// The Totals pane: a product's counts as a row of figures. Mocks only the data boundary (the hook).
import { cleanup, render, screen } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

vi.mock("@adh-sdk/data/product-admin", () => ({ useProductTotals: vi.fn() }));

import { useProductTotals } from "@adh-sdk/data/product-admin";
import { ProductTotalsPane } from "./ProductTotalsPane";

const hook = vi.mocked(useProductTotals);
type HookResult = ReturnType<typeof useProductTotals>;

const TOTALS = {
  customers: 1234,
  new7d: 5,
  new30d: 21,
  active7d: 40,
  active30d: 310,
  storageBytes: 3 * 1024 * 1024,
  pendingInvitations: 2,
  pendingRequests: 7,
};

beforeEach(() => vi.clearAllMocks());
afterEach(cleanup);

const figure = (label: string) => screen.getByText(label).parentElement?.textContent;

describe("ProductTotalsPane", () => {
  it("shows each figure, read for the product it is given", () => {
    hook.mockReturnValue({ data: TOTALS, error: null, isPending: false } as unknown as HookResult);
    render(<ProductTotalsPane ecosystemId="eco-1" />);
    expect(hook).toHaveBeenCalledWith("eco-1");
    expect(figure("Customers")).toContain("1,234");
    expect(figure("New in 7 days")).toContain("5");
    expect(figure("New in 30 days")).toContain("21");
    expect(figure("Active in 7 days")).toContain("40");
    expect(figure("Active in 30 days")).toContain("310");
    expect(figure("Storage")).toContain("3.0 MB");
    expect(figure("Invitations waiting")).toContain("2");
    expect(figure("Requests waiting")).toContain("7");
  });

  it("says it is loading, and says when it could not load", () => {
    hook.mockReturnValue({ data: undefined, error: null, isPending: true } as unknown as HookResult);
    const { rerender } = render(<ProductTotalsPane ecosystemId="eco-1" />);
    expect(screen.getByText("Loading…")).toBeInTheDocument();

    hook.mockReturnValue({ data: undefined, error: new Error("Forbidden"), isPending: false } as unknown as HookResult);
    rerender(<ProductTotalsPane ecosystemId="eco-1" />);
    expect(screen.getByText("Couldn't load the totals: Forbidden")).toBeInTheDocument();
  });
});

// @vitest-environment jsdom
// Phase 7, design sections 9 and 10: while content enforcement is on, a product's All Data shows
// only the product's house rows, and one line above the browser says so. The browser itself is a
// stand-in that says what it was handed; what is under test is the line and the rule for it.
import { cleanup, render, screen } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

vi.mock("@adh-sdk/crud", () => ({
  CrudDataBrowser: ({ ecosystemId, workspace }: { ecosystemId?: string; workspace?: string }) => (
    <p>{`Browser for ${String(workspace)} / ${String(ecosystemId)}`}</p>
  ),
}));

// The admin-site read, stubbed at the hook: `null` is "the route has not answered" (or answered
// 404, which is how it treats an ecosystem that is not a product), an object is its answer.
const useAdminSite = vi.fn();
vi.mock("@adh-sdk/data/product-admin", () => ({
  useAdminSite: (ecosystemId: string | null | undefined) => useAdminSite(ecosystemId),
}));

import { AllDataPane, HOUSE_ROWS_NOTICE } from "../AllDataPane";

const ECO = "0b9c4a52-6c3e-4d7e-9a1f-2f4c1d2e3a4b";

const answered = (contentGated: boolean) => ({
  data: { site: null, enabled: true, contentGated },
});

beforeEach(() => {
  useAdminSite.mockReset();
  useAdminSite.mockReturnValue({ data: undefined });
});

afterEach(cleanup);

describe("AllDataPane — the house-rows notice", () => {
  it("is the design's sentence", () => {
    expect(HOUSE_ROWS_NOTICE).toBe(
      "This shows the product's own data. Customers' data is not shown here.",
    );
  });

  it("shows above the browser when the host says the product is gated", () => {
    render(<AllDataPane workspace="acme" ecosystemId={ECO} contentGated />);
    const notice = screen.getByRole("note");
    expect(notice).toHaveTextContent(HOUSE_ROWS_NOTICE);
    const browser = screen.getByText(`Browser for acme / ${ECO}`);
    // Above the browser: the notice comes first in document order.
    expect(notice.compareDocumentPosition(browser) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
  });

  it("does not show when the host says the product is not gated, and the browser renders", () => {
    render(<AllDataPane workspace="acme" ecosystemId={ECO} contentGated={false} />);
    expect(screen.queryByRole("note")).not.toBeInTheDocument();
    expect(screen.queryByText(HOUSE_ROWS_NOTICE)).not.toBeInTheDocument();
    expect(screen.getByText(`Browser for acme / ${ECO}`)).toBeInTheDocument();
  });

  it("does not ask the admin site when the host has answered", () => {
    render(<AllDataPane workspace="acme" ecosystemId={ECO} contentGated />);
    for (const [arg] of useAdminSite.mock.calls) expect(arg).toBeNull();
  });

  it("a host's false wins over an admin site that says gated", () => {
    useAdminSite.mockReturnValue(answered(true));
    render(<AllDataPane workspace="acme" ecosystemId={ECO} contentGated={false} />);
    expect(screen.queryByText(HOUSE_ROWS_NOTICE)).not.toBeInTheDocument();
  });

  it("left to itself, asks the admin site for this ecosystem and shows the line when gated", () => {
    useAdminSite.mockReturnValue(answered(true));
    render(<AllDataPane workspace="acme" ecosystemId={ECO} />);
    expect(useAdminSite).toHaveBeenCalledWith(ECO);
    expect(screen.getByText(HOUSE_ROWS_NOTICE)).toBeInTheDocument();
    expect(screen.getByText(`Browser for acme / ${ECO}`)).toBeInTheDocument();
  });

  it("left to itself, shows no line when the product is not gated", () => {
    useAdminSite.mockReturnValue(answered(false));
    render(<AllDataPane workspace="acme" ecosystemId={ECO} />);
    expect(screen.queryByText(HOUSE_ROWS_NOTICE)).not.toBeInTheDocument();
    expect(screen.getByText(`Browser for acme / ${ECO}`)).toBeInTheDocument();
  });

  it("left to itself, shows no line for an ecosystem that is not a product (no answer)", () => {
    // The route answers 404 for a workspace's own ecosystem; the hook then has no data.
    render(<AllDataPane workspace="acme" ecosystemId={ECO} />);
    expect(screen.queryByText(HOUSE_ROWS_NOTICE)).not.toBeInTheDocument();
    expect(screen.getByText(`Browser for acme / ${ECO}`)).toBeInTheDocument();
  });

  it("still shows Loading… and no line until the ecosystem resolves", () => {
    useAdminSite.mockReturnValue(answered(true));
    render(<AllDataPane workspace="acme" ecosystemId={undefined} />);
    expect(screen.getByText("Loading…")).toBeInTheDocument();
    expect(screen.queryByText(HOUSE_ROWS_NOTICE)).not.toBeInTheDocument();
    expect(screen.queryByText(/Browser for/)).not.toBeInTheDocument();
  });
});

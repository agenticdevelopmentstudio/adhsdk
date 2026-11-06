import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { RailHostBoundary } from "@adh-sdk/resource";

const listProviderConfigs = vi.fn();
const listProviders = vi.fn();
vi.mock("@adh-sdk/data/integrations", () => ({
  integrationsApi: {
    listProviderConfigs: (...a: unknown[]) => listProviderConfigs(...a),
    listProviders: (...a: unknown[]) => listProviders(...a),
    getProviderConfigById: async () => null,
  },
}));

// The picker stubbed down to the one fact under test: whether the pane asked for it to be open.
vi.mock("../AddIntegrationModal", () => ({
  AddIntegrationModal: ({ open }: { open: boolean }) =>
    open ? <div role="dialog" aria-label="Add integration picker" /> : null,
}));

import { IntegrationsPane } from "../IntegrationsPane";

// The bar's Add lives in the DETAIL column's toolbar slot. A host that collapses that column
// (the hub's /home stack with no row open) left the list with no way to add anything — so the
// list's own title row carries a gear that opens the same picker.
describe("IntegrationsPane list gear", () => {
  it("opens the add-integration picker from the list's title row", async () => {
    listProviders.mockResolvedValue([
      { providerId: "github-app", displayName: "GitHub", subtitle: "Code", serviceTypes: ["code"] },
    ]);
    listProviderConfigs.mockResolvedValue([]);

    render(
      <RailHostBoundary>
        <IntegrationsPane ecosystemId="e1" />
      </RailHostBoundary>,
    );

    const gear = await screen.findByRole("button", { name: "Add integration" });
    expect(gear).toHaveAttribute("aria-haspopup", "dialog");
    expect(screen.queryByRole("dialog", { name: "Add integration picker" })).toBeNull();

    await userEvent.click(gear);

    expect(screen.getByRole("dialog", { name: "Add integration picker" })).toBeInTheDocument();
  });
});

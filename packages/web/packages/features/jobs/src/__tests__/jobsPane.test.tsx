// @vitest-environment jsdom
// JobsPane: the customer side creates from the catalog only (vector jobs-004), and a create names
// the catalog entry's latest version (jobs-005). Mocks the jobs data client.
import { cleanup, fireEvent, screen, waitFor } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const api = vi.hoisted(() => ({
  list: vi.fn(),
  catalog: vi.fn(),
  runs: vi.fn(),
  create: vi.fn(),
}));

vi.mock("@adh-sdk/data/jobs", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@adh-sdk/data/jobs")>();
  return { ...actual, jobsApi: { ...actual.jobsApi, ...api } };
});

import { JobsPane } from "../JobsPane";
import { catalogTemplate, job, renderWithQuery } from "./fixtures";

beforeEach(() => {
  api.list.mockReset().mockResolvedValue([]);
  api.catalog.mockReset().mockResolvedValue([catalogTemplate()]);
  api.runs.mockReset().mockResolvedValue({ runs: [], nextBefore: null });
  api.create.mockReset().mockResolvedValue(job({ id: "job-new" }));
});
afterEach(cleanup);

describe("JobsPane", () => {
  it("offers creation only from the catalog entry on the customer side (vector jobs-004)", async () => {
    renderWithQuery(<JobsPane side="customer" onOpenTemplates={() => {}} />);
    expect(await screen.findByRole("button", { name: "Create a job from Daily digest" })).toBeTruthy();
    // The only create action is the entry's; no authoring and no inline-steps action.
    const buttons = screen.getAllByRole("button").map((b) => b.getAttribute("aria-label") ?? b.textContent);
    expect(buttons).toEqual(["Create a job from Daily digest"]);
    expect(screen.queryByRole("button", { name: "Templates" })).toBeNull();
    expect(screen.queryByText(/steps/i)).toBeNull();
  });

  it("creates from the catalog entry at its latest version (vector jobs-005)", async () => {
    const onOpenJob = vi.fn();
    renderWithQuery(<JobsPane side="account" onOpenJob={onOpenJob} />);
    fireEvent.click(await screen.findByRole("button", { name: "Create a job from Daily digest" }));
    fireEvent.change(screen.getByLabelText("Name"), { target: { value: "My digest" } });
    fireEvent.click(screen.getByRole("button", { name: "Create job" }));
    await waitFor(() =>
      expect(api.create).toHaveBeenCalledWith(
        { name: "My digest", templateId: "tpl-1", templateVersion: 3, inputs: {} },
        { workspace: undefined },
      ),
    );
    await waitFor(() => expect(onOpenJob).toHaveBeenCalledWith("job-new"));
  });

  it("shows Templates on the account side when the host gives the way there", async () => {
    renderWithQuery(<JobsPane side="account" onOpenTemplates={() => {}} />);
    expect(await screen.findByRole("button", { name: "Templates" })).toBeTruthy();
  });
});

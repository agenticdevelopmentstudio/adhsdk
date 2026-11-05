// @vitest-environment jsdom
import { afterEach, describe, expect, it, vi } from "vitest";
import { cleanup, render, screen } from "@testing-library/react";
import { ErrorsView } from "./ErrorsView";

// The dashboard query is the whole subject: what the view draws for a site when it has, or has not,
// got an answer. The site page itself is stood in for, since only whether it renders matters here.
const query = vi.hoisted(() => ({ current: {} as Record<string, unknown> }));
vi.mock("../hooks/use-dashboards", () => ({ useErrorsDashboard: () => query.current }));
vi.mock("./ErrorsSitePage", () => ({ ErrorsSitePage: () => <p>site page</p> }));

afterEach(cleanup);

describe("ErrorsView on a site", () => {
  it("draws no site page when the dashboard could not be loaded, only why", () => {
    query.current = { data: undefined, isLoading: false, isError: true, error: new Error("Unauthorized") };
    render(<ErrorsView site="foo.com" onSite={() => {}} />);
    expect(screen.getByRole("alert").textContent).toContain("Could not load errors: Unauthorized");
    expect(screen.queryByText("site page")).toBeNull();
  });

  it("draws the site page while the first answer is on its way", () => {
    query.current = { data: undefined, isLoading: true, isError: false, error: null };
    render(<ErrorsView site="foo.com" onSite={() => {}} />);
    expect(screen.getByText("site page")).toBeTruthy();
  });
});

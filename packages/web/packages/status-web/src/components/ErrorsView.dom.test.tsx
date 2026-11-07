// @vitest-environment jsdom
import { afterEach, describe, expect, it, vi } from "vitest";
import { cleanup, render, screen } from "@testing-library/react";
import { ErrorsView } from "./ErrorsView";
import { VIEWS_MISSING } from "./DashboardParts";

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

// A status server older than this page answers without `views`. Its sections still hold real
// numbers, so drawing the views panels from nothing would be an all-clear nobody gave.
describe("ErrorsView against a server that sends no views", () => {
  const empty = { data: null, error: null, updatedAt: null };
  const oldBody = {
    generatedAt: "2026-11-07T00:00:00Z",
    refreshing: false,
    configured: { glitchtip: true, posthog: true, vercel: true },
    sections: {
      issues: empty,
      sites: { data: [{ host: "a.dev", errors: 40, requests: 100, failures: 0, p95Ms: null }], error: null, updatedAt: null },
      detail: empty,
      runtime: empty,
    },
  };

  it("says so in the most-errors panel instead of claiming no site reported an error", () => {
    query.current = { data: oldBody, isLoading: false, isError: false, error: null };
    render(<ErrorsView site={null} onSite={() => {}} />);
    expect(screen.getByText(VIEWS_MISSING)).toBeTruthy();
    expect(screen.queryByText(/No site reported an error/)).toBeNull();
  });

  it("says so instead of drawing a site page", () => {
    query.current = { data: oldBody, isLoading: false, isError: false, error: null };
    render(<ErrorsView site="a.dev" onSite={() => {}} />);
    expect(screen.getByRole("alert").textContent).toBe(VIEWS_MISSING);
    expect(screen.queryByText("site page")).toBeNull();
  });
});

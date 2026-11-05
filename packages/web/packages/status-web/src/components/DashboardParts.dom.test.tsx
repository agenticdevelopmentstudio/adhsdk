// @vitest-environment jsdom
import { afterEach, describe, expect, it, vi } from "vitest";
import { cleanup, fireEvent, render, screen } from "@testing-library/react";
import { eitherSection, OpenOnClickTable } from "./DashboardParts";

afterEach(cleanup);

const ROWS = [{ key: "a.com" }, { key: "b.com" }, { key: "c.com" }];

function table(onOpen: (id: string) => void): void {
  render(
    <OpenOnClickTable
      ariaLabel="Sites"
      columns={[{ key: "site", header: "Site", render: (row: { key: string }) => row.key }]}
      rows={ROWS}
      getRowId={(row) => row.key}
      onOpen={onOpen}
    />,
  );
}

describe("eitherSection", () => {
  const ok = (updatedAt: string) => ({ data: 1, error: null, updatedAt });

  it("pairs a failure with the failing provider's own last good read, and names it", () => {
    const s = eitherSection({
      PostHog: { data: 1, error: "HTTP 503", updatedAt: "2026-11-04T09:00:00Z" },
      Vercel: ok("2026-11-04T11:59:00Z"),
    });
    expect(s).toEqual({ data: true, error: "PostHog: HTTP 503", updatedAt: "2026-11-04T09:00:00Z" });
  });

  it("does not borrow a healthy provider's time for a failure that has none", () => {
    const s = eitherSection({ PostHog: ok("2026-11-04T11:59:00Z"), Vercel: { data: null, error: "timeout", updatedAt: null } });
    expect(s).toEqual({ data: true, error: "Vercel: timeout", updatedAt: null });
  });

  it("is as old as its oldest read when nothing failed, and leaves a lone provider unnamed", () => {
    expect(eitherSection({ PostHog: ok("2026-11-04T11:00:00Z"), Vercel: ok("2026-11-04T10:00:00Z") }).updatedAt).toBe(
      "2026-11-04T10:00:00Z",
    );
    expect(eitherSection({ Vercel: { data: null, error: "x", updatedAt: null } }).error).toBe("x");
  });
});

describe("OpenOnClickTable", () => {
  it("opens the row that was clicked", () => {
    const onOpen = vi.fn();
    table(onOpen);
    fireEvent.click(screen.getByText("b.com"));
    expect(onOpen).toHaveBeenCalledExactlyOnceWith("b.com");
  });

  // Arrowing through the rows is reading them, not choosing one.
  it("only moves the highlight on the arrow keys, and opens the highlighted row on Enter", () => {
    const onOpen = vi.fn();
    table(onOpen);
    const grid = screen.getByRole("grid");
    fireEvent.keyDown(grid, { key: "ArrowDown" });
    fireEvent.keyDown(grid, { key: "ArrowDown" });
    expect(onOpen).not.toHaveBeenCalled();
    const highlighted = grid.querySelector("[aria-selected='true']")?.textContent;
    expect(highlighted).toBeTruthy();
    fireEvent.keyDown(grid, { key: "Enter" });
    expect(onOpen).toHaveBeenCalledExactlyOnceWith(highlighted);
  });
});

// @vitest-environment jsdom
import { afterEach, describe, expect, it, vi } from "vitest";
import { cleanup, fireEvent, render, screen } from "@testing-library/react";
import { OpenOnClickTable } from "./DashboardParts";

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

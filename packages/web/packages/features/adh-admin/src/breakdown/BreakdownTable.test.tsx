// @vitest-environment jsdom
import { describe, it, expect, afterEach, vi } from "vitest";
import { render, cleanup, fireEvent, screen } from "@testing-library/react";
import {
  BreakdownTable,
  DirectCell,
  EstimatedCell,
  UNATTRIBUTED_KEY,
  unattributedLast,
  type BreakdownRow,
} from "./BreakdownTable";

afterEach(cleanup);

const row = (over: Partial<BreakdownRow>): BreakdownRow => ({
  key: "k",
  label: "Acme",
  requests: 0,
  server_ms: 0,
  db_ms: 0,
  llm_tokens: { input: 0, output: 0, cache_read: 0, cache_write: 0, reasoning: 0 },
  direct_micros: 0,
  hosting_share_micros: 0,
  estimated_micros: 0,
  unpriced_lines: 0,
  ...over,
});

describe("unattributedLast", () => {
  it("moves the nil-key row to the end and keeps the server's order otherwise", () => {
    const rows = [row({ key: "a" }), row({ key: UNATTRIBUTED_KEY }), row({ key: "b" })];
    expect(unattributedLast(rows).map((r) => r.key)).toEqual(["a", "b", UNATTRIBUTED_KEY]);
  });
});

describe("DirectCell", () => {
  it("reads null as Unpriced, a real zero as $0.00, and unpriced lines as a floor", () => {
    expect(render(<DirectCell row={row({ direct_micros: null })} />).container.textContent).toBe(
      "Unpriced",
    );
    cleanup();
    expect(render(<DirectCell row={row({ direct_micros: 0 })} />).container.textContent).toBe(
      "$0.00",
    );
    cleanup();
    expect(
      render(<DirectCell row={row({ direct_micros: 1_500_000, unpriced_lines: 2 })} />).container
        .textContent,
    ).toBe("≥ $1.50");
  });
});

describe("EstimatedCell", () => {
  const text = (r: BreakdownRow) => {
    const out = render(<EstimatedCell row={r} />).container.textContent;
    cleanup();
    return out;
  };

  it("reads Unpriced, never ≥ $0.00, when all direct cost is unpriced and there is no hosting share", () => {
    expect(text(row({ direct_micros: null, unpriced_lines: 3 }))).toBe("Unpriced");
  });

  it("is a floor over the hosting share when the direct cost is unpriced", () => {
    expect(
      text(row({ direct_micros: null, hosting_share_micros: 250_000, estimated_micros: 250_000, unpriced_lines: 3 })),
    ).toBe("≥ $0.25");
  });

  it("is a floor when a priced row has unpriced lines, exact otherwise", () => {
    expect(text(row({ direct_micros: 1_000_000, estimated_micros: 1_500_000, unpriced_lines: 1 }))).toBe(
      "≥ $1.50",
    );
    expect(text(row({ direct_micros: 1_000_000, estimated_micros: 1_500_000 }))).toBe("$1.50");
  });
});

describe("BreakdownTable", () => {
  const table = (onOpen: (key: string) => void) =>
    render(
      <BreakdownTable
        by="organization"
        rows={[row({ key: "a", label: "Acme" }), row({ key: "b", label: "Bravo" })]}
        loading={false}
        sort="direct"
        onSortChange={vi.fn()}
        openKey="a"
        onOpen={onOpen}
      />,
    );
  const rowNamed = (label: string) => screen.getByText(label).closest("[role='row']")!;

  it("opens a clicked row", () => {
    const onOpen = vi.fn();
    table(onOpen);
    fireEvent.click(rowNamed("Bravo"));
    expect(onOpen).toHaveBeenLastCalledWith("b");
  });

  // Alt-click adds to the selection, so the set holds the open row too: the new row still opens.
  it("switches the detail on an alt-click, not back to the open row", () => {
    const onOpen = vi.fn();
    table(onOpen);
    fireEvent.click(rowNamed("Bravo"), { altKey: true });
    expect(onOpen).toHaveBeenLastCalledWith("b");
  });

  // Space toggles the focused row INTO the selection, so the open row is still in the set too.
  it("switches the detail on Space, not back to the open row", () => {
    const onOpen = vi.fn();
    table(onOpen);
    const grid = screen.getByRole("grid");
    fireEvent.focus(grid);
    fireEvent.keyDown(grid, { key: "ArrowDown" });
    onOpen.mockClear();
    fireEvent.keyDown(grid, { key: " " });
    expect(onOpen).toHaveBeenLastCalledWith("b");
  });

  it("opens a double-clicked row", () => {
    const onOpen = vi.fn();
    table(onOpen);
    fireEvent.doubleClick(rowNamed("Bravo"));
    expect(onOpen).toHaveBeenLastCalledWith("b");
  });
});

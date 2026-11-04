// @vitest-environment jsdom
import { afterEach, describe, expect, it } from "vitest"
import { cleanup, fireEvent, render, screen } from "@testing-library/react"

import { BarList } from "../blocks/bar-list"
import { axisLabelIndexes, formatCount, niceTicks, TrendChart } from "../blocks/trend-chart"

afterEach(cleanup)

const LABELS = ["a", "b", "c"]

/** jsdom lays nothing out, so a plot has to be told how wide it is. */
function hoverPlot(container: HTMLElement, clientX: number): void {
  const plot = container.querySelector<HTMLElement>('[data-slot="trend-plot"]')!
  plot.getBoundingClientRect = () => ({ left: 0, width: 100, top: 0, height: 100 }) as DOMRect
  fireEvent.pointerMove(plot, { clientX })
}

describe("niceTicks", () => {
  it("starts at zero and reaches past the maximum on a round step", () => {
    expect(niceTicks(487)).toEqual([0, 200, 400, 600])
    expect(niceTicks(100)).toEqual([0, 50, 100])
  })

  it("never steps by a fraction of a count", () => {
    expect(niceTicks(2)).toEqual([0, 1, 2])
    expect(niceTicks(1)).toEqual([0, 1])
  })

  it("gives a flat series an axis to sit on", () => {
    expect(niceTicks(0)).toEqual([0, 1])
  })
})

describe("axisLabelIndexes", () => {
  it("labels every bucket when there are few", () => {
    expect(axisLabelIndexes(3)).toEqual([0, 1, 2])
    expect(axisLabelIndexes(5)).toEqual([0, 1, 2, 3, 4])
  })

  it("keeps the gaps equal, so a week does not read Oct 29, 31, Nov 1, 3, 4", () => {
    expect(axisLabelIndexes(7)).toEqual([0, 2, 4, 6])
  })

  it.each([6, 7, 8, 14, 24, 30, 31, 90])("steps evenly and ends on the newest bucket across %i", (n) => {
    const indexes = axisLabelIndexes(n)
    expect(indexes.length).toBeLessThanOrEqual(5)
    expect(indexes.at(-1)).toBe(n - 1)
    expect(new Set(indexes.slice(1).map((v, i) => v - indexes[i]!)).size).toBe(1)
  })
})

describe("formatCount", () => {
  it("keeps every digit until there are too many to read", () => {
    expect(formatCount(9_999)).toBe("9,999")
    expect(formatCount(26_243)).toBe("26.2K")
  })
})

describe("TrendChart", () => {
  it("says so when there is nothing to plot", () => {
    render(<TrendChart ariaLabel="x" labels={[]} series={[]} />)
    expect(screen.getByText("No data in this range.")).toBeTruthy()
  })

  it("treats an all-null series as no data, not as a flat zero", () => {
    render(<TrendChart ariaLabel="x" labels={LABELS} series={[{ name: "s", color: "red", values: [null, null, null] }]} />)
    expect(screen.getByText("No data in this range.")).toBeTruthy()
  })

  it("names series in a legend only when there are two to tell apart", () => {
    const { rerender } = render(
      <TrendChart ariaLabel="x" labels={LABELS} series={[{ name: "one", color: "red", values: [1, 2, 3] }]} />,
    )
    expect(screen.queryByRole("list")).toBeNull()
    rerender(
      <TrendChart
        ariaLabel="x"
        labels={LABELS}
        series={[
          { name: "one", color: "red", values: [1, 2, 3] },
          { name: "two", color: "blue", values: [3, 2, 1] },
        ]}
      />,
    )
    expect(screen.getByRole("list").textContent).toContain("two")
  })

  it("breaks the line at a null instead of drawing it to zero", () => {
    const { container } = render(
      <TrendChart ariaLabel="x" labels={["a", "b", "c", "d"]} series={[{ name: "s", color: "red", values: [1, 2, null, 4] }]} />,
    )
    expect(container.querySelectorAll("polyline")).toHaveLength(2)
  })

  it("shows the value under the pointer", () => {
    const { container } = render(
      <TrendChart ariaLabel="x" labels={LABELS} series={[{ name: "s", color: "red", values: [10, 20, 30] }]} />,
    )
    hoverPlot(container, 100)
    const tip = screen.getByRole("status")
    expect(tip.textContent).toContain("c")
    expect(tip.textContent).toContain("30")
  })

  it("resolves the pointer to a band when drawing bars", () => {
    const { container } = render(
      <TrendChart ariaLabel="x" variant="bars" labels={LABELS} series={[{ name: "s", color: "red", values: [10, 20, 30] }]} />,
    )
    hoverPlot(container, 50)
    expect(screen.getByRole("status").textContent).toContain("20")
  })

  it("carries every value in its table view", () => {
    render(<TrendChart ariaLabel="x" labels={LABELS} series={[{ name: "s", color: "red", values: [10, null, 30] }]} />)
    const table = screen.getByRole("table", { hidden: true })
    expect(table.textContent).toContain("10")
    expect(table.textContent).toContain("—")
    expect(table.textContent).toContain("30")
  })
})

describe("BarList", () => {
  const ITEMS = [
    { name: "US", value: 100 },
    { name: "SG", value: 50 },
    { name: "CN", value: 10 },
  ]

  it("counts what it leaves out", () => {
    render(<BarList ariaLabel="x" items={ITEMS} maxItems={2} />)
    expect(screen.queryByText("CN")).toBeNull()
    expect(screen.getByText("and 1 more")).toBeTruthy()
  })

  it("is plain text until it can do something", () => {
    render(<BarList ariaLabel="x" items={ITEMS} />)
    expect(screen.queryByRole("button")).toBeNull()
  })

  it("reports the row chosen, and marks it", () => {
    let chosen = ""
    render(<BarList ariaLabel="x" items={ITEMS} selected="SG" onSelect={(name) => (chosen = name)} />)
    expect(screen.getByRole("button", { name: /SG/ }).getAttribute("aria-pressed")).toBe("true")
    fireEvent.click(screen.getByRole("button", { name: /US/ }))
    expect(chosen).toBe("US")
  })
})

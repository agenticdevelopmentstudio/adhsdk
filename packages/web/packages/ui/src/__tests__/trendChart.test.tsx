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
  it("trend-chart-008 starts at zero and reaches past the maximum on a round step", () => {
    expect(niceTicks(487)).toEqual([0, 200, 400, 600])
    expect(niceTicks(100)).toEqual([0, 50, 100])
  })

  it("trend-chart-009 never steps by a fraction of a count", () => {
    expect(niceTicks(2)).toEqual([0, 1, 2])
    expect(niceTicks(1)).toEqual([0, 1])
  })

  it("trend-chart-009 gives a flat series an axis to sit on", () => {
    expect(niceTicks(0)).toEqual([0, 1])
  })
})

describe("axisLabelIndexes", () => {
  it("trend-chart-010 labels every bucket when there are few", () => {
    expect(axisLabelIndexes(3)).toEqual([0, 1, 2])
    expect(axisLabelIndexes(5)).toEqual([0, 1, 2, 3, 4])
  })

  it("trend-chart-010 keeps the gaps equal, so a week does not read Oct 29, 31, Nov 1, 3, 4", () => {
    expect(axisLabelIndexes(7)).toEqual([0, 2, 4, 6])
  })

  it.each([6, 7, 8, 14, 24, 30, 31, 90])("trend-chart-011 steps evenly and ends on the newest bucket across %i", (n) => {
    const indexes = axisLabelIndexes(n)
    expect(indexes.length).toBeLessThanOrEqual(5)
    expect(indexes.at(-1)).toBe(n - 1)
    expect(new Set(indexes.slice(1).map((v, i) => v - indexes[i]!)).size).toBe(1)
  })
})

describe("formatCount", () => {
  it("trend-chart-012 keeps every digit until there are too many to read", () => {
    expect(formatCount(9_999)).toBe("9,999")
    expect(formatCount(26_243)).toBe("26.2K")
  })
})

describe("TrendChart", () => {
  it("trend-chart-001 says so when there is nothing to plot", () => {
    render(<TrendChart ariaLabel="x" labels={[]} series={[]} />)
    expect(screen.getByText("No data in this range.")).toBeTruthy()
  })

  it("trend-chart-002 treats an all-null series as no data, not as a flat zero", () => {
    render(<TrendChart ariaLabel="x" labels={LABELS} series={[{ name: "s", color: "red", values: [null, null, null] }]} />)
    expect(screen.getByText("No data in this range.")).toBeTruthy()
  })

  it("trend-chart-003 names series in a legend only when there are two to tell apart", () => {
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

  it("trend-chart-004 breaks the line at a null instead of drawing it to zero", () => {
    const { container } = render(
      <TrendChart ariaLabel="x" labels={["a", "b", "c", "d"]} series={[{ name: "s", color: "red", values: [1, 2, null, 4] }]} />,
    )
    expect(container.querySelectorAll("polyline")).toHaveLength(2)
  })

  it("trend-chart-005 shows the value under the pointer", () => {
    const { container } = render(
      <TrendChart ariaLabel="x" labels={LABELS} series={[{ name: "s", color: "red", values: [10, 20, 30] }]} />,
    )
    hoverPlot(container, 100)
    const tip = screen.getByRole("status")
    expect(tip.textContent).toContain("c")
    expect(tip.textContent).toContain("30")
  })

  it("trend-chart-006 resolves the pointer to a band when drawing bars", () => {
    const { container } = render(
      <TrendChart ariaLabel="x" variant="bars" labels={LABELS} series={[{ name: "s", color: "red", values: [10, 20, 30] }]} />,
    )
    hoverPlot(container, 50)
    expect(screen.getByRole("status").textContent).toContain("20")
  })

  it("trend-chart-007 carries every value in its table view", () => {
    render(<TrendChart ariaLabel="x" labels={LABELS} series={[{ name: "s", color: "red", values: [10, null, 30] }]} />)
    const table = screen.getByRole("table", { hidden: true })
    expect(table.textContent).toContain("10")
    expect(table.textContent).toContain("—")
    expect(table.textContent).toContain("30")
  })

  it("trend-chart-013 shows no tooltip when the plot box has zero width", () => {
    const { container } = render(
      <TrendChart ariaLabel="x" labels={LABELS} series={[{ name: "s", color: "red", values: [10, 20, 30] }]} />,
    )
    const plot = container.querySelector<HTMLElement>('[data-slot="trend-plot"]')!
    plot.getBoundingClientRect = () => ({ left: 0, width: 0, top: 0, height: 0 }) as DOMRect
    fireEvent.pointerMove(plot, { clientX: 50 })
    expect(screen.queryByRole("status")).toBeNull()
  })

  it("trend-chart-014 flips the tooltip to the left of the pointer past 55 percent of the plot", () => {
    const { container } = render(
      <TrendChart ariaLabel="x" labels={LABELS} series={[{ name: "s", color: "red", values: [10, 20, 30] }]} />,
    )
    hoverPlot(container, 0)
    expect(screen.getByRole("status").style.transform).toBe("translateX(10px)")
    hoverPlot(container, 100)
    expect(screen.getByRole("status").style.transform).toBe("translateX(calc(-100% - 10px))")
  })
})

describe("BarList", () => {
  const ITEMS = [
    { name: "US", value: 100 },
    { name: "SG", value: 50 },
    { name: "CN", value: 10 },
  ]

  it("bl-001 opens what it leaves out, and closes it again", () => {
    render(<BarList ariaLabel="x" items={ITEMS} maxItems={2} />)
    expect(screen.queryByText("CN")).toBeNull()
    fireEvent.click(screen.getByRole("button", { name: "Show all 3" }))
    expect(screen.getByText("CN")).toBeTruthy()
    fireEvent.click(screen.getByRole("button", { name: "Show fewer" }))
    expect(screen.queryByText("CN")).toBeNull()
  })

  it("bl-002 offers nothing to open when every row fits", () => {
    render(<BarList ariaLabel="x" items={ITEMS} maxItems={Infinity} />)
    expect(screen.getByText("CN")).toBeTruthy()
    expect(screen.queryByRole("button")).toBeNull()
  })

  it("bl-003 lets a long name wrap rather than cutting it off", () => {
    const name = "/a/very/long/path/that/would/not/fit/in/a/narrow/panel"
    render(<BarList ariaLabel="x" items={[{ name, value: 1 }]} />)
    expect(screen.getByText(name).className).not.toContain("truncate")
  })

  it("bl-004 is plain text until it can do something", () => {
    render(<BarList ariaLabel="x" items={ITEMS} />)
    expect(screen.queryByRole("button")).toBeNull()
  })

  it("bl-005 reports the row chosen, and marks it", () => {
    let chosen = ""
    render(<BarList ariaLabel="x" items={ITEMS} selected="SG" onSelect={(name) => (chosen = name)} />)
    expect(screen.getByRole("button", { name: /SG/ }).getAttribute("aria-pressed")).toBe("true")
    fireEvent.click(screen.getByRole("button", { name: /US/ }))
    expect(chosen).toBe("US")
  })

  const barWidths = (container: HTMLElement): string[] =>
    [...container.querySelectorAll<HTMLElement>("[aria-hidden] > span")].map((el) => el.style.width)

  it("bl-006 renders rows in the order of items, without sorting", () => {
    render(
      <BarList
        ariaLabel="x"
        items={[
          { name: "CN", value: 10 },
          { name: "US", value: 100 },
          { name: "SG", value: 50 },
        ]}
      />,
    )
    const rows = screen.getAllByRole("listitem").map((li) => li.textContent ?? "")
    expect(rows[0]).toContain("CN")
    expect(rows[1]).toContain("US")
    expect(rows[2]).toContain("SG")
  })

  it("bl-007 exposes ariaLabel as the list's accessible name", () => {
    render(<BarList ariaLabel="Top countries" items={ITEMS} />)
    expect(screen.getByRole("list", { name: "Top countries" })).toBeTruthy()
  })

  it("bl-008 formats values with the default count formatter", () => {
    render(
      <BarList
        ariaLabel="x"
        items={[
          { name: "A", value: 9999 },
          { name: "B", value: 12500 },
        ]}
      />,
    )
    expect(screen.getByText("9,999")).toBeTruthy()
    expect(screen.getByText("12.5K")).toBeTruthy()
  })

  it("bl-009 shows detail in place of the value and does not call formatValue for it", () => {
    const calls: number[] = []
    render(
      <BarList
        ariaLabel="x"
        items={[{ name: "A", value: 5, detail: "12 issues · 340 events" }]}
        formatValue={(v) => {
          calls.push(v)
          return String(v)
        }}
      />,
    )
    expect(screen.getByText("12 issues · 340 events")).toBeTruthy()
    expect(calls).toEqual([])
  })

  it("bl-010 an empty detail string still replaces the value", () => {
    render(<BarList ariaLabel="x" items={[{ name: "A", value: 5, detail: "" }]} />)
    const valueEl = screen.getByText("A").nextElementSibling!
    expect(valueEl.textContent).toBe("")
    expect(screen.queryByText("5")).toBeNull()
  })

  it("bl-011 bar widths are proportional to the largest value", () => {
    const { container } = render(<BarList ariaLabel="x" items={ITEMS} />)
    expect(barWidths(container)).toEqual(["100%", "50%", "10%"])
  })

  it("bl-012 the maximum counts rows hidden by the limit", () => {
    const { container } = render(<BarList ariaLabel="x" items={[ITEMS[1]!, ITEMS[0]!, ITEMS[2]!]} maxItems={1} />)
    expect(barWidths(container)).toEqual(["50%"])
    fireEvent.click(screen.getByRole("button", { name: "Show all 3" }))
    expect(barWidths(container)).toEqual(["50%", "100%", "10%"])
  })

  it("bl-013 a zero maximum gives every bar width 0%", () => {
    const { container } = render(
      <BarList
        ariaLabel="x"
        items={[
          { name: "A", value: 0 },
          { name: "B", value: 0 },
        ]}
      />,
    )
    expect(barWidths(container)).toEqual(["0%", "0%"])
  })

  it("bl-014 a positive value has a 2px minimum bar width", () => {
    const { container } = render(
      <BarList
        ariaLabel="x"
        items={[
          { name: "US", value: 100000 },
          { name: "CN", value: 1 },
        ]}
      />,
    )
    const bars = container.querySelectorAll<HTMLElement>("[aria-hidden] > span")
    expect(bars[1]!.style.minWidth).toBe("2px")
  })

  it("bl-015 a zero value has no minimum bar width", () => {
    const { container } = render(
      <BarList
        ariaLabel="x"
        items={[
          { name: "US", value: 100 },
          { name: "ZZ", value: 0 },
        ]}
      />,
    )
    const bars = container.querySelectorAll<HTMLElement>("[aria-hidden] > span")
    expect(bars[1]!.style.minWidth).toMatch(/^0(px)?$/)
  })

  it("bl-016 bars use the color prop, defaulting to the blue category token", () => {
    const first = render(<BarList ariaLabel="x" items={ITEMS} />)
    expect(first.container.querySelector<HTMLElement>("[aria-hidden] > span")!.style.backgroundColor).toBe(
      "var(--color-apt-cat-blue)",
    )
    cleanup()
    const second = render(<BarList ariaLabel="x" items={ITEMS} color="red" />)
    expect(second.container.querySelector<HTMLElement>("[aria-hidden] > span")!.style.backgroundColor).toBe("red")
  })

  it("bl-017 each bar wrapper is hidden from assistive technology", () => {
    const { container } = render(<BarList ariaLabel="x" items={ITEMS} />)
    const wrappers = container.querySelectorAll("[aria-hidden]")
    expect(wrappers.length).toBe(3)
    wrappers.forEach((w) => expect(w.getAttribute("aria-hidden")).toBe("true"))
  })

  it("bl-018 an empty list renders only the empty label", () => {
    const first = render(<BarList ariaLabel="x" items={[]} />)
    expect(screen.getByText("Nothing to show.")).toBeTruthy()
    expect(screen.queryByRole("list")).toBeNull()
    expect(screen.queryByRole("button")).toBeNull()
    first.unmount()
    render(<BarList ariaLabel="x" items={[]} emptyLabel="No referrers" />)
    expect(screen.getByText("No referrers")).toBeTruthy()
  })

  it("bl-019 unselected row buttons are dimmed to 55% while one row is selected", () => {
    render(<BarList ariaLabel="x" items={ITEMS} onSelect={() => {}} selected="SG" />)
    expect(screen.getByRole("button", { name: /US/ }).className).toContain("opacity-55")
    expect(screen.getByRole("button", { name: /CN/ }).className).toContain("opacity-55")
    expect(screen.getByRole("button", { name: /SG/ }).className).not.toContain("opacity-55")
  })

  it("bl-020 no row is dimmed when nothing is selected", () => {
    render(<BarList ariaLabel="x" items={ITEMS} onSelect={() => {}} />)
    for (const button of screen.getAllByRole("button")) {
      expect(button.className).not.toContain("opacity-55")
      expect(button.getAttribute("aria-pressed")).toBe("false")
    }
  })

  it("bl-021 the expand button exposes aria-expanded", () => {
    render(<BarList ariaLabel="x" items={ITEMS} maxItems={2} />)
    expect(screen.getByRole("button", { name: "Show all 3" }).getAttribute("aria-expanded")).toBe("false")
    fireEvent.click(screen.getByRole("button", { name: "Show all 3" }))
    expect(screen.getByRole("button", { name: "Show fewer" }).getAttribute("aria-expanded")).toBe("true")
  })

  it("bl-022 the expanded state survives a change of items", () => {
    const { rerender } = render(<BarList ariaLabel="x" items={ITEMS} maxItems={2} />)
    fireEvent.click(screen.getByRole("button", { name: "Show all 3" }))
    rerender(
      <BarList
        ariaLabel="x"
        items={[
          { name: "A", value: 3 },
          { name: "B", value: 2 },
          { name: "C", value: 1 },
        ]}
        maxItems={2}
      />,
    )
    expect(screen.getByText("C")).toBeTruthy()
    expect(screen.getByRole("button", { name: "Show fewer" })).toBeTruthy()
  })

  it("bl-023 className lands on the outermost element, also when empty", () => {
    const filled = render(<BarList ariaLabel="x" items={ITEMS} className="x" />)
    expect(filled.container.firstElementChild!.classList.contains("x")).toBe(true)
    filled.unmount()
    const empty = render(<BarList ariaLabel="x" items={[]} className="x" />)
    expect(empty.container.firstElementChild!.classList.contains("x")).toBe(true)
  })

  it("bl-024 clicking the already-selected row still calls onSelect once with its name", () => {
    const calls: string[] = []
    render(<BarList ariaLabel="x" items={ITEMS} selected="SG" onSelect={(name) => calls.push(name)} />)
    fireEvent.click(screen.getByRole("button", { name: /SG/ }))
    expect(calls).toEqual(["SG"])
  })
})

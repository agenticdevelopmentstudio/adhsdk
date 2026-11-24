/**
 * `SectionHeader` — the content header: optional eyebrow, h2 title, actions slot and a help popover,
 * plus the `paneTitle` hand-off to a detail stack's strip. One test per conformance vector.
 */
/// <reference types="@testing-library/jest-dom/vitest" />
import type { ReactNode } from "react"
import { afterEach, describe, expect, it } from "vitest"
import { cleanup, render, screen, waitFor } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { HierarchicalTopicDetail, type TopicLevel } from "../blocks/hierarchical-topic-detail"
import { SectionHeader } from "../blocks/section-header"

const levels: TopicLevel[] = [
  {
    id: "companies",
    title: "Companies",
    items: [{ id: "acme", label: "Acme" }],
    selectedId: "acme",
    onSelect: () => {},
    onClear: () => {},
  },
]

function htdv(children: ReactNode) {
  return (
    <HierarchicalTopicDetail levels={levels} layoutMode="wide" disclosureStyle="covered">
      {children}
    </HierarchicalTopicDetail>
  )
}

const strip = (c: HTMLElement) => c.querySelector<HTMLElement>("[data-htd-detail-title]")!
const pane = (c: HTMLElement) => strip(c).parentElement!.nextElementSibling as HTMLElement

afterEach(cleanup)

describe("SectionHeader", () => {
  it("section-header-001: renders the title as an h2 in the left section", () => {
    const { container } = render(<SectionHeader title="All ecosystems" />)
    const h2 = screen.getByRole("heading", { level: 2, name: "All ecosystems" })
    expect(h2.tagName).toBe("H2")
    const root = container.firstElementChild!
    expect(root.firstElementChild!.contains(h2)).toBe(true)
  })

  it("section-header-002: renders the eyebrow above the title in dim mono, the title in gold mono", () => {
    render(<SectionHeader eyebrow="Section" title="Title" />)
    const eyebrow = screen.getByText("Section")
    const h2 = screen.getByRole("heading", { name: "Title" })
    expect(eyebrow.className).toContain("font-mono")
    expect(eyebrow.className).toContain("text-apt-text-dim")
    expect(h2.className).toContain("font-mono")
    expect(h2.className).toContain("text-apt-gold")
    expect(eyebrow.compareDocumentPosition(h2) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy()
    expect(eyebrow.parentElement).toBe(h2.parentElement)
  })

  it("section-header-003: renders no eyebrow slot without an eyebrow", () => {
    render(<SectionHeader title="Title" />)
    const h2 = screen.getByRole("heading", { name: "Title" })
    expect(h2.parentElement!.children).toHaveLength(1)
    expect(h2.parentElement!.querySelector(".text-apt-text-dim")).toBeNull()
  })

  it("section-header-004: shows the help button when help is given", () => {
    render(<SectionHeader title="Title" help={<div>Help content</div>} />)
    expect(screen.getByRole("button", { name: "About this section" })).toBeInTheDocument()
  })

  it("section-header-005: renders no help button without help", () => {
    render(<SectionHeader title="Title" />)
    expect(screen.queryByRole("button")).toBeNull()
  })

  it("section-header-006: clicking the help trigger opens a popover below, aligned to the end", async () => {
    const user = userEvent.setup()
    render(<SectionHeader title="Title" help={<div>Help content</div>} />)
    expect(screen.queryByText("Help content")).toBeNull()
    await user.click(screen.getByRole("button", { name: "About this section" }))
    expect(await screen.findByText("Help content")).toBeVisible()
    const popup = document.querySelector<HTMLElement>('[data-slot="popover-content"]')!
    expect(popup).toBeInTheDocument()
    const positioner = popup.parentElement!
    expect(positioner.getAttribute("data-side")).toBe("bottom")
    expect(positioner.getAttribute("data-align")).toBe("end")
  })

  it("section-header-007: pressing Enter on the focused help trigger opens the popover", async () => {
    const user = userEvent.setup()
    render(<SectionHeader title="Title" help={<div>Help content</div>} />)
    const trigger = screen.getByRole("button", { name: "About this section" })
    trigger.focus()
    await user.keyboard("{Enter}")
    expect(await screen.findByText("Help content")).toBeVisible()
  })

  it("section-header-008: labels the help trigger 'About this section'", () => {
    render(<SectionHeader title="Title" help={<div>Help content</div>} />)
    expect(screen.getByRole("button", { name: "About this section" })).toHaveAttribute(
      "aria-label",
      "About this section",
    )
  })

  it("section-header-009: renders actions in the right section, before the help button", () => {
    const { container } = render(
      <SectionHeader title="Title" actions={<button>Action</button>} help={<div>Help content</div>} />,
    )
    const action = screen.getByRole("button", { name: "Action" })
    const help = screen.getByRole("button", { name: "About this section" })
    const right = container.firstElementChild!.lastElementChild!
    expect(right.contains(action)).toBe(true)
    expect(right.contains(help)).toBe(true)
    expect(action.compareDocumentPosition(help) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy()
  })

  it("section-header-010: renders no actions slot without actions", () => {
    const { container } = render(<SectionHeader title="Title" />)
    const right = container.firstElementChild!.lastElementChild!
    expect(right.children).toHaveLength(0)
  })

  it("section-header-011: puts className on the root beside the default flex classes", () => {
    const { container } = render(<SectionHeader title="Title" className="my-custom-class" />)
    const root = container.firstElementChild!
    expect(root).toHaveClass("flex", "items-start", "justify-between", "my-custom-class")
  })

  it("section-header-012: puts the left section before the right, justified to opposite edges", () => {
    const { container } = render(
      <SectionHeader
        eyebrow="Section"
        title="Title"
        actions={<button>Action</button>}
        help={<div>Help content</div>}
      />,
    )
    const root = container.firstElementChild!
    expect(root).toHaveClass("justify-between")
    expect(root.children).toHaveLength(2)
    const [left, right] = [root.children[0]!, root.children[1]!]
    expect(left.contains(screen.getByRole("heading", { name: "Title" }))).toBe(true)
    expect(right.contains(screen.getByRole("button", { name: "Action" }))).toBe(true)
    expect(left.compareDocumentPosition(right) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy()
  })

  it("section-header-013: pressing Space on the focused help trigger opens the popover", async () => {
    const user = userEvent.setup()
    render(<SectionHeader title="Title" help={<div>Help content</div>} />)
    screen.getByRole("button", { name: "About this section" }).focus()
    await user.keyboard(" ")
    expect(await screen.findByText("Help content")).toBeVisible()
  })

  it("section-header-014: Escape closes the popover and returns focus to the trigger", async () => {
    const user = userEvent.setup()
    render(<SectionHeader title="Title" help={<div>Help content</div>} />)
    const trigger = screen.getByRole("button", { name: "About this section" })
    await user.click(trigger)
    await screen.findByText("Help content")
    await user.keyboard("{Escape}")
    await waitFor(() => expect(screen.queryByText("Help content")).toBeNull())
    expect(trigger).toHaveFocus()
  })

  it("section-header-015: a second activation closes the popover, reflected in aria-expanded", async () => {
    const user = userEvent.setup()
    render(<SectionHeader title="Title" help={<div>Help content</div>} />)
    const trigger = screen.getByRole("button", { name: "About this section" })
    expect(trigger).toHaveAttribute("aria-expanded", "false")
    await user.click(trigger)
    await screen.findByText("Help content")
    expect(trigger).toHaveAttribute("aria-expanded", "true")
    await user.click(trigger)
    await waitFor(() => expect(screen.queryByText("Help content")).toBeNull())
    expect(trigger).toHaveAttribute("aria-expanded", "false")
  })

  it("section-header-016: carries a SectionHeader marked paneTitle, and leaves an unmarked one where it is", () => {
    const { container } = render(
      htdv(
        <>
          <SectionHeader paneTitle title="Providers" />
          <SectionHeader title="Sign-in methods" />
        </>,
      ),
    )
    expect(strip(container)).toHaveTextContent("Providers")
    expect(pane(container).textContent).not.toContain("Providers")
    expect(pane(container).textContent).toContain("Sign-in methods")
  })

  it("section-header-017: draws an unmarked title in the pane, not the strip", () => {
    const { container } = render(htdv(<SectionHeader title="Title" />))
    expect(pane(container).querySelector("h2")).toHaveTextContent("Title")
    expect(strip(container).textContent).not.toContain("Title")
  })

  it("section-header-018: a hoisted header keeps its eyebrow and help in the pane, with no h2", () => {
    const { container } = render(
      htdv(<SectionHeader paneTitle title="Providers" eyebrow="Auth" help={<div>Help content</div>} />),
    )
    expect(strip(container)).toHaveTextContent("Providers")
    expect(pane(container)).toHaveTextContent("Auth")
    expect(pane(container).querySelector('button[aria-label="About this section"]')).not.toBeNull()
    expect(pane(container).querySelector("h2")).toBeNull()
    expect(pane(container).textContent).not.toContain("Providers")
  })

  it("section-header-019: a bare hoisted header draws nothing in the pane, not even the root", () => {
    const { container } = render(htdv(<SectionHeader paneTitle title="Providers" className="my-custom-class" />))
    expect(strip(container)).toHaveTextContent("Providers")
    expect(pane(container).textContent).toBe("")
    expect(pane(container).querySelector(".my-custom-class")).toBeNull()
    expect(pane(container).querySelector(".justify-between")).toBeNull()
  })

  it("section-header-020: paneTitle outside any stack draws the h2 inline", () => {
    render(<SectionHeader paneTitle title="Providers" />)
    expect(screen.getByRole("heading", { level: 2, name: "Providers" })).toBeInTheDocument()
  })

  it("section-header-021: the last paneTitle header holds the strip; the earlier one draws in place", () => {
    const { container } = render(
      htdv(
        <>
          <SectionHeader paneTitle title="First" />
          <SectionHeader paneTitle title="Second" />
        </>,
      ),
    )
    expect(strip(container)).toHaveTextContent("Second")
    expect(strip(container).textContent).not.toContain("First")
    expect(pane(container).querySelector("h2")).toHaveTextContent("First")
    expect(pane(container).textContent).not.toContain("Second")
  })
})

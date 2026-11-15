/// <reference types="@testing-library/jest-dom/vitest" />
import { describe, expect, it } from "vitest"
import { render, screen } from "@testing-library/react"

import { FieldGroup } from "../blocks/field-group"
import { fieldCaptionClass } from "../lib/typography"

describe("FieldGroup", () => {
  it("T1 renders the title in an h3 carrying the field caption classes", () => {
    render(<FieldGroup title="Profile">body</FieldGroup>)
    const h = screen.getByRole("heading", { level: 3, name: "Profile" })
    for (const c of fieldCaptionClass.split(" ")) expect(h).toHaveClass(c)
    expect(h).toHaveClass("font-mono", "uppercase", "tracking-wider", "text-apt-text-muted")
  })

  it("T2 renders trailing in the title row opposite the title", () => {
    render(<FieldGroup title="Profile" trailing={<button>Reset</button>}>x</FieldGroup>)
    const row = screen.getByRole("heading", { level: 3 }).parentElement!
    expect(row).toHaveClass("flex", "justify-between")
    expect(row.children).toHaveLength(2)
    expect(row.lastElementChild).toBe(screen.getByRole("button", { name: "Reset" }))
  })

  it("T3 omits the trailing element when not provided", () => {
    render(<FieldGroup title="Profile">x</FieldGroup>)
    const row = screen.getByRole("heading", { level: 3 }).parentElement!
    expect(row.children).toHaveLength(1)
    expect(row).toHaveClass("justify-between")
  })

  it("T4 stacks children below the title row with gap-3", () => {
    const { container } = render(
      <FieldGroup title="Profile">
        <div data-testid="a" />
        <div data-testid="b" />
      </FieldGroup>,
    )
    const root = container.querySelector("section")!
    expect(root).toHaveClass("flex", "flex-col", "gap-3")
    expect(root.children).toHaveLength(3)
    expect(root.children[1]).toBe(screen.getByTestId("a"))
    expect(root.children[2]).toBe(screen.getByTestId("b"))
  })

  it("T5 root section is a bordered rounded recessed surface", () => {
    const { container } = render(<FieldGroup title="Profile">x</FieldGroup>)
    expect(container.firstElementChild!.tagName).toBe("SECTION")
    expect(container.firstElementChild).toHaveClass("rounded-lg", "border", "border-apt-border", "bg-apt-surface-2/40")
  })

  it("T6 merges className onto the root keeping layout classes", () => {
    const { container } = render(<FieldGroup title="Profile" className="mt-6">x</FieldGroup>)
    expect(container.firstElementChild).toHaveClass("flex", "flex-col", "border", "mt-6")
  })

  it.skip("T7 wraps a long title within a 375px viewport without overflow (jsdom has no layout)", () => {})
})

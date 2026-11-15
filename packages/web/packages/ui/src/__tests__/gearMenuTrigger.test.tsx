/// <reference types="@testing-library/jest-dom/vitest" />
import { describe, expect, it } from "vitest"
import { render, screen, fireEvent } from "@testing-library/react"

import { DropdownMenu } from "../components/dropdown-menu"
import { GearMenuTrigger, type GearMenuTriggerProps } from "../blocks/gear-menu-trigger"

function renderTrigger(props: GearMenuTriggerProps) {
  return render(
    <DropdownMenu>
      <GearMenuTrigger {...props} />
    </DropdownMenu>,
  )
}

describe("GearMenuTrigger", () => {
  it("gear-001 renders a 14px settings icon inside an activatable trigger", () => {
    const { container } = renderTrigger({ label: "Test" })
    const btn = screen.getByRole("button", { name: "Test" })
    const svg = container.querySelector("svg")!
    expect(btn).toContainElement(svg)
    expect(svg).toHaveAttribute("width", "14")
    expect(svg).toHaveAttribute("height", "14")
    expect(svg).toHaveClass("lucide-settings")
  })

  it("gear-002 sets aria-label from label", () => {
    renderTrigger({ label: "Registry actions" })
    expect(screen.getByRole("button")).toHaveAttribute("aria-label", "Registry actions")
  })

  it("gear-003 requires label (type-level)", () => {
    // @ts-expect-error label is required
    const props: GearMenuTriggerProps = {}
    expect(props).toBeDefined()
  })

  it("gear-004 disabled sets the attribute and the 40% opacity class", () => {
    renderTrigger({ label: "Test", disabled: true })
    const btn = screen.getByRole("button")
    expect(btn).toBeDisabled()
    expect(btn).toHaveClass("disabled:opacity-40")
  })

  it("gear-005 disabled trigger does not respond to a click", () => {
    renderTrigger({ label: "Test", disabled: true })
    const btn = screen.getByRole("button")
    fireEvent.click(btn)
    expect(btn).toHaveAttribute("aria-expanded", "false")
  })

  it("gear-006 applies className alongside default styles", () => {
    renderTrigger({ label: "Test", className: "custom-class" })
    expect(screen.getByRole("button")).toHaveClass("custom-class", "size-6", "text-apt-text-dim")
  })

  it("gear-007 hides the icon from assistive tech", () => {
    const { container } = renderTrigger({ label: "Test" })
    expect(container.querySelector("svg")).toHaveAttribute("aria-hidden", "true")
  })

  it("gear-008 suppresses the outline and uses a 2px gold/40 focus-visible ring", () => {
    renderTrigger({ label: "Test" })
    expect(screen.getByRole("button")).toHaveClass("outline-none", "focus-visible:ring-2", "focus-visible:ring-apt-gold/40")
  })

  it("gear-009 changes from dim text to normal text on hover", () => {
    renderTrigger({ label: "Test" })
    expect(screen.getByRole("button")).toHaveClass("text-apt-text-dim", "hover:text-apt-text")
  })
})

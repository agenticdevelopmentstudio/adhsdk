/// <reference types="@testing-library/jest-dom/vitest" />
import { describe, expect, it } from "vitest"
import { render, screen } from "@testing-library/react"

import { ErrorText, DialogErrorText } from "../components/error-text"

/**
 * The two inline error lines are ONE treatment in two elements. `DialogErrorText` exists
 * solely because a `<p>` may not nest inside `DialogDescription`'s `<p>` — the element is the
 * only thing the rule forces, and its own docblock says it is "rather than a second
 * treatment". A different colour token here means two consecutive failures of the same kind
 * (a rename the server refused, then a delete it refused) render in two different reds
 * wherever the theme's `--destructive` and `--apt-red` differ.
 */
describe("ErrorText / DialogErrorText", () => {
  it("paints the dialog error the same colour and size as every other inline error", () => {
    render(
      <>
        <ErrorText error="Name already taken." />
        <DialogErrorText error="That did not work." />
      </>,
    )
    const [inline, inDialog] = screen.getAllByRole("alert")
    for (const el of [inline!, inDialog!]) {
      expect(el).toHaveClass("text-sm")
      expect(el).toHaveClass("text-apt-red")
      expect(el.className).not.toContain("text-destructive")
    }
  })

  it("keeps the elements different — a span in the dialog, a paragraph everywhere else", () => {
    render(
      <>
        <ErrorText error="Name already taken." />
        <DialogErrorText error="That did not work." />
      </>,
    )
    const [inline, inDialog] = screen.getAllByRole("alert")
    expect(inline!.tagName).toBe("P")
    expect(inDialog!.tagName).toBe("SPAN")
    expect(inDialog!).toHaveClass("block")
  })

  it("renders nothing without an error", () => {
    render(
      <>
        <ErrorText error={null} />
        <DialogErrorText error={undefined} />
      </>,
    )
    expect(screen.queryByRole("alert")).toBeNull()
  })

  const longText = "x".repeat(500)

  it("error-text-001 renders a p role=alert with the text", () => {
    render(<ErrorText error="Username is required" />)
    const el = screen.getByRole("alert")
    expect(el.tagName).toBe("P")
    expect(el).toHaveTextContent("Username is required")
  })

  it("error-text-002 renders nothing for null", () => {
    const { container } = render(<ErrorText error={null} />)
    expect(container).toBeEmptyDOMElement()
  })

  it("error-text-003 renders nothing for undefined", () => {
    const { container } = render(<ErrorText error={undefined} />)
    expect(container).toBeEmptyDOMElement()
  })

  it("error-text-004 renders nothing for an empty string", () => {
    const { container } = render(<ErrorText error="" />)
    expect(container).toBeEmptyDOMElement()
  })

  it("error-text-005 renders exactly the error text", () => {
    render(<ErrorText error="Invalid email format" />)
    expect(screen.getByRole("alert").textContent).toBe("Invalid email format")
  })

  it("error-text-006 applies text-sm and text-apt-red", () => {
    render(<ErrorText error="Error message" />)
    const el = screen.getByRole("alert")
    expect(el).toHaveClass("text-sm")
    expect(el).toHaveClass("text-apt-red")
  })

  it("error-text-007 has role=alert", () => {
    render(<ErrorText error="Error" />)
    expect(screen.getByRole("alert")).toHaveAttribute("role", "alert")
  })

  it("error-text-008 merges className", () => {
    render(<ErrorText error="Error" className="px-4" />)
    const el = screen.getByRole("alert")
    expect(el).toHaveClass("px-4")
    expect(el).toHaveClass("text-sm")
    expect(el).toHaveClass("text-apt-red")
  })

  it("error-text-009 DialogErrorText renders a span, not a p", () => {
    const { container } = render(<DialogErrorText error="Error" />)
    expect(container.querySelector("span")).not.toBeNull()
    expect(container.querySelector("p")).toBeNull()
  })

  it("error-text-010 DialogErrorText carries mt-2 block text-sm text-apt-red", () => {
    render(<DialogErrorText error="Error" />)
    const el = screen.getByRole("alert")
    for (const c of ["mt-2", "block", "text-sm", "text-apt-red"]) expect(el).toHaveClass(c)
  })

  it("error-text-011 DialogErrorText renders nothing for null", () => {
    const { container } = render(<DialogErrorText error={null} />)
    expect(container).toBeEmptyDOMElement()
  })

  it("error-text-012 DialogErrorText merges className with the defaults", () => {
    render(<DialogErrorText error="Error" className="px-4" />)
    const el = screen.getByRole("alert")
    for (const c of ["px-4", "mt-2", "block", "text-sm", "text-apt-red"]) expect(el).toHaveClass(c)
  })

  it("error-text-013 a caller text-xs replaces text-sm and keeps the color", () => {
    render(<ErrorText error="Error" className="text-xs" />)
    const el = screen.getByRole("alert")
    expect(el).toHaveClass("text-xs")
    expect(el).not.toHaveClass("text-sm")
    expect(el).toHaveClass("text-apt-red")
  })

  it("error-text-014 keeps the alert in a hidden parent and updates its text", () => {
    const { rerender } = render(
      <div style={{ display: "none" }}>
        <ErrorText error="First" />
      </div>,
    )
    expect(screen.getByRole("alert", { hidden: true })).toHaveTextContent("First")
    rerender(
      <div style={{ display: "block" }}>
        <ErrorText error="Second" />
      </div>,
    )
    expect(screen.getByRole("alert")).toHaveTextContent("Second")
  })

  it("error-text-015 renders a 500-character string untruncated", () => {
    render(<ErrorText error={longText} />)
    expect(screen.getByRole("alert").textContent).toBe(longText)
  })

  it("error-text-016 a caller color class displaces the default error color", () => {
    render(<ErrorText error="Error" className="text-blue-500" />)
    const el = screen.getByRole("alert")
    expect(el).toHaveClass("text-blue-500")
    expect(el).not.toHaveClass("text-apt-red")
  })
})

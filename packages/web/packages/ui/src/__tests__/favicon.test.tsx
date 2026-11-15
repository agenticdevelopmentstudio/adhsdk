import { fireEvent, render } from "@testing-library/react"
import { afterEach, describe, expect, it, vi } from "vitest"

import { FAVICON_PATHS, Favicon } from "../components/favicon"

afterEach(() => {
  vi.restoreAllMocks()
})

describe("Favicon", () => {
  it("favicon-001 asks the site itself for its icon", () => {
    const { container } = render(<Favicon href="https://example.com/some/page" />)
    expect(container.querySelector("img")?.getAttribute("src")).toBe(
      "https://example.com/favicon.ico",
    )
  })

  it("favicon-002 tries each candidate in turn", () => {
    const { container } = render(<Favicon href="https://example.com" fallback={<span>globe</span>} />)
    for (const path of FAVICON_PATHS) {
      const img = container.querySelector("img")
      expect(img?.getAttribute("src")).toBe(`https://example.com${path}`)
      fireEvent.error(img!)
    }
  })

  it("favicon-003 shows the fallback after the sixth error", () => {
    const { container, getByText } = render(
      <Favicon href="https://example.com" fallback={<span>globe</span>} />,
    )
    for (let i = 0; i < FAVICON_PATHS.length; i++) fireEvent.error(container.querySelector("img")!)
    expect(container.querySelector("img")).toBeNull()
    expect(getByText("globe")).toBeTruthy()
  })

  it("favicon-004 shows the fallback for an address that is not one", () => {
    const { container, getByText } = render(<Favicon href="not a url" fallback={<span>globe</span>} />)
    expect(getByText("globe")).toBeTruthy()
    expect(container.querySelector("img")).toBeNull()
  })

  it("favicon-005 renders nothing without a fallback", () => {
    const { container } = render(<Favicon href="not a url" />)
    expect(container.innerHTML).toBe("")
  })

  it("favicon-006 keeps the first candidate once it loads", () => {
    const { container } = render(<Favicon href="https://example.com" />)
    fireEvent.load(container.querySelector("img")!)
    expect(container.querySelectorAll("img")).toHaveLength(1)
    expect(container.querySelector("img")?.getAttribute("src")).toBe("https://example.com/favicon.ico")
  })

  it("favicon-007 uses only the origin of href", () => {
    const { container } = render(<Favicon href="https://example.com:8080/a/b?q=1#frag" />)
    expect(container.querySelector("img")?.getAttribute("src")).toBe(
      "https://example.com:8080/favicon.ico",
    )
  })

  it("favicon-008 hides the image from assistive technology and sets size and decoding", () => {
    const { container } = render(<Favicon href="https://example.com" size={24} />)
    const img = container.querySelector("img")!
    expect(img.getAttribute("alt")).toBe("")
    expect(img.getAttribute("aria-hidden")).toBe("true")
    expect(img.getAttribute("width")).toBe("24")
    expect(img.getAttribute("height")).toBe("24")
    expect(img.getAttribute("decoding")).toBe("async")
  })

  it("favicon-009 defaults the size to 16", () => {
    const { container } = render(<Favicon href="https://example.com" />)
    const img = container.querySelector("img")!
    expect(img.getAttribute("width")).toBe("16")
    expect(img.getAttribute("height")).toBe("16")
  })

  it("favicon-010 merges className with its own classes", () => {
    const { container } = render(<Favicon href="https://example.com" className="ml-1" />)
    const img = container.querySelector("img")!
    for (const c of ["ml-1", "shrink-0", "rounded-[3px]", "object-contain"]) {
      expect(img.classList.contains(c)).toBe(true)
    }
  })

  it("favicon-011 advances when the image already failed (complete, natural width 0) at mount", () => {
    // jsdom stands in for the pre-hydration state: an image that is complete with no pixels
    // and never delivered an error event to React.
    const isFirst = (img: HTMLImageElement): boolean =>
      img.getAttribute("src")?.endsWith("/favicon.ico") ?? false
    vi.spyOn(HTMLImageElement.prototype, "complete", "get").mockImplementation(function (
      this: HTMLImageElement,
    ): boolean {
      return isFirst(this)
    })
    vi.spyOn(HTMLImageElement.prototype, "naturalWidth", "get").mockImplementation(function (
      this: HTMLImageElement,
    ): number {
      return isFirst(this) ? 0 : 16
    })
    const { container } = render(<Favicon href="https://example.com" />)
    expect(container.querySelector("img")?.getAttribute("src")).toBe("https://example.com/icon.svg")
  })

  it("favicon-012 exports the candidate list in order", () => {
    expect(FAVICON_PATHS).toEqual([
      "/favicon.ico",
      "/icon.svg",
      "/icon.png",
      "/icon",
      "/apple-icon.png",
      "/apple-icon",
    ])
  })

  it("favicon-013 uses a fresh image element for each candidate", () => {
    const { container } = render(<Favicon href="https://example.com" />)
    const before = container.querySelector("img")!
    fireEvent.error(before)
    const after = container.querySelector("img")!
    expect(after).not.toBe(before)
  })
})

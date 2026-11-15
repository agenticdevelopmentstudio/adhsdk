/**
 * The detail header block (dh-001 .. dh-022): the claimable [API][?] slots, the disabled
 * fallbacks, the `actions` box, and the row's layout. Uses `DetailHeaderProvider` and
 * `DetailHeaderRow` directly; `detailHeaderActions.test.tsx` covers actions through real stacks.
 */
/// <reference types="@testing-library/jest-dom/vitest" />
import { afterEach, describe, expect, it } from "vitest"
import { act, cleanup, render, screen } from "@testing-library/react"
import type { ReactNode } from "react"
import {
  DetailHeaderPortal,
  DetailHeaderProvider,
  DetailHeaderRow,
  DisabledApiButton,
  DisabledHelpButton,
  useDetailHeader,
  useHasDetailHeader,
  type DetailHeaderHost,
  type DetailHeaderKind,
} from "../blocks/detail-header"
import type { DetailStripTitle } from "../blocks/detail-title"

afterEach(cleanup)

const apiSlot = (c: ParentNode) => c.querySelector<HTMLElement>("[data-adh-detail-api-slot]")!
const helpSlot = (c: ParentNode) => c.querySelector<HTMLElement>("[data-adh-detail-help-slot]")!
const disabledApi = () => screen.queryByRole("button", { name: /^API — / })
const disabledHelp = () => screen.queryByRole("button", { name: /^About this section — / })

function Portal({ id, kind = "api" }: { id: string; kind?: DetailHeaderKind }) {
  return (
    <DetailHeaderPortal kind={kind}>
      <button type="button">{`ctl-${id}`}</button>
    </DetailHeaderPortal>
  )
}

function wrap(children: ReactNode, props: { actions?: ReactNode; fallbackHelp?: ReactNode } = {}) {
  return (
    <DetailHeaderProvider {...props}>
      <DetailHeaderRow />
      {children}
    </DetailHeaderProvider>
  )
}

describe("DetailHeaderProvider actions box", () => {
  const link = <a href="/openapi.json">Download</a>

  it("dh-001 places the actions box inside the header, immediately before the API slot", () => {
    const { container } = render(wrap(null, { actions: link }))
    const header = container.querySelector('[data-slot="detail-header"]')!
    const box = screen.getByRole("link", { name: "Download" }).closest("[data-adh-detail-actions]")!
    expect(header.contains(box)).toBe(true)
    expect(box.nextElementSibling).toBe(apiSlot(container))
  })

  it("dh-002 draws no toolbar strip", () => {
    const { container } = render(wrap(null, { actions: link }))
    expect(container.querySelector("[data-adh-toolbar-slot]")).toBeNull()
    expect(container.querySelectorAll('[data-slot="detail-header"]')).toHaveLength(1)
  })

  it("dh-003 renders exactly one link", () => {
    render(wrap(null, { actions: link }))
    expect(screen.getAllByRole("link")).toHaveLength(1)
  })

  it("dh-014 omits the actions box for undefined, null and false", () => {
    const { container, rerender } = render(wrap(null, { actions: undefined }))
    expect(container.querySelector("[data-adh-detail-actions]")).toBeNull()
    rerender(wrap(null, { actions: null }))
    expect(container.querySelector("[data-adh-detail-actions]")).toBeNull()
    rerender(wrap(null, { actions: false }))
    expect(container.querySelector("[data-adh-detail-actions]")).toBeNull()
  })
})

describe("fallbacks", () => {
  it("dh-004 holds a disabled API button and a disabled help button when nothing claims", () => {
    const { container } = render(wrap(null))
    expect(apiSlot(container).contains(disabledApi())).toBe(true)
    expect(disabledApi()).toBeDisabled()
    expect(helpSlot(container).contains(disabledHelp())).toBe(true)
    expect(disabledHelp()).toBeDisabled()
  })

  it("dh-005 shows fallbackHelp instead of the disabled help button", () => {
    const { container } = render(wrap(null, { fallbackHelp: <button type="button">Stack help</button> }))
    expect(helpSlot(container)).toContainElement(screen.getByRole("button", { name: "Stack help" }))
    expect(disabledHelp()).toBeNull()
  })

  it("dh-013 shows both disabled buttons and no API slot outside any provider", () => {
    const { container } = render(<DetailHeaderRow />)
    expect(disabledApi()).toBeDisabled()
    expect(disabledHelp()).toBeDisabled()
    expect(container.querySelector("[data-adh-detail-api-slot]")).toBeNull()
  })
})

describe("claims", () => {
  it("dh-006 portals a claimed control into the slot and drops the disabled button", () => {
    const { container } = render(wrap(<Portal id="A" />))
    expect(apiSlot(container)).toContainElement(screen.getByRole("button", { name: "ctl-A" }))
    expect(disabledApi()).toBeNull()
  })

  it("dh-007 gives the slot to the last claimant and renders nothing for the other", () => {
    const { container, rerender } = render(wrap(<Portal key="A" id="A" />))
    rerender(wrap([<Portal key="A" id="A" />, <Portal key="B" id="B" />]))
    expect(screen.queryByRole("button", { name: "ctl-A" })).toBeNull()
    expect(apiSlot(container)).toContainElement(screen.getByRole("button", { name: "ctl-B" }))
    expect(apiSlot(container).querySelectorAll("button")).toHaveLength(1)
  })

  it("dh-008 returns the earlier claimant's control when the later one unmounts", () => {
    const { container, rerender } = render(wrap(<Portal key="A" id="A" />))
    rerender(wrap([<Portal key="A" id="A" />, <Portal key="B" id="B" />]))
    rerender(wrap([<Portal key="A" id="A" />]))
    expect(apiSlot(container)).toContainElement(screen.getByRole("button", { name: "ctl-A" }))
    expect(screen.queryByRole("button", { name: "ctl-B" })).toBeNull()
  })

  it("dh-009 keeps the later claimant's control when the earlier one unmounts", () => {
    const { container, rerender } = render(wrap(<Portal key="A" id="A" />))
    rerender(wrap([<Portal key="A" id="A" />, <Portal key="B" id="B" />]))
    rerender(wrap([<Portal key="B" id="B" />]))
    expect(apiSlot(container)).toContainElement(screen.getByRole("button", { name: "ctl-B" }))
    expect(screen.queryByRole("button", { name: "ctl-A" })).toBeNull()
  })

  it("dh-010 brings the disabled API button back when the only claimant unmounts", () => {
    const { rerender } = render(wrap(<Portal key="A" id="A" />))
    expect(disabledApi()).toBeNull()
    rerender(wrap(null))
    expect(disabledApi()).toBeDisabled()
  })

  it("dh-019 reaches the slot after the slot element mounts when the portal mounts with the provider", () => {
    const { container } = render(wrap(<Portal id="A" />))
    expect(apiSlot(container)).toContainElement(screen.getByRole("button", { name: "ctl-A" }))
  })

  it("dh-021 keeps the api and help kinds independent", () => {
    const { container } = render(wrap([<Portal key="a" id="A" kind="api" />, <Portal key="h" id="H" kind="help" />]))
    expect(apiSlot(container)).toContainElement(screen.getByRole("button", { name: "ctl-A" }))
    expect(helpSlot(container)).toContainElement(screen.getByRole("button", { name: "ctl-H" }))
    expect(apiSlot(container).querySelectorAll("button")).toHaveLength(1)
    expect(helpSlot(container).querySelectorAll("button")).toHaveLength(1)
  })

  it("dh-022 releases the api claim and takes the help claim when kind changes", () => {
    const { container, rerender } = render(wrap(<Portal id="A" kind="api" />))
    expect(disabledApi()).toBeNull()
    rerender(wrap(<Portal id="A" kind="help" />))
    expect(helpSlot(container)).toContainElement(screen.getByRole("button", { name: "ctl-A" }))
    expect(apiSlot(container)).not.toContainElement(screen.queryByRole("button", { name: "ctl-A" }))
    expect(disabledApi()).toBeDisabled()
    expect(disabledHelp()).toBeNull()
  })

  it("dh-020 leaves the claim list and render count unchanged on a repeated claim or an unheld release", () => {
    let host: DetailHeaderHost | null = null
    let renders = 0
    function Probe() {
      renders += 1
      host = useDetailHeader()
      return null
    }
    render(
      <DetailHeaderProvider>
        <Probe />
      </DetailHeaderProvider>,
    )
    act(() => host!.claim("x", "api", true))
    expect(host!.apiOwner).toBe("x")
    const after = renders
    act(() => host!.claim("x", "api", true))
    act(() => host!.claim("never-held", "api", false))
    expect(host!.apiOwner).toBe("x")
    expect(renders).toBe(after)
  })
})

describe("outside a provider", () => {
  it("dh-011 renders a portal inline and reports no header", () => {
    let hasHeader: boolean | null = null
    let header: DetailHeaderHost | null | undefined
    function Probe() {
      hasHeader = useHasDetailHeader()
      header = useDetailHeader()
      return null
    }
    render(
      <>
        <DetailHeaderPortal kind="api">
          <span>inline child</span>
        </DetailHeaderPortal>
        <Probe />
      </>,
    )
    expect(screen.getByText("inline child")).toBeInTheDocument()
    expect(hasHeader).toBe(false)
    expect(header).toBeNull()
  })

  it("dh-012 reports a header inside a provider", () => {
    let hasHeader: boolean | null = null
    let header: DetailHeaderHost | null | undefined
    function Probe() {
      hasHeader = useHasDetailHeader()
      header = useDetailHeader()
      return null
    }
    render(
      <DetailHeaderProvider>
        <Probe />
      </DetailHeaderProvider>,
    )
    expect(hasHeader).toBe(true)
    expect(header).not.toBeNull()
    expect(typeof header!.claim).toBe("function")
  })
})

describe("DetailHeaderRow layout", () => {
  const row = (c: ParentNode) => c.querySelector<HTMLElement>('[data-slot="detail-header"]')!

  it("dh-015 seats a leadCell lead in a 32px cell with right padding only, else inline with side padding", () => {
    const { container, rerender } = render(<DetailHeaderRow lead={<button type="button">lead</button>} leadCell />)
    const lead = screen.getByRole("button", { name: "lead" })
    expect(lead.parentElement!.className).toContain("w-8")
    expect(row(container).className).toContain("pr-2")
    expect(row(container).className).not.toContain("px-2")

    rerender(<DetailHeaderRow lead={<button type="button">lead</button>} />)
    expect(screen.getByRole("button", { name: "lead" }).parentElement).toBe(row(container))
    expect(row(container).className).toContain("px-2")

    rerender(<DetailHeaderRow />)
    expect(screen.queryByRole("button", { name: "lead" })).toBeNull()
    expect(row(container).className).toContain("px-2")
  })

  it("dh-016 renders the title cell when given, else an empty flexible spacer", () => {
    const title: DetailStripTitle = { titled: true, cell: <span data-testid="title-cell">T</span> }
    const { container, rerender } = render(<DetailHeaderRow title={title} />)
    expect(row(container)).toContainElement(screen.getByTestId("title-cell"))

    rerender(<DetailHeaderRow />)
    expect(screen.queryByTestId("title-cell")).toBeNull()
    const spacer = Array.from(row(container).children).find((el) => el.className === "min-w-0 flex-1")!
    expect(spacer).toBeDefined()
    expect(spacer.textContent).toBe("")
  })
})

describe("disabled buttons", () => {
  it("dh-017 names the disabled API button and its tooltip from the default or given reason", () => {
    const { container, rerender } = render(<DisabledApiButton />)
    expect(screen.getByRole("button", { name: "API — This view has no API endpoint" })).toBeDisabled()
    expect(container.querySelector("[title]")!.getAttribute("title")).toBe("This view has no API endpoint")

    rerender(<DisabledApiButton reason="Pick an endpoint" />)
    expect(screen.getByRole("button", { name: "API — Pick an endpoint" })).toBeDisabled()
    expect(container.querySelector("[title]")!.getAttribute("title")).toBe("Pick an endpoint")
  })

  it("dh-018 names the disabled help button, sets its tooltip and merges triggerClassName", () => {
    const { container } = render(<DisabledHelpButton triggerClassName="x" />)
    const button = screen.getByRole("button", { name: "About this section — No help for this view" })
    expect(button).toBeDisabled()
    expect(container.querySelector("[title]")!.getAttribute("title")).toBe("No help for this view")
    expect(button.className.split(/\s+/)).toContain("x")
  })
})

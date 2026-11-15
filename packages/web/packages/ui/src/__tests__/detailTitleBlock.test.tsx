/**
 * The detail title module's own vectors (detail-title-001 .. 020): the host's registration state,
 * suppression, the strip cell, the pane hook, and `useSelectedTopicLabel`. Driven directly through
 * `useDetailTitleHost` / `DetailTitleProvider` rather than a real stack; `detailTitle.test.tsx`
 * covers the module through HTDV and HMDV.
 */
/// <reference types="@testing-library/jest-dom/vitest" />
import { renderToString } from "react-dom/server"
import { afterEach, describe, expect, it, vi } from "vitest"
import { act, cleanup, render, renderHook, screen } from "@testing-library/react"
import { useEffect, type ReactNode, type ReactPortal } from "react"
import {
  DetailTitleProvider,
  DetailTitleSuppressed,
  detailStripTitle,
  useDetailTitle,
  useDetailTitleHost,
  useSelectedTopicLabel,
  type DetailTitleHost,
} from "../blocks/detail-title"

afterEach(cleanup)

interface PaneResult {
  hoisted: boolean
  portal: ReactPortal | null
}

/** A titled pane: records what the hook returned and draws the title inline unless hoisted. */
function Pane({ name, title, out }: { name: string; title: ReactNode; out?: Record<string, PaneResult> }) {
  const result = useDetailTitle(title)
  if (out) out[name] = result
  return (
    <>
      {result.portal}
      {!result.hoisted && title !== null && title !== undefined && title !== false && (
        <h3 data-pane={name}>{title}</h3>
      )}
      <p data-testid={`body-${name}`}>body</p>
    </>
  )
}

/** A stack stand-in: owns the host, publishes it, and draws the strip cell above its children. */
function Stack({
  fallback,
  onHost,
  children,
}: {
  fallback?: ReactNode
  onHost?: (h: DetailTitleHost, titled: boolean) => void
  children?: ReactNode
}) {
  const host = useDetailTitleHost()
  const strip = detailStripTitle(host, fallback)
  onHost?.(host, strip.titled)
  return (
    <DetailTitleProvider host={host}>
      <div data-testid="strip">{strip.cell}</div>
      {children}
    </DetailTitleProvider>
  )
}

describe("registration state", () => {
  it("detail-title-001 appends ids, publishes, and makes the last registered active", () => {
    let host!: DetailTitleHost
    render(<Stack onHost={(h) => (host = h)} />)
    expect(host.published).toBe(false)
    act(() => {
      host.registrar.register("a")
      host.registrar.register("b")
    })
    expect(host.published).toBe(true)
    expect(host.target.activeId).toBe("b")
  })

  it("detail-title-002 falls back to the previous id when the last unregisters", () => {
    let host!: DetailTitleHost
    render(<Stack onHost={(h) => (host = h)} />)
    act(() => {
      host.registrar.register("a")
      host.registrar.register("b")
    })
    act(() => host.registrar.unregister("b"))
    expect(host.target.activeId).toBe("a")
  })

  it("detail-title-003 ignores a duplicate register without a state change", () => {
    let host!: DetailTitleHost
    render(<Stack onHost={(h) => (host = h)} />)
    act(() => host.registrar.register("a"))
    const target = host.target
    act(() => host.registrar.register("a"))
    // the memoised target keeps its identity: the id list did not change
    expect(host.target).toBe(target)
    expect(host.target.activeId).toBe("a")
    // a single unregister empties it, so "a" was never held twice
    act(() => host.registrar.unregister("a"))
    expect(host.published).toBe(false)
  })

  it("detail-title-004 ignores an unregister of an unknown id", () => {
    let host!: DetailTitleHost
    render(<Stack onHost={(h) => (host = h)} />)
    act(() => host.registrar.unregister("x"))
    expect(host.published).toBe(false)
    expect(host.target.activeId).toBeUndefined()
  })
})

describe("suppression", () => {
  it("detail-title-005 withdraws the pane's title while when is true", () => {
    let host!: DetailTitleHost
    render(
      <Stack onHost={(h) => (host = h)}>
        <DetailTitleSuppressed when>
          <Pane name="p" title="Pane" />
        </DetailTitleSuppressed>
      </Stack>,
    )
    expect(host.published).toBe(false)
    expect(host.target.activeId).toBeUndefined()
  })

  it("detail-title-006 re-registers when suppression lifts, without remounting the children", () => {
    let host!: DetailTitleHost
    let mounts = 0
    function Child() {
      useEffect(() => {
        mounts += 1
      }, [])
      return <Pane name="p" title="Pane" />
    }
    const tree = (when: boolean) => (
      <Stack onHost={(h) => (host = h)}>
        <DetailTitleSuppressed when={when}>
          <Child />
        </DetailTitleSuppressed>
      </Stack>
    )
    const { rerender } = render(tree(true))
    const before = screen.getByTestId("body-p")
    expect(host.published).toBe(false)
    rerender(tree(false))
    expect(host.published).toBe(true)
    expect(screen.getByTestId("body-p")).toBe(before)
    expect(mounts).toBe(1)
  })
})

describe("strip cell", () => {
  it("detail-title-007 draws the fallback as a level-2 heading when nothing is published", () => {
    let titled: boolean | undefined
    render(<Stack fallback="Profile" onHost={(_h, t) => (titled = t)} />)
    expect(titled).toBe(true)
    const heading = screen.getByRole("heading", { level: 2, name: "Profile" })
    expect(heading).toHaveAttribute("role", "heading")
    expect(heading).toHaveAttribute("aria-level", "2")
  })

  it("detail-title-008 draws no heading role when the fallback is null", () => {
    let titled: boolean | undefined
    const { container } = render(<Stack fallback={null} onHost={(_h, t) => (titled = t)} />)
    expect(titled).toBe(false)
    const cell = container.querySelector("[data-htd-detail-title]")!
    expect(cell.hasAttribute("role")).toBe(false)
    expect(cell.hasAttribute("aria-level")).toBe(false)
  })

  it("detail-title-009 shows the published title and not the fallback", () => {
    const { container } = render(
      <Stack fallback="Profile">
        <Pane name="m" title="Milestones" />
      </Stack>,
    )
    const cell = container.querySelector("[data-htd-detail-title]")!
    expect(cell).toHaveTextContent("Milestones")
    expect(cell.textContent).not.toContain("Profile")
  })
})

describe("useDetailTitle", () => {
  it("detail-title-010 stays inline with no registrar", () => {
    const out: Record<string, PaneResult> = {}
    render(<Pane name="A" title="A" out={out} />)
    expect(out["A"]!.hoisted).toBe(false)
    expect(out["A"]!.portal).toBeNull()
    expect(screen.getByRole("heading", { name: "A" })).toBeInTheDocument()
  })

  it("detail-title-011 hoists only the last registrant; the other draws inline", () => {
    const out: Record<string, PaneResult> = {}
    const { container } = render(
      <Stack>
        <Pane name="A" title="A" out={out} />
        <Pane name="B" title="B" out={out} />
      </Stack>,
    )
    expect(out["B"]!.hoisted).toBe(true)
    expect(out["B"]!.portal).not.toBeNull()
    expect(out["A"]!.hoisted).toBe(false)
    expect(container.querySelector("[data-pane='A']")).toHaveTextContent("A")
    expect(container.querySelector("[data-pane='B']")).toBeNull()
    expect(container.querySelector("[data-htd-detail-title]")).toHaveTextContent("B")
  })

  it("detail-title-018 registers nothing for false, null and undefined titles", () => {
    let host!: DetailTitleHost
    const out: Record<string, PaneResult> = {}
    const tree = (title: ReactNode) => (
      <Stack onHost={(h) => (host = h)}>
        <Pane name="p" title={title} out={out} />
      </Stack>
    )
    const { rerender } = render(tree(false))
    expect(host.published).toBe(false)
    expect(out["p"]!.hoisted).toBe(false)
    rerender(tree(null))
    expect(host.published).toBe(false)
    expect(out["p"]!.hoisted).toBe(false)
    rerender(tree(undefined))
    expect(host.published).toBe(false)
    expect(out["p"]!.hoisted).toBe(false)
  })

  it("detail-title-019 does not re-register when the title node changes each render", () => {
    const register = vi.fn()
    const unregister = vi.fn()
    const host: DetailTitleHost = {
      registrar: { register, unregister },
      target: { slot: null, activeId: undefined },
      published: false,
      slotRef: () => {},
    }
    const tree = (title: ReactNode) => (
      <DetailTitleProvider host={host}>
        <Pane name="p" title={title} />
      </DetailTitleProvider>
    )
    const { rerender } = render(tree(<b>one</b>))
    rerender(tree(<b>two</b>))
    rerender(tree(<b>three</b>))
    expect(register).toHaveBeenCalledTimes(1)
    expect(unregister).not.toHaveBeenCalled()
  })

  it("detail-title-020 keeps the inline title in server HTML with no portal", () => {
    const out: Record<string, PaneResult> = {}
    const html = renderToString(
      <Stack>
        <Pane name="p" title="Server Title" out={out} />
      </Stack>,
    )
    expect(html).toContain("Server Title")
    expect(out["p"]!.portal).toBeNull()
    expect(out["p"]!.hoisted).toBe(false)
  })
})

describe("useSelectedTopicLabel", () => {
  type Level = { selectedId: string | null; items: { id: string; label: string }[] }
  const label = (levels: Level[]) => renderHook(() => useSelectedTopicLabel(levels)).result.current

  it("detail-title-012 returns undefined for an empty stack", () => {
    expect(label([])).toBeUndefined()
  })

  it("detail-title-013 returns undefined when the hole is the first level", () => {
    expect(
      label([
        { selectedId: null, items: [] },
        { selectedId: "b", items: [{ id: "b", label: "Beta" }] },
      ]),
    ).toBeUndefined()
  })

  it("detail-title-014 names the selected row of the level above the first unselected one", () => {
    expect(
      label([
        { selectedId: "a", items: [{ id: "a", label: "Alpha" }] },
        { selectedId: "b", items: [{ id: "b", label: "Beta" }] },
        { selectedId: null, items: [{ id: "c", label: "Gamma" }] },
      ]),
    ).toBe("Beta")
  })

  it("detail-title-015 holds the last seen label after the row drops out of items", () => {
    const { result, rerender } = renderHook(
      ({ levels }: { levels: Level[] }) => useSelectedTopicLabel(levels),
      { initialProps: { levels: [{ selectedId: "n1", items: [{ id: "n1", label: "Note" }] }] } },
    )
    expect(result.current).toBe("Note")
    rerender({ levels: [{ selectedId: "n1", items: [] }] })
    expect(result.current).toBe("Note")
  })

  it("detail-title-016 falls back to the selected id when it was never present", () => {
    expect(label([{ selectedId: "n1", items: [] }])).toBe("n1")
  })

  it("detail-title-017 keys the held label on depth as well as id", () => {
    const { result, rerender } = renderHook(
      ({ levels }: { levels: Level[] }) => useSelectedTopicLabel(levels),
      { initialProps: { levels: [{ selectedId: "x", items: [{ id: "x", label: "One" }] }] } },
    )
    expect(result.current).toBe("One")
    rerender({
      levels: [
        { selectedId: "p", items: [{ id: "p", label: "Parent" }] },
        { selectedId: "x", items: [] },
      ],
    })
    expect(result.current).toBe("x")
  })
})

/// <reference types="@testing-library/jest-dom/vitest" />
import { describe, expect, it, vi } from "vitest"
import { render, screen } from "@testing-library/react"

const menuSpy = vi.fn()
const topicSpy = vi.fn()

vi.mock("../blocks/hierarchical-menu-detail", () => ({
  HierarchicalMenuDetail: (props: Record<string, unknown>) => {
    menuSpy(props)
    return <div data-testid="menu" />
  },
}))
vi.mock("../blocks/hierarchical-topic-detail", () => ({
  HierarchicalTopicDetail: (props: Record<string, unknown>) => {
    topicSpy(props)
    return <div data-testid="topic" />
  },
}))

import {
  HierarchicalDetailView,
  HierarchicalDetailViewProvider,
  useHierarchicalMenuDetailView,
  type HierarchicalDetailViewProps,
} from "../blocks/hierarchical-detail-view"

// The mocked children ignore their props' shape, so the tests pass loose props.
const view = (extra: Record<string, unknown> = {}) => (
  <HierarchicalDetailView {...({ levels: [], ...extra } as unknown as HierarchicalDetailViewProps)} />
)

function Probe() {
  return <span data-testid="probe">{String(useHierarchicalMenuDetailView())}</span>
}

function reset() {
  menuSpy.mockClear()
  topicSpy.mockClear()
}

describe("HierarchicalDetailView", () => {
  it("hdv-001 provider menuDetail=true: hook returns true and the menu view renders", () => {
    reset()
    render(
      <HierarchicalDetailViewProvider menuDetail>
        <Probe />
        {view()}
      </HierarchicalDetailViewProvider>,
    )
    expect(screen.getByTestId("probe")).toHaveTextContent("true")
    expect(screen.getByTestId("menu")).toBeInTheDocument()
    expect(screen.queryByTestId("topic")).toBeNull()
  })

  it("hdv-002 no provider: hook returns false and the topic view renders", () => {
    reset()
    render(
      <>
        <Probe />
        {view()}
      </>,
    )
    expect(screen.getByTestId("probe")).toHaveTextContent("false")
    expect(screen.getByTestId("topic")).toBeInTheDocument()
  })

  it("hdv-003 context true routes to HierarchicalMenuDetail", () => {
    reset()
    render(<HierarchicalDetailViewProvider menuDetail>{view()}</HierarchicalDetailViewProvider>)
    expect(menuSpy).toHaveBeenCalled()
    expect(topicSpy).not.toHaveBeenCalled()
  })

  it("hdv-004 context false routes to HierarchicalTopicDetail", () => {
    reset()
    render(<HierarchicalDetailViewProvider menuDetail={false}>{view()}</HierarchicalDetailViewProvider>)
    expect(topicSpy).toHaveBeenCalled()
    expect(menuSpy).not.toHaveBeenCalled()
  })

  it("hdv-005 cascading becomes covered under the classic view", () => {
    reset()
    render(<HierarchicalDetailViewProvider menuDetail={false}>{view({ disclosureStyle: "cascading" })}</HierarchicalDetailViewProvider>)
    expect(topicSpy.mock.calls[0]![0].disclosureStyle).toBe("covered")
  })

  it("hdv-006 autoHideTopics passes through unchanged under the classic view", () => {
    reset()
    render(<HierarchicalDetailViewProvider menuDetail={false}>{view({ autoHideTopics: true })}</HierarchicalDetailViewProvider>)
    expect(topicSpy.mock.calls[0]![0].autoHideTopics).toBe(true)
  })

  it("hdv-007 levels and detail pass through unmodified in both views", () => {
    const levels = [{ id: "a" }]
    const detail = { title: "d" }
    for (const menuDetail of [true, false]) {
      reset()
      render(<HierarchicalDetailViewProvider menuDetail={menuDetail}>{view({ levels, detail })}</HierarchicalDetailViewProvider>)
      const props = (menuDetail ? menuSpy : topicSpy).mock.calls[0]![0]
      expect(props.levels).toBe(levels)
      expect(props.detail).toBe(detail)
    }
  })

  it("hdv-008 provider menuDetail=false: hook returns false", () => {
    render(
      <HierarchicalDetailViewProvider menuDetail={false}>
        <Probe />
      </HierarchicalDetailViewProvider>,
    )
    expect(screen.getByTestId("probe")).toHaveTextContent("false")
  })

  it("hdv-009 covered passes through unchanged under the classic view", () => {
    reset()
    render(<HierarchicalDetailViewProvider menuDetail={false}>{view({ disclosureStyle: "covered" })}</HierarchicalDetailViewProvider>)
    expect(topicSpy.mock.calls[0]![0].disclosureStyle).toBe("covered")
  })

  it("hdv-010 cascading passes through unchanged under the menu view", () => {
    reset()
    render(<HierarchicalDetailViewProvider menuDetail>{view({ disclosureStyle: "cascading" })}</HierarchicalDetailViewProvider>)
    expect(menuSpy.mock.calls[0]![0].disclosureStyle).toBe("cascading")
  })

  it("hdv-011 rejects unknown props at the type level", () => {
    const element = (
      // @ts-expect-error surfaceScope is not a prop of HierarchicalMenuDetail
      <HierarchicalDetailView levels={[]} surfaceScope="x" />
    )
    expect(element).toBeDefined()
  })
})

import * as React from "react"
import { describe, expect, it, vi } from "vitest"
import { render, screen, waitFor } from "@testing-library/react"
import userEvent from "@testing-library/user-event"

import { CategoryRenameDialog } from "../blocks/category-rename-dialog"
import type { CategoryTreeNode } from "../blocks/category-tree"

const WORK: CategoryTreeNode = { id: "work", name: "Work", parentIds: [] }
const PLANNING: CategoryTreeNode = { id: "plan", name: "Planning", parentIds: [] }
const NODES: CategoryTreeNode[] = [WORK, PLANNING]

describe("CategoryRenameDialog", () => {
  it("commits the trimmed new name", async () => {
    const user = userEvent.setup()
    const onRename = vi.fn().mockResolvedValue(undefined)
    render(
      <CategoryRenameDialog open node={WORK} nodes={NODES} noun="category"
        onRename={onRename} onClose={vi.fn()} />,
    )
    const field = screen.getByRole("textbox", { name: /New category name/i })
    await user.clear(field)
    await user.type(field, "  Employment  ")
    await user.click(screen.getByRole("button", { name: "Rename" }))
    expect(onRename).toHaveBeenCalledWith(WORK, "Employment")
  })

  it("refuses a name another category already has, without calling the host", async () => {
    const user = userEvent.setup()
    const onRename = vi.fn()
    render(
      <CategoryRenameDialog open node={WORK} nodes={NODES} noun="category"
        onRename={onRename} onClose={vi.fn()} />,
    )
    const field = screen.getByRole("textbox", { name: /New category name/i })
    await user.clear(field)
    await user.type(field, "planning")
    await user.click(screen.getByRole("button", { name: "Rename" }))
    expect(screen.getByText(/already a category called/i)).toBeInTheDocument()
    expect(onRename).not.toHaveBeenCalled()
  })

  it("closes without calling the host when the name is unchanged", async () => {
    const user = userEvent.setup()
    const onRename = vi.fn()
    const onClose = vi.fn()
    render(
      <CategoryRenameDialog open node={WORK} nodes={NODES} noun="category"
        onRename={onRename} onClose={onClose} />,
    )
    await user.click(screen.getByRole("button", { name: "Rename" }))
    expect(onRename).not.toHaveBeenCalled()
    expect(onClose).toHaveBeenCalled()
  })

  it("keeps the dialog open and shows the reason when the host rejects", async () => {
    const user = userEvent.setup()
    const onRename = vi.fn().mockRejectedValue(new Error("Name is taken on the server."))
    render(
      <CategoryRenameDialog open node={WORK} nodes={NODES} noun="category"
        onRename={onRename} onClose={vi.fn()} />,
    )
    const field = screen.getByRole("textbox", { name: /New category name/i })
    await user.clear(field)
    await user.type(field, "Employment")
    await user.click(screen.getByRole("button", { name: "Rename" }))
    expect(await screen.findByText("Name is taken on the server.")).toBeInTheDocument()
  })
})

describe("CategoryRenameDialog closing", () => {
  it("does not re-seed the field from the category it is only holding for the exit", () => {
    // The held value is for the way OUT. Seeding from it would reopen the dialog on the
    // last rename's text with no category behind it.
    const { rerender } = render(
      <CategoryRenameDialog open node={WORK} nodes={NODES} noun="category"
        onRename={vi.fn()} onClose={vi.fn()} />,
    )
    rerender(
      <CategoryRenameDialog open={false} node={null} nodes={NODES} noun="category"
        onRename={vi.fn()} onClose={vi.fn()} />,
    )
    rerender(
      <CategoryRenameDialog open node={PLANNING} nodes={NODES} noun="category"
        onRename={vi.fn()} onClose={vi.fn()} />,
    )
    expect(screen.getByRole("textbox", { name: /New category name/i })).toHaveValue("Planning")
  })

  it("renders nothing before it has ever had a category", () => {
    const { container } = render(
      <CategoryRenameDialog open={false} node={null} nodes={NODES} noun="category"
        onRename={vi.fn()} onClose={vi.fn()} />,
    )
    expect(container).toBeEmptyDOMElement()
  })
})

// Conformance vectors rename-001 .. rename-029. Several are also covered above in prose form;
// these carry the vector ids so each one has a test whose title names it.
describe("CategoryRenameDialog conformance vectors", () => {
  const INVENTORY: CategoryTreeNode = { id: "inv", name: "Inventory", parentIds: [] }
  const ARMORY: CategoryTreeNode = { id: "arm", name: "Armory", parentIds: [] }
  const ALL: CategoryTreeNode[] = [INVENTORY, ARMORY]

  type Over = Partial<React.ComponentProps<typeof CategoryRenameDialog>>
  function ui(over: Over = {}): React.ReactElement {
    return (
      <CategoryRenameDialog
        open
        node={INVENTORY}
        nodes={ALL}
        noun="category"
        onRename={vi.fn()}
        onClose={vi.fn()}
        {...over}
      />
    )
  }
  const field = (): HTMLInputElement =>
    screen.getByRole("textbox", { name: /New category name/i }) as HTMLInputElement
  const confirm = (): HTMLElement => screen.getByRole("button", { name: "Rename" })

  it("rename-001: open node shows the dialog", () => {
    render(ui())
    expect(screen.getByRole("dialog")).toBeInTheDocument()
  })

  it("rename-002: open=false with a never-set node renders nothing", () => {
    const { container } = render(ui({ open: false, node: null }))
    expect(container).toBeEmptyDOMElement()
    expect(screen.queryByRole("dialog")).toBeNull()
  })

  it("rename-003: the input is pre-filled with the node name", () => {
    render(ui())
    expect(field()).toHaveValue("Inventory")
  })

  it("rename-004: an empty name shows the needs-a-name error", async () => {
    const user = userEvent.setup()
    const onRename = vi.fn()
    render(ui({ onRename }))
    await user.clear(field())
    // Confirm is disabled while empty (rename-016), so submit through Enter.
    await user.type(field(), "{Enter}")
    expect(screen.getByText("A category needs a name.")).toBeInTheDocument()
    expect(onRename).not.toHaveBeenCalled()
  })

  it("rename-005: an unchanged name closes without calling onRename", async () => {
    const user = userEvent.setup()
    const onRename = vi.fn()
    const onClose = vi.fn()
    render(ui({ onRename, onClose }))
    await user.click(confirm())
    expect(onRename).not.toHaveBeenCalled()
    expect(onClose).toHaveBeenCalledTimes(1)
  })

  it("rename-006: a name another node has (case-insensitive) shows the duplicate error", async () => {
    const user = userEvent.setup()
    const onRename = vi.fn()
    render(ui({ onRename }))
    await user.clear(field())
    await user.type(field(), "Armory")
    await user.click(confirm())
    expect(screen.getByText("There is already a category called “Armory”.")).toBeInTheDocument()
    expect(onRename).not.toHaveBeenCalled()
  })

  it("rename-007: a name in extraNames shows the duplicate error", async () => {
    const user = userEvent.setup()
    const onRename = vi.fn()
    render(ui({ onRename, extraNames: ["Taken"] }))
    await user.clear(field())
    await user.type(field(), "Taken")
    await user.click(confirm())
    expect(screen.getByText("There is already a category called “Taken”.")).toBeInTheDocument()
    expect(onRename).not.toHaveBeenCalled()
  })

  it("rename-008: Enter in the input submits", async () => {
    const user = userEvent.setup()
    const onRename = vi.fn()
    render(ui({ onRename }))
    await user.clear(field())
    await user.type(field(), "NewName{Enter}")
    expect(onRename).toHaveBeenCalledWith(INVENTORY, "NewName")
  })

  it("rename-009: while onRename is pending the input is disabled and a status spinner replaces the buttons", async () => {
    const user = userEvent.setup()
    let resolve: () => void = () => {}
    const onRename = vi.fn(() => new Promise<void>((r) => { resolve = r }))
    render(ui({ onRename }))
    await user.clear(field())
    await user.type(field(), "Other")
    await user.click(confirm())
    await waitFor(() => expect(field()).toBeDisabled())
    expect(screen.getByRole("status")).toBeInTheDocument()
    expect(screen.queryByRole("button", { name: "Rename" })).toBeNull()
    expect(screen.queryByRole("button", { name: "Cancel" })).toBeNull()
    resolve()
    await waitFor(() => expect(screen.queryByRole("status")).toBeNull())
  })

  it("rename-010: typing clears a showing error", async () => {
    const user = userEvent.setup()
    render(ui())
    await user.clear(field())
    await user.type(field(), "Armory")
    await user.click(confirm())
    expect(screen.getByRole("alert")).toBeInTheDocument()
    await user.type(field(), "x")
    expect(screen.queryByRole("alert")).toBeNull()
  })

  it("rename-011: a valid name calls onRename(node, trimmed)", async () => {
    const user = userEvent.setup()
    const onRename = vi.fn()
    render(ui({ onRename }))
    await user.clear(field())
    await user.type(field(), "NewCategory")
    await user.click(confirm())
    expect(onRename).toHaveBeenCalledWith(INVENTORY, "NewCategory")
  })

  it("rename-012: a rejected onRename keeps the dialog open and shows the reason", async () => {
    const user = userEvent.setup()
    const onClose = vi.fn()
    render(ui({ onRename: vi.fn().mockRejectedValue(new Error("Server said no.")), onClose }))
    await user.clear(field())
    await user.type(field(), "Other")
    await user.click(confirm())
    expect(await screen.findByText("Server said no.")).toBeInTheDocument()
    expect(onClose).not.toHaveBeenCalled()
    expect(screen.getByRole("dialog")).toBeInTheDocument()
  })

  it("rename-013: a successful rename calls onRenamed(node, newName)", async () => {
    const user = userEvent.setup()
    const onRenamed = vi.fn()
    render(ui({ onRename: vi.fn().mockResolvedValue(undefined), onRenamed }))
    await user.clear(field())
    await user.type(field(), "Other")
    await user.click(confirm())
    await waitFor(() => expect(onRenamed).toHaveBeenCalledWith(INVENTORY, "Other"))
  })

  it("rename-014: a successful rename calls onClose", async () => {
    const user = userEvent.setup()
    const onClose = vi.fn()
    render(ui({ onRename: vi.fn().mockResolvedValue(undefined), onClose }))
    await user.clear(field())
    await user.type(field(), "Other")
    await user.click(confirm())
    await waitFor(() => expect(onClose).toHaveBeenCalledTimes(1))
  })

  it("rename-015: Escape while busy leaves the dialog open", async () => {
    const user = userEvent.setup()
    const onClose = vi.fn()
    let resolve: () => void = () => {}
    const onRename = vi.fn(() => new Promise<void>((r) => { resolve = r }))
    render(ui({ onRename, onClose }))
    await user.clear(field())
    await user.type(field(), "Other")
    await user.click(confirm())
    await waitFor(() => expect(screen.getByRole("status")).toBeInTheDocument())
    await user.keyboard("{Escape}")
    expect(onClose).not.toHaveBeenCalled()
    expect(screen.getByRole("dialog")).toBeInTheDocument()
    resolve()
    await waitFor(() => expect(onClose).toHaveBeenCalled())
  })

  it("rename-016: an empty input disables Confirm", async () => {
    const user = userEvent.setup()
    const { unmount } = render(ui({ node: { id: "e", name: "", parentIds: [] } }))
    expect(confirm()).toBeDisabled()
    unmount()
    render(ui())
    expect(confirm()).toBeEnabled()
    await user.clear(field())
    expect(confirm()).toBeDisabled()
  })

  it("rename-017: a validation failure is shown in the error text component", async () => {
    const user = userEvent.setup()
    render(ui())
    await user.clear(field())
    await user.type(field(), "Armory")
    await user.click(confirm())
    const alert = screen.getByRole("alert")
    expect(alert.tagName).toBe("P")
    expect(alert).toHaveTextContent("There is already a category called")
  })

  it("rename-018: a whitespace-only name is trimmed to empty and rejected", async () => {
    const user = userEvent.setup()
    const onRename = vi.fn()
    render(ui({ onRename }))
    await user.clear(field())
    await user.type(field(), "   {Enter}")
    expect(screen.getByText("A category needs a name.")).toBeInTheDocument()
    expect(onRename).not.toHaveBeenCalled()
  })

  it("rename-019: a non-Error rejection shows the fallback message", async () => {
    const user = userEvent.setup()
    const onClose = vi.fn()
    render(ui({ onRename: vi.fn().mockRejectedValue("boom"), onClose }))
    await user.clear(field())
    await user.type(field(), "Other")
    await user.click(confirm())
    expect(await screen.findByText("Could not rename the category.")).toBeInTheDocument()
    expect(onClose).not.toHaveBeenCalled()
    expect(screen.getByRole("dialog")).toBeInTheDocument()
  })

  it("rename-020: busy renders only the spinner, with no Cancel or Confirm", async () => {
    const user = userEvent.setup()
    const onRename = vi.fn(() => new Promise<void>(() => {}))
    render(ui({ onRename }))
    await user.clear(field())
    await user.type(field(), "Other")
    await user.click(confirm())
    await waitFor(() => expect(screen.getByRole("status")).toBeInTheDocument())
    const actions = document.querySelector('[data-slot="dialog-actions"]') as HTMLElement
    expect(actions.querySelectorAll("button")).toHaveLength(0)
    expect(screen.queryByRole("button", { name: "Cancel" })).toBeNull()
    expect(screen.queryByRole("button", { name: "Rename" })).toBeNull()
  })

  it("rename-021: a backdrop click never closes the dialog, idle or busy", async () => {
    const user = userEvent.setup()
    const onClose = vi.fn()
    const onRename = vi.fn(() => new Promise<void>(() => {}))
    render(ui({ onRename, onClose }))
    const backdrop = (): Element => document.querySelector(".backdrop-blur-sm")!
    await user.click(backdrop())
    expect(onClose).not.toHaveBeenCalled()
    expect(screen.getByRole("dialog")).toBeInTheDocument()
    await user.clear(field())
    await user.type(field(), "Other")
    await user.click(confirm())
    await waitFor(() => expect(screen.getByRole("status")).toBeInTheDocument())
    await user.click(backdrop())
    expect(onClose).not.toHaveBeenCalled()
    expect(screen.getByRole("dialog")).toBeInTheDocument()
  })

  it("rename-022: a case-only change is passed to onRename", async () => {
    const user = userEvent.setup()
    const onRename = vi.fn()
    const lower: CategoryTreeNode = { id: "inv", name: "inventory", parentIds: [] }
    render(ui({ node: lower, nodes: [lower, ARMORY], onRename }))
    await user.clear(field())
    await user.type(field(), "INVENTORY")
    await user.click(confirm())
    expect(onRename).toHaveBeenCalledWith(lower, "INVENTORY")
  })

  it("rename-023: reopening on a different node shows that node's name, not the old edit", async () => {
    const user = userEvent.setup()
    const { rerender } = render(ui())
    await user.clear(field())
    await user.type(field(), "half-typed")
    rerender(ui({ open: false, node: null }))
    rerender(ui({ open: true, node: ARMORY }))
    expect(field()).toHaveValue("Armory")
  })

  it("rename-024: Escape while idle calls onClose", async () => {
    const user = userEvent.setup()
    const onClose = vi.fn()
    render(ui({ onClose }))
    await user.keyboard("{Escape}")
    expect(onClose).toHaveBeenCalled()
  })

  it("rename-025: Cancel calls onClose and not onRename", async () => {
    const user = userEvent.setup()
    const onClose = vi.fn()
    const onRename = vi.fn()
    render(ui({ onClose, onRename }))
    await user.click(screen.getByRole("button", { name: "Cancel" }))
    expect(onClose).toHaveBeenCalledTimes(1)
    expect(onRename).not.toHaveBeenCalled()
  })

  it("rename-026: the input has focus when the dialog opens", async () => {
    render(ui())
    await waitFor(() => expect(field()).toHaveFocus())
  })

  it("rename-027: extraNames holding the original name does not block an unchanged submit", async () => {
    const user = userEvent.setup()
    const onRename = vi.fn()
    const onClose = vi.fn()
    render(ui({ onRename, onClose, extraNames: ["Inventory"] }))
    await user.click(confirm())
    expect(onRename).not.toHaveBeenCalled()
    expect(screen.queryByRole("alert")).toBeNull()
    expect(onClose).toHaveBeenCalledTimes(1)
  })

  it("rename-028: reopening after a closed-with-error session shows no error", async () => {
    const user = userEvent.setup()
    const { rerender } = render(ui())
    await user.clear(field())
    await user.type(field(), "Armory")
    await user.click(confirm())
    expect(screen.getByRole("alert")).toBeInTheDocument()
    rerender(ui({ open: false, node: null }))
    rerender(ui({ open: true, node: INVENTORY }))
    expect(screen.queryByRole("alert")).toBeNull()
  })

  it("rename-029: node reverting to null keeps the last node rendered", () => {
    const { rerender } = render(ui())
    expect(field()).toHaveValue("Inventory")
    rerender(ui({ node: null }))
    expect(screen.getByRole("dialog")).toBeInTheDocument()
    expect(field()).toHaveValue("Inventory")
  })
})

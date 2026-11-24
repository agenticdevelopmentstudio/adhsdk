import { describe, expect, it, vi } from "vitest";
import { render, screen, fireEvent, waitFor, within } from "@testing-library/react";
import "@testing-library/jest-dom/vitest";
import { PopupMenu } from "../blocks/popup-menu";

// The first describe block asserts on the trigger only; the conformance block at the bottom
// opens the menu with fireEvent.click, which Base UI's menu accepts in jsdom (see
// dropdownMenu.test.tsx).

const items = [
  { id: "acme", label: "Acme" },
  { id: "globex", label: "Globex" },
];

describe("PopupMenu trigger customisation", () => {
  it("renders the default chevron when no icon is given", () => {
    const { container } = render(
      <PopupMenu items={items} selectedId="acme" onSelect={vi.fn()} ariaLabel="Workspace" />,
    );
    expect(container.querySelector("svg")).not.toBeNull();
  });

  it("renders a supplied icon instead of the default", () => {
    const { container } = render(
      <PopupMenu
        items={items}
        selectedId="acme"
        onSelect={vi.fn()}
        ariaLabel="Workspace"
        icon={<span data-testid="caret">v</span>}
      />,
    );
    expect(screen.getByTestId("caret")).toBeInTheDocument();
    // "instead of the default" — the sibling test above already proves the default chevron
    // renders an <svg>, so this is the free falsifying check: if the icon were unioned in
    // alongside the default (`??` swapped for rendering both) rather than replacing it, this
    // would still find the chevron's svg and fail.
    expect(container.querySelector("svg")).toBeNull();
  });

  it("merges a trigger className over the block's own width", () => {
    render(
      <PopupMenu
        items={items}
        selectedId="acme"
        onSelect={vi.fn()}
        ariaLabel="Workspace"
        className="w-auto"
      />,
    );
    const trigger = screen.getByLabelText("Workspace");
    expect(trigger.className).toContain("w-auto");
    // tailwind-merge drops the conflicting w-full rather than leaving both.
    expect(trigger.className).not.toContain("w-full");
  });
});

describe("PopupMenu conformance vectors", () => {
  const ITEMS = [
    { id: "a", label: "Item A" },
    { id: "b", label: "Item B" },
  ];
  type Props = React.ComponentProps<typeof PopupMenu>;

  function mount(extra: Partial<Props> = {}) {
    return render(
      <PopupMenu items={ITEMS} selectedId={null} onSelect={vi.fn()} ariaLabel="Pick" {...extra} />,
    );
  }
  const trigger = (): HTMLElement => screen.getByRole("button", { name: "Pick" });
  async function openMenu(): Promise<HTMLElement> {
    fireEvent.click(trigger());
    return await screen.findByRole("menu");
  }
  const radios = (menu: HTMLElement): HTMLElement[] => within(menu).getAllByRole("menuitemradio");
  const closed = (): Promise<void> => waitFor(() => expect(screen.queryByRole("menu")).toBeNull());

  it("popup-001 accept-items: both items appear in the dropdown", async () => {
    mount();
    const menu = await openMenu();
    expect(within(menu).getByRole("menuitemradio", { name: "Item A" })).toBeInTheDocument();
    expect(within(menu).getByRole("menuitemradio", { name: "Item B" })).toBeInTheDocument();
  });

  it("popup-002 accept-selected-id, display-selected-label-on-trigger: trigger shows the selected item's label", () => {
    mount({ selectedId: "a" });
    expect(trigger()).toHaveTextContent("Item A");
  });

  it("popup-003 accept-selected-id, display-selected-label-on-trigger: null selection shows allLabel", () => {
    mount({ selectedId: null, allLabel: "All" });
    expect(trigger()).toHaveTextContent("All");
  });

  it("popup-004 call-select-callback: clicking an item calls onSelect with its id", async () => {
    const onSelect = vi.fn();
    mount({ items: [{ id: "x", label: "Item X" }], onSelect });
    const menu = await openMenu();
    fireEvent.click(within(menu).getByRole("menuitemradio", { name: "Item X" }));
    expect(onSelect).toHaveBeenCalledWith("x");
  });

  it("popup-005 call-select-callback: clicking the All row calls onSelect(null)", async () => {
    const onSelect = vi.fn();
    mount({ selectedId: "a", onSelect });
    const menu = await openMenu();
    fireEvent.click(within(menu).getByRole("menuitemradio", { name: "All" }));
    expect(onSelect).toHaveBeenCalledWith(null);
  });

  it("popup-006 render-all-row-when-enabled: the All row is the first item", async () => {
    mount({ allLabel: "All" });
    const menu = await openMenu();
    expect(radios(menu)[0]).toHaveTextContent("All");
  });

  it("popup-007 omit-all-row-when-disabled: allLabel=null renders no All row", async () => {
    mount({ allLabel: null, selectedId: "a" });
    const menu = await openMenu();
    expect(within(menu).queryByRole("menuitemradio", { name: "All" })).toBeNull();
    expect(radios(menu)).toHaveLength(2);
  });

  it("popup-008 display-selected-label-on-trigger: null selection with allLabel=null shows an empty string", () => {
    mount({ selectedId: null, allLabel: null });
    expect(trigger().textContent).toBe("");
  });

  it("popup-009 render-new-row-when-callback-present: New… is the last entry", async () => {
    mount({ onNew: vi.fn() });
    const menu = await openMenu();
    const entries = Array.from(menu.querySelectorAll('[role^="menuitem"]'));
    expect(entries[entries.length - 1]).toHaveTextContent("New…");
  });

  it("popup-010 omit-new-row-when-no-callback: no New… row and no divider", async () => {
    mount();
    const menu = await openMenu();
    expect(within(menu).queryByText("New…")).toBeNull();
    expect(within(menu).queryByRole("separator")).toBeNull();
  });

  it("popup-011 render-new-row-when-callback-present: clicking New… calls onNew", async () => {
    const onNew = vi.fn();
    mount({ onNew });
    const menu = await openMenu();
    fireEvent.click(within(menu).getByRole("menuitem", { name: "New…" }));
    expect(onNew).toHaveBeenCalledTimes(1);
  });

  it("popup-012 single-select-item-group: the selected item is checked, the others are not", async () => {
    mount({ selectedId: "a" });
    const menu = await openMenu();
    expect(within(menu).getByRole("menuitemradio", { name: "Item A" })).toHaveAttribute("aria-checked", "true");
    expect(within(menu).getByRole("menuitemradio", { name: "Item B" })).toHaveAttribute("aria-checked", "false");
    expect(within(menu).getByRole("menuitemradio", { name: "All" })).toHaveAttribute("aria-checked", "false");
  });

  it.skip("popup-013 truncate-long-trigger-labels: jsdom applies no Tailwind CSS, so overflow/text-overflow/white-space computed styles and real ellipsis rendering cannot be observed", () => {});

  it("popup-014 accept-aria-label: the trigger carries the ariaLabel", () => {
    mount({ ariaLabel: "Select focus" });
    expect(screen.getByRole("button", { name: "Select focus" })).toHaveAttribute("aria-label", "Select focus");
  });

  it("popup-015 default-affordance-icon: the default chevron renders on the trigger", () => {
    mount();
    const svg = trigger().querySelector("svg");
    expect(svg).not.toBeNull();
    expect(svg).toHaveAttribute("width", "13");
  });

  it("popup-016 accept-custom-icon: a supplied icon replaces the chevron", () => {
    mount({ icon: <span data-testid="caret">v</span> });
    expect(screen.getByTestId("caret")).toBeInTheDocument();
    expect(trigger().querySelector("svg")).toBeNull();
  });

  it("popup-017 accept-trigger-class-name, trigger-fills-width: className=w-auto replaces w-full", () => {
    mount({ className: "w-auto" });
    expect(trigger().className).toContain("w-auto");
    expect(trigger().className).not.toContain("w-full");
  });

  it("popup-018 hide-icon-from-accessibility: default chevron is aria-hidden; a custom icon gets no aria-hidden", () => {
    const { unmount } = mount();
    expect(trigger().querySelector("svg")).toHaveAttribute("aria-hidden", "true");
    unmount();
    mount({ icon: <span data-testid="caret">v</span> });
    expect(screen.getByTestId("caret")).not.toHaveAttribute("aria-hidden");
  });

  it("popup-019 warn-on-sentinel-collision: an item id of __all__ logs the collision warning", () => {
    const warn = vi.spyOn(console, "warn").mockImplementation(() => {});
    mount({ items: [{ id: "__all__", label: "Item" }] });
    expect(warn).toHaveBeenCalledWith('PopupMenu: item id "__all__" collides with the All sentinel');
    warn.mockRestore();
  });

  it("popup-020 single-select-item-group: changing selectedId moves the checked row (mutual exclusivity)", async () => {
    const { rerender } = mount({ selectedId: "a" });
    rerender(<PopupMenu items={ITEMS} selectedId="b" onSelect={vi.fn()} ariaLabel="Pick" />);
    const menu = await openMenu();
    expect(within(menu).getByRole("menuitemradio", { name: "Item B" })).toHaveAttribute("aria-checked", "true");
    expect(within(menu).getByRole("menuitemradio", { name: "Item A" })).toHaveAttribute("aria-checked", "false");
  });

  it("popup-021 render-new-row-when-callback-present: a separator sits between the last item and New…", async () => {
    mount({ onNew: vi.fn() });
    const menu = await openMenu();
    const sep = within(menu).getByRole("separator");
    const lastItem = radios(menu)[radios(menu).length - 1]!;
    const newRow = within(menu).getByRole("menuitem", { name: "New…" });
    expect(lastItem.compareDocumentPosition(sep) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
    expect(sep.compareDocumentPosition(newRow) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
  });

  it("popup-022 render-new-row-when-callback-present: newLabel replaces the default New… text", async () => {
    mount({ onNew: vi.fn(), newLabel: "Create item" });
    const menu = await openMenu();
    expect(within(menu).getByRole("menuitem", { name: "Create item" })).toBeInTheDocument();
    expect(within(menu).queryByText("New…")).toBeNull();
  });

  it.skip("popup-023 focus-indicator-contrast: :focus-visible styling and its contrast depend on real CSS, which jsdom does not apply", () => {});

  it("popup-024 display-selected-label-on-trigger: an unmatched selectedId shows allLabel and checks no row", async () => {
    mount({ selectedId: "zzz", allLabel: "All" });
    expect(trigger()).toHaveTextContent("All");
    const menu = await openMenu();
    for (const r of radios(menu)) expect(r).toHaveAttribute("aria-checked", "false");
  });

  it("popup-025 accept-items: duplicate ids log no PopupMenu warning and share one selection value", async () => {
    const warn = vi.spyOn(console, "warn").mockImplementation(() => {});
    const error = vi.spyOn(console, "error").mockImplementation(() => {});
    const onSelect = vi.fn();
    mount({ items: [{ id: "a", label: "First" }, { id: "a", label: "Second" }], onSelect });
    expect(warn).not.toHaveBeenCalled();
    const menu = await openMenu();
    expect(within(menu).getByRole("menuitemradio", { name: "First" })).toBeInTheDocument();
    expect(within(menu).getByRole("menuitemradio", { name: "Second" })).toBeInTheDocument();
    fireEvent.click(within(menu).getByRole("menuitemradio", { name: "Second" }));
    expect(onSelect).toHaveBeenCalledWith("a");
    warn.mockRestore();
    error.mockRestore();
  });

  it("popup-026 new-row-icon: the New… row shows an aria-hidden plus icon before its label", async () => {
    mount({ onNew: vi.fn() });
    const menu = await openMenu();
    const row = within(menu).getByRole("menuitem", { name: "New…" });
    const svg = row.querySelector("svg");
    expect(svg).not.toBeNull();
    expect(svg).toHaveAttribute("aria-hidden", "true");
    expect(row.firstChild).toBe(svg);
  });

  it("popup-027 menu-align-start: the open dropdown is positioned with align=start", async () => {
    mount();
    const menu = await openMenu();
    expect(menu.closest("[data-align]")).toHaveAttribute("data-align", "start");
  });

  it("popup-028 trigger-fills-width: the trigger applies w-full by default", () => {
    mount();
    expect(trigger().className).toContain("w-full");
  });

  it("popup-029 close-on-select: choosing an item, All or New… closes the dropdown", async () => {
    const onNew = vi.fn();
    mount({ selectedId: "a", onNew });
    let menu = await openMenu();
    fireEvent.click(within(menu).getByRole("menuitemradio", { name: "Item B" }));
    await closed();
    menu = await openMenu();
    fireEvent.click(within(menu).getByRole("menuitemradio", { name: "All" }));
    await closed();
    menu = await openMenu();
    fireEvent.click(within(menu).getByRole("menuitem", { name: "New…" }));
    await closed();
    expect(onNew).toHaveBeenCalledTimes(1);
  });
});

import { act, cleanup, fireEvent, render, screen } from "@testing-library/react";
import { useState } from "react";
import { afterEach, describe, expect, it } from "vitest";
import { HierarchicalDetailView, type TopicLevel } from "@adh-sdk/ui/blocks";

import {
  ADMIN_CATEGORIES,
  adminTopicsIn,
  useAdminCategorySelection,
  type AdminTopicId,
} from "../adminTopics";

afterEach(() => {
  cleanup();
});

// The console's rail in miniature, through the REAL stack, so a click takes the same
// row → railOnSelect → onSelect path a user's does. The URL names only the section; the category
// rail's selection is read off it by useAdminCategorySelection.
function Console({ topicId, go }: { topicId: AdminTopicId | null; go: (id: AdminTopicId | null) => void }) {
  const category = useAdminCategorySelection(topicId, async () => {
    go(null);
    return true;
  });
  const open = ADMIN_CATEGORIES.find((c) => c.id === category.selectedId) ?? null;
  const levels: TopicLevel[] = [
    {
      id: "admin",
      title: "Admin",
      items: ADMIN_CATEGORIES.map((c) => ({ id: c.id, label: c.label, leadsTo: "list" as const })),
      selectedId: category.selectedId,
      onSelect: category.onSelect,
      onClear: () => category.onSelect(null),
    },
  ];
  if (open) {
    levels.push({
      id: "admin-topics",
      title: open.label,
      items: adminTopicsIn(open.id).map((t) => ({ id: t.id, label: t.label })),
      selectedId: topicId,
      onSelect: (id) => go(id as AdminTopicId),
      onClear: () => go(null),
    });
  }
  return (
    <HierarchicalDetailView levels={levels} rootLabel="Admin">
      <div data-testid="detail">{topicId ?? "none"}</div>
    </HierarchicalDetailView>
  );
}

// The router. The admin site holds its shell in a layout, which keeps the one instance across
// routes.
function Router({ initial }: { initial: AdminTopicId | null }) {
  const [topicId, setTopicId] = useState(initial);
  return <Console topicId={topicId} go={setTopicId} />;
}

const row = (label: string) =>
  screen.getAllByRole("button").find((b) => b.textContent?.trim() === label)!;
const settle = () => act(() => new Promise((resolve) => setTimeout(resolve, 0)));

describe("the category rail", () => {
  it("selects another category clicked while a section is open, not just closes the section", async () => {
    render(<Router initial="llm-providers" />);
    fireEvent.click(row("Communication"));
    await settle();
    expect(screen.getByTestId("detail").textContent).toBe("none");
    // Communication's own sections are on screen, and AI Processing's are gone.
    expect(screen.queryByText("Messaging")).not.toBeNull();
    expect(screen.queryByText("AI Providers")).toBeNull();
  });

  it("keeps a section's category open once the section closes", async () => {
    render(<Router initial="llm-providers" />);
    // Re-clicking the open section closes it, the in-page way back up.
    fireEvent.click(row("AI Providers"));
    await settle();
    expect(screen.getByTestId("detail").textContent).toBe("none");
    expect(screen.queryByText("AI Providers")).not.toBeNull();
  });
});

describe("a category choice the unsaved-changes guard refused", () => {
  it("leaves the open section and its category where they were", async () => {
    // The guard answers false: Stay, or a Back press that replaced this choice's dialog.
    function Guarded({ topicId }: { topicId: AdminTopicId | null }) {
      const category = useAdminCategorySelection(topicId, async () => false);
      return (
        <button type="button" onClick={() => category.onSelect("communication")}>
          {category.selectedId ?? "none"}
        </button>
      );
    }
    render(<Guarded topicId="llm-providers" />);
    const open = screen.getByRole("button").textContent;
    fireEvent.click(screen.getByRole("button"));
    await settle();
    expect(screen.getByRole("button").textContent).toBe(open);
  });
});

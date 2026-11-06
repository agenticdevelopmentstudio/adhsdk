import { act, render } from "@testing-library/react";
import type { ReactNode } from "react";
import { beforeEach, describe, expect, it, vi } from "vitest";

type Selection = { selectedId: string | null; onSelect: (id: string | null) => void };
type LevelProps = {
  levelId: string;
  title: string;
  urlSelection: Selection;
  items: { id: string; label: string; render: () => ReactNode }[];
};

const h = vi.hoisted(() => ({
  pushSegment: vi.fn(),
  confirm: vi.fn<() => Promise<boolean>>(),
  // The latest props each rail level was rendered with, by levelId.
  levels: {} as Record<string, LevelProps>,
}));

vi.mock("@adh-sdk/resource", () => ({
  RailHostBoundary: ({ children }: { children: ReactNode }) => <>{children}</>,
  // Records each level, and renders the CATEGORY level's selected member — enough of the real
  // component to reach the section rail, which only exists once a category is selected. The
  // section level renders nothing: these tests are about the rail, not the panes behind it.
  StackGroupDetail: (props: LevelProps) => {
    h.levels[props.levelId] = props;
    if (props.levelId !== "admin-categories") return null;
    const active = props.items.find((i) => i.id === props.urlSelection.selectedId);
    return <>{active?.render()}</>;
  },
  useBasePathRoute: () => ({ pushSegment: h.pushSegment }),
}));
vi.mock("@adh-sdk/ui/lib/navigation-guard", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@adh-sdk/ui/lib/navigation-guard")>()),
  confirmNavigation: h.confirm,
}));

import { AdminFeature } from "../AdminFeature";

const settle = () => act(() => new Promise((resolve) => setTimeout(resolve, 0)));
const categories = () => h.levels["admin-categories"];
const sections = () => h.levels["admin-topics"];

beforeEach(() => {
  h.pushSegment.mockReset();
  h.confirm.mockReset();
  h.levels = {};
});

describe("AdminFeature's rail", () => {
  it("lists the categories alphabetically at the root, none selected", () => {
    render(<AdminFeature basePath="/admin" />);
    expect(categories().items.map((i) => i.label)).toEqual([
      "Access",
      "AI Processing",
      "Communication",
      "Configuration",
      "Usage & Costs",
    ]);
    expect(categories().urlSelection.selectedId).toBeNull();
    expect(sections()).toBeUndefined();
  });

  it("opens a section's own category when the URL names the section", () => {
    render(<AdminFeature basePath="/admin" topicId="reserved-identifiers" />);
    expect(categories().urlSelection.selectedId).toBe("configuration");
    expect(sections().title).toBe("Configuration");
    expect(sections().urlSelection.selectedId).toBe("reserved-identifiers");
    expect(sections().items.map((i) => i.label)).toEqual([
      "Authentication",
      "Feature Flags",
      "Reserved Identifiers",
      "Server Bags",
      "Sync Tables",
    ]);
  });

  it("choosing a category with no section open moves no URL", async () => {
    render(<AdminFeature basePath="/admin" />);
    act(() => categories().urlSelection.onSelect("communication"));
    await settle();
    expect(categories().urlSelection.selectedId).toBe("communication");
    expect(sections().items.map((i) => i.label)).toEqual(["Feedback", "Messaging"]);
    expect(h.confirm).not.toHaveBeenCalled();
    expect(h.pushSegment).not.toHaveBeenCalled();
  });
});

describe("AdminFeature's category switch with a section open", () => {
  it("closes the section through the unsaved-changes guard", async () => {
    h.confirm.mockResolvedValue(true);
    render(<AdminFeature basePath="/admin" topicId="users" />);
    act(() => categories().urlSelection.onSelect("ai-processing"));
    await settle();
    expect(h.confirm).toHaveBeenCalledTimes(1);
    expect(h.pushSegment).toHaveBeenCalledWith(null);
  });

  it("stays put when the guard says no", async () => {
    h.confirm.mockResolvedValue(false);
    render(<AdminFeature basePath="/admin" topicId="users" />);
    act(() => categories().urlSelection.onSelect("ai-processing"));
    await settle();
    expect(h.pushSegment).not.toHaveBeenCalled();
    expect(categories().urlSelection.selectedId).toBe("access");
  });

  it("keeps the category open once its section closes", () => {
    const { rerender } = render(<AdminFeature basePath="/admin" topicId="costs" />);
    rerender(<AdminFeature basePath="/admin" />);
    expect(categories().urlSelection.selectedId).toBe("usage-costs");
  });
});

describe("AdminFeature's section switch", () => {
  beforeEach(() => {
    render(<AdminFeature basePath="/admin" topicId="audit" />);
  });

  it("asks the unsaved-changes guard first, and stays put when it says no", async () => {
    h.confirm.mockResolvedValue(false);
    sections().urlSelection.onSelect("users");
    await settle();
    expect(h.confirm).toHaveBeenCalledTimes(1);
    expect(h.pushSegment).not.toHaveBeenCalled();
  });

  it("switches once the guard allows it", async () => {
    h.confirm.mockResolvedValue(true);
    sections().urlSelection.onSelect("users");
    await settle();
    expect(h.pushSegment).toHaveBeenCalledWith("users");
  });
});

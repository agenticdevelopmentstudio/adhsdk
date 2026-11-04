// @vitest-environment jsdom
//
// The Personal / Organization (hub-data) ecosystem in the Ecosystems feature, through a real render:
// pinned first in the list with its own icon, no Manage features picker, no Child Ecosystems row
// (the add-sub-ecosystem path), and its hub-data rows (Notes, Documents, …) drawn only for it.
//
// ResourceExplorer is replaced by a stand-in that prints what it was handed: each list row (in
// order, with the icon the feature chose), the topic rows, and the toolbar action.
import type { ReactNode } from "react";
import { describe, it, expect, vi, afterEach, beforeEach } from "vitest";
import { render, screen, cleanup } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import type { Ecosystem } from "@agentic-toolkit/data/ecosystems";

vi.mock("next/navigation", () => ({
  useRouter: () => ({ push: vi.fn(), replace: vi.fn(), prefetch: vi.fn() }),
}));

vi.mock("@agentic-toolkit/data/ecosystems", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@agentic-toolkit/data/ecosystems")>()),
  ecosystemsApi: {
    list: vi.fn(),
    listChildren: vi.fn(),
    get: vi.fn(),
    ecosystemIdForSlug: vi.fn(),
    listForWorkspace: vi.fn(),
    delete: vi.fn(),
    update: vi.fn(),
  },
  useWorkspaceDefaultEcosystemId: vi.fn(() => ({
    ecosystemId: undefined,
    canManage: true,
    isPending: false,
    isError: false,
    isLoadingError: false,
  })),
  useProvisionedFeatures: vi.fn(),
}));

vi.mock("@agentic-toolkit/resource", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@agentic-toolkit/resource")>()),
  ResourceExplorer: function StandInExplorer({
    activeId,
    items,
    getId,
    getLabel,
    getItemIcon,
    topics,
    topicsTitleActions,
  }: {
    activeId?: string;
    items: Ecosystem[] | null;
    getId: (e: Ecosystem) => string;
    getLabel: (e: Ecosystem) => string;
    getItemIcon?: (e: Ecosystem) => ReactNode;
    topics: { id: string; label: string }[];
    topicsTitleActions?: (id: string) => ReactNode;
  }) {
    return (
      <div>
        <ul aria-label="list">
          {(items ?? []).map((e) => (
            <li key={getId(e)} data-testid="row">
              <span data-testid="icon">{getItemIcon?.(e)}</span>
              {getLabel(e)}
            </li>
          ))}
        </ul>
        <ul aria-label="topics">
          {topics.map((t) => (
            <li key={t.id}>{t.label}</li>
          ))}
        </ul>
        <div>{activeId && topicsTitleActions?.(activeId)}</div>
      </div>
    );
  },
}));

import { EcosystemsFeature, type EcosystemsFeatureProps } from "./EcosystemsFeature";
import { ecosystemsApi, useProvisionedFeatures } from "@agentic-toolkit/data/ecosystems";

const eco = (slug: string, name: string, type?: Ecosystem["type"]): Ecosystem => ({
  id: `ecosystem.acme.${slug}`,
  identifier: `ecosystem.acme.${slug}`,
  slug,
  name,
  description: "",
  region: "",
  domain: "",
  createdAt: "2026-01-01T00:00:00.000Z",
  updatedAt: "2026-01-01T00:00:00.000Z",
  ...(type ? { type } : {}),
});

const WIDGETS = eco("widgets", "Widgets", "product");
const ZEBRA = eco("zebra", "Zebra", "container");
const PERSONAL = eco("personal", "Personal", "personal");
const ORGANIZATION = eco("organization", "Organization", "organization");

const held = (...keys: string[]) => ({
  data: keys.map((featureKey) => ({ featureKey, state: "active", provisionedAt: "", provisionedBy: null })),
  isPending: false,
  isError: false,
  isLoadingError: false,
});

// The rail as adh-products builds it (PRODUCT_TOPICS order), without importing that package, which
// depends on this one.
const HUB = ["personal", "organization"];
const topic = (id: string, label: string, feature: string, types?: string[]) => ({
  id,
  label,
  icon: null,
  features: [feature],
  ...(types ? { types } : {}),
});
const TOPICS = [
  topic("notebook", "Notes", "notes", HUB),
  topic("docs", "Documents", "documents", HUB),
  topic("research", "Research", "research", HUB),
  topic("projects", "Planning", "planning", HUB),
  topic("narratives", "Narratives", "narratives", HUB),
  topic("storage", "Storage", "storage"),
  topic("integrations", "Integrations", "integrations"),
  { id: "settings", label: "Settings", icon: null },
  { id: "child-ecosystems", label: "Child Ecosystems", icon: null },
];

beforeEach(() => {
  vi.mocked(ecosystemsApi.listChildren).mockResolvedValue([]);
  vi.mocked(useProvisionedFeatures).mockReturnValue(held() as never);
});

afterEach(() => {
  cleanup();
  vi.clearAllMocks();
});

function renderFeature(props: Partial<EcosystemsFeatureProps>) {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  return render(
    <QueryClientProvider client={qc}>
      <EcosystemsFeature basePath="/ecosystems" listFirst workspaceSlug="acme" topics={TOPICS} {...props} />
    </QueryClientProvider>,
  );
}

const topicLabels = () =>
  Array.from(screen.getByRole("list", { name: "topics" }).querySelectorAll("li")).map((li) => li.textContent);

describe("the Ecosystems list", () => {
  it("pins the Personal ecosystem first and gives it its own icon", async () => {
    vi.mocked(ecosystemsApi.listForWorkspace).mockResolvedValue([WIDGETS, ZEBRA, PERSONAL]);
    renderFeature({});
    const rows = await screen.findAllByTestId("row");
    expect(rows.map((r) => r.textContent)).toEqual(["Personal", "Widgets", "Zebra"]);
    const iconOf = (i: number) => rows[i]!.querySelector("svg")?.getAttribute("class") ?? "";
    expect(iconOf(0)).toContain("lucide-user");
    expect(iconOf(1)).toContain("lucide-network");
  });

  it("pins the Organization ecosystem first with a building icon", async () => {
    vi.mocked(ecosystemsApi.listForWorkspace).mockResolvedValue([WIDGETS, ORGANIZATION]);
    renderFeature({});
    const rows = await screen.findAllByTestId("row");
    expect(rows.map((r) => r.textContent)).toEqual(["Organization", "Widgets"]);
    expect(rows[0]!.querySelector("svg")?.getAttribute("class")).toContain("lucide-building");
  });

  it("leaves a list from an older backend, which sends no type, in its own order", async () => {
    vi.mocked(ecosystemsApi.listForWorkspace).mockResolvedValue([eco("a", "A"), eco("b", "B")]);
    renderFeature({});
    const rows = await screen.findAllByTestId("row");
    expect(rows.map((r) => r.textContent)).toEqual(["A", "B"]);
  });
});

describe("a hub-data ecosystem's topics", () => {
  beforeEach(() => {
    vi.mocked(ecosystemsApi.listForWorkspace).mockResolvedValue([PERSONAL, WIDGETS]);
    vi.mocked(useProvisionedFeatures).mockReturnValue(
      held("notes", "documents", "research", "planning", "narratives", "storage", "integrations") as never,
    );
  });

  it("draws Notes, Documents, Research, Planning, Narratives, Storage, Integrations, then Settings", async () => {
    renderFeature({ activeEcoId: PERSONAL.id });
    await screen.findAllByTestId("row");
    expect(topicLabels()).toEqual([
      "Notes", "Documents", "Research", "Planning", "Narratives", "Storage", "Integrations", "Settings",
    ]);
  });

  it("draws no Narratives row where the ecosystem does not hold it", async () => {
    vi.mocked(useProvisionedFeatures).mockReturnValue(
      held("notes", "documents", "research", "planning", "storage", "integrations") as never,
    );
    renderFeature({ activeEcoId: PERSONAL.id });
    await screen.findAllByTestId("row");
    expect(topicLabels()).not.toContain("Narratives");
  });

  it("offers no Manage features picker and no Child Ecosystems row", async () => {
    renderFeature({ activeEcoId: PERSONAL.id });
    await screen.findAllByTestId("row");
    expect(screen.queryByRole("button", { name: "Manage ecosystem features" })).toBeNull();
    expect(topicLabels()).not.toContain("Child Ecosystems");
  });
});

describe("a product or container holding hub-data features", () => {
  beforeEach(() => {
    vi.mocked(ecosystemsApi.listForWorkspace).mockResolvedValue([PERSONAL, WIDGETS, ZEBRA]);
    vi.mocked(useProvisionedFeatures).mockReturnValue(held("notes", "documents", "storage") as never);
  });

  it("draws no Notes or Documents row, still has its picker, and keeps Child Ecosystems", async () => {
    renderFeature({ activeEcoId: ZEBRA.id });
    await screen.findAllByTestId("row");
    expect(topicLabels()).toEqual(["Storage", "Child Ecosystems", "Settings"]);
    expect(screen.getByRole("button", { name: "Manage ecosystem features" })).toBeInTheDocument();
  });

  it("draws no hub-data row when the type is unknown (an older backend)", async () => {
    vi.mocked(ecosystemsApi.listForWorkspace).mockResolvedValue([eco("legacy", "Legacy")]);
    renderFeature({ activeEcoId: "ecosystem.acme.legacy" });
    await screen.findAllByTestId("row");
    expect(topicLabels()).toEqual(["Storage", "Child Ecosystems", "Settings"]);
  });
});

// @vitest-environment jsdom
// The Sets pane: an ecosystem's sets, each set's values generated from the catalog's setEntries,
// its containment, and the rule a refused change names. Mocks only the data boundary.
import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

vi.mock("@adh-sdk/data/sets", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@adh-sdk/data/sets")>()),
  setsApi: { list: vi.fn(), create: vi.fn(), edit: vi.fn(), remove: vi.fn(), setValues: vi.fn(), setMembers: vi.fn() },
}));

vi.mock("@adh-sdk/data/ecosystems", () => ({ ecosystemFeaturesApi: { catalog: vi.fn() } }));

import { ecosystemFeaturesApi, type CatalogFeature } from "@adh-sdk/data/ecosystems";
import { SetRefusedError, setsApi, type SetRow } from "@adh-sdk/data/sets";
import { DEFAULT_QUOTA_BYTES } from "@adh-sdk/data/product-admin";
import { SetsPane, setEntryFeaturesFor, valuesOfDraft } from "./SetsPane";

const api = vi.mocked(setsApi);
const catalogApi = vi.mocked(ecosystemFeaturesApi);

const set = (over: Partial<SetRow> & { id: string; name: string }): SetRow => ({
  slug: over.name.toLowerCase(),
  description: "",
  isDefault: false,
  isPersonal: false,
  personalCustomerId: null,
  contains: [],
  values: [],
  ...over,
});

const feature = (over: Partial<CatalogFeature> & { key: string; label: string }): CatalogFeature => ({
  description: "",
  subscriptionTier: "free",
  ...over,
});

const CATALOG = [
  feature({ key: "storage", label: "Storage", setEntries: { permission: true, limits: [{ key: "storage.bytes", type: "bytes", label: "Storage space" }] } }),
  feature({ key: "notes", label: "Notes" }),
  feature({ key: "usage", label: "Usage", setEntries: { limits: [{ key: "usage.tier", type: "tier", label: "Usage tier" }] } }),
];

const BASIC = set({ id: "s-basic", name: "Basic", isDefault: true });
const PRO = set({
  id: "s-pro",
  name: "Pro",
  contains: [],
  values: [
    { kind: "permission", key: "storage", value: true },
    { kind: "limit", key: "usage.tier", value: "pro" },
  ],
});

let n = 0;
const eco = () => `eco-${n}`;

beforeEach(() => {
  n += 1;
  vi.clearAllMocks();
  api.list.mockResolvedValue([BASIC, PRO]);
  api.create.mockResolvedValue(set({ id: "s-new", name: "Team" }));
  api.edit.mockResolvedValue(PRO);
  api.remove.mockResolvedValue(undefined);
  api.setValues.mockResolvedValue(PRO);
  api.setMembers.mockResolvedValue(PRO);
  catalogApi.catalog.mockResolvedValue(CATALOG);
});

afterEach(cleanup);

const openPro = async () => {
  render(<SetsPane ecosystemId={eco()} />);
  fireEvent.click(await screen.findByRole("button", { name: "Pro" }));
  await screen.findByRole("checkbox", { name: "Storage" });
};

describe("SetsPane", () => {
  it("says so when no product is selected, and reads nothing", () => {
    render(<SetsPane />);
    expect(screen.getByText("No product selected.")).toBeInTheDocument();
    expect(api.list).not.toHaveBeenCalled();
  });

  it("lists the sets, the default marked", async () => {
    render(<SetsPane ecosystemId={eco()} />);
    expect(await screen.findByRole("button", { name: "Basic" })).toBeInTheDocument();
    expect(api.list).toHaveBeenCalledWith(eco());
    expect(screen.getByText("Default")).toBeInTheDocument();
  });

  it("creates a set with its name and slug", async () => {
    render(<SetsPane ecosystemId={eco()} />);
    await screen.findByRole("button", { name: "Basic" });
    fireEvent.change(screen.getByLabelText("Name"), { target: { value: " Team " } });
    fireEvent.change(screen.getByLabelText("Slug"), { target: { value: "team" } });
    fireEvent.click(screen.getByRole("button", { name: "Create" }));
    await waitFor(() => expect(api.create).toHaveBeenCalledWith(eco(), { name: "Team", slug: "team" }));
    await waitFor(() => expect(api.list).toHaveBeenCalledTimes(2));
  });

  it("renders each feature's setEntries generically: a checkbox per permission, a typed field per limit", async () => {
    await openPro();
    expect(screen.getByRole("checkbox", { name: "Storage" })).toHaveAttribute("aria-checked", "true");
    expect(screen.queryByRole("checkbox", { name: "Notes" })).toBeNull();
    expect(screen.queryByRole("checkbox", { name: "Usage" })).toBeNull();
    expect(screen.getByLabelText("Storage space")).toHaveAttribute("type", "number");
    expect(screen.getByLabelText("Usage tier")).toHaveAttribute("type", "text");
    expect(screen.getByLabelText("Usage tier")).toHaveValue("pro");
    expect(screen.getByRole("checkbox", { name: "Basic" })).toHaveAttribute("aria-checked", "false");
  });

  it("saves the values it changed, and the containment on its own", async () => {
    await openPro();
    fireEvent.change(screen.getByLabelText("Storage space"), { target: { value: "1024" } });
    fireEvent.click(screen.getByRole("button", { name: "Save" }));
    await waitFor(() =>
      expect(api.setValues).toHaveBeenCalledWith(eco(), "s-pro", [
        { kind: "permission", key: "storage", value: true },
        { kind: "limit", key: "storage.bytes", value: 1024 },
        { kind: "limit", key: "usage.tier", value: "pro" },
      ]),
    );
    expect(api.setMembers).not.toHaveBeenCalled();

    api.setValues.mockClear();
    fireEvent.click(screen.getByRole("checkbox", { name: "Basic" }));
    fireEvent.click(screen.getByRole("button", { name: "Save" }));
    await waitFor(() => expect(api.setMembers).toHaveBeenCalledWith(eco(), "s-pro", ["s-basic"]));
  });

  it("refuses a count that is not a whole number, and sends nothing", async () => {
    await openPro();
    fireEvent.change(screen.getByLabelText("Storage space"), { target: { value: "1.5" } });
    fireEvent.click(screen.getByRole("button", { name: "Save" }));
    expect(await screen.findByText("Storage space must be a whole number.")).toBeInTheDocument();
    expect(api.setValues).not.toHaveBeenCalled();
  });

  it("shows a refusal with its rule, its limits and the sets it names", async () => {
    api.setMembers.mockRejectedValue(
      new SetRefusedError({ rule: 8, message: "the edit unsettles a container or puts a holder in conflict", limits: ["usage.tier"], containers: ["s-basic"] }),
    );
    await openPro();
    fireEvent.click(screen.getByRole("checkbox", { name: "Basic" }));
    fireEvent.click(screen.getByRole("button", { name: "Save" }));
    expect(
      await screen.findByText(
        "Refused under rule 8: the edit unsettles a container or puts a holder in conflict. Limits: usage.tier. Sets affected: Basic.",
      ),
    ).toBeInTheDocument();
  });

  it("makes a set the default, and deletes one", async () => {
    await openPro();
    fireEvent.click(screen.getByRole("button", { name: "Make default" }));
    await waitFor(() => expect(api.edit).toHaveBeenCalledWith(eco(), "s-pro", { isDefault: true }));
    fireEvent.click(screen.getByRole("button", { name: "Delete Basic" }));
    await waitFor(() => expect(api.remove).toHaveBeenCalledWith(eco(), "s-basic"));
  });
});

// The product admin site mounts the same pane (phase 6). The backend refuses a product admin the
// usage tier and a quota above the default; the pane hides the one and caps the other.
describe("SetsPane for a product admin", () => {
  const QUOTA_CATALOG = [
    ...CATALOG,
    feature({
      key: "quota",
      label: "Quota",
      setEntries: { limits: [{ key: "storage.quota_bytes", type: "bytes", label: "Storage quota" }] },
    }),
  ];
  const PLAIN = set({ id: "s-plain", name: "Plain", values: [{ kind: "permission", key: "storage", value: true }] });

  const openPlain = async () => {
    catalogApi.catalog.mockResolvedValue(QUOTA_CATALOG);
    api.list.mockResolvedValue([BASIC, PRO, PLAIN]);
    render(<SetsPane ecosystemId={eco()} caller="product_admin" />);
    fireEvent.click(await screen.findByRole("button", { name: "Plain" }));
    await screen.findByRole("checkbox", { name: "Storage" });
  };

  it("hides the usage tier and caps the quota field at the default", async () => {
    await openPlain();
    expect(screen.queryByLabelText("Usage tier")).toBeNull();
    expect(screen.getByLabelText("Storage quota")).toHaveAttribute("max", String(DEFAULT_QUOTA_BYTES));
    expect(screen.getByLabelText("Storage space")).not.toHaveAttribute("max");
  });

  it("refuses a quota above the default and sends nothing, and saves one at it", async () => {
    await openPlain();
    fireEvent.change(screen.getByLabelText("Storage quota"), { target: { value: String(DEFAULT_QUOTA_BYTES + 1) } });
    fireEvent.click(screen.getByRole("button", { name: "Save" }));
    expect(await screen.findByText(`Storage quota can be at most ${DEFAULT_QUOTA_BYTES}.`)).toBeInTheDocument();
    expect(api.setValues).not.toHaveBeenCalled();

    fireEvent.change(screen.getByLabelText("Storage quota"), { target: { value: String(DEFAULT_QUOTA_BYTES) } });
    fireEvent.click(screen.getByRole("button", { name: "Save" }));
    await waitFor(() =>
      expect(api.setValues).toHaveBeenCalledWith(eco(), "s-plain", [
        { kind: "permission", key: "storage", value: true },
        { kind: "limit", key: "storage.quota_bytes", value: DEFAULT_QUOTA_BYTES },
      ]),
    );
  });

  it("leaves a set with a tier to the managers, but still saves what it contains", async () => {
    render(<SetsPane ecosystemId={eco()} caller="product_admin" />);
    fireEvent.click(await screen.findByRole("button", { name: "Pro" }));
    await screen.findByRole("checkbox", { name: "Storage" });
    expect(screen.getAllByText(/only the product's managers can change/)).toHaveLength(1);
    fireEvent.click(screen.getByRole("checkbox", { name: "Storage" }));
    fireEvent.click(screen.getByRole("button", { name: "Save" }));
    expect(await screen.findAllByText(/only the product's managers can change/)).toHaveLength(2);
    expect(api.setValues).not.toHaveBeenCalled();

    fireEvent.click(screen.getByRole("checkbox", { name: "Storage" }));
    fireEvent.click(screen.getByRole("checkbox", { name: "Basic" }));
    fireEvent.click(screen.getByRole("button", { name: "Save" }));
    await waitFor(() => expect(api.setMembers).toHaveBeenCalledWith(eco(), "s-pro", ["s-basic"]));
  });

  it("leaves a manager's fields alone", () => {
    const features = [
      { key: "usage", label: "Usage", setEntries: { limits: [{ key: "usage.tier", type: "tier" as const, label: "Tier" }] } },
    ];
    expect(setEntryFeaturesFor(features, "manager")).toEqual(features);
    expect(setEntryFeaturesFor(features, "product_admin")[0]?.setEntries.limits).toEqual([]);
  });
});

describe("valuesOfDraft", () => {
  it("keeps a value the catalog no longer declares, and leaves an empty limit undefined", () => {
    const old = set({ id: "s", name: "S", values: [{ kind: "limit", key: "retired.count", value: 3 }] });
    const features = [
      { key: "usage", label: "Usage", setEntries: { limits: [{ key: "usage.tier", type: "tier" as const, label: "Tier" }] } },
    ];
    expect(valuesOfDraft(old, { permissions: new Set(), limits: { "usage.tier": " " } }, features)).toEqual({
      values: [{ kind: "limit", key: "retired.count", value: 3 }],
    });
  });
});

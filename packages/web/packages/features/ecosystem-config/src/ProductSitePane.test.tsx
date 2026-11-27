// @vitest-environment jsdom
// The hub's Product site pane, in the mockup's states: the console switch off and on, the handle
// rename and its confirm, and a taken handle (409); then the product's admins and the
// add-an-admin form carried over from the Admin site pane. Mocks only the data boundary.
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import type { ReactElement } from "react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

vi.mock("next/navigation", () => ({ useRouter: () => ({ push: vi.fn() }) }));

// The real data package, with revalidateResources watched so a test can see which lists a write
// asks to be read again.
vi.mock("@adh-sdk/data", async (importOriginal) => {
  const real = await importOriginal<typeof import("@adh-sdk/data")>();
  return { ...real, revalidateResources: vi.fn(real.revalidateResources) };
});

vi.mock("@adh-sdk/data/access", async (importOriginal) => ({
  accessTargetKey: (await importOriginal<typeof import("@adh-sdk/data/access")>()).accessTargetKey,
  accessApi: {
    listRoles: vi.fn(),
    listAssignments: vi.fn(),
    putAssignment: vi.fn(),
    deleteAssignment: vi.fn(),
    listSubjects: vi.fn(),
  },
}));

vi.mock("@adh-sdk/data/ecosystem-config", () => ({
  signupListApi: { list: vi.fn(), put: vi.fn(), remove: vi.fn() },
}));

// The hooks call the module's own `productSiteApi`, which a mock of the export cannot reach, so
// the mock rebuilds the two hooks the same way over a mocked api: the cache behaviour under test
// (an update's answer written straight into the cache) stays the real react-query's.
vi.mock("@adh-sdk/data/product-sites", async (importOriginal) => {
  const real = await importOriginal<typeof import("@adh-sdk/data/product-sites")>();
  const rq = await import("@tanstack/react-query");
  const productSiteApi = { get: vi.fn(), update: vi.fn() };
  return {
    ProductSiteError: real.ProductSiteError,
    PRODUCT_SITE_KEY: real.PRODUCT_SITE_KEY,
    productSiteApi,
    useProductSite: (eco: string) =>
      rq.useQuery({ queryKey: real.PRODUCT_SITE_KEY(eco), queryFn: () => productSiteApi.get(eco) }),
    useUpdateProductSite: (eco: string) => {
      const qc = rq.useQueryClient();
      return rq.useMutation({
        mutationFn: (body: { handle?: string; adminEnabled?: boolean }) => productSiteApi.update(eco, body),
        onSuccess: (site) => qc.setQueryData(real.PRODUCT_SITE_KEY(eco), site),
      });
    },
  };
});

// The Custom domain section has its own tests and its own data; here it is a marker, so the pane's
// tests see only where it sits.
vi.mock("./ProductDomainsSection", () => ({
  ProductDomainsSection: () => <div data-testid="product-domains-section" />,
}));

vi.mock("@adh-sdk/data/product-admin", () => ({
  useProductTotals: vi.fn(() => ({ data: undefined, error: null, isPending: true })),
}));

import { revalidateResources } from "@adh-sdk/data";
import { accessApi, type AccessRoleRow } from "@adh-sdk/data/access";
import { signupListApi } from "@adh-sdk/data/ecosystem-config";
import { ProductSiteError, productSiteApi, type ProductSite } from "@adh-sdk/data/product-sites";
import { ProductSitePane } from "./ProductSitePane";

const access = vi.mocked(accessApi);
const signup = vi.mocked(signupListApi);
const api = vi.mocked(productSiteApi);

const role = (over: Partial<AccessRoleRow> & { id: string; slug: string; name: string }) =>
  ({ description: "", isSystem: false, defaultFor: "", grants: [], ...over }) as AccessRoleRow;
const ADMIN = role({ id: "r-admin", slug: "admin", name: "Admin", isSystem: true });
const EDITOR = role({ id: "r-editor", slug: "editor", name: "Editor" });

const ORIGIN = "https://temporal.agenticdeveloperhub.com";

let n = 0;
const eco = () => `eco-${n}`;

const siteOf = (over: Partial<ProductSite> = {}): ProductSite => ({
  ecosystemId: eco(),
  handle: "temporal",
  primaryOrigin: ORIGIN,
  subdomainOrigin: ORIGIN,
  adminEnabled: false,
  adminClientId: null,
  consoleLive: false,
  contentGated: false,
  ...over,
});

beforeEach(() => {
  n += 1;
  vi.clearAllMocks();
  access.listRoles.mockResolvedValue([EDITOR, ADMIN]);
  access.listAssignments.mockResolvedValue({
    assignments: [
      { id: "a1", subjectKind: "customer", subjectId: "cust-ann", scopeFeature: "", scopeItemId: "", roleId: "r-admin" },
    ],
  });
  access.listSubjects.mockResolvedValue([
    { kind: "customer", id: "cust-ann", label: "Ann", email: "ann@x.test", slug: "ann" },
  ]);
  api.get.mockResolvedValue(siteOf());
  signup.list.mockResolvedValue([]);
  signup.put.mockResolvedValue({
    id: "e1",
    email: "cy@x.test",
    roleId: "r-admin",
    setId: null,
    createdAt: "2026-11-22T00:00:00.000Z",
    grantedAt: null,
    grantedCustomerId: null,
  });
});

afterEach(cleanup);

const renderPane = (ui: ReactElement) =>
  render(
    <QueryClientProvider client={new QueryClient({ defaultOptions: { queries: { retry: false } } })}>
      {ui}
    </QueryClientProvider>,
  );

const startRename = async (to: string) => {
  fireEvent.click(await screen.findByRole("button", { name: "Rename" }));
  fireEvent.change(screen.getByLabelText("Handle"), { target: { value: to } });
  fireEvent.click(screen.getByRole("button", { name: "Rename" }));
};

describe("ProductSitePane", () => {
  it("says so when no product is selected", () => {
    renderPane(<ProductSitePane />);
    expect(screen.getByText("No product selected.")).toBeInTheDocument();
    expect(api.get).not.toHaveBeenCalled();
  });

  it("names the product in its intro", async () => {
    renderPane(<ProductSitePane ecosystemId={eco()} productName="Temporal" help="The product's own address." />);
    expect(await screen.findByText(/^Temporal's own address, where its customers sign in/)).toBeInTheDocument();
    expect(screen.queryByText("The product's own address.")).toBeNull();
  });

  it("shows the host's blurb when it has no product name", async () => {
    renderPane(<ProductSitePane ecosystemId={eco()} help="The product's own address." />);
    expect(await screen.findByText("The product's own address.")).toBeInTheDocument();
  });

  // Mockup state 2.
  it("switch off: the address, its two links, the console marked not turned on, and the off sentence", async () => {
    renderPane(<ProductSitePane ecosystemId={eco()} productName="Temporal" />);
    expect(await screen.findByRole("link", { name: ORIGIN })).toHaveAttribute("href", ORIGIN);
    expect(screen.getByRole("link", { name: `${ORIGIN}/login` })).toHaveAttribute("href", `${ORIGIN}/login`);
    expect(screen.getByRole("link", { name: `${ORIGIN}/admin` })).toHaveAttribute("href", `${ORIGIN}/admin`);
    expect(screen.getByText("Not turned on")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Copy the sign-in and sign-up address" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Copy the admin console address" })).toBeInTheDocument();
    expect(screen.getByText(/says the admin console is not turned on for Temporal/)).toBeInTheDocument();
    expect(screen.getByRole("switch", { name: "Admin console at /admin" })).not.toBeChecked();
    expect(screen.getByText(".agenticdeveloperhub.com")).toBeInTheDocument();
  });

  // Mockup state 3.
  it("switch on and live: no not-turned-on mark, and the on sentence names the console's address", async () => {
    api.get.mockResolvedValue(siteOf({ adminEnabled: true, adminClientId: "client-1", consoleLive: true }));
    renderPane(<ProductSitePane ecosystemId={eco()} productName="Temporal" />);
    expect(await screen.findByText(/Temporal's admins run its users, roles, sign-up list and sets at/)).toBeInTheDocument();
    expect(screen.queryByText("Not turned on")).toBeNull();
    expect(screen.getByRole("switch", { name: "Admin console at /admin" })).toBeChecked();
  });

  it("switch on but not live yet: says the hub still runs the four rows", async () => {
    api.get.mockResolvedValue(siteOf({ adminEnabled: true, consoleLive: false }));
    renderPane(<ProductSitePane ecosystemId={eco()} productName="Temporal" />);
    expect(await screen.findByText(/On, and not answering yet at/)).toBeInTheDocument();
  });

  it("turning the console on sends adminEnabled and shows the answer", async () => {
    api.update.mockResolvedValue(siteOf({ adminEnabled: true, consoleLive: true }));
    renderPane(<ProductSitePane ecosystemId={eco()} productName="Temporal" />);
    fireEvent.click(await screen.findByRole("switch", { name: "Admin console at /admin" }));
    await waitFor(() => expect(api.update).toHaveBeenCalledWith(eco(), { adminEnabled: true }));
    expect(await screen.findByText(/Temporal's admins run its users/)).toBeInTheDocument();
  });

  it("a console refused for want of a base domain shows the backend's sentence", async () => {
    api.update.mockRejectedValue(
      new ProductSiteError(409, "Product sites are not configured on this server.", "product_sites_unconfigured"),
    );
    renderPane(<ProductSitePane ecosystemId={eco()} />);
    fireEvent.click(await screen.findByRole("switch", { name: "Admin console at /admin" }));
    expect(await screen.findByText("Product sites are not configured on this server.")).toBeInTheDocument();
  });

  it("with no base domain: says the address is not configured, and shows no links", async () => {
    api.get.mockResolvedValue(siteOf({ primaryOrigin: null, subdomainOrigin: null }));
    renderPane(<ProductSitePane ecosystemId={eco()} productName="Temporal" />);
    expect(await screen.findByText(/The product sites address is not configured on this server/)).toBeInTheDocument();
    expect(screen.queryByRole("link", { name: /\/login$/ })).toBeNull();
    expect(screen.queryByText("Not turned on")).toBeNull();
  });

  // Mockup state 4.
  it("rename: the warning names both addresses, and the confirm sends the handle", async () => {
    api.update.mockResolvedValue(
      siteOf({
        handle: "temporal-app",
        primaryOrigin: "https://temporal-app.agenticdeveloperhub.com",
        subdomainOrigin: "https://temporal-app.agenticdeveloperhub.com",
      }),
    );
    renderPane(<ProductSitePane ecosystemId={eco()} productName="Temporal" />);
    fireEvent.click(await screen.findByRole("button", { name: "Rename" }));
    fireEvent.change(screen.getByLabelText("Handle"), { target: { value: " Temporal-App " } });
    expect(screen.getByText("The old address stops working.")).toBeInTheDocument();
    expect(screen.getAllByText("https://temporal-app.agenticdeveloperhub.com").length).toBeGreaterThan(0);
    fireEvent.click(screen.getByRole("button", { name: "Rename" }));
    expect(await screen.findByText("Rename Temporal's address?")).toBeInTheDocument();
    expect(api.update).not.toHaveBeenCalled();
    // The dialog renders in a portal after the pane, so its Rename is the last one.
    fireEvent.click(screen.getAllByRole("button", { name: "Rename" }).at(-1)!);
    await waitFor(() => expect(api.update).toHaveBeenCalledWith(eco(), { handle: "temporal-app" }));
    expect(await screen.findByRole("link", { name: "https://temporal-app.agenticdeveloperhub.com" })).toBeInTheDocument();
    await waitFor(() => expect(screen.queryByText("The old address stops working.")).toBeNull());
  });

  it("renders the Custom domain section once the site has loaded", async () => {
    renderPane(<ProductSitePane ecosystemId={eco()} productName="Temporal" />);
    expect(await screen.findByTestId("product-domains-section")).toBeInTheDocument();
  });

  describe("with a custom domain primary", () => {
    const CUSTOM = "https://app.temporal.com";
    beforeEach(() => {
      api.get.mockResolvedValue(siteOf({ primaryOrigin: CUSTOM, subdomainOrigin: ORIGIN }));
    });

    it("the address links follow the custom domain, and the subdomain is named too", async () => {
      renderPane(<ProductSitePane ecosystemId={eco()} productName="Temporal" />);
      expect(await screen.findByRole("link", { name: CUSTOM })).toHaveAttribute("href", CUSTOM);
      expect(screen.getByRole("link", { name: `${CUSTOM}/login` })).toBeInTheDocument();
      expect(screen.getByText(/^Also at/)).toBeInTheDocument();
      expect(screen.getByText(ORIGIN)).toBeInTheDocument();
    });

    it("the handle keeps the subdomain's suffix", async () => {
      renderPane(<ProductSitePane ecosystemId={eco()} productName="Temporal" />);
      expect(await screen.findByText(".agenticdeveloperhub.com")).toBeInTheDocument();
    });

    it("the rename warning names the subdomain, and says the custom domain stays primary", async () => {
      renderPane(<ProductSitePane ecosystemId={eco()} productName="Temporal" />);
      fireEvent.click(await screen.findByRole("button", { name: "Rename" }));
      fireEvent.change(screen.getByLabelText("Handle"), { target: { value: "temporal-app" } });
      expect(screen.getByText("The old address stops working.")).toBeInTheDocument();
      // The subdomain twice: the Address group's "Also at" line and the warning's old address.
      expect(screen.getAllByText(ORIGIN)).toHaveLength(2);
      expect(screen.getByText("https://temporal-app.agenticdeveloperhub.com")).toBeInTheDocument();
      expect(screen.getByText("app.temporal.com")).toBeInTheDocument();
      expect(screen.getByText(/stays the primary address\./)).toBeInTheDocument();
    });
  });

  it("with the subdomain primary, the warning says nothing of a primary staying", async () => {
    renderPane(<ProductSitePane ecosystemId={eco()} productName="Temporal" />);
    fireEvent.click(await screen.findByRole("button", { name: "Rename" }));
    fireEvent.change(screen.getByLabelText("Handle"), { target: { value: "temporal-app" } });
    expect(screen.getByText("The old address stops working.")).toBeInTheDocument();
    expect(screen.queryByText(/stays the primary address/)).toBeNull();
    expect(screen.queryByText(/^Also at/)).toBeNull();
  });

  it("a cancelled rename confirm sends nothing", async () => {
    renderPane(<ProductSitePane ecosystemId={eco()} productName="Temporal" />);
    await startRename("temporal-app");
    await screen.findByText("Rename Temporal's address?");
    fireEvent.click(screen.getAllByRole("button", { name: "Cancel" }).at(-1)!);
    await waitFor(() => expect(screen.queryByText("Rename Temporal's address?")).toBeNull());
    expect(api.update).not.toHaveBeenCalled();
  });

  it("the unchanged handle cannot be renamed", async () => {
    renderPane(<ProductSitePane ecosystemId={eco()} />);
    fireEvent.click(await screen.findByRole("button", { name: "Rename" }));
    expect(screen.getByRole("button", { name: "Rename" })).toBeDisabled();
  });

  // Mockup state 5.
  it("a taken handle (409): the backend's sentence under the field, and the draft kept", async () => {
    const sentence = "notes.agenticdeveloperhub.com is already another product's address. Choose another handle.";
    api.update.mockRejectedValue(new ProductSiteError(409, sentence, "product_site_handle_taken"));
    renderPane(<ProductSitePane ecosystemId={eco()} productName="Temporal" />);
    await startRename("notes");
    await screen.findByText("Rename Temporal's address?");
    fireEvent.click(screen.getAllByRole("button", { name: "Rename" }).at(-1)!);
    expect(await screen.findByText(sentence)).toBeInTheDocument();
    expect(screen.getByLabelText("Handle")).toHaveValue("notes");
    expect(screen.getByLabelText("Handle")).toHaveAttribute("aria-invalid", "true");
  });

  it("shows the load error", async () => {
    api.get.mockRejectedValue(new ProductSiteError(404, "Not a product."));
    renderPane(<ProductSitePane ecosystemId={eco()} />);
    expect(await screen.findByText("Couldn't load the product site: Not a product.")).toBeInTheDocument();
  });

  it("lists the admin role's holders, read on the ecosystem target", async () => {
    renderPane(<ProductSitePane ecosystemId={eco()} />);
    expect(await screen.findByText("Ann")).toBeInTheDocument();
    expect(access.listRoles).toHaveBeenCalledWith({ ecosystem: eco() });
    expect(access.listAssignments).toHaveBeenCalledWith({ ecosystem: eco() });
  });

  it("says where a new admin signs in, naming the product's console", async () => {
    renderPane(<ProductSitePane ecosystemId={eco()} productName="Temporal" />);
    expect(
      await screen.findByText(
        "The person becomes an admin the first time they sign in to Temporal's admin console with this address.",
      ),
    ).toBeInTheDocument();
  });

  it("adds an admin as a sign-up list entry carrying the admin role", async () => {
    renderPane(<ProductSitePane ecosystemId={eco()} />);
    fireEvent.change(await screen.findByLabelText("Admin email"), { target: { value: " cy@x.test " } });
    fireEvent.click(screen.getByRole("button", { name: "Add an admin" }));
    await waitFor(() =>
      expect(signup.put).toHaveBeenCalledWith(eco(), { email: "cy@x.test", roleId: "r-admin", setId: null }),
    );
    expect(await screen.findByText("cy@x.test is on the sign-up list as an admin.")).toBeInTheDocument();
    // The Sign-up list pane's cached copy is read again, and no other list.
    const match = vi.mocked(revalidateResources).mock.calls.at(-1)?.[0];
    expect(match?.(`signup-list:${eco()}`)).toBe(true);
    expect(match?.(`signup-list:other`)).toBe(false);
  });

  it("keeps the set of an address already on the sign-up list, and changes only its role", async () => {
    signup.list.mockResolvedValue([
      {
        id: "e0",
        email: "alice@x.test",
        roleId: "r-editor",
        setId: "set-pro",
        createdAt: "2026-11-20T00:00:00.000Z",
        grantedAt: null,
        grantedCustomerId: null,
      },
    ]);
    renderPane(<ProductSitePane ecosystemId={eco()} />);
    fireEvent.change(await screen.findByLabelText("Admin email"), { target: { value: "Alice@X.test" } });
    fireEvent.click(screen.getByRole("button", { name: "Add an admin" }));
    await waitFor(() =>
      expect(signup.put).toHaveBeenCalledWith(eco(), { email: "Alice@X.test", roleId: "r-admin", setId: "set-pro" }),
    );
    expect(signup.list).toHaveBeenCalledWith(eco());
  });

  it("refuses an address that is not an email, and sends nothing", async () => {
    renderPane(<ProductSitePane ecosystemId={eco()} />);
    fireEvent.change(await screen.findByLabelText("Admin email"), { target: { value: "cy@" } });
    fireEvent.click(screen.getByRole("button", { name: "Add an admin" }));
    expect(await screen.findByText('"cy@" is not an email address.')).toBeInTheDocument();
    expect(signup.put).not.toHaveBeenCalled();
  });
});

// @vitest-environment jsdom
// The hub's Admin site pane: the host, the product's admins and the add-an-admin form, and the
// totals. Mocks only the data boundary.
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import type { ReactElement } from "react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

vi.mock("next/navigation", () => ({ useRouter: () => ({ push: vi.fn() }) }));

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

// The hooks call the module's own `adminSiteApi`, which a mock of the export cannot reach, so the
// mock rebuilds the three hooks the same way over a mocked api: the cache behaviour under test
// (a set-up answer written straight into the cache) stays the real react-query's.
vi.mock("@adh-sdk/data/product-admin", async () => {
  const rq = await import("@tanstack/react-query");
  const adminSiteApi = { get: vi.fn(), put: vi.fn(), remove: vi.fn() };
  const key = (eco: string) => ["product-admin", eco, "admin-site"];
  return {
    adminSiteApi,
    useAdminSite: (eco: string) => rq.useQuery({ queryKey: key(eco), queryFn: () => adminSiteApi.get(eco) }),
    usePutAdminSite: (eco: string) => {
      const qc = rq.useQueryClient();
      return rq.useMutation({
        mutationFn: (host: string) => adminSiteApi.put(eco, host),
        onSuccess: (state) => qc.setQueryData(key(eco), state),
      });
    },
    useRemoveAdminSite: (eco: string) => {
      const qc = rq.useQueryClient();
      return rq.useMutation({
        mutationFn: () => adminSiteApi.remove(eco),
        onSuccess: () => qc.setQueryData(key(eco), { site: null, enabled: true }),
      });
    },
    useProductTotals: vi.fn(() => ({ data: undefined, error: null, isPending: true })),
  };
});

import { accessApi, type AccessRoleRow } from "@adh-sdk/data/access";
import { signupListApi } from "@adh-sdk/data/ecosystem-config";
import { adminSiteApi, type AdminSite } from "@adh-sdk/data/product-admin";
import { AdminSitePane } from "./AdminSitePane";

const access = vi.mocked(accessApi);
const signup = vi.mocked(signupListApi);
const site = vi.mocked(adminSiteApi);

const role = (over: Partial<AccessRoleRow> & { id: string; slug: string; name: string }) =>
  ({ description: "", isSystem: false, defaultFor: "", grants: [], ...over }) as AccessRoleRow;
const ADMIN = role({ id: "r-admin", slug: "admin", name: "Admin", isSystem: true });
const EDITOR = role({ id: "r-editor", slug: "editor", name: "Editor" });

const SITE: AdminSite = {
  id: "site-1",
  host: "admin.example.com",
  applicationId: "app-1",
  clientId: "client-1",
  createdAt: null,
  updatedAt: null,
};

let n = 0;
const eco = () => `eco-${n}`;

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
  site.get.mockResolvedValue({ site: null, enabled: true });
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

describe("AdminSitePane", () => {
  it("says so when no product is selected", () => {
    renderPane(<AdminSitePane />);
    expect(screen.getByText("No product selected.")).toBeInTheDocument();
    expect(site.get).not.toHaveBeenCalled();
  });

  it("sets a site up at a host", async () => {
    site.put.mockResolvedValue({ site: SITE, enabled: true });
    renderPane(<AdminSitePane ecosystemId={eco()} productName="Notes" />);
    expect(await screen.findByText(/Notes has no admin site yet/)).toBeInTheDocument();
    fireEvent.change(screen.getByLabelText("Host"), { target: { value: " Admin.Example.com " } });
    fireEvent.click(screen.getByRole("button", { name: "Set up" }));
    await waitFor(() => expect(site.put).toHaveBeenCalledWith(eco(), "admin.example.com"));
    expect(await screen.findByRole("link", { name: "https://admin.example.com" })).toHaveAttribute(
      "href",
      "https://admin.example.com",
    );
    expect(screen.getByRole("button", { name: "Remove" })).toBeInTheDocument();
  });

  it("shows the backend's sentence when the host is refused", async () => {
    site.put.mockRejectedValue(new Error("Another product's admin site uses admin.example.com."));
    renderPane(<AdminSitePane ecosystemId={eco()} />);
    fireEvent.change(await screen.findByLabelText("Host"), { target: { value: "admin.example.com" } });
    fireEvent.click(screen.getByRole("button", { name: "Set up" }));
    expect(await screen.findByText("Another product's admin site uses admin.example.com.")).toBeInTheDocument();
  });

  it("removes a site", async () => {
    site.get.mockResolvedValue({ site: SITE, enabled: true });
    site.remove.mockResolvedValue(undefined);
    renderPane(<AdminSitePane ecosystemId={eco()} />);
    fireEvent.click(await screen.findByRole("button", { name: "Remove" }));
    await waitFor(() => expect(site.remove).toHaveBeenCalledWith(eco()));
  });

  it("lists the admin role's holders, read on the ecosystem target", async () => {
    renderPane(<AdminSitePane ecosystemId={eco()} />);
    expect(await screen.findByText("Ann")).toBeInTheDocument();
    expect(access.listRoles).toHaveBeenCalledWith({ ecosystem: eco() });
    expect(access.listAssignments).toHaveBeenCalledWith({ ecosystem: eco() });
  });

  it("adds an admin as a sign-up list entry carrying the admin role", async () => {
    renderPane(<AdminSitePane ecosystemId={eco()} />);
    fireEvent.change(await screen.findByLabelText("Admin email"), { target: { value: " cy@x.test " } });
    fireEvent.click(screen.getByRole("button", { name: "Add an admin" }));
    await waitFor(() =>
      expect(signup.put).toHaveBeenCalledWith(eco(), { email: "cy@x.test", roleId: "r-admin", setId: null }),
    );
    expect(await screen.findByText("cy@x.test is on the sign-up list as an admin.")).toBeInTheDocument();
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
    renderPane(<AdminSitePane ecosystemId={eco()} />);
    fireEvent.change(await screen.findByLabelText("Admin email"), { target: { value: "Alice@X.test" } });
    fireEvent.click(screen.getByRole("button", { name: "Add an admin" }));
    await waitFor(() =>
      expect(signup.put).toHaveBeenCalledWith(eco(), { email: "Alice@X.test", roleId: "r-admin", setId: "set-pro" }),
    );
    expect(signup.list).toHaveBeenCalledWith(eco());
  });

  it("refuses an address that is not an email, and sends nothing", async () => {
    renderPane(<AdminSitePane ecosystemId={eco()} />);
    fireEvent.change(await screen.findByLabelText("Admin email"), { target: { value: "cy@" } });
    fireEvent.click(screen.getByRole("button", { name: "Add an admin" }));
    expect(await screen.findByText('"cy@" is not an email address.')).toBeInTheDocument();
    expect(signup.put).not.toHaveBeenCalled();
  });
});

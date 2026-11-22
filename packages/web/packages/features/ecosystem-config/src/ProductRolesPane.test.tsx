// @vitest-environment jsdom
// The Product roles pane: the Teams roles editor on an ECOSYSTEM target, plus who holds each role.
// Mocks only the data boundary (@adh-sdk/data/access), as the Teams pane's own test does.
import { cleanup, fireEvent, render, screen, waitFor, within } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

vi.mock("next/navigation", () => ({ useRouter: () => ({ push: vi.fn() }) }));

vi.mock("@adh-sdk/data/access", async (importOriginal) => ({
  accessTargetKey: (await importOriginal<typeof import("@adh-sdk/data/access")>()).accessTargetKey,
  ACCESS_FEATURES: [{ key: "projects", label: "Projects" }],
  accessApi: {
    listFeatures: vi.fn(),
    listRoles: vi.fn(),
    createRole: vi.fn(),
    updateRole: vi.fn(),
    deleteRole: vi.fn(),
    listAssignments: vi.fn(),
    putAssignment: vi.fn(),
    deleteAssignment: vi.fn(),
    listSubjects: vi.fn(),
  },
}));

import { accessApi, type AccessRoleRow } from "@adh-sdk/data/access";
import { ProductRolesPane, RoleHolders } from "./ProductRolesPane";

const api = vi.mocked(accessApi);

const role = (over: Partial<AccessRoleRow> & { id: string; slug: string; name: string }) =>
  ({ description: "", isSystem: false, defaultFor: "", grants: [], ...over }) as AccessRoleRow;
const EDITOR = role({ id: "r-editor", slug: "editor", name: "Editor" });
const USER = role({ id: "r-user", slug: "user", name: "User", isSystem: true, defaultFor: "customer" });

const assignment = (id: string, subjectId: string, roleId: string, scopeFeature = "") => ({
  id,
  subjectKind: "customer" as const,
  subjectId,
  scopeFeature,
  scopeItemId: scopeFeature ? "item-1" : "",
  roleId,
});

let n = 0;
beforeEach(() => {
  // Each test its own ecosystem id, so the module-scope query cache never answers one test with
  // another's rows.
  n += 1;
  vi.clearAllMocks();
  api.listFeatures.mockResolvedValue([{ key: "notes", label: "Notes" }]);
  api.listRoles.mockResolvedValue([EDITOR, USER]);
  api.listAssignments.mockResolvedValue({
    assignments: [
      assignment("a1", "cust-ann", "r-editor"),
      assignment("a2", "cust-bob", "r-editor", "notes"),
      assignment("a3", "cust-cy", "r-user"),
    ],
  });
  api.listSubjects.mockResolvedValue([
    { kind: "customer", id: "cust-ann", label: "Ann", email: "ann@x.test", slug: "ann" },
    { kind: "customer", id: "cust-bob", label: "Bob", email: "bob@x.test", slug: "bob" },
    { kind: "customer", id: "cust-cy", label: "Cy", email: null, slug: "cy" },
  ]);
  api.putAssignment.mockResolvedValue(assignment("a9", "cust-bob", "r-editor"));
  api.deleteAssignment.mockResolvedValue(undefined);
});

afterEach(cleanup);

const eco = () => `eco-${n}`;

describe("ProductRolesPane", () => {
  it("lists the ecosystem's roles, read on the ecosystem target", async () => {
    render(<ProductRolesPane ecosystemId={eco()} />);
    await waitFor(() => expect(api.listRoles).toHaveBeenCalledWith({ ecosystem: eco() }));
    expect(api.listFeatures).toHaveBeenCalledWith({ ecosystem: eco() });
  });

  it("says so when no product is selected, and reads nothing", () => {
    render(<ProductRolesPane />);
    expect(screen.getByText("No product selected.")).toBeTruthy();
    expect(api.listRoles).not.toHaveBeenCalled();
  });
});

describe("RoleHolders", () => {
  it("lists the role's workspace-wide holders only", async () => {
    render(<RoleHolders ecosystemId={eco()} role={EDITOR} />);
    expect(await screen.findByText("Ann")).toBeTruthy();
    // Bob's grant is item-scoped and Cy holds another role: neither is a holder of this one.
    const list = screen.getByRole("list");
    expect(within(list).queryByText("Bob")).toBeNull();
    expect(within(list).queryByText("Cy")).toBeNull();
  });

  it("offers only realm product users who do not hold the role, from the ecosystem directory", async () => {
    render(<RoleHolders ecosystemId={eco()} role={EDITOR} />);
    await screen.findByText("Ann");
    await waitFor(() =>
      expect(api.listSubjects).toHaveBeenCalledWith({ ecosystem: eco() }, { q: undefined }),
    );
    const picker = screen.getByLabelText("Choose a product user") as HTMLSelectElement;
    await waitFor(() => expect(picker.options.length).toBe(3));
    const offered = [...picker.options].map((o) => o.textContent);
    expect(offered).toEqual(["Choose a product user…", "Bob", "Cy"]);
  });

  it("grants the role to a realm customer, workspace-wide, on the ecosystem target", async () => {
    render(<RoleHolders ecosystemId={eco()} role={EDITOR} />);
    await screen.findByText("Ann");
    const picker = screen.getByLabelText("Choose a product user") as HTMLSelectElement;
    await waitFor(() => expect(picker.options.length).toBe(3));
    fireEvent.change(picker, { target: { value: "cust-bob" } });
    fireEvent.click(screen.getByRole("button", { name: "Grant" }));
    await waitFor(() =>
      expect(api.putAssignment).toHaveBeenCalledWith(
        { ecosystem: eco() },
        { subjectKind: "customer", subjectId: "cust-bob", roleId: "r-editor" },
      ),
    );
  });

  it("revokes a holder's grant", async () => {
    render(<RoleHolders ecosystemId={eco()} role={EDITOR} />);
    fireEvent.click(await screen.findByRole("button", { name: "Revoke Ann" }));
    await waitFor(() => expect(api.deleteAssignment).toHaveBeenCalledWith({ ecosystem: eco() }, "a1"));
  });

  it("notes that every product user holds the default role", async () => {
    render(<RoleHolders ecosystemId={eco()} role={USER} />);
    expect(await screen.findByText(/Every product user holds this role/)).toBeTruthy();
  });
});

// The product admin site mounts the same pane with no hub around it (phase 6). The backend refuses
// a product admin any change to an `admin` seat, so those seats are shown and not revocable.
describe("ProductRolesPane for a product admin", () => {
  const ADMIN = role({ id: "r-admin", slug: "admin", name: "Admin", isSystem: true });

  it("reads the roles from the ecosystemId prop alone", async () => {
    render(<ProductRolesPane ecosystemId={eco()} caller="product_admin" />);
    await waitFor(() => expect(api.listRoles).toHaveBeenCalledWith({ ecosystem: eco() }));
  });

  it("shows the admin role's holders without a revoke, and still grants it", async () => {
    api.listAssignments.mockResolvedValue({ assignments: [assignment("a1", "cust-ann", "r-admin")] });
    render(<RoleHolders ecosystemId={eco()} role={ADMIN} caller="product_admin" />);
    expect(await screen.findByText("Ann")).toBeTruthy();
    expect(screen.queryByRole("button", { name: "Revoke Ann" })).toBeNull();
    expect(screen.getByText(/removed by the product's managers/)).toBeTruthy();
    expect(screen.getByRole("button", { name: "Grant" })).toBeTruthy();
  });

  it("keeps revoke on every other role", async () => {
    render(<RoleHolders ecosystemId={eco()} role={EDITOR} caller="product_admin" />);
    expect(await screen.findByRole("button", { name: "Revoke Ann" })).toBeTruthy();
  });

  it("keeps revoke on the admin role for a manager", async () => {
    api.listAssignments.mockResolvedValue({ assignments: [assignment("a1", "cust-ann", "r-admin")] });
    render(<RoleHolders ecosystemId={eco()} role={ADMIN} />);
    expect(await screen.findByRole("button", { name: "Revoke Ann" })).toBeTruthy();
  });
});

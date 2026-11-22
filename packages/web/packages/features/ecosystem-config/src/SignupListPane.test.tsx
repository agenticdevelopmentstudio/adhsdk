// @vitest-environment jsdom
// The Sign-up list pane: the emails that may sign in, each with the product role it grants.
// Mocks only the data boundary.
import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

vi.mock("@adh-sdk/data/access", async (importOriginal) => ({
  accessTargetKey: (await importOriginal<typeof import("@adh-sdk/data/access")>()).accessTargetKey,
  accessApi: { listRoles: vi.fn() },
}));

vi.mock("@adh-sdk/data/ecosystem-config", () => ({
  signupListApi: { list: vi.fn(), put: vi.fn(), remove: vi.fn() },
}));

vi.mock("@adh-sdk/data/sets", () => ({ setsApi: { list: vi.fn() } }));

import { accessApi, type AccessRoleRow } from "@adh-sdk/data/access";
import { signupListApi, type SignupListEntry } from "@adh-sdk/data/ecosystem-config";
import { setsApi, type SetRow } from "@adh-sdk/data/sets";
import { SignupListPane } from "./SignupListPane";

const roles = vi.mocked(accessApi);
const api = vi.mocked(signupListApi);
const setsMock = vi.mocked(setsApi);

const PRO = {
  id: "s-pro",
  slug: "pro",
  name: "Pro",
  description: "",
  isDefault: false,
  isPersonal: false,
  personalCustomerId: null,
  contains: [],
  values: [],
} as SetRow;

const EDITOR = {
  id: "r-editor",
  slug: "editor",
  name: "Editor",
  description: "",
  isSystem: false,
  defaultFor: "",
  grants: [],
} as AccessRoleRow;

const entry = (over: Partial<SignupListEntry> & { id: string; email: string }): SignupListEntry => ({
  roleId: null,
  setId: null,
  createdAt: "2026-11-22T00:00:00.000Z",
  grantedAt: null,
  grantedCustomerId: null,
  ...over,
});

let n = 0;
const eco = () => `eco-${n}`;

beforeEach(() => {
  n += 1;
  vi.clearAllMocks();
  roles.listRoles.mockResolvedValue([EDITOR]);
  setsMock.list.mockResolvedValue([PRO]);
  api.list.mockResolvedValue([
    entry({ id: "e1", email: "ann@x.test", roleId: "r-editor", grantedAt: "2026-11-20T00:00:00.000Z" }),
    entry({ id: "e2", email: "bob@x.test", setId: "s-pro" }),
  ]);
  api.put.mockResolvedValue(entry({ id: "e3", email: "cy@x.test" }));
  api.remove.mockResolvedValue(undefined);
});

afterEach(cleanup);

describe("SignupListPane", () => {
  it("says so when no product is selected, and reads nothing", () => {
    render(<SignupListPane />);
    expect(screen.getByText("No product selected.")).toBeInTheDocument();
    expect(api.list).not.toHaveBeenCalled();
  });

  it("lists each entry with its role and whether it was granted", async () => {
    render(<SignupListPane ecosystemId={eco()} />);
    expect(await screen.findByText("ann@x.test")).toBeInTheDocument();
    expect(api.list).toHaveBeenCalledWith(eco());
    expect(roles.listRoles).toHaveBeenCalledWith({ ecosystem: eco() });
    expect(await screen.findAllByText("Editor")).not.toHaveLength(0);
    expect(screen.getByText("No role", { selector: "span" })).toBeInTheDocument();
    expect(setsMock.list).toHaveBeenCalledWith(eco());
    expect(await screen.findByText("Pro", { selector: "span" })).toBeInTheDocument();
    expect(screen.getByText("No set", { selector: "span" })).toBeInTheDocument();
    expect(screen.getByText(/^Granted/)).toBeInTheDocument();
    expect(screen.getByText("Waiting")).toBeInTheDocument();
  });

  it("says the list is empty", async () => {
    api.list.mockResolvedValue([]);
    render(<SignupListPane ecosystemId={eco()} />);
    expect(await screen.findByText("No one is on the sign-up list.")).toBeInTheDocument();
  });

  it("adds an email with the chosen role and set, then reloads", async () => {
    render(<SignupListPane ecosystemId={eco()} />);
    await screen.findByText("ann@x.test");
    await screen.findByRole("option", { name: "Editor" });
    await screen.findByRole("option", { name: "Pro" });
    fireEvent.change(screen.getByLabelText("Email"), { target: { value: " cy@x.test " } });
    fireEvent.change(screen.getByLabelText("Role"), { target: { value: "r-editor" } });
    fireEvent.change(screen.getByLabelText("Set"), { target: { value: "s-pro" } });
    fireEvent.click(screen.getByRole("button", { name: "Add" }));
    await waitFor(() =>
      expect(api.put).toHaveBeenCalledWith(eco(), {
        email: "cy@x.test",
        roleId: "r-editor",
        setId: "s-pro",
      }),
    );
    await waitFor(() => expect(api.list).toHaveBeenCalledTimes(2));
    expect(screen.getByLabelText("Email")).toHaveValue("");
  });

  it("adds without a role or a set as null", async () => {
    render(<SignupListPane ecosystemId={eco()} />);
    await screen.findByText("ann@x.test");
    fireEvent.change(screen.getByLabelText("Email"), { target: { value: "cy@x.test" } });
    fireEvent.click(screen.getByRole("button", { name: "Add" }));
    await waitFor(() =>
      expect(api.put).toHaveBeenCalledWith(eco(), { email: "cy@x.test", roleId: null, setId: null }),
    );
  });

  it("refuses an address that is not an email, and sends nothing", async () => {
    render(<SignupListPane ecosystemId={eco()} />);
    await screen.findByText("ann@x.test");
    fireEvent.change(screen.getByLabelText("Email"), { target: { value: "alice@" } });
    fireEvent.click(screen.getByRole("button", { name: "Add" }));
    expect(await screen.findByText('"alice@" is not an email address.')).toBeInTheDocument();
    expect(api.put).not.toHaveBeenCalled();
  });

  it("shows the server's refusal", async () => {
    api.put.mockRejectedValue(new Error("The sign-up list is full."));
    render(<SignupListPane ecosystemId={eco()} />);
    await screen.findByText("ann@x.test");
    fireEvent.change(screen.getByLabelText("Email"), { target: { value: "cy@x.test" } });
    fireEvent.click(screen.getByRole("button", { name: "Add" }));
    expect(await screen.findByText("The sign-up list is full.")).toBeInTheDocument();
  });

  it("removes an entry, then reloads", async () => {
    render(<SignupListPane ecosystemId={eco()} />);
    fireEvent.click(await screen.findByRole("button", { name: "Remove bob@x.test" }));
    await waitFor(() => expect(api.remove).toHaveBeenCalledWith(eco(), "e2"));
    await waitFor(() => expect(api.list).toHaveBeenCalledTimes(2));
  });

  // The product admin site (phase 6) mounts it with only the uuid and the caller: no hub context.
  it("runs for a product admin from the ecosystemId prop alone", async () => {
    render(<SignupListPane ecosystemId={eco()} caller="product_admin" />);
    expect(await screen.findByText("ann@x.test")).toBeInTheDocument();
    expect(api.list).toHaveBeenCalledWith(eco());
    expect(roles.listRoles).toHaveBeenCalledWith({ ecosystem: eco() });
  });
});

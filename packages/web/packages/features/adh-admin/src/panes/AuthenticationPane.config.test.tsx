// @vitest-environment jsdom
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";

const { state, createProvider, updateProvider } = vi.hoisted(() => ({
  state: { clients: [] as unknown[], providers: [] as unknown[], templates: {} as Record<string, unknown> },
  createProvider: vi.fn(async () => ({})),
  updateProvider: vi.fn(async () => ({})),
}));

vi.mock("next/navigation", () => ({ useRouter: () => ({ push: vi.fn() }) }));
vi.mock("../api/http", () => ({ authedJson: vi.fn(async () => ({ providers: [] })) }));
vi.mock("../api/auth-config", () => {
  const mutation = () => ({ mutateAsync: vi.fn(async () => ({})), isPending: false });
  const loaded = (data: unknown) => ({ data, isLoading: false, error: null });
  return {
    useProviders: () => loaded(state.providers),
    useClients: () => loaded(state.clients),
    useProviderTemplates: () => loaded({ templates: state.templates }),
    useAuthMethods: () => loaded([]),
    useCreateClient: mutation,
    useUpdateClient: mutation,
    useDeleteClient: mutation,
    useCreateProvider: () => ({ mutateAsync: createProvider, isPending: false }),
    useUpdateProvider: () => ({ mutateAsync: updateProvider, isPending: false }),
    useDeleteProvider: mutation,
    useLinkProvider: mutation,
    useUnlinkProvider: mutation,
    useUpdateAuthMethod: mutation,
  };
});

import { AuthenticationPane } from "./AuthenticationPane";

const CORE = { subjectField: "sub", emailField: "email", nameField: "name", avatarField: "picture" };
const JWT_MAPPING = {
  ...CORE,
  responseMode: "form_post",
  clientSecretJwt: { teamId: "", keyId: "", audience: "https://appleid.apple.com" },
};
const appleTemplate = { slug: "apple", name: "Apple", authType: "oauth2_code", identityMapping: JWT_MAPPING };
const githubTemplate = { slug: "github", name: "GitHub", authType: "oauth2_code", identityMapping: CORE };

function client(slug: string, originsManaged: boolean, origins: string[]) {
  return { id: slug, slug, name: slug, allowedReturnOrigins: origins, originsManaged, isInternal: false };
}

function renderPane() {
  const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  return render(
    <QueryClientProvider client={queryClient}>
      <AuthenticationPane />
    </QueryClientProvider>,
  );
}

/** The input a Field wraps, found from its visible label. */
function fieldInput(label: string): HTMLInputElement {
  const field = screen.getByText(label).parentElement;
  const input = field?.querySelector("input");
  if (!input) throw new Error(`no input under "${label}"`);
  return input;
}

/** Opens a card by its disclosure toggle, which wraps the (separately clickable) title. */
async function openCard(name: string): Promise<void> {
  const title = await screen.findByText(name);
  const toggle = title.closest("[aria-expanded]");
  if (!toggle) throw new Error(`no disclosure around "${name}"`);
  fireEvent.click(toggle);
}

function type(label: string, value: string): void {
  fireEvent.change(fieldInput(label), { target: { value } });
}

beforeEach(() => {
  state.clients = [];
  state.providers = [];
  state.templates = {};
});

afterEach(() => {
  cleanup();
  vi.clearAllMocks();
});

describe("entry point return origins", () => {
  it("shows a deployment-managed list without any way to edit it", async () => {
    state.clients = [client("adh", true, ["https://agenticdeveloperhub.com"])];
    renderPane();
    await openCard("adh");
    expect(await screen.findByText("https://agenticdeveloperhub.com")).toBeTruthy();
    expect(screen.queryByText("Add Return Origin")).toBeNull();
    expect(screen.queryByLabelText("Remove return origin")).toBeNull();
  });

  it("keeps the editor for any other client", async () => {
    state.clients = [client("partner", false, ["https://partner.example"])];
    renderPane();
    await openCard("partner");
    expect(await screen.findByText("Add Return Origin")).toBeTruthy();
  });
});

describe("a provider whose client secret is a minted JWT", () => {
  it("sends the admin's keys in the mapping when it is created", async () => {
    state.templates = { apple: appleTemplate };
    renderPane();
    fireEvent.click(await screen.findByRole("button", { name: /add provider/i }));
    type("Slug", "apple");
    type("Client ID", "com.example.web");
    type("Team ID", "TEAM123 ");
    type("Key ID", "KEY456");
    type("Private Key", "-----BEGIN PRIVATE KEY-----");
    fireEvent.click(screen.getByRole("button", { name: "Save" }));

    await waitFor(() => expect(createProvider).toHaveBeenCalledTimes(1));
    expect(createProvider).toHaveBeenCalledWith({
      templateSlug: "apple",
      slug: "apple",
      clientId: "com.example.web",
      clientSecret: "-----BEGIN PRIVATE KEY-----",
      identityMapping: {
        ...JWT_MAPPING,
        clientSecretJwt: { teamId: "TEAM123", keyId: "KEY456", audience: "https://appleid.apple.com" },
      },
    });
  });

  it("sends only the mapping when a key changes on an existing provider", async () => {
    const mapping = {
      ...JWT_MAPPING,
      clientSecretJwt: { teamId: "TEAM123", keyId: "OLD", audience: "https://appleid.apple.com" },
    };
    state.providers = [
      { id: "1", slug: "apple", name: "Apple", authType: "oauth2_code", clientId: "com.example.web", scopes: [], identityMapping: mapping },
    ];
    renderPane();
    await openCard("Apple");
    type("Key ID", "NEW");
    fireEvent.click(screen.getByRole("button", { name: "Save" }));

    await waitFor(() => expect(updateProvider).toHaveBeenCalledTimes(1));
    expect(updateProvider).toHaveBeenCalledWith({
      slug: "apple",
      identityMapping: { ...mapping, clientSecretJwt: { ...mapping.clientSecretJwt, keyId: "NEW" } },
    });
  });

  it("asks an ordinary provider only for a client secret, and sends no mapping", async () => {
    state.templates = { github: githubTemplate };
    renderPane();
    fireEvent.click(await screen.findByRole("button", { name: /add provider/i }));
    expect(screen.queryByText("Team ID")).toBeNull();
    type("Slug", "github");
    type("Client ID", "abc");
    type("Client Secret", "shh");
    fireEvent.click(screen.getByRole("button", { name: "Save" }));

    await waitFor(() => expect(createProvider).toHaveBeenCalledTimes(1));
    expect(createProvider).toHaveBeenCalledWith({
      templateSlug: "github",
      slug: "github",
      clientId: "abc",
      clientSecret: "shh",
    });
  });
});

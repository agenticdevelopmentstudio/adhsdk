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

const CORE = { subject_field: "sub", email_field: "email", name_field: "name", avatar_field: "picture" };
const JWT_MAPPING = {
  ...CORE,
  response_mode: "form_post",
  client_secret_jwt: { team_id: "", key_id: "", audience: "https://appleid.apple.com" },
};
const appleTemplate = { slug: "apple", name: "Apple", auth_type: "oauth2_code", identity_mapping: JWT_MAPPING };
const githubTemplate = { slug: "github", name: "GitHub", auth_type: "oauth2_code", identity_mapping: CORE };

function client(slug: string, origins_managed: boolean, origins: string[]) {
  return { id: slug, slug, name: slug, allowed_return_origins: origins, origins_managed, is_internal: false };
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
      template_slug: "apple",
      slug: "apple",
      client_id: "com.example.web",
      client_secret: "-----BEGIN PRIVATE KEY-----",
      identity_mapping: {
        ...JWT_MAPPING,
        client_secret_jwt: { team_id: "TEAM123", key_id: "KEY456", audience: "https://appleid.apple.com" },
      },
    });
  });

  it("sends only the mapping when a key changes on an existing provider", async () => {
    const mapping = {
      ...JWT_MAPPING,
      client_secret_jwt: { team_id: "TEAM123", key_id: "OLD", audience: "https://appleid.apple.com" },
    };
    state.providers = [
      { id: "1", slug: "apple", name: "Apple", auth_type: "oauth2_code", client_id: "com.example.web", scopes: [], identity_mapping: mapping },
    ];
    renderPane();
    await openCard("Apple");
    type("Key ID", "NEW");
    fireEvent.click(screen.getByRole("button", { name: "Save" }));

    await waitFor(() => expect(updateProvider).toHaveBeenCalledTimes(1));
    expect(updateProvider).toHaveBeenCalledWith({
      slug: "apple",
      identity_mapping: { ...mapping, client_secret_jwt: { ...mapping.client_secret_jwt, key_id: "NEW" } },
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
      template_slug: "github",
      slug: "github",
      client_id: "abc",
      client_secret: "shh",
    });
  });
});

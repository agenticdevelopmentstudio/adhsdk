// The /v1 wire contract of the personas clients: URLs, snake_case bodies, list envelopes and the
// mapping back to the camelCase domain shapes. Only `fetch` is stubbed, so the shared /v1 helpers
// (`listAllV1`, `withV1Query`, `unixToIso`) run for real.
import { describe, expect, it, vi, beforeEach } from "vitest";
import { api } from "../personas";
import { personaApprovalsApi, personaMayActApi, personaToolsApi } from "../persona-abilities";
import { personaUserToolsApi } from "../persona-user-tools";

const fetchMock = vi.fn();
const list = (data: unknown[]) => ({ object: "list", data, has_more: false, url: "/v1/x" });
const respond = (body: unknown) =>
  fetchMock.mockResolvedValue({
    ok: true,
    status: 200,
    json: async () => body,
    text: async () => JSON.stringify(body),
  });

beforeEach(() => {
  fetchMock.mockReset();
  vi.stubGlobal("fetch", fetchMock);
});

const urlOf = (n = 0) => String(fetchMock.mock.calls[n]![0]);
const initOf = (n = 0) => fetchMock.mock.calls[n]![1] ?? {};
const bodyOf = (n = 0) => JSON.parse(String(initOf(n).body));

describe("account", () => {
  const account = {
    object: "account",
    id: "u1",
    email: "a@b.c",
    name: "Ann",
    avatar_url: "http://x/a.png",
    slug: "ann",
    public_profile_enabled: true,
    capabilities: ["x"],
  };

  it("reads /v1/account into the camelCase MeRow", async () => {
    respond(account);
    const me = await api.me();
    expect(urlOf()).toBe("/api/v1/account");
    expect(me).toEqual({
      id: "u1",
      email: "a@b.c",
      name: "Ann",
      avatarUrl: "http://x/a.png",
      slug: "ann",
      publicProfileEnabled: true,
      capabilities: ["x"],
    });
  });

  it("updates with POST and a snake_case body", async () => {
    respond(account);
    await api.patchMe({ name: "Ann", avatarUrl: "http://x/a.png", publicProfileEnabled: false });
    expect(urlOf()).toBe("/api/v1/account");
    expect(initOf().method).toBe("POST");
    expect(bodyOf()).toEqual({
      name: "Ann",
      avatar_url: "http://x/a.png",
      public_profile_enabled: false,
    });
  });

  it("maps /v1/handles/{handle} to SlugAvailability", async () => {
    respond({ object: "handle", available: false, reason: "taken" });
    await expect(api.slugAvailable("ann")).resolves.toEqual({ available: false, reason: "taken" });
    expect(urlOf()).toBe("/api/v1/handles/ann");
    respond({ object: "handle", available: true });
    await expect(api.slugAvailable("zed")).resolves.toEqual({ available: true });
  });
});

describe("public lookups", () => {
  it("reads a public user card by ?handle=", async () => {
    respond({
      object: "user",
      slug: "ann",
      display_name: "Ann",
      avatar_url: null,
      created: 1767225600,
      social_links: [],
      emails: [],
      phones: [],
      addresses: [
        { label: "h", line1: "1", line2: "", city: "c", region: "r", postal_code: "123", country: "US" },
      ],
      personas: [
        {
          slug: "bob",
          name: "Bob",
          description: null,
          visibility: "public",
          created: 1767225600,
          owner: { slug: "ann", display_name: "Ann", avatar_url: null },
        },
      ],
    });
    const u = await api.publicUser("ann");
    expect(urlOf()).toBe("/api/v1/users?handle=ann");
    expect(u.createdAt).toBe("2026-01-01T00:00:00.000Z");
    expect(u.addresses[0]!.postalCode).toBe("123");
    expect(u.personas[0]!.owner).toEqual({ slug: "ann", displayName: "Ann", avatarUrl: null });
  });

  it("reads a public persona by ?slug= and by ?owner=&slug=", async () => {
    respond({
      object: "persona",
      slug: "bob",
      name: "Bob",
      description: null,
      model_prompt: "p",
      provider: null,
      model: "m",
      avatar_url: null,
      voice: null,
      character: null,
      examples: null,
      visibility: "public",
      created: 1767225600,
      owner: null,
      demo_enabled: true,
      chat_status: { kind: "word" },
    });
    const p = await api.publicPersona("bob");
    expect(urlOf()).toBe("/api/v1/personas?slug=bob");
    expect(p.modelPrompt).toBe("p");
    expect(p.demoEnabled).toBe(true);
    expect(p.chatStatus).toEqual({ kind: "word" });
    await api.publicPersonaByOwner("ann", "bob");
    expect(urlOf(1)).toBe("/api/v1/personas?owner=ann&slug=bob");
  });
});

describe("personas", () => {
  const personaRow = (slug: string) => ({
    object: "persona",
    id: `persona.acme.${slug}`,
    user_id: "u1",
    owner_kind: "customer",
    owner_id: "u1",
    slug,
    name: slug,
    description: null,
    visibility: "private",
    model: "m",
    service_id: "s1",
    app_id: null,
    avatar_attachment_id: null,
    model_prompt: "p",
    voice: null,
    character: null,
    examples: null,
    canned_chat: { enabled: true, pacing: { thinkMinMs: 1 } },
    chat_status: null,
    created: 1767225600,
    updated: 1767225600,
  });

  it("lists every persona, scoped by workspace", async () => {
    respond(list([personaRow("bob")]));
    const rows = await api.personas.list({ workspace: "acme" });
    expect(urlOf()).toBe("/api/v1/personas?workspace=acme&limit=100");
    expect(rows[0]!.serviceId).toBe("s1");
    // JSON-column bags keep their exact (camelCase) keys.
    expect(rows[0]!.cannedChat).toEqual({ enabled: true, pacing: { thinkMinMs: 1 } });
  });

  it("creates with a snake_case body", async () => {
    respond(personaRow("bob"));
    await api.personas.create({
      slug: "bob",
      name: "Bob",
      modelPrompt: "p",
      avatarAttachmentId: null,
      serviceId: "s1",
      cannedChat: null,
    });
    expect(urlOf()).toBe("/api/v1/personas");
    expect(initOf().method).toBe("POST");
    expect(bodyOf()).toEqual({
      slug: "bob",
      name: "Bob",
      model_prompt: "p",
      avatar_attachment_id: null,
      service_id: "s1",
      canned_chat: null,
    });
  });

  it("deletes by id", async () => {
    respond({ id: "persona.acme.bob", object: "persona", deleted: true });
    await api.personas.delete("persona.acme.bob");
    expect(urlOf()).toBe("/api/v1/personas/persona.acme.bob");
    expect(initOf().method).toBe("DELETE");
  });

  it("finds the owner's persona by slug in their own list (a ?slug= call answers the public card)", async () => {
    respond(list([personaRow("alice"), personaRow("bob")]));
    const row = await api.personas.bySlugAsOwner("bob");
    expect(urlOf()).toBe("/api/v1/personas?limit=100");
    expect(row.id).toBe("persona.acme.bob");
    await expect(api.personas.bySlugAsOwner("nope")).rejects.toThrow("404");
  });
});

describe("ai services and templates", () => {
  const service = {
    object: "ai_service",
    id: "s1",
    template_id: "t1",
    provider_kind: "openai",
    name: "Mine",
    base_url: "http://x",
    has_api_key: true,
    connect_status: "connected",
    models: [{ id: "gpt", displayName: "GPT", contextWindow: 10 }, "bare"],
    models_fetched_at: "2026-01-01T00:00:00Z",
  };

  it("lists services, keeping model-bag keys and expanding bare model ids", async () => {
    respond(list([service]));
    const rows = await api.services.list();
    expect(urlOf()).toBe("/api/v1/ai_services?limit=100");
    expect(rows[0]!.hasApiKey).toBe(true);
    expect(rows[0]!.templateId).toBe("t1");
    expect(rows[0]!.models).toEqual([
      { id: "gpt", displayName: "GPT", contextWindow: 10 },
      { id: "bare" },
    ]);
  });

  it("creates and patches with snake_case bodies (connection spec included)", async () => {
    respond(service);
    await api.services.create({
      templateId: "t1",
      name: "Mine",
      providerKind: "openai",
      baseUrl: "http://x",
      apiKey: "k",
      connectionSpec: {
        specVersion: 1,
        urlVars: [{ name: "region" }],
        auth: { type: "oauth2", tokenUrl: "http://t" },
        extraHeaders: { "X-Keep-Case": "v" },
      },
    });
    expect(urlOf()).toBe("/api/v1/ai_services");
    expect(bodyOf()).toEqual({
      template_id: "t1",
      name: "Mine",
      provider_kind: "openai",
      base_url: "http://x",
      api_key: "k",
      connection_spec: {
        spec_version: 1,
        url_vars: [{ name: "region" }],
        auth: { type: "oauth2", token_url: "http://t" },
        extra_headers: { "X-Keep-Case": "v" },
      },
    });
    await api.services.patch("s1", { baseUrl: "http://y", connectionSpec: null });
    expect(urlOf(1)).toBe("/api/v1/ai_services/s1");
    expect(initOf(1).method).toBe("POST");
    expect(bodyOf(1)).toEqual({ base_url: "http://y", connection_spec: null });
  });

  it("connects, refreshes and deletes on the ai_services paths", async () => {
    respond(service);
    await api.services.connect("s1");
    await api.services.refreshModels("s1");
    respond({ id: "s1", object: "ai_service", deleted: true });
    await api.services.delete("s1");
    expect(urlOf(0)).toBe("/api/v1/ai_services/s1/connect");
    expect(urlOf(1)).toBe("/api/v1/ai_services/s1/refresh_models");
    expect(urlOf(2)).toBe("/api/v1/ai_services/s1");
    expect(initOf(2).method).toBe("DELETE");
  });

  it("lists a connection's models from /v1/models?service=", async () => {
    respond(list([{ object: "model", id: "gpt", displayName: "GPT" }]));
    await expect(api.services.models("s1")).resolves.toEqual([{ id: "gpt", displayName: "GPT" }]);
    expect(urlOf()).toBe("/api/v1/models?service=s1&limit=100");
  });

  it("maps provider templates, their nested models and the connection spec", async () => {
    respond(
      list([
        {
          object: "provider_template",
          id: "t1",
          provider_kind: "openai",
          name: "OpenAI",
          base_url: "http://x",
          documentation_url: null,
          status_url: null,
          connection_spec: { spec_version: 1, header_vars: [{ header: "x-h" }], default_query: { "api-version": "1" } },
          modalities: ["chat"],
          models: [
            {
              id: "m1",
              name: "M1",
              description: null,
              metadata: { contextWindow: 5 },
              source: "synced",
              last_synced_at: "2026-01-01T00:00:00Z",
              created: 1767225600,
            },
          ],
          created: 1767225600,
          updated: 1767225600,
        },
      ]),
    );
    const [t] = await api.templates();
    expect(urlOf()).toBe("/api/v1/provider_templates?limit=100");
    expect(t!.connectionSpec).toEqual({
      specVersion: 1,
      headerVars: [{ header: "x-h" }],
      defaultQuery: { "api-version": "1" },
    });
    expect(t!.models[0]).toMatchObject({
      lastSyncedAt: "2026-01-01T00:00:00Z",
      createdAt: "2026-01-01T00:00:00.000Z",
      metadata: { contextWindow: 5 },
    });
    expect(t!.modalities).toEqual(["chat"]);
  });
});

describe("persona grants and approvals", () => {
  const approval = {
    object: "processing.persona_approval",
    id: "a1",
    persona_id: "p1",
    subject_kind: "user",
    subject_eco: "e",
    tool_name: "web",
    args: { someKey: 1 },
    status: "pending",
    created: 1767225600,
  };

  it("lists approvals with status and persona_id filters", async () => {
    respond(list([approval]));
    const rows = await personaApprovalsApi.list("pending", "p1");
    expect(urlOf()).toBe(
      "/api/v1/processing/persona_approvals?status=pending&persona_id=p1&limit=100",
    );
    expect(rows[0]).toMatchObject({
      personaId: "p1",
      toolName: "web",
      args: { someKey: 1 },
      createdAt: "2026-01-01T00:00:00.000Z",
    });
  });

  it("approves and rejects with POST on the approval path (bare answers)", async () => {
    respond(approval);
    const a = await personaApprovalsApi.approve("a1");
    await personaApprovalsApi.reject("a1");
    expect(urlOf(0)).toBe("/api/v1/processing/persona_approvals/a1/approve");
    expect(urlOf(1)).toBe("/api/v1/processing/persona_approvals/a1/reject");
    expect(initOf(0).method).toBe("POST");
    expect(a.id).toBe("a1");
  });

  it("reads and writes may-act through /actors", async () => {
    respond({ object: "actor", kinds: ["self", "user"] });
    await expect(personaMayActApi.list("p1")).resolves.toEqual(["self", "user"]);
    await personaMayActApi.grant("p1", "team");
    await personaMayActApi.revoke("p1", "team");
    expect(urlOf(0)).toBe("/api/v1/personas/p1/actors");
    expect(bodyOf(1)).toEqual({ kind: "team" });
    expect(urlOf(2)).toBe("/api/v1/personas/p1/actors/team");
    expect(initOf(2).method).toBe("DELETE");
  });

  it("lists, grants, revokes and sets autonomy on /tools", async () => {
    const tool = {
      object: "tool",
      tool_name: "web",
      source: null,
      display_name: "Web",
      description: "d",
      read_only: true,
      granted: true,
      autonomous: false,
    };
    respond(list([tool]));
    const rows = await personaToolsApi.list("p1");
    expect(urlOf()).toBe("/api/v1/personas/p1/tools?limit=100");
    expect(rows[0]).toEqual({
      toolName: "web",
      source: null,
      displayName: "Web",
      description: "d",
      readOnly: true,
      granted: true,
      autonomous: false,
    });
    respond(tool);
    await personaToolsApi.grant("p1", "web");
    expect(bodyOf(1)).toEqual({ tool_name: "web" });
    respond({ object: "tool", tool_name: "web", autonomous: true, created: 1767225600 });
    const g = await personaToolsApi.setAutonomy("p1", "web", true);
    expect(urlOf(2)).toBe("/api/v1/personas/p1/tools/web");
    expect(initOf(2).method).toBe("POST");
    expect(bodyOf(2)).toEqual({ autonomous: true });
    expect(g).toEqual({ toolName: "web", autonomous: true, createdAt: "2026-01-01T00:00:00.000Z" });
    respond({ id: "web", object: "tool", deleted: true });
    await personaToolsApi.revoke("p1", "web");
    expect(urlOf(3)).toBe("/api/v1/personas/p1/tools/web");
    expect(initOf(3).method).toBe("DELETE");
  });

  it("finds actable personas with ?actable_by=me and sets user tools by POST", async () => {
    respond(list([{ id: "p1", slug: "bob", name: "Bob", model: "m" }]));
    await expect(personaUserToolsApi.listActable()).resolves.toEqual([
      { id: "p1", slug: "bob", name: "Bob" },
    ]);
    expect(urlOf()).toBe("/api/v1/personas?actable_by=me&limit=100");
    const ut = {
      tool_name: "web",
      source: null,
      display_name: "Web",
      description: "",
      read_only: false,
      allowed: true,
    };
    respond({ object: "user_tool", tools: [ut] });
    const tools = await personaUserToolsApi.setAllowed("p1", ["web"]);
    expect(urlOf(1)).toBe("/api/v1/personas/p1/user_tools");
    expect(initOf(1).method).toBe("POST");
    expect(bodyOf(1)).toEqual({ allowed: ["web"] });
    expect(tools[0]!.toolName).toBe("web");
    respond(list([ut]));
    await expect(personaUserToolsApi.listTools("p1")).resolves.toHaveLength(1);
    expect(urlOf(2)).toBe("/api/v1/personas/p1/user_tools?limit=100");
  });
});

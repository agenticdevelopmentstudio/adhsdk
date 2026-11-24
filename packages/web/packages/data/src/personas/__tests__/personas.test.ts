// Persona rdids are DERIVED (`persona.<owner-address>.<slug>`, where the owner segment is itself an
// rdid — `org.<slug>` or `user.<eco-path>.<slug>` — NOT a bare workspace slug) from the stored slug,
// and the update body always carries `slug` — so the update IS the rename: the server moves the address
// columns and cascades the new address onto the handle. `api.personas.update()` is therefore ONE
// call, and the id it returns is the server's derived answer, never a client-side leaf swap. Only
// the transport (`authedJson`, re-exported by `../personas` via `../http` from
// `@adh-sdk/auth/client`) is stubbed.
import { describe, expect, it, vi, beforeEach } from "vitest";

vi.mock("@adh-sdk/auth/client", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@adh-sdk/auth/client")>()),
  authedJson: vi.fn(),
}));

import { authedJson, AuthHttpError } from "@adh-sdk/auth/client";
import { api } from "../personas";
import type { PersonaBody } from "../personas";
import type { V1Persona } from "../wire";

const mockedJson = vi.mocked(authedJson);

const BODY: PersonaBody = {
  slug: "bob",
  name: "Bob",
  modelPrompt: "You are Bob.",
};

const WIRE_BODY = {
  slug: "bob",
  name: "Bob",
  model_prompt: "You are Bob.",
};

function row(overrides: Partial<V1Persona> = {}): V1Persona {
  return {
    object: "persona",
    id: "persona.acme.bob",
    user_id: "u-1",
    owner_kind: "customer",
    owner_id: "u-1",
    slug: "bob",
    name: "Bob",
    description: null,
    visibility: "private",
    model: "m",
    service_id: null,
    app_id: null,
    avatar_attachment_id: null,
    model_prompt: "You are Bob.",
    voice: null,
    character: null,
    examples: null,
    created: 1767225600,
    updated: 1767225600,
    owned_ecosystem_id: null,
    ...overrides,
  };
}

beforeEach(() => {
  mockedJson.mockReset();
});

describe("personas.update", () => {
  it("no slug change: ONE POST under the current id", async () => {
    mockedJson.mockResolvedValueOnce(row());
    const saved = await api.personas.update("persona.acme.bob", { ...BODY, slug: "bob" });
    expect(mockedJson).toHaveBeenCalledTimes(1);
    expect(mockedJson).toHaveBeenCalledWith("/api/v1/personas/persona.acme.bob", {
      method: "POST",
      body: JSON.stringify({ ...WIRE_BODY, slug: "bob" }),
    });
    expect(saved.id).toBe("persona.acme.bob");
  });

  // The defect this replaced: the update already cascaded the handle onto the new address, and the
  // follow-up identifiers PATCH then tried to rename a superseded alias onto an rdid the row
  // itself now holds — a taken target (23505 -> 409), reporting a successful rename as a failure.
  it("slug change: STILL one POST — the slug in the body IS the rename", async () => {
    mockedJson.mockResolvedValueOnce(row({ id: "persona.acme.bobby", slug: "bobby" }));
    const saved = await api.personas.update("persona.acme.bob", { ...BODY, slug: "bobby" });

    expect(mockedJson).toHaveBeenCalledTimes(1);
    expect(mockedJson).toHaveBeenCalledWith("/api/v1/personas/persona.acme.bob", {
      method: "POST",
      body: JSON.stringify({ ...WIRE_BODY, slug: "bobby" }),
    });
    expect(saved.id).toBe("persona.acme.bobby");
    // `created`/`updated` are unix seconds on the wire; the domain keeps ISO strings.
    expect(saved.createdAt).toBe("2026-01-01T00:00:00.000Z");
    expect(saved.modelPrompt).toBe("You are Bob.");
  });

  it("scopes an update to a workspace with ?workspace=", async () => {
    mockedJson.mockResolvedValueOnce(row());
    await api.personas.update("persona.acme.bob", BODY, { workspace: "acme" });
    expect(mockedJson.mock.calls[0]![0]).toBe("/api/v1/personas/persona.acme.bob?workspace=acme");
  });

  it("returns the address the SERVER derived, not a client-side leaf swap", async () => {
    // The server's cascade is the authority: a handle it declined to move (a legacy
    // reverse-domain mapping) comes back unchanged, and callers must see that, not a guess.
    mockedJson.mockResolvedValueOnce(row({ id: "com.acme.bob", slug: "bobby" }));
    const saved = await api.personas.update("persona.acme.bob", { ...BODY, slug: "bobby" });
    expect(saved.id).toBe("com.acme.bob");
  });

  it("propagates a failed POST — one call has no half-landed state to recover", async () => {
    mockedJson.mockRejectedValueOnce(new AuthHttpError(404, "Not Found"));
    await expect(
      api.personas.update("persona.acme.bob", { ...BODY, slug: "bobby" }),
    ).rejects.toThrow();
    expect(mockedJson).toHaveBeenCalledTimes(1);
  });
});

import { describe, expect, it } from "vitest";
import {
  applySyncKeys,
  buildTemplateBody,
  templateFormBlockedReason,
  BASE_URL_REQUIRED_MESSAGE,
  NAME_REQUIRED_MESSAGE,
  stateFromTemplate,
  syncKeysSignature,
  toggleModality,
  type Modality,
  type TemplateFormState,
} from "./template-form";
import { emptyConnectionSpecDraft } from "./connection-spec-draft";
import type { ProviderTemplate } from "../api/llm-providers";

const baseForm = (o: Partial<TemplateFormState> = {}): TemplateFormState => ({
  providerKind: "openai",
  name: "OpenAI",
  baseUrl: "https://api.openai.com/v1",
  documentationUrl: "",
  statusUrl: "",
  models: [],
  modalities: [],
  availableViaNote: "",
  availableViaTemplates: "",
  syncModelsDev: "",
  syncOpenrouter: "",
  syncArenaVendor: "",
  spec: emptyConnectionSpecDraft(),
  ...o,
});

const templateFixture = (o: Partial<ProviderTemplate> = {}): ProviderTemplate => ({
  id: "tpl_1",
  provider_kind: "openai",
  name: "OpenAI",
  base_url: "https://api.openai.com/v1",
  documentation_url: null,
  status_url: null,
  connection_spec: null,
  available_via: null,
  modalities: ["chat", "image"],
  created: 1782864000,
  updated: 1782864000,
  models: [],
  ...o,
});

// The actual wire body is JSON.stringify(body), so assert the serialized shape:
// an omitted (`undefined`) syncKeys must not appear on the wire at all.
const wireBody = (body: unknown) => JSON.parse(JSON.stringify(body));

describe("buildTemplateBody: syncKeys gating (the round-trip data-loss guard)", () => {
  it("OMITS syncKeys from the wire in edit mode until the mapping has loaded", () => {
    const body = buildTemplateBody(baseForm({ syncModelsDev: "openai" }), {
      editing: true,
      syncKeysLoaded: false,
    });
    // undefined in-memory, and absent after JSON serialization (PUT: untouched).
    expect(body.sync_keys).toBeUndefined();
    expect("sync_keys" in wireBody(body)).toBe(false);
  });

  it("sends syncKeys in edit mode once the mapping has loaded", () => {
    const body = buildTemplateBody(baseForm({ syncModelsDev: "openai" }), {
      editing: true,
      syncKeysLoaded: true,
    });
    expect(wireBody(body).sync_keys).toEqual({ models_dev: "openai" });
  });

  it("sends an explicit null to CLEAR once loaded and all keys are blank", () => {
    const body = buildTemplateBody(baseForm(), { editing: true, syncKeysLoaded: true });
    expect(body.sync_keys).toBeNull();
    expect(wireBody(body).sync_keys).toBeNull();
  });

  it("always includes syncKeys on create (nothing stored to clobber)", () => {
    const withVal = buildTemplateBody(baseForm({ syncArenaVendor: "OpenAI" }), {
      editing: false,
      syncKeysLoaded: false,
    });
    expect(wireBody(withVal).sync_keys).toEqual({ arena_vendor: "OpenAI" });

    const empty = buildTemplateBody(baseForm(), { editing: false, syncKeysLoaded: false });
    expect(wireBody(empty).sync_keys).toBeNull();
  });

  it("trims sync-key values and drops whitespace-only ones", () => {
    const body = buildTemplateBody(
      baseForm({ syncModelsDev: "  openai  ", syncOpenrouter: "   " }),
      { editing: true, syncKeysLoaded: true },
    );
    expect(wireBody(body).sync_keys).toEqual({ models_dev: "openai" });
  });

  it("nulls syncKeys when every value is blank/whitespace (loaded)", () => {
    const body = buildTemplateBody(baseForm({ syncOpenrouter: "  " }), {
      editing: true,
      syncKeysLoaded: true,
    });
    expect(body.sync_keys).toBeNull();
  });
});

describe("sync-key (re)load: a refreshed mapping must replace a stale cached one", () => {
  // The data-loss path this guards: save a new mapping, reopen the dialog inside
  // the 30s staleTime, react-query serves the PRE-save mapping from cache and then
  // refetches (the update mutation invalidates the sync-keys query). Applying only
  // the first arrival would leave the stale value in the form — and the next save
  // would write it straight back, reverting the operator's edit.
  it("applies a later, DIFFERENT fetch so the next save sends the new keys", () => {
    const template = templateFixture();
    let form = stateFromTemplate(template, { models_dev: "old" });
    // Arrival 1: the stale cached mapping.
    form = applySyncKeys(form, { models_dev: "old" });
    // Arrival 2: the refetch, carrying what was just saved.
    form = applySyncKeys(form, { models_dev: "new" });

    expect(form.syncModelsDev).toBe("new");
    const body = buildTemplateBody(form, { editing: true, syncKeysLoaded: true });
    expect(wireBody(body).sync_keys).toEqual({ models_dev: "new" });
  });

  it("signals 'apply' only when the mapping actually changed", () => {
    // Different mapping ⇒ different signature ⇒ the dialog re-applies (re-arms).
    expect(syncKeysSignature({ models_dev: "old" })).not.toBe(
      syncKeysSignature({ models_dev: "new" }),
    );
    // Same mapping ⇒ same signature ⇒ skipped, so a background refetch can't
    // clobber an operator's in-progress edit.
    expect(syncKeysSignature({ models_dev: "openai", arena_vendor: "OpenAI" })).toBe(
      syncKeysSignature({ arena_vendor: "OpenAI", models_dev: "openai" }),
    );
    // A cleared mapping is distinct from a populated one (and null ≡ undefined).
    expect(syncKeysSignature(null)).toBe(syncKeysSignature(undefined));
    expect(syncKeysSignature(null)).not.toBe(syncKeysSignature({ models_dev: "openai" }));
  });

  it("blanks the fields when the stored mapping came back cleared", () => {
    const form = applySyncKeys(
      baseForm({ syncModelsDev: "old", syncOpenrouter: "old", syncArenaVendor: "old" }),
      null,
    );
    expect(form.syncModelsDev).toBe("");
    expect(form.syncOpenrouter).toBe("");
    expect(form.syncArenaVendor).toBe("");
    // …and a save then CLEARS upstream rather than resurrecting the stale mapping.
    expect(buildTemplateBody(form, { editing: true, syncKeysLoaded: true }).sync_keys).toBeNull();
  });

  it("seeds the same fields from a mapping (initial state stays in step)", () => {
    const state = stateFromTemplate(templateFixture(), {
      models_dev: "openai",
      openrouter: "openai",
      arena_vendor: "OpenAI",
    });
    expect(applySyncKeys(baseForm(), {
      models_dev: "openai",
      openrouter: "openai",
      arena_vendor: "OpenAI",
    })).toMatchObject({
      syncModelsDev: state.syncModelsDev,
      syncOpenrouter: state.syncOpenrouter,
      syncArenaVendor: state.syncArenaVendor,
    });
  });
});

describe("toggleModality: order-stable so a no-op toggle isn't 'unsaved changes'", () => {
  it("returns the ORIGINAL array after unchecking then re-checking", () => {
    const original: Modality[] = ["chat", "image"];
    const off = toggleModality(original, "chat", false);
    expect(off).toEqual(["image"]);
    const back = toggleModality(off, "chat", true);
    expect(back).toEqual(original);
    // The dialog's dirty flag is exactly this comparison against `initial`.
    expect(JSON.stringify(back)).toBe(JSON.stringify(original));
  });

  it("keeps the fixed MODALITIES order whatever the check order, and dedupes", () => {
    expect(toggleModality(["video"], "chat", true)).toEqual(["chat", "video"]);
    expect(toggleModality(["image", "chat"], "video", true)).toEqual(["chat", "image", "video"]);
    expect(toggleModality(["chat"], "chat", true)).toEqual(["chat"]);
    expect(toggleModality(["chat"], "chat", false)).toEqual([]);
  });

  it("canonicalizes the seeded state too, so a stored order can't read dirty", () => {
    const state = stateFromTemplate(templateFixture({ modalities: ["video", "chat"] }), undefined);
    expect(state.modalities).toEqual(["chat", "video"]);
    expect(toggleModality(toggleModality(state.modalities, "video", false), "video", true)).toEqual(
      state.modalities,
    );
  });
});

describe("templateFormBlockedReason: the sentence a doomed click would have produced", () => {
  it("is null for a fully-populated, well-formed form", () => {
    expect(templateFormBlockedReason(baseForm())).toBeNull();
  });

  it("names the missing name when it is blank or whitespace-only", () => {
    expect(templateFormBlockedReason(baseForm({ name: "" }))).toBe(NAME_REQUIRED_MESSAGE);
    expect(templateFormBlockedReason(baseForm({ name: "   " }))).toBe(NAME_REQUIRED_MESSAGE);
  });

  it("names the missing base URL when it is blank or whitespace-only", () => {
    expect(templateFormBlockedReason(baseForm({ baseUrl: "" }))).toBe(
      BASE_URL_REQUIRED_MESSAGE,
    );
    expect(templateFormBlockedReason(baseForm({ baseUrl: "   " }))).toBe(
      BASE_URL_REQUIRED_MESSAGE,
    );
  });

  it("passes the connection spec's own complaint straight through", () => {
    const badSpec = { ...emptyConnectionSpecDraft(), authType: "header" as const, header: "" };
    expect(templateFormBlockedReason(baseForm({ spec: badSpec }))).toBe(
      "Custom-header auth needs a header name.",
    );
  });

  // Order matters: the reason has to be the one handleSubmit would have thrown first.
  it("reports the missing name before the missing base URL", () => {
    expect(templateFormBlockedReason(baseForm({ name: "", baseUrl: "" }))).toBe(
      NAME_REQUIRED_MESSAGE,
    );
  });
});

describe("buildTemplateBody: other fields", () => {
  it("trims name/baseUrl and nulls empty modalities + availableVia", () => {
    const body = buildTemplateBody(baseForm({ name: "  OpenAI  ", baseUrl: "  https://x  " }), {
      editing: false,
      syncKeysLoaded: false,
    });
    expect(body.name).toBe("OpenAI");
    expect(body.base_url).toBe("https://x");
    expect(body.modalities).toBeNull();
    expect(body.available_via).toBeNull();
  });

  it("builds modalities and availableVia (comma-split, trimmed, blanks dropped)", () => {
    const body = buildTemplateBody(
      baseForm({
        modalities: ["chat", "image"],
        availableViaNote: "  via gateways ",
        availableViaTemplates: "OpenRouter, , Vertex AI ,",
      }),
      { editing: false, syncKeysLoaded: false },
    );
    expect(body.modalities).toEqual(["chat", "image"]);
    expect(body.available_via).toEqual({
      note: "via gateways",
      templates: ["OpenRouter", "Vertex AI"],
    });
  });
});

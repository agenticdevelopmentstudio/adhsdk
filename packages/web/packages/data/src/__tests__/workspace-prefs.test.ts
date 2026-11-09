import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

// The auth-aware fetchers are the seam every data module goes through, so mock those rather
// than global fetch — that is what the module actually depends on.
const authedJson = vi.fn();
vi.mock("../http", async (importOriginal) => ({
  ...(await importOriginal<typeof import("../http")>()),
  authedJson,
}));

const { workspacePrefsApi, readCachedWorkspace, writeCachedWorkspace } = await import(
  "../workspace-prefs"
);

beforeEach(() => {
  localStorage.clear();
  authedJson.mockReset();
  authedJson.mockResolvedValue({});
});
afterEach(() => {
  vi.restoreAllMocks();
});

describe("workspacePrefsApi", () => {
  it("get() reads the workspace_prefs include of /v1/account and unwraps { prefs }", async () => {
    authedJson.mockResolvedValue({ object: "account", workspace_prefs: { prefs: { slug: "acme" } } });
    await expect(workspacePrefsApi.get()).resolves.toEqual({ slug: "acme" });
    expect(authedJson).toHaveBeenCalledWith("/api/v1/account?include%5B%5D=workspace_prefs");
  });

  it("get() returns {} for a user who has never chosen (never a 404 to handle)", async () => {
    authedJson.mockResolvedValue({ workspace_prefs: { prefs: {} } });
    await expect(workspacePrefsApi.get()).resolves.toEqual({});
  });

  it("get() returns {} when the account answers without the include", async () => {
    authedJson.mockResolvedValue({ object: "account" });
    await expect(workspacePrefsApi.get()).resolves.toEqual({});
  });

  it("put() POSTs the whole shape under workspace_prefs", async () => {
    await workspacePrefsApi.put({ slug: "globex" });
    expect(authedJson).toHaveBeenCalledWith("/api/v1/account", {
      method: "POST",
      body: JSON.stringify({ workspace_prefs: { slug: "globex" } }),
    });
  });
});

describe("the localStorage mirror", () => {
  it("round-trips the slug", () => {
    expect(readCachedWorkspace()).toBeNull();
    writeCachedWorkspace("acme");
    expect(readCachedWorkspace()).toBe("acme");
  });

  it("survives a storage failure rather than throwing (private mode / quota)", () => {
    // The workspace-root vitest.setup.ts replaces window.localStorage with a plain-object
    // in-memory shim (Node 24's experimental built-in localStorage otherwise leaves jsdom's
    // version with missing methods), so its getItem/setItem are the shim's OWN properties,
    // never inherited from Storage.prototype. Spying on Storage.prototype has no effect on
    // this object — the throw has to be injected on the shim instance itself.
    const boom = vi.spyOn(window.localStorage, "getItem").mockImplementation(() => {
      throw new Error("SecurityError");
    });
    expect(readCachedWorkspace()).toBeNull();
    boom.mockRestore();

    const boom2 = vi.spyOn(window.localStorage, "setItem").mockImplementation(() => {
      throw new Error("QuotaExceededError");
    });
    expect(() => writeCachedWorkspace("acme")).not.toThrow();
    boom2.mockRestore();
  });
});

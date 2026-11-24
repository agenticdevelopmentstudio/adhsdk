/// <reference types="@testing-library/jest-dom/vitest" />
import type { ReactElement } from "react";
import { render, renderHook, screen, cleanup, act } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { QueryClient, QueryClientProvider, notifyManager } from "@tanstack/react-query";

// Only the transport, so the client, its query keys and its cache are all the real ones.
vi.mock("../../http", async (importOriginal) => ({
  ...(await importOriginal<typeof import("../../http")>()),
  authedRequest: vi.fn(),
  authedJson: vi.fn(),
  listAllV1: vi.fn(),
}));

import {
  ecosystemFeaturesApi,
  useApplyFeatureChange,
  useFeatureCatalog,
  useProvisionedFeatures,
  useProvisionFeatures,
  useRemoveFeature,
  FeatureRequiredError,
  removalLevels,
  type CatalogFeature,
} from "../ecosystem-features";
import { authedRequest, authedJson, listAllV1 } from "../../http";
import { AuthHttpError } from "@adh-sdk/auth/client";

// Notify observers synchronously — react-query's default scheduler batches into a macrotask,
// and these tests read mutation state right after `act`, not through a `waitFor`.
notifyManager.setScheduler((cb) => cb());

const mockedRequest = vi.mocked(authedRequest);
const mockedJson = vi.mocked(authedJson);
const mockedList = vi.mocked(listAllV1);

/** A status-carrying HTTP error, the shape `isNotFound` duck-types on. */
const httpError = (status: number) => Object.assign(new Error(`HTTP ${status}`), { status });

afterEach(() => {
  cleanup();
  vi.clearAllMocks();
});

describe("ecosystemFeaturesApi.remove", () => {
  // A double-click, a stale list, or a second tab racing the same removal all land here: the row
  // is already gone, which is the caller's goal either way, so a 404 must resolve, not throw.
  it("ecosystems-037: treats a 404 as success — the row is already gone", async () => {
    mockedRequest.mockRejectedValueOnce(httpError(404));
    await expect(ecosystemFeaturesApi.remove("eco-1", "widgets")).resolves.toBeUndefined();
  });

  it("ecosystems-038: still throws on a real failure", async () => {
    mockedRequest.mockRejectedValueOnce(httpError(500));
    await expect(ecosystemFeaturesApi.remove("eco-1", "widgets")).rejects.toThrow("HTTP 500");
  });

  it("ecosystems-039: resolves normally when the DELETE succeeds outright", async () => {
    mockedRequest.mockResolvedValueOnce(undefined);
    await expect(ecosystemFeaturesApi.remove("eco-1", "widgets")).resolves.toBeUndefined();
    expect(mockedRequest).toHaveBeenCalledTimes(1);
    expect(mockedRequest).toHaveBeenCalledWith("/api/v1/ecosystems/eco-1/features/widgets", {
      method: "DELETE",
    });
  });

  // The backend's DELETE returns 409 `{ error: { code: "feature_required", message, neededBy } }`
  // when another active feature still needs this one (ecosystemFeatures.ts ~line 136). The picker
  // needs `neededBy` to name the blocking features, not just a generic failure message — so this
  // must surface as a typed FeatureRequiredError, not the plain AuthHttpError every other 4xx gets.
  it("maps a 409 feature_required response to a typed FeatureRequiredError", async () => {
    const body = {
      error: {
        code: "feature_required",
        message: "this feature is needed by Client Auth",
        neededBy: ["signin-apps"],
      },
    };
    mockedRequest.mockRejectedValueOnce(
      new AuthHttpError(409, body.error.message, body.error.code, body),
    );

    const rejection = ecosystemFeaturesApi.remove("eco-1", "users");
    await expect(rejection).rejects.toBeInstanceOf(FeatureRequiredError);
    await expect(rejection).rejects.toThrow("this feature is needed by Client Auth");
    await rejection.catch((err: FeatureRequiredError) => {
      expect(err.neededBy).toEqual(["signin-apps"]);
    });
  });

  // A 409 with a different code (or no structured body at all) is not a feature-requirement
  // conflict — it must pass through unchanged rather than being coerced into FeatureRequiredError.
  it("leaves a 409 with no feature_required body as a plain error", async () => {
    mockedRequest.mockRejectedValueOnce(new AuthHttpError(409, "some other conflict"));
    await expect(ecosystemFeaturesApi.remove("eco-1", "widgets")).rejects.not.toBeInstanceOf(
      FeatureRequiredError,
    );
  });
});

describe("useApplyFeatureChange", () => {
  function Probe({ ecosystemId }: { ecosystemId: string }): ReactElement {
    const apply = useApplyFeatureChange(ecosystemId);
    return (
      <div>
        <button onClick={() => apply.mutate({ add: [], remove: ["a", "b", "c"] })}>go</button>
        <div data-testid="status">{apply.status}</div>
        <div data-testid="error">{apply.error instanceof Error ? apply.error.message : ""}</div>
        <div data-testid="required">{apply.error instanceof FeatureRequiredError ? "yes" : "no"}</div>
        <div data-testid="other-failures">
          {apply.error instanceof FeatureRequiredError ? apply.error.otherFailures.join(",") : ""}
        </div>
      </div>
    );
  }

  function mount() {
    const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } });
    render(
      <QueryClientProvider client={qc}>
        <Probe ecosystemId="eco-1" />
      </QueryClientProvider>,
    );
  }

  // Sequential `for … await` removal would abort on the first rejection and never attempt "c".
  // `Promise.allSettled` must let every removal run, then fail loudly by name for the ones that
  // didn't make it — not silently drop them.
  it("ecosystems-040: runs every removal even when one fails, and names the failed keys", async () => {
    mockedRequest
      .mockResolvedValueOnce(undefined) // a
      .mockRejectedValueOnce(httpError(500)) // b
      .mockResolvedValueOnce(undefined); // c

    mount();
    await act(async () => {
      screen.getByText("go").click();
    });

    // All three DELETEs were issued despite "b" failing.
    expect(mockedRequest).toHaveBeenCalledTimes(3);
    expect(screen.getByTestId("status").textContent).toBe("error");
    expect(screen.getByTestId("error").textContent).toBe("Couldn't remove: b");
    // No add request: the change had no adds, so the provision route was never called.
    expect(mockedJson).not.toHaveBeenCalled();
  });

  it("ecosystems-041: succeeds when every removal succeeds (or is a 404, already-gone)", async () => {
    mockedRequest
      .mockResolvedValueOnce(undefined) // a
      .mockRejectedValueOnce(httpError(404)) // b — already gone, counts as success
      .mockResolvedValueOnce(undefined); // c

    mount();
    await act(async () => {
      screen.getByText("go").click();
    });

    expect(screen.getByTestId("status").textContent).toBe("success");
    expect(screen.getByTestId("error").textContent).toBe("");
  });

  // A race with another session: it added something, between the picker's confirm and this DELETE
  // landing, that now needs the key being removed. That is the ONE removal failure worth naming —
  // rethrown as the typed FeatureRequiredError itself, not folded into the generic "Couldn't
  // remove: b" every other failure gets, so the caller (ManageFeaturesDialog) can tell them apart.
  it("rethrows a FeatureRequiredError from a removal instead of the generic message", async () => {
    mockedRequest
      .mockResolvedValueOnce(undefined) // a
      .mockRejectedValueOnce(
        new AuthHttpError(409, "this feature is needed by Client Auth", "feature_required", {
          error: { code: "feature_required", message: "this feature is needed by Client Auth", neededBy: ["signin-apps"] },
        }),
      ) // b
      .mockResolvedValueOnce(undefined); // c

    mount();
    await act(async () => {
      screen.getByText("go").click();
    });

    expect(screen.getByTestId("status").textContent).toBe("error");
    expect(screen.getByTestId("required").textContent).toBe("yes");
    expect(screen.getByTestId("error").textContent).toBe("this feature is needed by Client Auth");
  });

  // Two removals fail in the same batch — "b" a FeatureRequiredError, "c" a plain 500. The old
  // code found the FeatureRequiredError and threw ONLY it, dropping "c" on the floor entirely:
  // the picker would say Users is needed by Client Auth and never mention that "c" also failed.
  // Nothing may be swallowed — "c" must still be named, on the thrown error itself.
  it("keeps every other failed key when a FeatureRequiredError is thrown, not just the first", async () => {
    mockedRequest
      .mockResolvedValueOnce(undefined) // a
      .mockRejectedValueOnce(
        new AuthHttpError(409, "this feature is needed by Client Auth", "feature_required", {
          error: { code: "feature_required", message: "this feature is needed by Client Auth", neededBy: ["signin-apps"] },
        }),
      ) // b
      .mockRejectedValueOnce(httpError(500)); // c

    mount();
    await act(async () => {
      screen.getByText("go").click();
    });

    expect(mockedRequest).toHaveBeenCalledTimes(3);
    expect(screen.getByTestId("status").textContent).toBe("error");
    expect(screen.getByTestId("required").textContent).toBe("yes");
    expect(screen.getByTestId("error").textContent).toBe("this feature is needed by Client Auth");
    expect(screen.getByTestId("other-failures").textContent).toBe("c");
  });
});

describe("useApplyFeatureChange — removal order", () => {
  afterEach(() => {
    mockedJson.mockReset();
    mockedList.mockReset();
    mockedRequest.mockReset();
  });

  // `signin-apps` requires `users`: the backend refuses DELETE users with a 409 while signin-apps
  // is still active, so a picker visit that removes BOTH must send signin-apps first and let it
  // settle before users goes out. Sent in parallel, the users DELETE could land first and fail.
  const CATALOG = [
    { key: "users", label: "Users", description: "", subscription_tier: "Free" },
    {
      key: "signin-apps",
      label: "Client Auth",
      description: "",
      subscription_tier: "Free",
      requires_features: ["users"],
    },
  ];

  function Probe({ remove }: { remove: string[] }): ReactElement {
    const apply = useApplyFeatureChange("eco-1");
    return (
      <div>
        <button onClick={() => apply.mutate({ add: [], remove })}>go</button>
        <div data-testid="status">{apply.status}</div>
      </div>
    );
  }

  it("sends a dependent's DELETE and lets it settle before the DELETE of what it requires", async () => {
    mockedList.mockResolvedValue(CATALOG);
    const calls: string[] = [];
    let settleSigninApps: () => void = () => undefined;
    mockedRequest.mockImplementation((url: string) => {
      calls.push(url);
      if (url.endsWith("/signin-apps")) {
        return new Promise<void>((resolve) => {
          settleSigninApps = () => resolve();
        });
      }
      return Promise.resolve();
    });

    const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } });
    render(
      <QueryClientProvider client={qc}>
        <Probe remove={["users", "signin-apps"]} />
      </QueryClientProvider>,
    );
    await act(async () => {
      screen.getByText("go").click();
    });

    // signin-apps is in flight; users must not have been sent yet.
    expect(calls).toEqual(["/api/v1/ecosystems/eco-1/features/signin-apps"]);

    await act(async () => {
      settleSigninApps();
    });

    expect(calls).toEqual([
      "/api/v1/ecosystems/eco-1/features/signin-apps",
      "/api/v1/ecosystems/eco-1/features/users",
    ]);
    expect(screen.getByTestId("status").textContent).toBe("success");
  });

  it("orders by the listed catalog: a key whose included feature needs another goes first", async () => {
    // Applications requires nothing itself, but Client Auth comes with it and needs Users.
    mockedList.mockResolvedValue([
      { key: "users", label: "Users", description: "", subscription_tier: "Free" },
      { key: "applications", label: "Applications", description: "", subscription_tier: "Free" },
      {
        key: "client-auth",
        label: "Client Auth",
        description: "",
        subscription_tier: "Free",
        requires_features: ["users"],
        included_with: "applications",
      },
    ]);
    const calls: string[] = [];
    let settleApplications: () => void = () => undefined;
    mockedRequest.mockImplementation((url: string) => {
      calls.push(url);
      if (url.endsWith("/applications")) {
        return new Promise<void>((resolve) => {
          settleApplications = () => resolve();
        });
      }
      return Promise.resolve();
    });

    const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } });
    render(
      <QueryClientProvider client={qc}>
        <Probe remove={["users", "applications"]} />
      </QueryClientProvider>,
    );
    await act(async () => {
      screen.getByText("go").click();
    });

    expect(calls).toEqual(["/api/v1/ecosystems/eco-1/features/applications"]);
    await act(async () => {
      settleApplications();
    });
    expect(calls).toEqual([
      "/api/v1/ecosystems/eco-1/features/applications",
      "/api/v1/ecosystems/eco-1/features/users",
    ]);
  });

  it("still sends the required key after its dependent failed, and reports both by the usual rules", async () => {
    mockedList.mockResolvedValue(CATALOG);
    const calls: string[] = [];
    mockedRequest.mockImplementation((url: string) => {
      calls.push(url);
      return Promise.reject(httpError(500));
    });

    const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } });
    render(
      <QueryClientProvider client={qc}>
        <Probe remove={["users", "signin-apps"]} />
      </QueryClientProvider>,
    );
    await act(async () => {
      screen.getByText("go").click();
    });

    expect(calls).toEqual([
      "/api/v1/ecosystems/eco-1/features/signin-apps",
      "/api/v1/ecosystems/eco-1/features/users",
    ]);
    expect(screen.getByTestId("status").textContent).toBe("error");
  });
});

describe("removalLevels", () => {
  const f = (key: string, requiresFeatures?: string[]): CatalogFeature => ({
    key,
    label: key,
    description: "",
    subscriptionTier: "Free",
    ...(requiresFeatures ? { requiresFeatures } : {}),
  });
  const catalog = [
    f("users"),
    f("user-authentication", ["users"]),
    f("signin-apps", ["users", "user-authentication"]),
    f("notes"),
  ];

  it("puts dependents before what they require, one level per step", () => {
    expect(removalLevels(["users", "user-authentication", "signin-apps"], catalog)).toEqual([
      ["signin-apps"],
      ["user-authentication"],
      ["users"],
    ]);
  });

  it("keeps independent keys in one parallel level, in the caller's order", () => {
    expect(removalLevels(["notes", "signin-apps", "users"], catalog)).toEqual([["notes", "signin-apps"], ["users"]]);
  });

  it("follows requirements transitively through a key that is not in the batch", () => {
    const chain = [f("a", ["b"]), f("b", ["c"]), f("c")];
    expect(removalLevels(["c", "a"], chain)).toEqual([["a"], ["c"]]);
  });

  it("treats a key the catalog does not know as requiring nothing", () => {
    expect(removalLevels(["mystery", "users"], catalog)).toEqual([["mystery", "users"]]);
  });

  it("terminates on a cycle", () => {
    const loop = [f("x", ["y"]), f("y", ["x"])];
    expect(removalLevels(["x", "y"], loop).flat().sort()).toEqual(["x", "y"]);
  });
});

// ── The client and its hooks: the vectors the removal tests above do not reach ─────────────────

const provisionedRow = (key: string, state: "provisioning" | "active" | "removed" = "active") => ({
  feature_key: key,
  state,
  provisioned_at: "2026-01-01T00:00:00Z",
  provisioned_by: null,
  updated: 1767225600,
});

describe("ecosystemFeaturesApi reads and provisioning", () => {
  afterEach(() => {
    mockedJson.mockReset();
    mockedList.mockReset();
    mockedRequest.mockReset();
  });

  it("ecosystems-042: provisions a batch in ONE request and returns the full list", async () => {
    mockedJson.mockResolvedValueOnce({
      features: [provisionedRow("users"), provisionedRow("storage"), provisionedRow("notes")],
    });
    const all = await ecosystemFeaturesApi.provision("eco-1", ["storage", "notes"]);
    expect(mockedJson).toHaveBeenCalledTimes(1);
    const [url, init] = mockedJson.mock.calls[0] as [string, RequestInit];
    expect(url).toBe("/api/v1/ecosystems/eco-1/features");
    expect(init.method).toBe("POST");
    expect(JSON.parse(String(init.body))).toEqual({ keys: ["storage", "notes"] });
    expect(all.map((f) => f.featureKey)).toEqual(["users", "storage", "notes"]);
  });

  it("ecosystems-043: keeps the catalog's order and passes a coming-soon entry through", async () => {
    mockedList.mockResolvedValueOnce([
      { key: "users", label: "Users", description: "", subscription_tier: "Free" },
      { key: "later", label: "Later", description: "", subscription_tier: "Free", coming_soon: true },
    ]);
    const catalog = await ecosystemFeaturesApi.catalog();
    expect(catalog.map((f) => f.key)).toEqual(["users", "later"]);
    expect(catalog[1]?.comingSoon).toBe(true);
    expect(catalog[0]).not.toHaveProperty("comingSoon");
  });

  it("ecosystems-044: lists every state, unfiltered", async () => {
    mockedList.mockResolvedValueOnce([
      provisionedRow("a", "active"),
      provisionedRow("b", "provisioning"),
      provisionedRow("c", "removed"),
    ]);
    const rows = await ecosystemFeaturesApi.list("eco-1");
    expect(rows.map((r) => [r.featureKey, r.state])).toEqual([
      ["a", "active"],
      ["b", "provisioning"],
      ["c", "removed"],
    ]);
  });

  it("ecosystems-049: percent-encodes the ecosystem id and feature key in the path", async () => {
    mockedRequest.mockResolvedValueOnce(undefined);
    await ecosystemFeaturesApi.remove("a/b c", "x y/z");
    expect(mockedRequest.mock.calls[0]?.[0]).toBe(
      `/api/v1/ecosystems/${encodeURIComponent("a/b c")}/features/${encodeURIComponent("x y/z")}`,
    );
  });
});

describe("the feature hooks' cache behavior", () => {
  afterEach(() => {
    mockedJson.mockReset();
    mockedList.mockReset();
    mockedRequest.mockReset();
  });

  function setup() {
    const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } });
    const wrapper = ({ children }: { children: React.ReactNode }) => (
      <QueryClientProvider client={qc}>{children}</QueryClientProvider>
    );
    return { qc, wrapper };
  }

  it("ecosystems-045: the provisioned query stays idle with no ecosystem id, under the empty-marker key", async () => {
    const { qc, wrapper } = setup();
    const { result } = renderHook(() => useProvisionedFeatures(undefined), { wrapper });
    await act(async () => {});
    expect(mockedList).not.toHaveBeenCalled();
    expect(result.current.fetchStatus).toBe("idle");
    expect(qc.getQueryCache().find({ queryKey: ["eco-features", ""] })).toBeDefined();
  });

  it("ecosystems-046: provisioning writes the fresh list into the cache, then invalidates that entry", async () => {
    const { qc, wrapper } = setup();
    const order: string[] = [];
    const setData = vi.spyOn(qc, "setQueryData").mockImplementation(((key: unknown, data: unknown) => {
      order.push("set");
      expect(key).toEqual(["eco-features", "eco-1"]);
      expect((data as { featureKey: string }[]).map((f) => f.featureKey)).toEqual(["storage"]);
      return undefined;
    }) as never);
    const invalidate = vi.spyOn(qc, "invalidateQueries").mockImplementation((async (filters: unknown) => {
      order.push("invalidate");
      expect(filters).toEqual({ queryKey: ["eco-features", "eco-1"] });
    }) as never);
    mockedJson.mockResolvedValueOnce({ features: [provisionedRow("storage")] });
    const { result } = renderHook(() => useProvisionFeatures("eco-1"), { wrapper });
    await act(async () => {
      await result.current.mutateAsync(["storage"]);
    });
    expect(setData).toHaveBeenCalledTimes(1);
    expect(invalidate).toHaveBeenCalledTimes(1);
    expect(order).toEqual(["set", "invalidate"]);
  });

  it("ecosystems-047: applies adds first; a failed add sends no removal and still invalidates", async () => {
    const { qc, wrapper } = setup();
    const invalidate = vi.spyOn(qc, "invalidateQueries").mockResolvedValue(undefined as never);
    mockedJson.mockRejectedValueOnce(httpError(500));
    const { result } = renderHook(() => useApplyFeatureChange("eco-1"), { wrapper });
    await act(async () => {
      await result.current.mutateAsync({ add: ["storage"], remove: ["notes"] }).catch(() => undefined);
    });
    expect(result.current.error?.message).toBe("HTTP 500");
    expect(mockedRequest).not.toHaveBeenCalled();
    expect(invalidate).toHaveBeenCalledWith({ queryKey: ["eco-features", "eco-1"] });
  });

  it("ecosystems-048: serves a second catalog render within the stale window from cache", async () => {
    const { wrapper } = setup();
    mockedList.mockResolvedValue([{ key: "users", label: "Users", description: "", subscription_tier: "Free" }]);
    const first = renderHook(() => useFeatureCatalog(), { wrapper });
    await act(async () => {});
    expect(first.result.current.data?.map((f) => f.key)).toEqual(["users"]);
    const second = renderHook(() => useFeatureCatalog(), { wrapper });
    await act(async () => {});
    expect(second.result.current.data?.map((f) => f.key)).toEqual(["users"]);
    expect(mockedList).toHaveBeenCalledTimes(1);
  });

  it("ecosystems-050: removing one feature invalidates the provisioned entry and writes nothing to it", async () => {
    const { qc, wrapper } = setup();
    const setData = vi.spyOn(qc, "setQueryData");
    const invalidate = vi.spyOn(qc, "invalidateQueries").mockResolvedValue(undefined as never);
    mockedRequest.mockResolvedValueOnce(undefined);
    const { result } = renderHook(() => useRemoveFeature("eco-1"), { wrapper });
    await act(async () => {
      await result.current.mutateAsync("widgets");
    });
    expect(invalidate).toHaveBeenCalledWith({ queryKey: ["eco-features", "eco-1"] });
    expect(setData).not.toHaveBeenCalled();
  });
});

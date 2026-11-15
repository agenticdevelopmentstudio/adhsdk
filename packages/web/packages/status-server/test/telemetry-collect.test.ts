import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";

// Conformance tests for the telemetry service recipe: `collect`, `collectTelemetry` and
// `emptySnapshot`. The provider fetchers are replaced at the module boundary so the
// composition root is exercised with scripted FetchResults and no network.
const fetchers = vi.hoisted(() => ({
  glitchtip: vi.fn(),
  posthog: vi.fn(),
  vercel: vi.fn(),
}));

vi.mock("../src/telemetry/fetchers/glitchtip", () => ({
  glitchtipFetcher: () => ({ fetch: fetchers.glitchtip }),
}));
vi.mock("../src/telemetry/fetchers/posthog", () => ({
  posthogFetcher: () => ({ fetch: fetchers.posthog }),
}));
vi.mock("../src/telemetry/fetchers/vercel-runtime", () => ({
  vercelRuntimeFetcher: () => ({ fetch: fetchers.vercel }),
}));

import { collect } from "../src/telemetry/collect";
import { collectTelemetry } from "../src/telemetry/server";
import { emptySnapshot } from "../src/telemetry/types";
import type { ErrorDTO } from "../src/telemetry/types";
import type { StatusConfig } from "../src/config/port";
import type { Storage } from "../src/storage/ports";

function item(id: string): ErrorDTO {
  return {
    id,
    issueKey: `GT-${id}`,
    project: "web",
    title: "Error",
    culprit: null,
    level: "error",
    count: 5,
    userCount: 2,
    firstSeen: "2026-09-24T00:00:00Z",
    lastSeen: "2026-09-24T12:00:00Z",
    permalink: "https://sentry.io/...",
  };
}

const GLITCHTIP = {
  GLITCHTIP_URL: "https://glitchtip.example",
  GLITCHTIP_API_TOKEN: "tok",
  GLITCHTIP_ORG: "adh",
};
const POSTHOG = {
  POSTHOG_HOST: "https://posthog.example",
  POSTHOG_API_KEY: "key",
  POSTHOG_PROJECT_ID: "1",
};

function configWith(credentials: Record<string, string | undefined>): StatusConfig {
  return { credentials } as unknown as StatusConfig;
}

function makeStorage() {
  const save = () => ({
    save: vi.fn(async () => {}),
    load: vi.fn(async () => []),
  });
  const telemetry = { errors: save(), analytics: save(), runtimeErrors: save() };
  const recordObservations = vi.fn(async () => {});
  const storage = { telemetry, observations: { recordObservations } } as unknown as Storage;
  return { storage, telemetry, recordObservations };
}

describe("collect", () => {
  it("telemetry-001: invokes the fetcher and the store and reports the count", async () => {
    const fetch = vi.fn(async () => ({ ok: true, items: [item("1")], complete: true }));
    const save = vi.fn(async () => {});
    const result = await collect({ fetch }, { save });
    expect(fetch).toHaveBeenCalledTimes(1);
    expect(save).toHaveBeenCalledTimes(1);
    expect(save).toHaveBeenCalledWith([item("1")], { complete: true });
    expect(result).toEqual({ ok: true, count: 1 });
  });

  it("telemetry-002: an ok:false poll is never persisted", async () => {
    const save = vi.fn(async () => {});
    const result = await collect({ fetch: async () => ({ ok: false, items: [], complete: true }) }, { save });
    expect(save).not.toHaveBeenCalled();
    expect(result).toEqual({ ok: false, count: 0 });
  });

  it("telemetry-003: a partial answer passes complete:false to the store", async () => {
    const save = vi.fn(async () => {});
    const items = [item("1"), item("2")];
    const result = await collect({ fetch: async () => ({ ok: true, items, complete: false }) }, { save });
    expect(result).toEqual({ ok: true, count: 2 });
    expect(save).toHaveBeenCalledWith(items, { complete: false });
  });

  it("telemetry-004: an omitted complete defaults to true", async () => {
    const save = vi.fn(async () => {});
    const result = await collect({ fetch: async () => ({ ok: true, items: [item("1")] }) }, { save });
    expect(save).toHaveBeenCalledWith([item("1")], { complete: true });
    expect(result).toEqual({ ok: true, count: 1 });
  });

  it("telemetry-009: complete:false reaches a reconciling store unchanged", async () => {
    const save = vi.fn(async () => {});
    await collect({ fetch: async () => ({ ok: true, items: [item("1")], complete: false }) }, { save });
    expect(save).toHaveBeenCalledTimes(1);
    expect(save.mock.calls[0]).toEqual([[item("1")], { complete: false }]);
  });
});

describe("collectTelemetry", () => {
  let errorSpy: ReturnType<typeof vi.spyOn>;

  beforeEach(() => {
    fetchers.glitchtip.mockReset();
    fetchers.posthog.mockReset();
    fetchers.vercel.mockReset();
    errorSpy = vi.spyOn(console, "error").mockImplementation(() => {});
  });
  afterEach(() => errorSpy.mockRestore());

  it("telemetry-005: polls both providers concurrently and saves each stream", async () => {
    let releaseErrors!: () => void;
    let releaseAnalytics!: () => void;
    fetchers.glitchtip.mockImplementation(
      () =>
        new Promise((resolve) => {
          releaseErrors = () => resolve({ ok: true, items: [item("1")] });
        }),
    );
    fetchers.posthog.mockImplementation(
      () =>
        new Promise((resolve) => {
          releaseAnalytics = () => resolve({ ok: true, items: [{ metric: "pageviews" }] });
        }),
    );
    const { storage, telemetry } = makeStorage();
    const run = collectTelemetry(storage, configWith({ ...GLITCHTIP, ...POSTHOG }));
    // Both fetches are in flight before either has answered: the polls are not serial.
    await vi.waitFor(() => {
      expect(fetchers.glitchtip).toHaveBeenCalledTimes(1);
      expect(fetchers.posthog).toHaveBeenCalledTimes(1);
    });
    releaseErrors();
    releaseAnalytics();
    await expect(run).resolves.toBeUndefined();
    expect(telemetry.errors.save).toHaveBeenCalledTimes(1);
    expect(telemetry.analytics.save).toHaveBeenCalledTimes(1);
  });

  it("telemetry-006: an unconfigured provider is skipped", async () => {
    fetchers.glitchtip.mockResolvedValue({ ok: true, items: [item("1")] });
    const { storage, telemetry } = makeStorage();
    await collectTelemetry(storage, configWith({ ...GLITCHTIP, POSTHOG_API_KEY: "" }));
    expect(fetchers.glitchtip).toHaveBeenCalledTimes(1);
    expect(fetchers.posthog).not.toHaveBeenCalled();
    expect(telemetry.errors.save).toHaveBeenCalledTimes(1);
    expect(telemetry.analytics.save).not.toHaveBeenCalled();
  });

  it("telemetry-007: a failing errors save is logged and does not stop the analytics leg", async () => {
    fetchers.glitchtip.mockResolvedValue({ ok: true, items: [item("1")] });
    fetchers.posthog.mockResolvedValue({ ok: true, items: [{ metric: "pageviews" }] });
    const { storage, telemetry, recordObservations } = makeStorage();
    telemetry.errors.save.mockRejectedValue(new Error("disk full"));
    await expect(collectTelemetry(storage, configWith({ ...GLITCHTIP, ...POSTHOG }))).resolves.toBeUndefined();
    expect(errorSpy).toHaveBeenCalledWith("[telemetry] errors collection failed", expect.any(Error));
    expect(telemetry.analytics.save).toHaveBeenCalledTimes(1);
    expect(recordObservations).toHaveBeenCalledTimes(1);
    expect(recordObservations.mock.calls[0]?.[0]).toContainEqual({
      source: "glitchtip",
      configured: true,
      reachable: false,
    });
  });

  it("telemetry-010: a reachable GlitchTip is recorded as an observation", async () => {
    fetchers.glitchtip.mockResolvedValue({ ok: true, items: [item("1")] });
    fetchers.posthog.mockResolvedValue({ ok: true, items: [{ metric: "pageviews" }] });
    const { storage, recordObservations } = makeStorage();
    await collectTelemetry(storage, configWith({ ...GLITCHTIP, ...POSTHOG }));
    expect(recordObservations).toHaveBeenCalledTimes(1);
    expect(recordObservations.mock.calls[0]?.[0]).toContainEqual({
      source: "glitchtip",
      configured: true,
      reachable: true,
    });
  });
});

describe("emptySnapshot", () => {
  it("telemetry-008: returns the empty snapshot shape", () => {
    expect(emptySnapshot()).toEqual({ generatedAt: "", errors: [], analytics: [] });
  });
});

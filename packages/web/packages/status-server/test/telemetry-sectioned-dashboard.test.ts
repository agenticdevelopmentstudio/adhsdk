import { afterEach, describe, expect, it, vi } from "vitest";
import { sectionedDashboard } from "../src/telemetry/dashboard/sectioned-dashboard";

interface Sections {
  a: number;
  b: string;
}

const flush = async (): Promise<void> => {
  for (let i = 0; i < 20; i++) await Promise.resolve();
};

function deferred<T>() {
  let resolve!: (v: T) => void;
  let reject!: (e: unknown) => void;
  const promise = new Promise<T>((res, rej) => {
    resolve = res;
    reject = rej;
  });
  return { promise, resolve, reject };
}

afterEach(() => {
  vi.restoreAllMocks();
});

function setup(loaders: { a: () => Promise<number>; b: () => Promise<string> }) {
  const clock = { t: 1_000_000 };
  const built = vi.fn();
  const dash = sectionedDashboard<"k1" | "k2", Sections>({
    ttlMs: 10_000,
    retryMs: 1_000,
    sections: ["a", "b"],
    now: () => clock.t,
    loaders: (key) => {
      built(key);
      return loaders;
    },
  });
  return { dash, clock, built };
}

describe("sectionedDashboard", () => {
  it("a cold read answers immediately and starts a refresh", () => {
    const { dash, built } = setup({ a: () => new Promise(() => undefined), b: () => new Promise(() => undefined) });
    const r = dash.read("k1");
    expect(r.refreshing).toBe(true);
    expect(r.sections.a).toEqual({ data: null, error: null, updatedAt: null });
    expect(built).toHaveBeenCalledTimes(1);
  });

  it("publishes each section as it finishes, in order, one at a time", async () => {
    const a = deferred<number>();
    const b = vi.fn(async () => "two");
    const { dash } = setup({ a: () => a.promise, b });
    dash.read("k1");
    await flush();
    expect(b).not.toHaveBeenCalled();

    a.resolve(1);
    await flush();
    const done = dash.read("k1");
    expect(done.refreshing).toBe(false);
    expect(done.sections.a.data).toBe(1);
    expect(done.sections.b.data).toBe("two");
  });

  it("reads during a refresh never start another", async () => {
    const a = deferred<number>();
    const { dash, built } = setup({ a: () => a.promise, b: async () => "x" });
    dash.read("k1");
    dash.read("k1");
    dash.read("k1");
    expect(built).toHaveBeenCalledTimes(1);
    a.resolve(1);
    await flush();
  });

  it("does not refresh again inside the TTL, and does after it", async () => {
    const { dash, clock, built } = setup({ a: async () => 1, b: async () => "x" });
    dash.read("k1");
    await flush();
    clock.t += 9_999;
    expect(dash.read("k1").refreshing).toBe(false);
    expect(built).toHaveBeenCalledTimes(1);
    clock.t += 1;
    expect(dash.read("k1").refreshing).toBe(true);
    expect(built).toHaveBeenCalledTimes(2);
    await flush();
  });

  it("a failed section keeps its last good data, reports why, and the rest still load", async () => {
    vi.spyOn(console, "warn").mockImplementation(() => {});
    let fail = false;
    const { dash, clock } = setup({
      a: async () => {
        if (fail) throw new Error("HTTP 504");
        return 1;
      },
      b: async () => "x",
    });
    dash.read("k1");
    await flush();
    fail = true;
    clock.t += 10_000;
    dash.read("k1");
    await flush();
    const r = dash.read("k1");
    expect(r.sections.a).toMatchObject({ data: 1, error: "HTTP 504" });
    expect(r.sections.b).toMatchObject({ data: "x", error: null });
  });

  it("retries sooner after a failure than after a success", async () => {
    vi.spyOn(console, "warn").mockImplementation(() => {});
    const { dash, clock, built } = setup({ a: async () => Promise.reject(new Error("x")), b: async () => "x" });
    dash.read("k1");
    await flush();
    clock.t += 999;
    dash.read("k1");
    expect(built).toHaveBeenCalledTimes(1);
    clock.t += 1;
    dash.read("k1");
    expect(built).toHaveBeenCalledTimes(2);
    await flush();
  });

  it("retries only the failing section, backing off with each failure in a row", async () => {
    vi.spyOn(console, "warn").mockImplementation(() => {});
    const a = vi.fn(async () => Promise.reject(new Error("x")));
    const b = vi.fn(async () => "x");
    const { dash, clock } = setup({ a, b });
    dash.read("k1");
    await flush();
    clock.t += 1_000; // a's first retry is due after retryMs
    dash.read("k1");
    await flush();
    expect([a.mock.calls.length, b.mock.calls.length]).toEqual([2, 1]);
    clock.t += 1_999; // the second waits twice as long
    dash.read("k1");
    expect(a).toHaveBeenCalledTimes(2);
    clock.t += 1;
    dash.read("k1");
    await flush();
    expect([a.mock.calls.length, b.mock.calls.length]).toEqual([3, 1]);
  });

  it("an answer known to be short is shown as a success but retried like a failure", async () => {
    const clock = { t: 1_000_000 };
    const built = vi.fn();
    const dash = sectionedDashboard<"k1", Sections>({
      ttlMs: 10_000,
      retryMs: 1_000,
      sections: ["a", "b"],
      now: () => clock.t,
      incomplete: (name, data) => name === "a" && data === -1,
      loaders: () => {
        built();
        return { a: async () => -1, b: async () => "x" };
      },
    });
    dash.read("k1");
    await flush();
    expect(dash.read("k1").sections.a).toMatchObject({ data: -1, error: null });
    clock.t += 1_000;
    dash.read("k1");
    expect(built).toHaveBeenCalledTimes(2);
    await flush();
  });

  it("keeps keys separate", async () => {
    const { dash, built } = setup({ a: async () => 1, b: async () => "x" });
    dash.read("k1");
    dash.read("k2");
    expect(built.mock.calls).toEqual([["k1"], ["k2"]]);
    await flush();
  });

  it("a loaders() builder that throws cannot wedge the key refreshing forever", async () => {
    vi.spyOn(console, "warn").mockImplementation(() => {});
    const dash = sectionedDashboard<"k", Sections>({
      ttlMs: 10_000,
      sections: ["a", "b"],
      loaders: () => {
        throw new Error("bad build");
      },
    });
    dash.read("k");
    await flush();
    expect(dash.read("k").refreshing).toBe(false);
  });

  describe("settle", () => {
    it("resolves true at once when nothing was ever read, and never starts a refresh", async () => {
      const { dash, built } = setup({ a: async () => 1, b: async () => "x" });
      await expect(dash.settle("k1", 1_000)).resolves.toBe(true);
      expect(built).not.toHaveBeenCalled();
    });

    it("waits for the refresh in flight, then a second read has the data", async () => {
      const a = deferred<number>();
      const { dash } = setup({ a: () => a.promise, b: async () => "two" });
      expect(dash.read("k1").refreshing).toBe(true);
      const settled = dash.settle("k1", 60_000);
      a.resolve(1);
      await expect(settled).resolves.toBe(true);
      const r = dash.read("k1");
      expect(r.refreshing).toBe(false);
      expect(r.sections.a.data).toBe(1);
      expect(r.sections.b.data).toBe("two");
    });

    it("gives up at the deadline and reports the key still refreshing", async () => {
      vi.useFakeTimers();
      try {
        const { dash } = setup({ a: () => new Promise(() => undefined), b: async () => "x" });
        dash.read("k1");
        const settled = dash.settle("k1", 5_000);
        await vi.advanceTimersByTimeAsync(5_000);
        await expect(settled).resolves.toBe(false);
        expect(dash.read("k1").refreshing).toBe(true);
      } finally {
        vi.useRealTimers();
      }
    });

    it("resolves true once the refresh has finished, without waiting", async () => {
      const { dash } = setup({ a: async () => 1, b: async () => "x" });
      dash.read("k1");
      await flush();
      await expect(dash.settle("k1", 60_000)).resolves.toBe(true);
    });
  });
});

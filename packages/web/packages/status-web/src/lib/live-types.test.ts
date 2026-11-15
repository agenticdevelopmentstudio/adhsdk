import { describe, it, expect } from "vitest";
import { readFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import * as liveTypesModule from "./live-types";
import { isSameSnapshot } from "../hooks/use-live-snapshot";
import { liveSnapshot } from "./live-snapshot.fixture";

// live-types.ts is a type-only module, so most vectors are compile-time facts that `tsc`
// enforces through read-types-parity.test.ts and the fixture's `LiveSnapshot` return type.
// Vitest transpiles without typechecking, so those vectors are skipped here with the reason.

describe("live-types conformance", () => {
  it("live-types-001 the fixture snapshot carries every required LiveSnapshot field", () => {
    const snap = liveSnapshot();
    expect(Object.keys(snap).sort()).toEqual(
      [
        "blind",
        "configDegraded",
        "configReason",
        "deployments",
        "freshness",
        "generatedAt",
        "lastCycleAt",
        "monitorVersion",
        "platformSummary",
        "probeIntervalMs",
        "providers",
        "services",
        "staleMonitors",
        "staleProd",
      ].sort(),
    );
    expect(snap.generatedAt).toBe("2026-06-30T00:00:00.000Z");
    expect(snap.configDegraded).toBe(false);
    expect(snap.configReason).toBeNull();
  });

  it("live-types-002 providers hold exactly the four ProviderKey members, each with configured and ok", () => {
    const { providers } = liveSnapshot();
    expect(Object.keys(providers).sort()).toEqual(["cloudflare-pages", "crunchy", "railway", "vercel"]);
    expect("cloudflare" in providers).toBe(false);
    for (const health of Object.values(providers)) {
      expect(Object.keys(health).sort()).toEqual(["configured", "ok"]);
      expect(typeof health.configured).toBe("boolean");
      expect(typeof health.ok).toBe("boolean");
    }
  });

  it("live-types-003 two snapshots with equal generatedAt are the same frame; a new clock or no previous is not", () => {
    const a = liveSnapshot({ generatedAt: "2026-06-30T00:00:00.000Z" });
    const b = liveSnapshot({ generatedAt: "2026-06-30T00:00:00.000Z" });
    expect(a).not.toBe(b);
    expect(isSameSnapshot(a, b)).toBe(true);
    const c = liveSnapshot({ generatedAt: "2026-06-30T00:01:00.000Z" });
    expect(isSameSnapshot(a, c)).toBe(false);
    expect(isSameSnapshot(null, c)).toBe(false);
  });

  it.skip("live-types-004 LiveServiceDTO carries the ServiceStatusDTO fields plus dnsOk and downSince — compile-time only; vitest does not typecheck", () => {});

  it.skip("live-types-005 StaleProdDTO fields and nullability — compile-time only; vitest does not typecheck", () => {});

  it.skip("live-types-006 ProviderKey rejects cloudflare and the optional-field rules — compile-time only; vitest does not typecheck", () => {});

  it("live-types-007 the module exports no runtime values", () => {
    expect(Object.keys(liveTypesModule)).toEqual([]);
  });

  it("live-types-008 the module's only import is the type-only import from ../types", () => {
    const source = readFileSync(join(dirname(fileURLToPath(import.meta.url)), "live-types.ts"), "utf8");
    const imports = source.split("\n").filter((line) => /^\s*import\b/.test(line));
    expect(imports).toHaveLength(1);
    expect(imports[0]).toMatch(/^import type \{[^}]*\} from "\.\.\/types";$/);
  });

  it.skip("live-types-009 the client copy matches the server copy field for field — enforced at compile time by read-types-parity.test.ts (tsc), not at runtime", () => {});
});

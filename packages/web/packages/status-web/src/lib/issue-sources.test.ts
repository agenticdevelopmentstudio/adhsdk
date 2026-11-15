import { describe, it, expect } from "vitest";
import { readdirSync, readFileSync, statSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import * as clientModule from "./issue-sources";
import { ISSUE_SOURCES, SOURCE_LABEL, isIssueSource } from "./issue-sources";
// The SERVER's twin, imported by relative path (the two files restate the vocabulary by hand;
// see deploy-status-parity.test.ts for the precedent of reading the server copy directly).
// Loaded by path at runtime so tsc does not pull the server file under this package's rootDir.
const serverModule = (await import(
  /* @vite-ignore */ fileURLToPath(new URL("../../../status-server/src/monitor/issue-sources.ts", import.meta.url))
)) as typeof clientModule;

const EXPECTED_ORDER = [
  "dns",
  "http",
  "glitchtip",
  "vercel",
  "vercel-runtime",
  "cloudflare-pages",
  "railway",
  "crunchy",
];

describe("issue sources", () => {
  it("includes dns as a first-class source with a label", () => {
    expect(ISSUE_SOURCES).toContain("dns");
    expect(SOURCE_LABEL.dns).toBe("DNS");
    // Every source has a label.
    for (const s of ISSUE_SOURCES) expect(SOURCE_LABEL[s]).toBeTruthy();
  });

  it("issue-sources-001 dns is in the order list, labelled DNS, and every label is non-empty", () => {
    expect(ISSUE_SOURCES.includes("dns")).toBe(true);
    expect(SOURCE_LABEL.dns).toBe("DNS");
    for (const label of Object.values(SOURCE_LABEL)) {
      expect(typeof label).toBe("string");
      expect(label.length).toBeGreaterThan(0);
    }
  });

  it("issue-sources-002 cloudflare-pages is spelled that way in both the guard and the order list", () => {
    expect(isIssueSource("cloudflare-pages")).toBe(true);
    expect(ISSUE_SOURCES.includes("cloudflare-pages")).toBe(true);
  });

  it("issue-sources-003 the order list is the canonical eight sources", () => {
    expect(ISSUE_SOURCES).toEqual(EXPECTED_ORDER);
    expect(ISSUE_SOURCES).toHaveLength(8);
    expect(new Set(ISSUE_SOURCES).size).toBe(8);
  });

  it("issue-sources-004 the label map holds exactly the eight pairs", () => {
    expect(SOURCE_LABEL).toEqual({
      dns: "DNS",
      http: "HTTP",
      glitchtip: "GlitchTip",
      vercel: "Vercel",
      "vercel-runtime": "Vercel runtime logs",
      "cloudflare-pages": "Cloudflare",
      railway: "Railway",
      crunchy: "Crunchy Bridge",
    });
    expect(Object.keys(SOURCE_LABEL)).toHaveLength(8);
  });

  it("issue-sources-005 the guard accepts every member of the order list", () => {
    for (const s of ISSUE_SOURCES) expect(isIssueSource(s)).toBe(true);
    expect(ISSUE_SOURCES).toHaveLength(8);
  });

  it("issue-sources-006 the guard rejects the integration spelling cloudflare", () => {
    expect(isIssueSource("cloudflare")).toBe(false);
  });

  it("issue-sources-007 the guard does not normalize case or whitespace", () => {
    expect(isIssueSource("DNS")).toBe(false);
    expect(isIssueSource(" http")).toBe(false);
    expect(isIssueSource("http ")).toBe(false);
  });

  it("issue-sources-008 the guard returns false without throwing for the empty string and an activity kind", () => {
    expect(() => isIssueSource("")).not.toThrow();
    expect(isIssueSource("")).toBe(false);
    expect(isIssueSource("deploy")).toBe(false);
  });

  it("issue-sources-010 looking up the label map with a non-member yields undefined", () => {
    expect((SOURCE_LABEL as Record<string, string>)["netlify"]).toBeUndefined();
  });

  it("issue-sources-013 the module exports no stuck-deploy threshold", () => {
    expect(Object.keys(clientModule).sort()).toEqual(["ISSUE_SOURCES", "SOURCE_LABEL", "isIssueSource"]);
    expect("STUCK_DEPLOY_MS" in clientModule).toBe(false);
  });

  it("issue-sources-014 the client vocabulary, labels and order equal the server's, in order", () => {
    expect(ISSUE_SOURCES).toEqual(serverModule.ISSUE_SOURCES);
    expect(SOURCE_LABEL).toEqual(serverModule.SOURCE_LABEL);
    expect(Object.keys(SOURCE_LABEL)).toEqual(Object.keys(serverModule.SOURCE_LABEL));
  });

  it("issue-sources-015 no other module in the client source tree reads the stuck-deploy threshold", () => {
    const srcRoot = join(dirname(fileURLToPath(import.meta.url)), "..");
    const readers: string[] = [];
    const walk = (dir: string): void => {
      for (const name of readdirSync(dir)) {
        const full = join(dir, name);
        if (statSync(full).isDirectory()) {
          walk(full);
        } else if (/\.(ts|tsx)$/.test(name) && !/\.test\.(ts|tsx)$/.test(name)) {
          // Doc comments may name the server's constant; only code that reads it counts.
          const code = readFileSync(full, "utf8")
            .replace(/\/\*[\s\S]*?\*\//g, "")
            .replace(/^\s*\/\/.*$/gm, "");
          if (code.includes("STUCK_DEPLOY_MS")) readers.push(full);
        }
      }
    };
    walk(srcRoot);
    expect(readers).toEqual([]);
  });
});
